import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:songbuddy/constants/app_colors.dart';
import 'package:songbuddy/constants/app_text_styles.dart';
import 'package:songbuddy/providers/auth_provider.dart';
import 'package:songbuddy/services/spotify_service.dart';
import 'package:songbuddy/services/spotify_deep_link_service.dart';
import 'package:songbuddy/services/backend_service.dart';
import 'package:songbuddy/models/Post.dart';
import 'package:songbuddy/models/ProfileData.dart';
import 'package:songbuddy/widgets/spotify_login_button.dart';
import 'package:songbuddy/widgets/swipeable_post_card.dart';
import 'package:songbuddy/screens/create_post_screen.dart';

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
  
  // Track selection for posts
  Set<String> _selectedTracks = <String>{};
  bool _isSelectionMode = false;

  // User posts
  List<Post> _userPosts = [];
  bool _loadingPosts = false;
  
  // Profile data (includes follow status)
  ProfileData? _profileData;

  bool _loadingTop = false; // non-blocking loading for top artists/tracks (kept for future use)
  static const Duration _animDur = Duration(milliseconds: 250);

  @override
  void initState() {
    super.initState();
    _authProvider = AuthProvider();
    _spotifyService = SpotifyService();
    _backendService = BackendService();
    _scrollController = ScrollController();
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
    _scrollController.dispose();
    super.dispose();
  }

  void _onAuthChanged() {
    if (!mounted) return;
    setState(() {});
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
      // User profile (required)
      final user = await _spotifyService.getCurrentUser(token);
      // Optional parallel calls with individual handling
      final futures = <Future<void>>[
        () async {
          try {
            _currentlyPlaying = await _spotifyService.getCurrentlyPlaying(token);
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

      setState(() {
        _user = user;
      });
      
      // Fetch user profile after getting user data
      _fetchUserProfile();
      
      // ignore: avoid_print
      print('[Profile] Fetch success: user=${user['id']} topArtists=${_topArtists.length} topTracks=${_topTracks.length} recently=${_recentlyPlayed.length}');
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

  Future<void> _handleConnect() async {
    await _authProvider.login();
    if (_authProvider.isAuthenticated) {
      await _fetchAll();
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
        _fetchUserProfile();
        HapticFeedback.lightImpact();
      }
    });
  }

  /// Fetch user profile with posts (NEW EFFICIENT API)
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

    if (!_authProvider.isAuthenticated) {
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
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person_outline, size: 72, color: AppColors.onDarkSecondary),
                  const SizedBox(height: 16),
                  const Text(
                    'Connect your Spotify to see your profile',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyOnDark,
                  ),
                  const SizedBox(height: 16),
                  SpotifyLoginButton(
                    onPressed: _handleConnect,
                    text: 'Connect Spotify',
                  ),
                ],
              ),
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: _buildTopBar(context),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    HapticFeedback.lightImpact();
                    await _fetchAll();
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
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
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
          if (title == 'Recently Played' && _recentlyPlayed.isNotEmpty)
            TextButton.icon(
              onPressed: _toggleSelectionMode,
              icon: Icon(
                _isSelectionMode ? Icons.close : Icons.checklist,
                size: 16,
              ),
              label: Text(_isSelectionMode ? 'Cancel' : 'Select'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCurrentlyPlaying() {
    final item = _currentlyPlaying?['item'] as Map<String, dynamic>?;
    if (item == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
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
                  maxLines: 2,
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
        itemBuilder: (_, __) => Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: const [
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

  // New: Top bar with title on the left
  Widget _buildTopBar(BuildContext context) {
    // final images = (_user?['images'] as List<dynamic>?) ?? const [];
    // final avatarUrl = images.isNotEmpty ? (images.first['url'] as String?) : null;
    return Row(
      children: [
        Text(
          'Profile',
          style: AppTextStyles.heading2OnDark.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            letterSpacing: 0.6,
            shadows: [
              Shadow(
                color: AppColors.onDarkPrimary.withOpacity(0.03),
                blurRadius: 6,
              )
            ],
          ),
        ),
        const Spacer(),
        // Commented out profile picture section
        // CircleAvatar(
        //   radius: 18,
        //   backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
        //   backgroundColor: Colors.transparent,
        //   child: avatarUrl == null
        //       ? const Icon(Icons.person_outline, color: AppColors.onDarkSecondary)
        //       : null,
        // ),
      ],
    );
  }

  // New: Top Artists as a widget (no slivers)
  Widget _buildTopArtistsWidget() {
    return AnimatedSwitcher(
      duration: _animDur,
      child: _loadingTop
          ? _buildTopArtistsSkeletonContent(key: const ValueKey('artists-skeleton'))
          : (_topArtists.isEmpty
              ? Padding(
                  key: const ValueKey('artists-empty'),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: const _EmptyCard(
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
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: const _EmptyCard(
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
                   maxLines: 2,
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
        itemBuilder: (_, __) => Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: const [
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
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: const _EmptyCard(
          icon: Icons.history,
          title: 'No recent plays',
          subtitle: 'Play some songs in the last 24 hours to see them here.',
        ),
      );
    }
    
    return Column(
      children: [
        // Selection mode controls
        if (_isSelectionMode)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedTracks.isNotEmpty 
                        ? 'Track selected' 
                        : 'No track selected',
                    style: AppTextStyles.captionOnDark.copyWith(fontSize: 12),
                  ),
                ),
                if (_selectedTracks.isNotEmpty)
                  TextButton.icon(
                    onPressed: _createPost,
                    icon: const Icon(Icons.add, size: 14),
                    label: const Text('Create Post'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
                TextButton(
                  onPressed: _toggleSelectionMode,
                  child: const Text('Cancel', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
        
        // Compact track list (max 5 items)
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: recentTracks.length > 5 ? 5 : recentTracks.length,
          itemBuilder: (context, index) {
            if (index >= recentTracks.length) return const SizedBox.shrink();
            final item = recentTracks[index];
            final track = item['track'] as Map<String, dynamic>? ?? const {};
            final trackId = track['id'] as String? ?? '';
            final images = track['album']?['images'] as List<dynamic>? ?? const [];
            final imageUrl = images.isNotEmpty ? images.last['url'] as String? : null;
            final artists = (track['artists'] as List<dynamic>? ?? const [])
                .map((a) => a['name'] as String? ?? '')
                .where((s) => s.isNotEmpty)
                .join(', ');
            final isSelected = _selectedTracks.contains(trackId);
            
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
                  onTap: _isSelectionMode 
                      ? () => _toggleTrackSelection(trackId)
                      : null,
                  trailing: _isSelectionMode
                      ? GestureDetector(
                          onTap: () => _toggleTrackSelection(trackId),
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : Colors.transparent,
                              border: Border.all(
                                color: isSelected ? AppColors.primary : AppColors.onDarkSecondary,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, size: 16, color: Colors.white)
                                : null,
                          ),
                        )
                      : null,
                ),
              ),
            );
          },
        ),
      ],
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
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
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
          // TODO: Implement share functionality
          print('Share post: ${post.id}');
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
        await _fetchUserProfile();
        
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
      _buildSectionTitle('Currently Playing'),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: _SkeletonTile(),
      ),
      _buildSectionTitle('Top Artists'),
      SizedBox(
        height: 120,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          itemBuilder: (_, __) => Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: const [
              _SkeletonCircle(diameter: 72),
              SizedBox(height: 8),
              _SkeletonBox(width: 80, height: 12, radius: 6),
            ],
          ),
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemCount: 6,
        ),
      ),
       _buildSectionTitle('Top Tracks'),
       SizedBox(
         height: 80,
         child: ListView.separated(
           padding: const EdgeInsets.symmetric(horizontal: 16),
           scrollDirection: Axis.horizontal,
           itemBuilder: (_, __) => Column(
             mainAxisAlignment: MainAxisAlignment.start,
             children: const [
               _SkeletonBox(width: 48, height: 48, radius: 8),
               SizedBox(height: 6),
               _SkeletonBox(width: 60, height: 10, radius: 6),
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
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
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
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: const _SkeletonTile(),
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
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
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
          (context, index) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: const _SkeletonTile(),
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
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: const [
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
    final email = _user?['email'] as String?;
    final followers = _user?['followers']?['total'] as int?;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(12),
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
          // Compact user info row
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
                    if (email != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        email,
                        style: AppTextStyles.captionOnDark.copyWith(fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (followers != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.people, size: 12, color: AppColors.onDarkSecondary),
                          const SizedBox(width: 4),
                          Text(
                            '$followers followers',
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
          const SizedBox(height: 12),
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

  /// Show followers dialog
  void _showFollowersDialog() async {
    if (_profileData == null) return;
    
    try {
      final followers = await _backendService.getUserFollowers(_profileData!.user.id);
      
      if (!mounted) return;
      
      showDialog(
        context: context,
        builder: (context) => _FollowersFollowingDialog(
          title: 'Followers',
          users: followers,
          currentUserId: _authProvider.userId!,
          backendService: _backendService,
          onFollowToggle: (userId, isFollowing) async {
            // Handle follow/unfollow logic here
            print('Follow toggle: $userId -> $isFollowing');
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
          users: [], // Empty list
          currentUserId: _authProvider.userId!,
          backendService: _backendService,
          onFollowToggle: (userId, isFollowing) async {
            print('Follow toggle: $userId -> $isFollowing');
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
      final following = await _backendService.getUserFollowing(_profileData!.user.id);
      
      if (!mounted) return;
      
      showDialog(
        context: context,
        builder: (context) => _FollowersFollowingDialog(
          title: 'Following',
          users: following,
          currentUserId: _authProvider.userId!,
          backendService: _backendService,
          onFollowToggle: (userId, isFollowing) async {
            // Handle follow/unfollow logic here
            print('Follow toggle: $userId -> $isFollowing');
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
          users: [], // Empty list
          currentUserId: _authProvider.userId!,
          backendService: _backendService,
          onFollowToggle: (userId, isFollowing) async {
            print('Follow toggle: $userId -> $isFollowing');
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
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: AppColors.darkBackgroundEnd,
          borderRadius: BorderRadius.circular(16),
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
                    onPressed: () => Navigator.pop(context),
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
              child: widget.users.isEmpty
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
                      itemCount: widget.users.length,
                      itemBuilder: (context, index) {
                        final user = widget.users[index];
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
                  style: AppTextStyles.bodyOnDark.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (username.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    '@$username',
                    style: AppTextStyles.captionOnDark,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          // Follow/Unfollow button (only show if not current user)
          if (userId != widget.currentUserId)
            _buildFollowButton(userId, user),
        ],
      ),
    );
  }

  Widget _buildFollowButton(String userId, Map<String, dynamic> user) {
    // Get follow status information
    final isFollowedBy = user['isFollowedBy'] as bool? ?? false;
    final followRequestStatus = user['followRequestStatus'] as String? ?? 'none'; // 'none', 'pending', 'accepted'
    
    // Determine button text and action based on context
    String buttonText;
    Color buttonColor;
    VoidCallback? onPressed;
    
    if (widget.title == 'Following') {
      // In Following list: Always show "Unfollow" since we're following them
      buttonText = 'Unfollow';
      buttonColor = Colors.red;
      onPressed = () async {
        await _handleUnfollow(userId);
      };
    } else {
      // In Followers list: Instagram-style logic
      if (isFollowedBy) {
        // They follow us back, so show "Remove"
        buttonText = 'Remove';
        buttonColor = Colors.red;
        onPressed = () async {
          await _handleRemove(userId);
        };
      } else if (followRequestStatus == 'pending') {
        // We sent a follow request, show "Pending"
        buttonText = 'Pending';
        buttonColor = Colors.orange;
        onPressed = null; // Disabled button
      } else {
        // They don't follow us back, show "Follow"
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
      await widget.backendService.followUser(widget.currentUserId, userId);
      print('✅ Followed user: $userId');
      
      // Update the user's status to pending
      setState(() {
        final userIndex = widget.users.indexWhere((u) => u['id'] == userId);
        if (userIndex != -1) {
          widget.users[userIndex]['followRequestStatus'] = 'pending';
        }
      });
      
      widget.onFollowToggle(userId, true);
      HapticFeedback.lightImpact();
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
      
      // Update the user's status
      setState(() {
        final userIndex = widget.users.indexWhere((u) => u['id'] == userId);
        if (userIndex != -1) {
          widget.users[userIndex]['isFollowing'] = false;
          widget.users[userIndex]['followRequestStatus'] = 'none';
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
      // Remove the user from our followers (this is different from unfollowing)
      // This would be a new API endpoint like removeFollower
      await widget.backendService.unfollowUser(widget.currentUserId, userId);
      print('✅ Removed user: $userId');
      
      // Update the user's status
      setState(() {
        final userIndex = widget.users.indexWhere((u) => u['id'] == userId);
        if (userIndex != -1) {
          widget.users[userIndex]['isFollowedBy'] = false;
        }
      });
      
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
    return _GlassCard(
      borderRadius: 12,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: const [
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


