import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:songbuddy/constants/app_colors.dart';
import 'package:songbuddy/constants/app_text_styles.dart';
import 'package:songbuddy/providers/auth_provider.dart';
import 'package:songbuddy/services/spotify_service.dart';
import 'package:songbuddy/services/spotify_deep_link_service.dart';
import 'package:songbuddy/services/backend_service.dart';
import 'package:songbuddy/services/simple_lifecycle_manager.dart';
import 'package:songbuddy/models/Post.dart';
import 'package:songbuddy/models/ProfileData.dart';
import 'package:songbuddy/widgets/create_post_sheet.dart';
import 'package:songbuddy/widgets/swipeable_post_card.dart';
import 'package:songbuddy/screens/create_post_screen.dart';
import 'package:songbuddy/utils/post_sharing_utils.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  late final AuthProvider _authProvider;
  late final SpotifyService _spotifyService;
  late final BackendService _backendService;
  late final ScrollController _scrollController;

  bool _initialized = false;
  bool _loading = false;

  Map<String, dynamic>? _user;
  Map<String, dynamic>? _currentlyPlaying; // can be null when 204
  List<Map<String, dynamic>> _topArtists = const [];
  List<Map<String, dynamic>> _topTracks = const [];
  List<Map<String, dynamic>> _recentlyPlayed = const [];
  bool _insufficientScopeTop = false;
  
  // Backend sync for currently playing (now handled by background service)
  Map<String, dynamic>? _lastSyncedCurrentlyPlaying;
  
  // Track selection for posts
  final Set<String> _selectedTracks = <String>{};
  bool _isSelectionMode = false;

  // User posts
  List<Post> _userPosts = [];
  bool _loadingPosts = false;
  
  // Profile data (includes follow status)
  ProfileData? _profileData;
  
  // Smart FAB positioning
  bool _shouldUseFAB = true;
  bool _isScrollingDown = false;
  bool _showFAB = true;
  double _lastScrollPosition = 0.0;

  final bool _loadingTop = false; // non-blocking loading for top artists/tracks (kept for future use)
  static const Duration _animDur = Duration(milliseconds: 250);

  @override
  void initState() {
    super.initState();
    _authProvider = AuthProvider();
    _authProvider.addListener(_onAuthChanged);
    _spotifyService = SpotifyService();
    _backendService = BackendService();
    _scrollController = ScrollController();
    
    // Add scroll listener for smart FAB behavior
    _scrollController.addListener(_onScroll);
    
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() {
      _loading = true;
    });
    try {
      await _authProvider.initialize();
      _authProvider.addListener(_onAuthChanged);
      _initialized = true;
      if (_authProvider.isAuthenticated) {
        await _fetchAll();
      }
    } catch (e) {
      // Handle error silently
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    if (_initialized) {
      _authProvider.removeListener(_onAuthChanged);
    }
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onAuthChanged() {
    if (!mounted) return;
    setState(() {});
  }


  /// Sync currently playing data to backend when it changes
  Future<void> _syncCurrentlyPlayingToBackend() async {
    if (_authProvider.userId == null) return;
    
    // Check if currently playing has changed
    if (_currentlyPlaying == _lastSyncedCurrentlyPlaying) {
      debugPrint('🎵 ProfileScreen: Currently playing unchanged - skipping sync');
      return;
    }
    
    debugPrint('🎵 ProfileScreen: Currently playing changed - syncing to backend');
    debugPrint('🎵 ProfileScreen: Old: $_lastSyncedCurrentlyPlaying');
    debugPrint('🎵 ProfileScreen: New: $_currentlyPlaying');
    
    try {
      final success = await _backendService.updateCurrentlyPlaying(
        _authProvider.userId!,
        _currentlyPlaying,
      );
      
      if (success) {
        debugPrint('✅ ProfileScreen: Successfully synced currently playing to backend');
        _lastSyncedCurrentlyPlaying = _currentlyPlaying;
      } else {
        debugPrint('❌ ProfileScreen: Failed to sync currently playing to backend');
      }
    } catch (e) {
      debugPrint('❌ ProfileScreen: Error syncing currently playing to backend: $e');
      // Don't show error to user - this is background sync
    }
  }

  /// Handle scroll events for smart FAB behavior
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    
    final currentScrollPosition = _scrollController.position.pixels;
    final isScrollingDown = currentScrollPosition > _lastScrollPosition;
    final isAtTop = currentScrollPosition <= 0;
    
    // Update FAB visibility based on scroll direction
    if (isScrollingDown && !_isScrollingDown && currentScrollPosition > 100) {
      // Started scrolling down, hide FAB
      setState(() {
        _isScrollingDown = true;
        _showFAB = false;
      });
    } else if (!isScrollingDown && _isScrollingDown) {
      // Started scrolling up, show FAB
      setState(() {
        _isScrollingDown = false;
        _showFAB = true;
      });
    } else if (isAtTop) {
      // At top, always show FAB
      setState(() {
        _showFAB = true;
        _isScrollingDown = false;
      });
    }
    
    _lastScrollPosition = currentScrollPosition;
  }

  /// Calculate if content is long enough to warrant scroll-aware FAB
  bool get _hasEnoughContentToScroll {
    if (!mounted) return false;
    
    final screenHeight = MediaQuery.of(context).size.height;
    final appBarHeight = AppBar().preferredSize.height;
    final statusBarHeight = MediaQuery.of(context).padding.top;
    const bottomNavHeight = kBottomNavigationBarHeight;
    
    final availableHeight = screenHeight - appBarHeight - statusBarHeight - bottomNavHeight;
    
    // Estimate content height based on posts and other content
    final estimatedContentHeight = _calculateEstimatedContentHeight();
    
    // Use 80% threshold - if content is less than 80% of available height, don't use FAB
    return estimatedContentHeight > availableHeight * 0.8;
  }

  /// Estimate total content height
  double _calculateEstimatedContentHeight() {
    double totalHeight = 0;
    
    // Profile header section (~300px)
    totalHeight += 300;
    
    // Music sections (currently playing, top artists, tracks, recently played)
    if (_currentlyPlaying != null) totalHeight += 120;
    if (_topArtists.isNotEmpty) totalHeight += 150;
    if (_topTracks.isNotEmpty) totalHeight += 150;
    if (_recentlyPlayed.isNotEmpty) totalHeight += 150;
    
    // Posts section - estimate ~200px per post
    totalHeight += _userPosts.length * 200.0;
    
    // Add some padding
    totalHeight += 100;
    
    return totalHeight;
  }

  /// Update FAB strategy based on content
  void _updateFABStrategy() {
    final shouldUseFAB = _hasEnoughContentToScroll;
    if (shouldUseFAB != _shouldUseFAB) {
      setState(() {
        _shouldUseFAB = shouldUseFAB;
        if (!_shouldUseFAB) {
          _showFAB = false; // Hide FAB when switching to header mode
        }
      });
    }
  }

  Future<void> _fetchAll() async {
    if (!_authProvider.isAuthenticated || _authProvider.accessToken == null) return;
    setState(() {
      _loading = true;
    });
    final token = _authProvider.accessToken;
    if (token == null) return;
    
    // ignore: avoid_print
    print('[Profile] Fetch start');
    try {
      // Essential data fetching in parallel for instant UI updates
      final futures = <Future<void>>[
        // Spotify user profile (required)
        () async {
          try {
            final user = await _spotifyService.getCurrentUser(token);
            setState(() {
              _user = user;
            });
          } catch (e) {
            print('[Profile] Failed to fetch Spotify user: $e');
          }
        }(),
        
        // Essential backend profile data (posts count, followers, following, username)
        () async {
          try {
            if (_authProvider.userId != null) {
              final profileData = await _backendService.getUserProfile(_authProvider.userId!, currentUserId: _authProvider.userId);
              setState(() {
                _profileData = profileData;
              });
              print('[Profile] Essential profile data loaded: ${profileData.user.username}, ${profileData.user.postsCount} posts, ${profileData.user.followersCount} followers');
            }
          } catch (e) {
            print('[Profile] Failed to fetch essential profile data: $e');
          }
        }(),
        
        // Optional Spotify data with individual handling
        () async {
          try {
            _currentlyPlaying = await _spotifyService.getCurrentlyPlaying(token);
            // Sync to backend after fetching from Spotify
            _syncCurrentlyPlayingToBackend();
          } catch (e) {
            // ignore
          }
        }(),
        () async {
          try {
            final ta = await _spotifyService.getUserTopArtists(
              token,
              timeRange: 'medium_term',
              limit: 10,
            );
            _topArtists = (ta['items'] as List<dynamic>? ?? const []).cast<Map<String, dynamic>>();
          } catch (e) {
            _insufficientScopeTop = true;
            _topArtists = const [];
          }
        }(),
        () async {
          try {
            final tt = await _spotifyService.getUserTopTracks(
              token,
              timeRange: 'medium_term',
              limit: 10,
            );
            _topTracks = (tt['items'] as List<dynamic>? ?? const []).cast<Map<String, dynamic>>();
          } catch (e) {
            _insufficientScopeTop = true;
            _topTracks = const [];
          }
        }(),
        () async {
          try {
            final rp = await _spotifyService.getRecentlyPlayed(token, limit: 10);
            _recentlyPlayed = (rp['items'] as List<dynamic>? ?? const []).cast<Map<String, dynamic>>();
          } catch (e) {}
        }(),
      ];
      await Future.wait(futures);
      
      // Fetch user posts separately (heavier data, can load after essential info)
      _fetchUserPosts();
      
      // Background sync is now handled by AppLifecycleManager
      // Force immediate sync to catch up
      await SimpleLifecycleManager.instance.forceSync();
      
      // ignore: avoid_print
      print('[Profile] Fetch success: user=${_user?['id']} topArtists=${_topArtists.length} topTracks=${_topTracks.length} recently=${_recentlyPlayed.length}');
    } catch (e) {
      // ignore: avoid_print
      print('[Profile] Fetch error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }



  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedTracks.clear();
      }
    });
  }

  void _toggleTrackSelection(String trackId) {
    setState(() {
      if (_selectedTracks.contains(trackId)) {
        _selectedTracks.remove(trackId);
      } else {
        // Clear any existing selection and select only this track
        _selectedTracks.clear();
        _selectedTracks.add(trackId);
      }
    });
  }

  void _createPost() {
    if (_selectedTracks.isEmpty) return;
    
    // Find the selected track from recently played
    final selectedTrackId = _selectedTracks.first;
    final selectedTrack = _recentlyPlayed.firstWhere(
      (track) => track['track']['id'] == selectedTrackId,
      orElse: () => _recentlyPlayed.first,
    );
    
    // Navigate to create post screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreatePostScreen(
          selectedTrack: selectedTrack['track'],
          selectedTrackId: selectedTrackId,
        ),
      ),
    ).then((success) {
      if (success == true) {
        // Post created successfully, exit selection mode and refresh posts
        _toggleSelectionMode();
        _fetchUserPosts();
        HapticFeedback.lightImpact();
      }
    });
  }

  /// Fetch user posts only (essential profile data is now fetched in parallel)
  Future<void> _fetchUserPosts() async {
    if (_authProvider.userId == null) {
      print('❌ ProfileScreen: User ID is null, cannot fetch posts');
      return;
    }
    
    print('🔍 ProfileScreen: Fetching user posts for: ${_authProvider.userId}');
    
    setState(() {
      _loadingPosts = true;
    });

    try {
      final profileData = await _backendService.getUserProfile(_authProvider.userId!, currentUserId: _authProvider.userId);
      print('🔍 ProfileScreen: Received posts data: ${profileData.posts.length} posts');
      
      // Update only posts data (profile data already loaded in parallel)
      setState(() {
        _userPosts = profileData.posts;
      });
      
      // Update FAB strategy based on new content
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateFABStrategy();
      });
      
      print('✅ ProfileScreen: Successfully updated _userPosts with ${_userPosts.length} posts');
    } catch (e) {
      print('❌ ProfileScreen: Failed to fetch user posts: $e');
      
      // Show user-friendly error message
      if (e.toString().contains('Connection timed out') || e.toString().contains('SocketException')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot connect to server. Please check your network connection.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load posts: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      setState(() {
        _loadingPosts = false;
      });
    }
  }

  /// Fetch user profile with posts (DEPRECATED - now split into parallel fetching)
  Future<void> _fetchUserProfile() async {
    if (_authProvider.userId == null) {
      print('❌ ProfileScreen: User ID is null, cannot fetch profile');
      return;
    }
    
    print('🔍 ProfileScreen: Fetching profile for user: ${_authProvider.userId}');
    
    setState(() {
      _loadingPosts = true;
    });

    try {
      final profileData = await _backendService.getUserProfile(_authProvider.userId!, currentUserId: _authProvider.userId);
      print('🔍 ProfileScreen: Received profile data');
      print('🔍 ProfileScreen: User: ${profileData.user.displayName}, Posts: ${profileData.posts.length}');
      
      // Update posts and profile data
      setState(() {
        _userPosts = profileData.posts;
        _profileData = profileData;
      });
      
      // Update FAB strategy based on new content
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateFABStrategy();
      });
      
      print('✅ ProfileScreen: Successfully updated _userPosts with ${_userPosts.length} posts');
      
      // Debug: Check final posts state
      if (_userPosts.isEmpty) {
        print('❌ ProfileScreen: _userPosts is empty after processing!');
      } else {
        print('✅ ProfileScreen: _userPosts has ${_userPosts.length} posts');
        for (int i = 0; i < _userPosts.length; i++) {
          final post = _userPosts[i];
          print('🔍 ProfileScreen: Final post $i: id=${post.id}, title=${post.songName}');
        }
      }
      
      // Log like states for debugging
      for (final post in _userPosts) {
        print('🔍 ProfileScreen: Post ${post.id} - liked: ${post.isLikedByCurrentUser}, count: ${post.likeCount}');
      }
    } catch (e) {
      print('❌ ProfileScreen: Failed to fetch user profile: $e');
      
      // Show user-friendly error message
      if (e.toString().contains('Connection timed out') || e.toString().contains('SocketException')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot connect to server. Please check your network connection.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load profile: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      setState(() {
        _loadingPosts = false;
      });
    }
  }

  /// Delete a post
  Future<void> _deletePost(String postId) async {
    try {
      // Get the current user ID
      final userId = _authProvider.userId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }
      
      // Debug: Print the post being deleted and userId
      final postToDelete = _userPosts.firstWhere((post) => post.id == postId);
      print('🔍 ProfileScreen: Deleting post: $postId');
      print('🔍 ProfileScreen: Post owner userId: ${postToDelete.userId}');
      print('🔍 ProfileScreen: Current user userId: $userId');
      print('🔍 ProfileScreen: UserIds match: ${postToDelete.userId == userId}');
      
      await _backendService.deletePost(postId, userId: userId);
      setState(() {
        _userPosts.removeWhere((post) => post.id == postId);
      });
      
      // Update FAB strategy after post deletion
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateFABStrategy();
      });
      
      HapticFeedback.lightImpact();
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Post deleted successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('❌ ProfileScreen: Failed to delete post: $e');
      // Show error message to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete post: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  // Removed time range switching; always uses medium_term

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.darkBackgroundStart, AppColors.darkBackgroundEnd],
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.onDarkSecondary,
            ),
          ),
        ),
      );
    }


    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.darkBackgroundStart, AppColors.darkBackgroundEnd],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    HapticFeedback.lightImpact();
                    await _fetchAll();
                    await SimpleLifecycleManager.instance.forceSync(); // Force sync on refresh
                    HapticFeedback.selectionClick();
                  },
                  child: ListView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    children: _loading
                        ? _buildSkeletonWidgets(context)
                        : [
                            _buildProfileHeader(),
                            _buildSectionTitle('Currently Playing'),
                            _buildCurrentlyPlaying(),
                            _buildSectionTitle('Top Artists'),
                            _buildTopArtistsWidget(),
                            _buildSectionTitle('Top Tracks'),
                            _loadingTop
                                ? _buildTopTracksSkeletonWidget(context)
                                : _buildTopTracksWidget(context),
                            _buildSectionTitle('Recently Played'),
                            _buildRecentlyPlayedWidget(),
                            _buildSectionTitle('My Posts'),
                            _buildUserPostsWidget(),
                            if (_insufficientScopeTop)
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: _EmptyCard(
                                  icon: Icons.lock_outline,
                                  title: 'Limited data due to permissions',
                                  subtitle: 'Re-connect and grant access to Top Artists/Tracks to see more.',
                                ),
                              ),
                            const SizedBox(height: 24),
                          ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      // Smart FAB - only show when content is long enough and user isn't scrolling down
      floatingActionButton: _shouldUseFAB ? _buildScrollAwareFAB() : null,
    );
  }

  /// Scroll to top of the profile screen
  void scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }


  /// Build scroll-aware FAB with smooth animations
  Widget _buildScrollAwareFAB() {
    return AnimatedSlide(
      duration: const Duration(milliseconds: 200),
      offset: _showFAB ? Offset.zero : const Offset(0, 2),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: _showFAB ? 1.0 : 0.0,
        child: FloatingActionButton.extended(
        heroTag: 'fab-create-post',
        backgroundColor: AppColors.primary,
          elevation: _showFAB ? 6 : 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
          onPressed: _showFAB ? () {
          showCreatePostSheet(
            context,
            nowPlaying: _currentlyPlaying,
            topTracks: _topTracks,
            recentPlayed: _recentlyPlayed,
          ).then((success) {
            if (success == true) {
              _fetchUserPosts();
            }
          });
          } : null,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Create post', style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }

  SliverAppBar _buildHeader(BuildContext context) {
    final images = (_user?['images'] as List<dynamic>?) ?? const [];
    final avatarUrl = images.isNotEmpty ? (images.first['url'] as String?) : null;
    final displayName = _user?['display_name'] as String? ?? 'Spotify User';
    final email = _user?['email'] as String?;
    final followers = _user?['followers']?['total'] as int?;

    return SliverAppBar(
      pinned: true,
      expandedHeight: MediaQuery.of(context).size.height * 0.28,
      backgroundColor: Colors.transparent,
      foregroundColor: AppColors.onDarkPrimary,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.darkBackgroundStart, AppColors.darkBackgroundEnd],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: MediaQuery.of(context).size.width < 360 ? 36 : 44,
                    backgroundColor: AppColors.onDarkPrimary.withOpacity(0.12),
                    backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                    child: avatarUrl == null
                        ? const Icon(Icons.person, color: AppColors.onDarkPrimary, size: 44)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: AppTextStyles.heading1OnDark,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (email != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            email,
                            style: AppTextStyles.captionOnDark,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (followers != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.people, size: 16, color: AppColors.onDarkSecondary),
                              const SizedBox(width: 6),
                              Text(
                                '$followers followers',
                                style: AppTextStyles.captionOnDark,
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 12),
                        // Instagram-style followers/following buttons
                        Row(
                          children: [
                            Expanded(
                              child: _buildFollowButton(
                                count: _profileData?.user.followersCount ?? 0,
                                label: 'Followers',
                                onTap: () => _showFollowersDialog(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildFollowButton(
                                count: _profileData?.user.followingCount ?? 0,
                                label: 'Following',
                                onTap: () => _showFollowingDialog(),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        title: const Text('Profile', style: AppTextStyles.heading2OnDark),
      ),
    );
  }


  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title, 
              style: AppTextStyles.heading2OnDark.copyWith(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentlyPlaying() {
    final item = _currentlyPlaying?['item'] as Map<String, dynamic>?;
    if (item == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: _EmptyCard(
          icon: Icons.play_circle_outline,
          title: 'Nothing playing right now',
          subtitle: 'Start a song on Spotify to see it here.',
        ),
      );
    }

    final name = item['name'] as String? ?? '';
    final artists = (item['artists'] as List<dynamic>? ?? const [])
        .map((a) => a['name'] as String? ?? '')
        .where((s) => s.isNotEmpty)
        .join(', ');
    final images = item['album']?['images'] as List<dynamic>? ?? const [];
    final imageUrl = images.isNotEmpty ? images.last['url'] as String? : null; // smaller image

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: _GlassCard(
        borderRadius: 12,
        child: ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: imageUrl != null
                ? Image.network(imageUrl, width: 56, height: 56, fit: BoxFit.cover)
                : Container(
                    width: 56,
                    height: 56,
                    color: AppColors.onDarkPrimary.withOpacity(0.12),
                    child: const Icon(Icons.music_note, color: AppColors.onDarkSecondary),
                  ),
          ),
          title: Text(name, style: AppTextStyles.bodyOnDark.copyWith(fontWeight: FontWeight.w600)),
          subtitle: Text(artists, style: AppTextStyles.captionOnDark),
        ),
      ),
    );
  }

  // Deprecated sliver-based method (kept for reference)
  // SliverToBoxAdapter _buildTopArtists() { ... }

  Widget _buildTopArtistsContent({Key? key}) {
    return SizedBox(
      key: key,
      height: 80,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final artist = _topArtists[index];
          final images = (artist['images'] as List<dynamic>? ?? const []);
          final url = images.isNotEmpty ? images.first['url'] as String? : null;
          return Column(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: url != null ? NetworkImage(url) : null,
                child: url == null ? const Icon(Icons.person, color: AppColors.onDarkSecondary, size: 20) : null,
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: 60,
                child: Text(
                  artist['name'] as String? ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.captionOnDark,
                ),
              )
            ],
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemCount: _topArtists.length > 5 ? 5 : _topArtists.length,
      ),
    );
  }

  Widget _buildTopArtistsSkeletonContent({Key? key}) {
    return SizedBox(
      key: key,
      height: 120,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemBuilder: (_, __) => const Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            _SkeletonCircle(diameter: 72),
            SizedBox(height: 8),
            _SkeletonBox(width: 80, height: 12, radius: 6),
          ],
        ),
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemCount: 6,
      ),
    );
  }

  // Removed time range toggle UI


  // New: Top Artists as a widget (no slivers)
  Widget _buildTopArtistsWidget() {
    return AnimatedSwitcher(
      duration: _animDur,
      child: _loadingTop
          ? _buildTopArtistsSkeletonContent(key: const ValueKey('artists-skeleton'))
          : (_topArtists.isEmpty
              ? const Padding(
                  key: ValueKey('artists-empty'),
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: _EmptyCard(
                    icon: Icons.person_outline,
                    title: 'No top artists yet',
                    subtitle: 'Listen more to build your top artists.',
                  ),
                )
              : _buildTopArtistsContent(key: const ValueKey('artists-list'))),
    );
  }

  // New: Top Tracks as a widget (no slivers)
  Widget _buildTopTracksWidget(BuildContext context) {
    if (_topTracks.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: _EmptyCard(
          icon: Icons.music_note,
          title: 'No top tracks yet',
          subtitle: 'Listen more to build your top tracks.',
        ),
      );
    }
     return SizedBox(
       height: 80,
       child: ListView.separated(
         padding: const EdgeInsets.symmetric(horizontal: 16),
         scrollDirection: Axis.horizontal,
         itemBuilder: (context, index) {
           if (index >= _topTracks.length) return const SizedBox.shrink();
           final track = _topTracks[index];
           final images = track['album']?['images'] as List<dynamic>? ?? const [];
           final imageUrl = images.isNotEmpty ? images.last['url'] as String? : null;
           return Column(
             children: [
               ClipRRect(
                 borderRadius: BorderRadius.circular(8),
                 child: imageUrl != null
                     ? Image.network(
                         imageUrl, 
                         width: 48, 
                         height: 48, 
                         fit: BoxFit.cover,
                       )
                     : Container(
                         width: 48,
                         height: 48,
                         color: AppColors.onDarkPrimary.withOpacity(0.12),
                         child: const Icon(Icons.music_note, color: AppColors.onDarkSecondary, size: 20),
                       ),
               ),
               const SizedBox(height: 6),
               SizedBox(
                 width: 60,
                 child: Text(
                   track['name'] as String? ?? '',
                   maxLines: 1,
                   overflow: TextOverflow.ellipsis,
                   textAlign: TextAlign.center,
                   style: AppTextStyles.captionOnDark.copyWith(fontSize: 10),
                 ),
               )
             ],
           );
         },
         separatorBuilder: (_, __) => const SizedBox(width: 12),
         itemCount: _topTracks.length > 5 ? 5 : _topTracks.length,
       ),
     );
  }

  Widget _buildTopTracksSkeletonWidget(BuildContext context) {
    return SizedBox(
      height: 80,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemBuilder: (_, __) => const Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            _SkeletonBox(width: 48, height: 48, radius: 8),
            SizedBox(height: 6),
            _SkeletonBox(width: 60, height: 10, radius: 6),
          ],
        ),
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemCount: 5,
      ),
    );
  }

  // New: Recently played as a widget (no slivers) - Last 24 hours only
  Widget _buildRecentlyPlayedWidget() {
    // Filter tracks from last 24 hours
    final now = DateTime.now();
    final last24Hours = now.subtract(const Duration(hours: 24));
    
    final recentTracks = _recentlyPlayed.where((track) {
      final playedAt = DateTime.tryParse(track['played_at'] as String? ?? '');
      return playedAt != null && playedAt.isAfter(last24Hours);
    }).toList();
    
    if (recentTracks.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: _EmptyCard(
          icon: Icons.history,
          title: 'No recent plays',
          subtitle: 'Play some songs in the last 24 hours to see them here.',
        ),
      );
    }
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: recentTracks.length > 5 ? 5 : recentTracks.length,
      itemBuilder: (context, index) {
        if (index >= recentTracks.length) return const SizedBox.shrink();
        final item = recentTracks[index];
        final track = item['track'] as Map<String, dynamic>? ?? const {};
        final images = track['album']?['images'] as List<dynamic>? ?? const [];
        final imageUrl = images.isNotEmpty ? images.last['url'] as String? : null;
        final artists = (track['artists'] as List<dynamic>? ?? const [])
            .map((a) => a['name'] as String? ?? '')
            .where((s) => s.isNotEmpty)
            .join(', ');
        
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
          child: _GlassCard(
            borderRadius: 8,
            child: ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: imageUrl != null
                    ? Image.network(imageUrl, width: 40, height: 40, fit: BoxFit.cover)
                    : Container(
                        width: 40,
                        height: 40,
                        color: AppColors.onDarkPrimary.withOpacity(0.12),
                        child: const Icon(Icons.music_note, color: AppColors.onDarkSecondary, size: 20),
                      ),
              ),
              title: Text(
                track['name'] as String? ?? '',
                style: AppTextStyles.bodyOnDark.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                artists, 
                style: AppTextStyles.captionOnDark.copyWith(fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              // Remove tap-to-open compose from recent list per request
              onTap: null,
            ),
          ),
        );
      },
    );
  }

  // User posts widget
  Widget _buildUserPostsWidget() {
    if (_loadingPosts) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: List.generate(3, (index) => const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: _SkeletonTile(),
          )),
        ),
      );
    }

    print('🔍 ProfileScreen: UI rendering - _userPosts.length = ${_userPosts.length}');

    if (_userPosts.isEmpty) {
      print('🔍 ProfileScreen: Showing empty state - no posts to display');
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: _EmptyCard(
          icon: Icons.post_add,
          title: 'No posts yet',
          subtitle: 'Create your first post by selecting a track from Recently Played.',
        ),
      );
    }

    print('🔍 ProfileScreen: Rendering ${_userPosts.length} posts');
    return Column(
      children: _userPosts.map((post) => _buildPostCard(post)).toList(),
    );
  }

  // Build individual post card using SwipeablePostCard
  Widget _buildPostCard(Post post) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: SwipeablePostCard(
        post: post,
        showUserInfo: false, // Hide username and avatar in profile screen
        onDelete: () => _deletePost(post.id),
        onEditDescription: (newDescription) => _editPost(post, newDescription: newDescription),
        onLikeChanged: (isLiked, likes) async {
          try {
            final userId = _authProvider.userId;
            if (userId == null) {
              print('❌ ProfileScreen: User not authenticated for like');
              return;
            }
            
            print('🔍 ProfileScreen: Toggling like for post: ${post.id}, isLiked: $isLiked');
            final result = await _backendService.togglePostLike(post.id, userId, !isLiked);
            print('✅ ProfileScreen: Like toggled successfully, result: $result');
            
            // Update the post in the list with new like count
            setState(() {
              final postIndex = _userPosts.indexWhere((p) => p.id == post.id);
              if (postIndex != -1) {
                _userPosts[postIndex] = _userPosts[postIndex].copyWith(
                  likeCount: likes,
                  isLikedByCurrentUser: isLiked,
                );
                print('✅ ProfileScreen: Updated like state for post ${post.id}: liked=$isLiked, count=$likes');
              } else {
                print('❌ ProfileScreen: Post ${post.id} not found for like update');
              }
            });
            
            HapticFeedback.lightImpact();
          } catch (e) {
            print('❌ ProfileScreen: Failed to toggle like: $e');
            // Show error message to user
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to update like: $e'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 2),
              ),
            );
          }
            },
            onCardTap: () {
              // TODO: Implement post tap functionality
              print('Post tapped: ${post.id}');
            },
        onShare: () {
          PostSharingUtils.sharePost(post);
        },
        onOpenInSpotify: () async {
          try {
            print('🔗 ProfileScreen: Opening song in Spotify: ${post.songName} by ${post.artistName}');
            final success = await SpotifyDeepLinkService.openSongInSpotify(
              songName: post.songName,
              artistName: post.artistName,
            );
            
            if (success) {
              print('✅ ProfileScreen: Successfully opened song in Spotify');
              HapticFeedback.lightImpact();
            } else {
              print('❌ ProfileScreen: Failed to open song in Spotify');
              
              // Try simple Spotify opening as fallback
              final simpleSuccess = await SpotifyDeepLinkService.openSpotifySimple();
              if (simpleSuccess) {
                print('✅ ProfileScreen: Opened Spotify app (simple method)');
                HapticFeedback.lightImpact();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(SpotifyDeepLinkService.getSpotifyErrorMessage()),
                    backgroundColor: Colors.orange,
                    duration: const Duration(seconds: 4),
                    action: SnackBarAction(
                      label: 'OK',
                      textColor: Colors.white,
                      onPressed: () {},
                    ),
                  ),
                );
              }
            }
          } catch (e) {
            print('❌ ProfileScreen: Error opening Spotify: $e');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error opening Spotify: $e'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
      ),
    );
  }


  /// Edit a post
  Future<void> _editPost(Post post, {String? newDescription}) async {
    try {
      final userId = _authProvider.userId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      if (newDescription != null) {
        print('🔍 ProfileScreen: Updating post: ${post.id} with new description');
        print('🔍 ProfileScreen: Original post ID: ${post.id}');
        
        final updatedPost = await _backendService.updatePost(post.id, userId, newDescription);
        print('🔍 ProfileScreen: Updated post ID: ${updatedPost.id}');
        
        // Handle case where backend doesn't return ID in response
        final finalUpdatedPost = updatedPost.id.isEmpty 
            ? updatedPost.copyWith(id: post.id) // Preserve original ID
            : updatedPost;
        
        print('🔍 ProfileScreen: Final post ID: ${finalUpdatedPost.id}');
        
        // Refresh the profile screen to get updated post information
        print('🔄 ProfileScreen: Refreshing profile screen after post update');
        await _fetchUserPosts();
        
        HapticFeedback.lightImpact();
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post updated successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('❌ ProfileScreen: Failed to update post: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update post: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // New: Skeleton widgets list used when loading
  List<Widget> _buildSkeletonWidgets(BuildContext context) {
    return [
      // Profile Header Skeleton - matches _buildProfileHeader() exactly
      Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        padding: const EdgeInsets.all(16), // Reduced from 20 to 16
        decoration: BoxDecoration(
          color: AppColors.onDarkPrimary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.onDarkPrimary.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            // Compact user info row - matches the real layout exactly like UserProfileScreen
            const Row(
              children: [
                _SkeletonCircle(diameter: 48), // radius: 24
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SkeletonBox(width: 120, height: 18, radius: 9), // displayName
                      SizedBox(height: 2),
                      _SkeletonBox(width: 80, height: 12, radius: 6), // @username
                      SizedBox(height: 4),
                      Row(
                        children: [
                          _SkeletonBox(width: 8, height: 8, radius: 4), // post_add icon
                          SizedBox(width: 4),
                          _SkeletonBox(width: 50, height: 11, radius: 5), // posts text
                        ],
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          _SkeletonBox(width: 8, height: 8, radius: 4), // people icon
                          SizedBox(width: 4),
                          _SkeletonBox(width: 70, height: 11, radius: 5), // followers text
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16), // Reduced from 20 to 16
            // Compact Instagram-style followers/following buttons
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.onDarkPrimary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Column(
                      children: [
                        _SkeletonBox(width: 20, height: 14, radius: 7), // count
                        SizedBox(height: 2),
                        _SkeletonBox(width: 50, height: 10, radius: 5), // "Followers"
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.onDarkPrimary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Column(
                      children: [
                        _SkeletonBox(width: 20, height: 14, radius: 7), // count
                        SizedBox(height: 2),
                        _SkeletonBox(width: 50, height: 10, radius: 5), // "Following"
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      _buildSectionTitle('Currently Playing'),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: _SkeletonTile(),
      ),
      _buildSectionTitle('Top Artists'),
      SizedBox(
        height: 100,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          itemBuilder: (_, __) => const Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _SkeletonCircle(diameter: 60),
              SizedBox(height: 6),
              _SkeletonBox(width: 60, height: 10, radius: 5),
            ],
          ),
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemCount: 6,
        ),
      ),
       _buildSectionTitle('Top Tracks'),
       SizedBox(
         height: 70,
         child: ListView.separated(
           padding: const EdgeInsets.symmetric(horizontal: 16),
           scrollDirection: Axis.horizontal,
           itemBuilder: (_, __) => const Column(
             mainAxisAlignment: MainAxisAlignment.start,
             children: [
               _SkeletonBox(width: 40, height: 40, radius: 6),
               SizedBox(height: 4),
               _SkeletonBox(width: 50, height: 8, radius: 4),
             ],
           ),
           separatorBuilder: (_, __) => const SizedBox(width: 12),
           itemCount: 5,
         ),
       ),
      _buildSectionTitle('Recently Played'),
      ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 6,
        itemBuilder: (context, index) => const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: _SkeletonTile(),
        ),
      ),
      _buildSectionTitle('My Posts'),
      ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 3,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Container(
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: AppColors.onDarkPrimary.withOpacity(0.03),
              border: Border.all(
                color: AppColors.onDarkPrimary.withOpacity(0.06),
                width: 1,
              ),
            ),
            child: const _Shimmer(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row: avatar + username
                    Row(
                      children: [
                        _SkeletonCircle(diameter: 28),
                        SizedBox(width: 12),
                        _SkeletonBox(width: 60, height: 13, radius: 6),
                        SizedBox(width: 30),
                      ],
                    ),
                    SizedBox(height: 12),
                    // Middle: cover + song info
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SkeletonBox(width: 60, height: 60, radius: 12),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SkeletonBox(width: 150, height: 16, radius: 8),
                              SizedBox(height: 6),
                              _SkeletonBox(width: 100, height: 13, radius: 6),
                              SizedBox(height: 8),
                              _SkeletonBox(width: 180, height: 12, radius: 6),
                              SizedBox(height: 4),
                              _SkeletonBox(width: 120, height: 12, radius: 6),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    // Bottom: 3 circles for action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _SkeletonCircle(diameter: 18),
                        SizedBox(width: 12),
                        _SkeletonCircle(diameter: 18),
                        SizedBox(width: 12),
                        _SkeletonCircle(diameter: 18),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 24),
    ];
  }

  SliverGrid _buildTopTracks(BuildContext context) {
    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _gridCountForWidth(MediaQuery.of(context).size.width),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index >= _topTracks.length) return const SizedBox.shrink();
          final track = _topTracks[index];
          final images = track['album']?['images'] as List<dynamic>? ?? const [];
          final imageUrl = images.isNotEmpty ? images.last['url'] as String? : null;
          final artists = (track['artists'] as List<dynamic>? ?? const [])
              .map((a) => a['name'] as String? ?? '')
              .where((s) => s.isNotEmpty)
              .join(', ');
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: imageUrl != null
                        ? Image.network(imageUrl, fit: BoxFit.cover)
                        : Container(
                            color: AppColors.onDarkPrimary.withOpacity(0.12),
                            child: const Icon(Icons.music_note, color: AppColors.onDarkSecondary),
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  track['name'] as String? ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyOnDark.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  artists,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.captionOnDark,
                ),
              ],
            ),
          );
        },
        childCount: _topTracks.length,
      ),
    );
  }

  SliverGrid _buildTopTracksSkeleton(BuildContext context) {
    final gridCount = _gridCountForWidth(MediaQuery.of(context).size.width);
    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: gridCount,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SkeletonBox(width: double.infinity, height: 140, radius: 12),
                SizedBox(height: 8),
                _SkeletonBox(width: 120, height: 14, radius: 6),
                SizedBox(height: 6),
                _SkeletonBox(width: 80, height: 12, radius: 6),
              ],
            ),
          );
        },
        childCount: gridCount * 2,
      ),
    );
  }

  int _gridCountForWidth(double width) {
    if (width >= 1024) return 5;
    if (width >= 800) return 4;
    if (width >= 600) return 3;
    return 2;
  }

  List<Widget> _buildSkeletonSlivers(BuildContext context) {
    final gridCount = _gridCountForWidth(MediaQuery.of(context).size.width);
    return [
      _skeletonHeader(),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(4, (_) => const _SkeletonBox(width: 160, height: 54, radius: 12)),
          ),
        ),
      ),
      SliverToBoxAdapter(child: _buildSectionTitle('Currently Playing')),
      const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: _SkeletonTile(),
        ),
      ),
      SliverToBoxAdapter(child: _buildSectionTitle('Top Artists')),
      SliverToBoxAdapter(
        child: SizedBox(
          height: 120,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemBuilder: (_, __) => const _SkeletonCircle(diameter: 72),
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemCount: 6,
          ),
        ),
      ),
      SliverToBoxAdapter(child: _buildSectionTitle('Top Tracks')),
      SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: gridCount,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.9,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SkeletonBox(width: double.infinity, height: 140, radius: 12),
                  SizedBox(height: 8),
                  _SkeletonBox(width: 120, height: 14, radius: 6),
                  SizedBox(height: 6),
                  _SkeletonBox(width: 80, height: 12, radius: 6),
                ],
              ),
            );
          },
          childCount: gridCount * 2,
        ),
      ),
      SliverToBoxAdapter(child: _buildSectionTitle('Recently Played')),
      SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: _SkeletonTile(),
          ),
          childCount: 6,
        ),
      ),
    ];
  }

  SliverList _buildRecentlyPlayed() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index >= _recentlyPlayed.length) return const SizedBox.shrink();
          final item = _recentlyPlayed[index];
          final track = item['track'] as Map<String, dynamic>? ?? const {};
          final images = track['album']?['images'] as List<dynamic>? ?? const [];
          final imageUrl = images.isNotEmpty ? images.last['url'] as String? : null;
          final artists = (track['artists'] as List<dynamic>? ?? const [])
              .map((a) => a['name'] as String? ?? '')
              .where((s) => s.isNotEmpty)
              .join(', ');
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: _GlassCard(
              borderRadius: 12,
              child: ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: imageUrl != null
                      ? Image.network(imageUrl, width: 56, height: 56, fit: BoxFit.cover)
                      : Container(
                          width: 56,
                          height: 56,
                          color: AppColors.onDarkPrimary.withOpacity(0.12),
                          child: const Icon(Icons.music_note, color: AppColors.onDarkSecondary),
                        ),
                ),
                title: Text(
                  track['name'] as String? ?? '',
                  style: AppTextStyles.bodyOnDark.copyWith(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(artists, style: AppTextStyles.captionOnDark),
              ),
            ),
          );
        },
        childCount: _recentlyPlayed.length,
      ),
    );
  }

  SliverToBoxAdapter _skeletonHeader() {
    return SliverToBoxAdapter(
      child: Container(
        height: 220,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.darkBackgroundStart, AppColors.darkBackgroundEnd],
          ),
        ),
        child: const SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 56, 20, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _SkeletonCircle(diameter: 88),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SkeletonBox(width: 180, height: 22, radius: 6),
                      SizedBox(height: 8),
                      _SkeletonBox(width: 140, height: 14, radius: 6),
                      SizedBox(height: 8),
                      _SkeletonBox(width: 120, height: 12, radius: 6),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build compact profile header with user info and followers/following buttons
  Widget _buildProfileHeader() {
    final images = (_user?['images'] as List<dynamic>?) ?? const [];
    final avatarUrl = images.isNotEmpty ? (images.first['url'] as String?) : null;
    final displayName = _user?['display_name'] as String? ?? 'Spotify User';
    final followers = _user?['followers']?['total'] as int?;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(16), // Reduced from 20 to 16
      decoration: BoxDecoration(
        color: AppColors.onDarkPrimary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.onDarkPrimary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Compact user info row - exactly like UserProfileScreen
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.onDarkPrimary.withOpacity(0.12),
                backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                child: avatarUrl == null
                    ? const Icon(Icons.person, color: AppColors.onDarkPrimary, size: 24)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: AppTextStyles.heading2OnDark.copyWith(fontSize: 18),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Show username if available from profile data
                    if (_profileData?.user.username.isNotEmpty == true) ...[
                      const SizedBox(height: 2),
                      Text(
                        '@${_profileData!.user.username}',
                        style: AppTextStyles.captionOnDark.copyWith(
                          fontSize: 12,
                          color: AppColors.onDarkSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    // Show posts count if available
                    if (_profileData != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.post_add, size: 12, color: AppColors.onDarkSecondary),
                          const SizedBox(width: 4),
                          Text(
                            '${_profileData!.user.postsCount} posts',
                            style: AppTextStyles.captionOnDark.copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                    // Show followers count from widget data or profile data
                    if (followers != null || _profileData != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.people, size: 12, color: AppColors.onDarkSecondary),
                          const SizedBox(width: 4),
                          Text(
                            '${followers ?? _profileData?.user.followersCount ?? 0} followers',
                            style: AppTextStyles.captionOnDark.copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16), // Reduced from 20 to 16
          // Compact Instagram-style followers/following buttons
          Row(
            children: [
              Expanded(
                child: _buildFollowButton(
                  count: _profileData?.user.followersCount ?? 0,
                  label: 'Followers',
                  onTap: () => _showFollowersDialog(),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildFollowButton(
                  count: _profileData?.user.followingCount ?? 0,
                  label: 'Following',
                  onTap: () => _showFollowingDialog(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build compact Instagram-style follow button
  Widget _buildFollowButton({
    required int count,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.onDarkPrimary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: AppColors.onDarkPrimary.withOpacity(0.12),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: AppTextStyles.heading2OnDark.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.onDarkPrimary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              label,
              style: AppTextStyles.captionOnDark.copyWith(
                fontSize: 10,
                color: AppColors.onDarkSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Enrich followers list with follow status by checking each user individually
  Future<List<Map<String, dynamic>>> _enrichFollowersWithFollowStatus(List<Map<String, dynamic>> followers) async {
    final enrichedFollowers = <Map<String, dynamic>>[];
    
    for (final follower in followers) {
      try {
        // Check follow status for each follower
        final followStatus = await _backendService.getFollowStatus(_authProvider.userId!, follower['id']);
        follower['isFollowing'] = followStatus['isFollowing'] ?? false;
        follower['followRequestStatus'] = followStatus['status'] ?? 'none';
        debugPrint('🔍 Debug - Follower ${follower['displayName']}: isFollowing = ${follower['isFollowing']}');
      } catch (e) {
        debugPrint('⚠️ Debug - Could not get follow status for ${follower['displayName']}: $e');
        follower['isFollowing'] = false;
        follower['followRequestStatus'] = 'none';
      }
      enrichedFollowers.add(follower);
    }
    
    return enrichedFollowers;
  }

  /// Show followers dialog
  void _showFollowersDialog() async {
    if (_profileData == null) return;
    
    try {
      final followers = await _backendService.getUserFollowers(_profileData!.user.id, currentUserId: _authProvider.userId);
      
      // Smart solution: If backend doesn't provide follow status, check it manually
      final followersWithStatus = await _enrichFollowersWithFollowStatus(followers);
      
      if (!mounted) return;
      
      showDialog(
        context: context,
        builder: (context) => _FollowersFollowingDialog(
          title: 'Followers',
          users: followersWithStatus,
          currentUserId: _authProvider.userId!,
          backendService: _backendService,
          onFollowToggle: (userId, isFollowing) async {
            // Handle follow/unfollow logic - refresh profile data
            print('Follow toggle: $userId -> $isFollowing');
            // Refresh essential profile data to update counters
            await _fetchUserProfile();
          },
        ),
      );
    } catch (e) {
      print('❌ ProfileScreen: Failed to get followers: $e');
      if (!mounted) return;
      
      // Show dialog with empty list instead of error
      showDialog(
        context: context,
        builder: (context) => _FollowersFollowingDialog(
          title: 'Followers',
          users: const [], // Empty list
          currentUserId: _authProvider.userId!,
          backendService: _backendService,
          onFollowToggle: (userId, isFollowing) async {
            print('Follow toggle: $userId -> $isFollowing');
            // Refresh essential profile data to update counters
            await _fetchUserProfile();
          },
        ),
      );
      
      // Show a brief error message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to load followers. Please try again later.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// Show following dialog
  void _showFollowingDialog() async {
    if (_profileData == null) return;
    
    try {
      final following = await _backendService.getUserFollowing(_profileData!.user.id, currentUserId: _authProvider.userId);
      
      if (!mounted) return;
      
      showDialog(
        context: context,
        builder: (context) => _FollowersFollowingDialog(
          title: 'Following',
          users: following,
          currentUserId: _authProvider.userId!,
          backendService: _backendService,
          onFollowToggle: (userId, isFollowing) async {
            // Handle follow/unfollow logic - refresh profile data
            print('Follow toggle: $userId -> $isFollowing');
            // Refresh essential profile data to update counters
            await _fetchUserProfile();
          },
        ),
      );
    } catch (e) {
      print('❌ ProfileScreen: Failed to get following: $e');
      if (!mounted) return;
      
      // Show dialog with empty list instead of error
      showDialog(
        context: context,
        builder: (context) => _FollowersFollowingDialog(
          title: 'Following',
          users: const [], // Empty list
          currentUserId: _authProvider.userId!,
          backendService: _backendService,
          onFollowToggle: (userId, isFollowing) async {
            print('Follow toggle: $userId -> $isFollowing');
            // Refresh essential profile data to update counters
            await _fetchUserProfile();
          },
        ),
      );
      
      // Show a brief error message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to load following. Please try again later.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}

/// Dialog to show followers/following list
class _FollowersFollowingDialog extends StatefulWidget {
  final String title;
  final List<Map<String, dynamic>> users;
  final String currentUserId;
  final Function(String userId, bool isFollowing) onFollowToggle;
  final BackendService backendService;

  const _FollowersFollowingDialog({
    required this.title,
    required this.users,
    required this.currentUserId,
    required this.onFollowToggle,
    required this.backendService,
  });

  @override
  State<_FollowersFollowingDialog> createState() => _FollowersFollowingDialogState();
}

class _FollowersFollowingDialogState extends State<_FollowersFollowingDialog> {
  late List<Map<String, dynamic>> _users;
  int _followersCount = 0;
  int _followingCount = 0;

  @override
  void initState() {
    super.initState();
    _users = List.from(widget.users); // Create a copy for local state management
    
    // Initialize user states properly
    for (var user in _users) {
      if (widget.title == 'Following') {
        // In Following list, all users are initially being followed
        user['isFollowing'] = true;
      } else {
        // In Followers list, check multiple possible field names for follow status
        // Backend might use different field names like: isFollowing, following, followed, etc.
        user['isFollowing'] = user['isFollowing'] ?? 
                              user['following'] ?? 
                              user['followed'] ?? 
                              user['isFollowedByCurrentUser'] ?? 
                              false;
        
        debugPrint('🔍 Debug - User ${user['displayName']}: isFollowing = ${user['isFollowing']}, all user data: $user');
      }
    }
    
    // Initialize counts from profile data
    _followersCount = widget.users.length;
    _followingCount = widget.users.length;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.zero,
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          color: AppColors.darkBackgroundEnd,
          borderRadius: BorderRadius.circular(0),
          border: Border.all(
            color: AppColors.onDarkPrimary.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.onDarkPrimary.withOpacity(0.1),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    widget.title,
                    style: AppTextStyles.heading2OnDark.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => _onDialogClose(),
                    icon: const Icon(
                      Icons.close,
                      color: AppColors.onDarkPrimary,
                    ),
                  ),
                ],
              ),
            ),
            // Users list
            Expanded(
              child: _users.isEmpty
                  ? Center(
                      child: Text(
                        'No ${widget.title.toLowerCase()} found',
                        style: AppTextStyles.bodyOnDark.copyWith(
                          color: AppColors.onDarkSecondary,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _users.length,
                      itemBuilder: (context, index) {
                        final user = _users[index];
                        return _buildUserTile(user);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserTile(Map<String, dynamic> user) {
    final userId = user['id'] as String;
    final displayName = user['displayName'] as String? ?? 'Unknown User';
    final username = user['username'] as String? ?? '';
    final profilePicture = user['profilePicture'] as String?;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.onDarkPrimary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.onDarkPrimary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.onDarkPrimary.withOpacity(0.1),
            backgroundImage: profilePicture != null ? NetworkImage(profilePicture) : null,
            child: profilePicture == null
                ? const Icon(Icons.person, color: AppColors.onDarkPrimary, size: 20)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: AppTextStyles.captionOnDark.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (username.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    '@$username',
                    style: AppTextStyles.captionOnDark.copyWith(
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          // Follow/Unfollow button (only show if not current user)
          if (userId != widget.currentUserId)
            _buildActionButtons(userId, user),
        ],
      ),
    );
  }

  Widget _buildActionButtons(String userId, Map<String, dynamic> user) {
    if (widget.title == 'Followers') {
      // In Followers list: Show Remove button + conditional Follow button
      final isFollowing = user['isFollowing'] as bool? ?? false;
      
      // Debug: Use debugPrint for Flutter debugging
      debugPrint('🔍 Debug - User: ${user['displayName']}, isFollowing: $isFollowing, user data: $user');
      
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Remove button (always available for followers)
          TextButton(
            onPressed: () async {
              await _handleRemove(userId);
            },
            child: Text(
              'Remove',
              style: AppTextStyles.captionOnDark.copyWith(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // Follow button (only show if not following)
          if (!isFollowing) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: () async {
                await _handleFollow(userId);
              },
              child: Text(
                'Follow',
                style: AppTextStyles.captionOnDark.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      );
    } else {
      // In Following list: Show only follow/unfollow button
      return _buildFollowButton(userId, user);
    }
  }

  Widget _buildFollowButton(String userId, Map<String, dynamic> user) {
    // Get current follow status from local state
    final isFollowing = user['isFollowing'] as bool? ?? true; // Default to true for Following list
    final isFollowedBy = user['isFollowedBy'] as bool? ?? false;
    final followRequestStatus = user['followRequestStatus'] as String? ?? 'none';
    
    // Determine button text and action based on context and current state
    String buttonText;
    Color buttonColor;
    VoidCallback? onPressed;
    
    if (widget.title == 'Following') {
      // In Following list: Smart Instagram-style workflow
      if (isFollowing) {
        // Currently following - show "Unfollow"
        buttonText = 'Unfollow';
        buttonColor = Colors.red;
        onPressed = () async {
          await _handleUnfollow(userId);
        };
      } else {
        // Unfollowed but still in list - show "Follow"
        buttonText = 'Follow';
        buttonColor = AppColors.primary;
        onPressed = () async {
          await _handleFollow(userId);
        };
      }
    } else {
      // In Followers list: Only show Follow/Following button (Remove is separate)
      if (isFollowing) {
        // We follow them back, show "Following"
        buttonText = 'Following';
        buttonColor = Colors.grey;
        onPressed = () async {
          await _handleUnfollow(userId);
        };
      } else if (followRequestStatus == 'pending') {
        // We sent a follow request, show "Pending"
        buttonText = 'Pending';
        buttonColor = Colors.orange;
        onPressed = null; // Disabled button
      } else if (followRequestStatus == 'accepted') {
        // We follow them back, show "Following"
        buttonText = 'Following';
        buttonColor = Colors.grey;
        onPressed = () async {
          await _handleUnfollow(userId);
        };
      } else {
        // They don't follow us back, show "Follow" (to follow back)
        buttonText = 'Follow';
        buttonColor = AppColors.primary;
        onPressed = () async {
          await _handleFollow(userId);
        };
      }
    }
    
    return TextButton(
      onPressed: onPressed,
      child: Text(
        buttonText,
        style: AppTextStyles.captionOnDark.copyWith(
          color: buttonColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Future<void> _handleFollow(String userId) async {
    try {
      debugPrint('🔍 Debug - Starting follow for user: $userId');
      await widget.backendService.followUser(widget.currentUserId, userId);
      debugPrint('✅ Followed user: $userId');
      
      // Update the user's status immediately and permanently
      setState(() {
        final userIndex = _users.indexWhere((u) => u['id'] == userId);
        debugPrint('🔍 Debug - User index: $userIndex, Users list length: ${_users.length}');
        if (userIndex != -1) {
          debugPrint('🔍 Debug - Before update: isFollowing = ${_users[userIndex]['isFollowing']}');
          _users[userIndex]['isFollowing'] = true;
          _users[userIndex]['followRequestStatus'] = 'accepted'; // Mark as accepted, not pending
          debugPrint('🔍 Debug - After update: isFollowing = ${_users[userIndex]['isFollowing']}');
        }
        
        // Update counter
        if (widget.title == 'Followers') {
          _followingCount++;
        }
      });
      
      // Update main profile screen (adds user to following list)
      // This ensures the state is saved on the backend
      widget.onFollowToggle(userId, true);
      HapticFeedback.lightImpact();
      debugPrint('🔍 Debug - Follow completed for user: $userId');
    } catch (e) {
      print('❌ Failed to follow: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send follow request: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _handleUnfollow(String userId) async {
    try {
      await widget.backendService.unfollowUser(widget.currentUserId, userId);
      print('✅ Unfollowed user: $userId');
      
      // Update the user's status immediately (Instagram-style: button changes, user stays in list)
      setState(() {
        final userIndex = _users.indexWhere((u) => u['id'] == userId);
        if (userIndex != -1) {
          _users[userIndex]['isFollowing'] = false;
          _users[userIndex]['followRequestStatus'] = 'none';
        }
        
        // Update counter
        if (widget.title == 'Following') {
          _followingCount--;
        }
      });
      
      widget.onFollowToggle(userId, false);
      HapticFeedback.lightImpact();
    } catch (e) {
      print('❌ Failed to unfollow: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to unfollow: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _handleRemove(String userId) async {
    try {
      // Check if we were following this user (to unfollow them too)
      final userIndex = _users.indexWhere((u) => u['id'] == userId);
      final wasFollowing = userIndex != -1 && (_users[userIndex]['isFollowing'] as bool? ?? false);
      
      // Step 1: Remove them from our followers (they stop following us)
      // This requires a different API endpoint - removeFollower
      // For now, we'll use unfollowUser but we need to implement removeFollower API
      await widget.backendService.unfollowUser(userId, widget.currentUserId); // Reverse the parameters
      print('✅ Removed user from followers: $userId');
      
      // Step 2: If we were following them, unfollow them too (we stop following them)
      if (wasFollowing) {
        await widget.backendService.unfollowUser(widget.currentUserId, userId);
        print('✅ Also unfollowed user: $userId');
      }
      
      // Remove user from list immediately (Instagram-style: immediate removal)
      setState(() {
        _users.removeWhere((u) => u['id'] == userId);
        _followersCount--;
        if (wasFollowing) {
          _followingCount--;
        }
      });
      
      // Update main profile screen with both changes
      widget.onFollowToggle(userId, false);
      HapticFeedback.lightImpact();
    } catch (e) {
      print('❌ Failed to remove: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to remove follower: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Handle dialog close - remove unfollowed users from Following list
  void _onDialogClose() {
    if (widget.title == 'Following') {
      // Remove users who were unfollowed and not re-followed
      final unfollowedUsers = <String>[];
      for (final user in _users) {
        final isFollowing = user['isFollowing'] as bool? ?? false;
        final followRequestStatus = user['followRequestStatus'] as String? ?? 'none';
        
        // If user was unfollowed and not re-followed, mark for removal
        if (!isFollowing && followRequestStatus == 'none') {
          unfollowedUsers.add(user['id'] as String);
        }
      }
      
      // Update the main profile screen with final changes
      if (unfollowedUsers.isNotEmpty) {
        widget.onFollowToggle(unfollowedUsers.join(','), false);
      }
    }
    
    // Close the dialog
    Navigator.pop(context);
  }
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _EmptyCard({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      borderRadius: 12,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, size: 28, color: AppColors.onDarkSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.bodyOnDark.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: AppTextStyles.captionOnDark),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

// Glassmorphism card helper (matching HomeFeed feel)
class _GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  const _GlassCard({required this.child, this.borderRadius = 14});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.onDarkPrimary.withOpacity(0.03),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: AppColors.onDarkPrimary.withOpacity(0.06)),
          ),
          child: child,
        ),
      ),
    );
  }
}


class _SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;
  const _SkeletonBox({required this.width, required this.height, this.radius = 8});

  @override
  Widget build(BuildContext context) {
    return _Shimmer(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.onDarkPrimary.withOpacity(0.12),
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

class _SkeletonCircle extends StatelessWidget {
  final double diameter;
  const _SkeletonCircle({required this.diameter});

  @override
  Widget build(BuildContext context) {
    return _Shimmer(
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          color: AppColors.onDarkPrimary.withOpacity(0.12),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _SkeletonTile extends StatelessWidget {
  const _SkeletonTile();

  @override
  Widget build(BuildContext context) {
    return const _GlassCard(
      borderRadius: 12,
      child: Padding(
        padding: EdgeInsets.all(12.0),
        child: Row(
          children: [
            _SkeletonBox(width: 56, height: 56, radius: 8),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SkeletonBox(width: 180, height: 14, radius: 6),
                  SizedBox(height: 8),
                  _SkeletonBox(width: 120, height: 12, radius: 6),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _Shimmer extends StatefulWidget {
  final Widget child;
  const _Shimmer({required this.child});

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 3500))
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (Rect bounds) {
            final gradient = LinearGradient(
              begin: Alignment(-1.0 - 3 * _controller.value, 0.0),
              end: Alignment(1.0 + 3 * _controller.value, 0.0),
              colors: [
                AppColors.onDarkPrimary.withOpacity(0.12),
                AppColors.onDarkPrimary.withOpacity(0.05),
                AppColors.onDarkPrimary.withOpacity(0.12),
              ],
              stops: const [0.25, 0.5, 0.75],
            );
            return gradient.createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: widget.child,
        );
      },
    );
  }
}


