import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:songbuddy/constants/app_colors.dart';
import 'package:songbuddy/constants/app_text_styles.dart';
import 'package:songbuddy/providers/auth_provider.dart';
import 'package:songbuddy/services/spotify_deep_link_service.dart';
import 'package:songbuddy/services/backend_service.dart';
import 'package:songbuddy/models/Post.dart';
import 'package:songbuddy/models/ProfileData.dart';
import 'package:songbuddy/widgets/swipeable_post_card.dart';

class UserProfileScreen extends StatefulWidget {
  final String username;
  final String avatarUrl;
  final String? userId;
  final VoidCallback? onBackPressed; // Callback for custom back navigation
  final GlobalKey<NavigatorState>? nestedNavigatorKey; // Navigator key for nested navigation

  const UserProfileScreen({
    super.key,
    required this.username,
    required this.avatarUrl,
    this.userId,
    this.onBackPressed,
    this.nestedNavigatorKey,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  late final AuthProvider _authProvider;
  late final BackendService _backendService;
  late final ScrollController _scrollController;

  bool _initialized = false;
  bool _loading = false;

  Map<String, dynamic>? _user;
  Map<String, dynamic>? _currentlyPlaying; // can be null when 204
  List<Map<String, dynamic>> _topArtists = const [];
  List<Map<String, dynamic>> _topTracks = const [];
  List<Map<String, dynamic>> _recentlyPlayed = const [];
  
  // User posts
  List<Post> _userPosts = [];
  bool _loadingPosts = false;
  
  // Profile data (includes follow status)
  ProfileData? _profileData;
  
  // Follow/unfollow state
  bool _isFollowing = false;
  bool _isPending = false;
  bool _isLoadingFollow = false;

  bool _loadingTop = false; // non-blocking loading for top artists/tracks (kept for future use)
  static const Duration _animDur = Duration(milliseconds: 250);

  @override
  void initState() {
    super.initState();
    _authProvider = AuthProvider();
    _backendService = BackendService();
    _scrollController = ScrollController();
    _initialize();
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

  Future<void> _initialize() async {
    setState(() {
      _loading = true;
    });
    try {
      await _authProvider.initialize();
      _authProvider.addListener(_onAuthChanged);
      _initialized = true;
      if (_authProvider.isAuthenticated && widget.userId != null) {
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

  // Method to navigate to another user profile using nested navigation
  void _navigateToUserProfile(String userId, String username, String avatarUrl) {
    if (widget.nestedNavigatorKey?.currentState != null) {
      widget.nestedNavigatorKey!.currentState!.push(
        MaterialPageRoute(
          builder: (context) => UserProfileScreen(
            username: username,
            avatarUrl: avatarUrl,
            userId: userId,
            onBackPressed: () {
              widget.nestedNavigatorKey!.currentState!.pop();
            },
            nestedNavigatorKey: widget.nestedNavigatorKey,
          ),
        ),
      );
    }
  }

  Future<void> _fetchAll() async {
    if (!_authProvider.isAuthenticated) return;
    setState(() {
      _loading = true;
    });
    
    // ignore: avoid_print
    print('[UserProfile] Fetch start for user: ${widget.userId}');
    try {
      // Initialize user data from widget parameters
      setState(() {
        _user = {
          'display_name': widget.username,
          'images': [{'url': widget.avatarUrl}],
          'email': null,
          'followers': {'total': 0}
        };
      });
      
      // Fetch user profile from backend if we have a userId
      if (widget.userId != null) {
        await _fetchUserProfile();
      } else {
        print('⚠️ UserProfile: No userId provided, showing basic info only');
        // Show basic info without backend data
        setState(() {
          _loadingPosts = false;
        });
      }
      
      // ignore: avoid_print
      print('[UserProfile] Fetch success for user: ${widget.userId}');
    } catch (e) {
      // ignore: avoid_print
      print('[UserProfile] Fetch error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  /// Fetch user profile with posts (NEW EFFICIENT API)
  Future<void> _fetchUserProfile() async {
    if (widget.userId == null) {
      print('❌ UserProfileScreen: User ID is null, cannot fetch profile');
      return;
    }
    
    print('🔍 UserProfileScreen: Fetching profile for user: ${widget.userId}');
    
    setState(() {
      _loadingPosts = true;
      _loadingTop = true; // Set loading state for music sections
    });

    try {
      // Fetch complete profile data (includes posts, follow info, and music sections)
      final profileData = await _backendService.getUserProfile(widget.userId!, currentUserId: _authProvider.userId);
      print('🔍 UserProfileScreen: Received profile data with music sections');
      print('🔍 UserProfileScreen: User: ${profileData.user.displayName}, Posts: ${profileData.posts.length}');
      print('🔍 UserProfileScreen: Currently Playing: ${profileData.currentlyPlaying != null ? "Yes" : "No"}');
      print('🔍 UserProfileScreen: Top Artists: ${profileData.topArtists.length}');
      print('🔍 UserProfileScreen: Top Tracks: ${profileData.topTracks.length}');
      print('🔍 UserProfileScreen: Recently Played: ${profileData.recentlyPlayed.length}');
      
      // Debug: Show the actual data structure we received
      print('🔍 UserProfileScreen: Raw ProfileData object:');
      print('  - currentlyPlaying: ${profileData.currentlyPlaying}');
      print('  - topArtists: ${profileData.topArtists}');
      print('  - topTracks: ${profileData.topTracks}');
      print('  - recentlyPlayed: ${profileData.recentlyPlayed}');
      
      // Debug: Show detailed data structure
      if (profileData.currentlyPlaying != null) {
        print('🔍 UserProfileScreen: Currently Playing data: ${profileData.currentlyPlaying}');
      }
      if (profileData.topArtists.isNotEmpty) {
        print('🔍 UserProfileScreen: First top artist: ${profileData.topArtists.first}');
      }
      if (profileData.topTracks.isNotEmpty) {
        print('🔍 UserProfileScreen: First top track: ${profileData.topTracks.first}');
      }
      if (profileData.recentlyPlayed.isNotEmpty) {
        print('🔍 UserProfileScreen: First recently played: ${profileData.recentlyPlayed.first}');
      }
      
      // Update user data with complete information from backend
      setState(() {
        _userPosts = profileData.posts;
        _profileData = profileData;
        _isFollowing = profileData.user.isFollowing;
        
        // Update Spotify data from profileData
        _currentlyPlaying = profileData.currentlyPlaying;
        _topArtists = profileData.topArtists;
        _topTracks = profileData.topTracks;
        _recentlyPlayed = profileData.recentlyPlayed;
        _loadingTop = false; // Data loaded successfully
        
        // Update _user with more complete data from backend
        _user = {
          'display_name': profileData.user.displayName,
          'images': [{'url': profileData.user.profilePicture}],
          'email': null, // Email is not returned in profile data for privacy
          'followers': {'total': profileData.user.followersCount}
        };
      });
      
      print('✅ UserProfileScreen: Successfully updated all data from getUserProfile API');
      print('✅ UserProfileScreen: Updated user info - DisplayName: ${profileData.user.displayName}, Username: @${profileData.user.username}');
      print('✅ UserProfileScreen: Spotify data loaded - Artists: ${_topArtists.length}, Tracks: ${_topTracks.length}, Recent: ${_recentlyPlayed.length}');
      print('✅ UserProfileScreen: Loading states - _loadingTop: $_loadingTop, _loadingPosts: $_loadingPosts');
      
      // Debug: Check final posts state
      if (_userPosts.isEmpty) {
        print('❌ UserProfileScreen: _userPosts is empty after processing!');
      } else {
        print('✅ UserProfileScreen: _userPosts has ${_userPosts.length} posts');
        for (int i = 0; i < _userPosts.length; i++) {
          final post = _userPosts[i];
          print('🔍 UserProfileScreen: Final post $i: id=${post.id}, title=${post.songName}');
        }
      }
      
      // Log like states for debugging
      for (final post in _userPosts) {
        print('🔍 UserProfileScreen: Post ${post.id} - liked: ${post.isLikedByCurrentUser}, count: ${post.likeCount}');
      }
    } catch (e) {
      print('❌ UserProfileScreen: Failed to fetch user profile: $e');
      
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
        _loadingTop = false; // Ensure loading state is cleared
      });
    }
  }

  Future<void> _handleFollow() async {
    if (widget.userId == null || _authProvider.userId == null) return;
    setState(() { _isLoadingFollow = true; });
    try {
      await _backendService.followUser(_authProvider.userId!, widget.userId!);
      setState(() { 
        _isFollowing = true; 
        _isPending = false;
        // Update profile data
        if (_profileData != null) {
          // Create a new ProfileData with updated follow status
          _profileData = ProfileData(
            user: User(
              id: _profileData!.user.id,
              displayName: _profileData!.user.displayName,
              username: _profileData!.user.username,
              profilePicture: _profileData!.user.profilePicture,
              followersCount: _profileData!.user.followersCount,
              followingCount: _profileData!.user.followingCount,
              postsCount: _profileData!.user.postsCount,
              isFollowing: true,
            ),
            posts: _profileData!.posts,
            pagination: _profileData!.pagination,
          );
        }
      });
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Following ${widget.username}'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to follow user: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() { _isLoadingFollow = false; });
    }
  }

  Future<void> _handleUnfollow() async {
    if (widget.userId == null || _authProvider.userId == null) return;
    setState(() { _isLoadingFollow = true; });
    try {
      await _backendService.unfollowUser(_authProvider.userId!, widget.userId!);
      setState(() { 
        _isFollowing = false; 
        _isPending = false;
        // Update profile data
        if (_profileData != null) {
          // Create a new ProfileData with updated follow status
          _profileData = ProfileData(
            user: User(
              id: _profileData!.user.id,
              displayName: _profileData!.user.displayName,
              username: _profileData!.user.username,
              profilePicture: _profileData!.user.profilePicture,
              followersCount: _profileData!.user.followersCount,
              followingCount: _profileData!.user.followingCount,
              postsCount: _profileData!.user.postsCount,
              isFollowing: false,
            ),
            posts: _profileData!.posts,
            pagination: _profileData!.pagination,
          );
        }
      });
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unfollowed ${widget.username}'), backgroundColor: Colors.orange),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to unfollow user: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() { _isLoadingFollow = false; });
    }
  }

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
                    HapticFeedback.selectionClick();
                  },
                  child: ListView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    children: _loading
                        ? _buildSkeletonWidgets(context)
                        : [
                            _buildTopBar(context),
                            _buildProfileHeader(),
                            _buildSectionTitle('Currently Playing'),
                            _buildCurrentlyPlaying(),
                            _buildSectionTitle('Top Artists'),
                            _buildTopArtistsWidget(),
                            _buildSectionTitle('Top Tracks'),
                            _buildTopTracksWidget(context),
                            _buildSectionTitle('Recently Played'),
                            _buildRecentlyPlayedWidget(),
                            _buildSectionTitle('Posts'),
                            _buildUserPostsWidget(),
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

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
      children: [
        IconButton(
           onPressed: () {
             if (widget.onBackPressed != null) {
               widget.onBackPressed!();
             } else {
               Navigator.pop(context);
             }
           },
          icon: const Icon(Icons.arrow_back, color: AppColors.onDarkSecondary),
        ),
      ],
      ),
    );
  }

  /// Build compact profile header with user info and followers/following buttons
  Widget _buildProfileHeader() {
    final images = (_user?['images'] as List<dynamic>?) ?? const [];
    final avatarUrl = images.isNotEmpty ? (images.first['url'] as String?) : null;
    final displayName = _user?['display_name'] as String? ?? widget.username;
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
                    if (email != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        email,
                        style: AppTextStyles.captionOnDark.copyWith(fontSize: 12),
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
              // Follow/Unfollow button (only show if not current user)
              if (_authProvider.userId != widget.userId)
                _buildFollowUnfollowButton(),
            ],
          ),
          const SizedBox(height: 12),
          // Compact Instagram-style followers/following buttons
          if (_profileData != null)
            Row(
              children: [
                Expanded(
                  child: _buildFollowButton(
                    count: _profileData!.user.followersCount,
                    label: 'Followers',
                    onTap: () => _showFollowersDialog(),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildFollowButton(
                    count: _profileData!.user.followingCount,
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

  Widget _buildFollowUnfollowButton() {
    String buttonText;
    Color buttonColor;
    VoidCallback? onPressed;

    if (_isLoadingFollow) {
      buttonText = 'Loading...';
      buttonColor = AppColors.onDarkSecondary;
      onPressed = null;
    } else if (_isFollowing) {
      buttonText = 'Unfollow';
      buttonColor = Colors.red;
      onPressed = _handleUnfollow;
    } else if (_isPending) {
      buttonText = 'Pending';
      buttonColor = Colors.orange;
      onPressed = null;
    } else {
      buttonText = 'Follow';
      buttonColor = AppColors.primary;
      onPressed = _handleFollow;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: buttonColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: buttonColor.withOpacity(0.3)),
      ),
      child: GestureDetector(
        onTap: onPressed,
        child: Text(
          buttonText,
          style: AppTextStyles.captionOnDark.copyWith(
            color: buttonColor,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
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
    print('🔍 UserProfileScreen: _buildCurrentlyPlaying - _currentlyPlaying: $_currentlyPlaying');
    // Handle both data structures: direct track data or nested in 'item'
    final trackData = _currentlyPlaying?['item'] as Map<String, dynamic>? ?? _currentlyPlaying;
    print('🔍 UserProfileScreen: _buildCurrentlyPlaying - trackData: $trackData');
    if (trackData == null) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: _EmptyCard(
          icon: Icons.play_circle_outline,
          title: 'Nothing playing right now',
          subtitle: 'User is not currently listening to anything.',
      ),
    );
  }

    final name = trackData['name'] as String? ?? '';
    final artists = (trackData['artists'] as List<dynamic>? ?? const [])
        .map((a) => a['name'] as String? ?? '')
        .where((s) => s.isNotEmpty)
        .join(', ');
    final images = trackData['album']?['images'] as List<dynamic>? ?? const [];
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

  // New: Top Artists as a widget (no slivers)
  Widget _buildTopArtistsWidget() {
    print('🔍 UserProfileScreen: _buildTopArtistsWidget - _loadingTop: $_loadingTop, _topArtists.length: ${_topArtists.length}');
    
    // Debug: Show data structure
    if (_topArtists.isNotEmpty) {
      print('🔍 UserProfileScreen: Top Artists data: ${_topArtists.first}');
    }
    
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
    print('🔍 UserProfileScreen: _buildTopTracksWidget - _topTracks.length: ${_topTracks.length}');
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


  // New: Recently played as a widget (no slivers) - Last 24 hours only
  Widget _buildRecentlyPlayedWidget() {
    print('🔍 UserProfileScreen: _buildRecentlyPlayedWidget - _recentlyPlayed.length: ${_recentlyPlayed.length}');
    // Filter tracks from last 24 hours
    final now = DateTime.now();
    final last24Hours = now.subtract(const Duration(hours: 24));
    
    final recentTracks = _recentlyPlayed.where((track) {
      final playedAt = DateTime.tryParse(track['played_at'] as String? ?? '');
      return playedAt != null && playedAt.isAfter(last24Hours);
    }).toList();
    
    print('🔍 UserProfileScreen: _buildRecentlyPlayedWidget - recentTracks.length: ${recentTracks.length}');
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

    print('🔍 UserProfileScreen: UI rendering - _userPosts.length = ${_userPosts.length}');

    if (_userPosts.isEmpty) {
      print('🔍 UserProfileScreen: Showing empty state - no posts to display');
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: _EmptyCard(
          icon: Icons.post_add,
          title: 'No posts yet',
          subtitle: '${widget.username} hasn\'t shared any music yet.',
        ),
      );
    }

    print('🔍 UserProfileScreen: Rendering ${_userPosts.length} posts');
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
        showUserInfo: true, // Show username and avatar in user profile screen
        onDelete: null, // Users can't delete other users' posts
        onEditDescription: null, // Users can't edit other users' posts
        onLikeChanged: (isLiked, likes) async {
          try {
            final userId = _authProvider.userId;
            if (userId == null) {
              print('❌ UserProfileScreen: User not authenticated for like');
              return;
            }
            
            print('🔍 UserProfileScreen: Toggling like for post: ${post.id}, isLiked: $isLiked');
            final result = await _backendService.togglePostLike(post.id, userId, !isLiked);
            print('✅ UserProfileScreen: Like toggled successfully, result: $result');
            
            // Update the post in the list with new like count
            setState(() {
              final postIndex = _userPosts.indexWhere((p) => p.id == post.id);
              if (postIndex != -1) {
                _userPosts[postIndex] = _userPosts[postIndex].copyWith(
                  likeCount: likes,
                  isLikedByCurrentUser: isLiked,
                );
                print('✅ UserProfileScreen: Updated like state for post ${post.id}: liked=$isLiked, count=$likes');
              } else {
                print('❌ UserProfileScreen: Post ${post.id} not found for like update');
              }
            });
            
            HapticFeedback.lightImpact();
          } catch (e) {
            print('❌ UserProfileScreen: Failed to toggle like: $e');
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
            print('🔗 UserProfileScreen: Opening song in Spotify: ${post.songName} by ${post.artistName}');
                final success = await SpotifyDeepLinkService.openSongInSpotify(
                  songName: post.songName,
                  artistName: post.artistName,
                );
            
                if (success) {
              print('✅ UserProfileScreen: Successfully opened song in Spotify');
              HapticFeedback.lightImpact();
            } else {
              print('❌ UserProfileScreen: Failed to open song in Spotify');
              
              // Try simple Spotify opening as fallback
              final simpleSuccess = await SpotifyDeepLinkService.openSpotifySimple();
              if (simpleSuccess) {
                print('✅ UserProfileScreen: Opened Spotify app (simple method)');
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
            print('❌ UserProfileScreen: Error opening Spotify: $e');
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


  // New: Skeleton widgets list used when loading
  List<Widget> _buildSkeletonWidgets(BuildContext context) {
    return [
      // Top bar skeleton
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            const _SkeletonCircle(diameter: 40),
            const Spacer(),
            const _SkeletonBox(width: 120, height: 20, radius: 10),
            const Spacer(),
            const _SkeletonCircle(diameter: 40),
          ],
        ),
      ),
      // Profile Header Skeleton - matches _buildProfileHeader() exactly
      Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        padding: const EdgeInsets.all(20),
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
            // Compact user info row - matches the real layout
            Row(
              children: [
                const _SkeletonCircle(diameter: 48), // radius: 24
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                      const _SkeletonBox(width: 120, height: 18, radius: 9), // displayName
                      const SizedBox(height: 2),
                      const _SkeletonBox(width: 80, height: 12, radius: 6), // email
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const _SkeletonBox(width: 8, height: 8, radius: 4), // people icon
                          const SizedBox(width: 4),
                          const _SkeletonBox(width: 60, height: 11, radius: 5), // followers text
                        ],
                      ),
                    ],
                  ),
                ),
                // Follow button skeleton
                const _SkeletonBox(width: 80, height: 32, radius: 16),
              ],
            ),
            const SizedBox(height: 20),
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
          itemBuilder: (_, __) => Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: const [
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
           itemBuilder: (_, __) => Column(
             mainAxisAlignment: MainAxisAlignment.start,
             children: const [
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
      _buildSectionTitle('Posts'),
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
                    const SizedBox(height: 20),
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
          onUserTap: _navigateToUserProfile,
        ),
      );
    } catch (e) {
      print('❌ UserProfileScreen: Failed to get followers: $e');
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
          onUserTap: _navigateToUserProfile,
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
          onUserTap: _navigateToUserProfile,
        ),
      );
    } catch (e) {
      print('❌ UserProfileScreen: Failed to get following: $e');
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
          onUserTap: _navigateToUserProfile,
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

/// Dialog to show followers/following list
class _FollowersFollowingDialog extends StatefulWidget {
  final String title;
  final List<Map<String, dynamic>> users;
  final String currentUserId;
  final Function(String userId, bool isFollowing) onFollowToggle;
  final BackendService backendService;
  final Function(String userId, String username, String avatarUrl)? onUserTap; // Navigation callback

  const _FollowersFollowingDialog({
    required this.title,
    required this.users,
    required this.currentUserId,
    required this.onFollowToggle,
    required this.backendService,
    this.onUserTap,
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
          GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      widget.onUserTap?.call(
                        userId,
                        displayName,
                        profilePicture ?? "https://i.pravatar.cc/150?img=1",
                      );
                    },
            child: CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.onDarkPrimary.withOpacity(0.1),
              backgroundImage: profilePicture != null ? NetworkImage(profilePicture) : null,
              child: profilePicture == null
                  ? const Icon(Icons.person, color: AppColors.onDarkPrimary, size: 20)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context);
                widget.onUserTap?.call(
                  userId,
                  displayName,
                  profilePicture ?? "https://i.pravatar.cc/150?img=1",
                );
              },
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
