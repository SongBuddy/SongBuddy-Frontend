import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:songbuddy/constants/app_colors.dart';
import 'package:songbuddy/constants/app_text_styles.dart';
import 'package:songbuddy/screens/notification_screen.dart';
import 'package:songbuddy/screens/user_profile_screen.dart';
import 'package:songbuddy/widgets/music_post_card.dart';
import 'package:songbuddy/widgets/shimmer_post_card.dart';
import 'package:songbuddy/services/backend_service.dart';
import 'package:songbuddy/providers/auth_provider.dart';
import 'package:songbuddy/models/Post.dart';
import 'package:songbuddy/services/spotify_deep_link_service.dart';
import 'package:songbuddy/utils/post_sharing_utils.dart';
import 'package:songbuddy/utils/error_snackbar_utils.dart';

class HomeFeedScreen extends StatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  State<HomeFeedScreen> createState() => HomeFeedScreenState();
}

class HomeFeedScreenState extends State<HomeFeedScreen> {
  late final AuthProvider _authProvider;
  late final BackendService _backendService;
  late final ScrollController _scrollController;

  List<Post> _posts = [];
  bool _loading = false;
  bool _loadingMore = false;
  bool _hasMorePosts = true;
  bool _initialized = false;
  int _currentPage = 1;
  static const int _postsPerPage = 10;

  // Suggested users variables
  List<Map<String, dynamic>> _suggestedUsers = [];
  bool _loadingSuggestedUsers = false;

  // Navigation state for nested navigation
  final GlobalKey<NavigatorState> _nestedNavigatorKey =
      GlobalKey<NavigatorState>();
  bool _showUserProfile = false;
  String? _selectedUserId;
  String? _selectedUsername;
  String? _selectedAvatarUrl;

  @override
  void initState() {
    super.initState();
    _authProvider = AuthProvider();
    _backendService = BackendService();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _initializeData();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMorePosts();
    }
  }

  // Method to navigate to user profile (sub-route)
  void _navigateToUserProfile(
      String userId, String username, String avatarUrl) {
    setState(() {
      _showUserProfile = true;
      _selectedUserId = userId;
      _selectedUsername = username;
      _selectedAvatarUrl = avatarUrl;
    });
  }

  // Method to go back to home feed
  void _goBackToHomeFeed() {
    setState(() {
      _showUserProfile = false;
      _selectedUserId = null;
      _selectedUsername = null;
      _selectedAvatarUrl = null;
    });
  }

  Future<void> _initializeData() async {
    if (!_authProvider.isAuthenticated) {
      setState(() {
        _initialized = true;
      });
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      await _fetchFollowingPosts();

      // If no posts found, load suggested users
      if (_posts.isEmpty) {
        await _loadSuggestedUsers();
      }
    } catch (e) {
      print('❌ HomeFeedScreen: Failed to fetch posts: $e');
      if (mounted) {
        ErrorSnackbarUtils.showErrorSnackbar(context, e, operation: 'load_posts');
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _initialized = true;
        });
      }
    }
  }

  Future<void> _fetchFollowingPosts() async {
    try {
      print('🔗 HomeFeedScreen: Fetching feed posts from users you follow...');
      print('🔍 HomeFeedScreen: User ID: ${_authProvider.userId}');
      print(
          '🔍 HomeFeedScreen: Is authenticated: ${_authProvider.isAuthenticated}');

      final posts = await _backendService.getFeedPosts(
        _authProvider.userId!,
        currentUserId: _authProvider.userId,
        limit: _postsPerPage,
        offset: 0,
      );

      print('📊 HomeFeedScreen: Received ${posts.length} posts from API');
      print(
          '📊 HomeFeedScreen: Posts details: ${posts.map((p) => '${p.songName} by ${p.artistName}').toList()}');

      setState(() {
        _posts = posts;
        _currentPage = 1;
        _hasMorePosts = posts.length >= _postsPerPage;
      });

      print(
          '✅ HomeFeedScreen: Successfully fetched ${posts.length} feed posts');
    } catch (e) {
      print('❌ HomeFeedScreen: Failed to fetch feed posts: $e');
      print('❌ HomeFeedScreen: Error type: ${e.runtimeType}');
      print('❌ HomeFeedScreen: Error details: $e');

      // Show error message to user
      if (mounted) {
        ErrorSnackbarUtils.showErrorSnackbar(context, e, operation: 'load_posts');
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadMorePosts() async {
    if (_loadingMore || !_hasMorePosts) return;

    setState(() {
      _loadingMore = true;
    });

    try {
      final nextPage = _currentPage + 1;
      final offset = (nextPage - 1) * _postsPerPage;

      print(
          '🔗 HomeFeedScreen: Loading more posts - Page: $nextPage, Offset: $offset');

      final newPosts = await _backendService.getFeedPosts(
        _authProvider.userId!,
        currentUserId: _authProvider.userId,
        limit: _postsPerPage,
        offset: offset,
      );

      print('📊 HomeFeedScreen: Received ${newPosts.length} more posts');

      setState(() {
        _posts.addAll(newPosts);
        _currentPage = nextPage;
        _hasMorePosts = newPosts.length >= _postsPerPage;
      });

      print(
          '✅ HomeFeedScreen: Successfully loaded ${newPosts.length} more posts. Total: ${_posts.length}');
    } catch (e) {
      print('❌ HomeFeedScreen: Failed to load more posts: $e');

      if (mounted) {
        ErrorSnackbarUtils.showErrorSnackbar(context, e, operation: 'load_posts');
      }
    } finally {
      setState(() {
        _loadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.darkBackgroundStart,
              AppColors.darkBackgroundEnd,
            ],
          ),
        ),
        child: SafeArea(
          child:
              _showUserProfile ? _buildUserProfileView() : _buildHomeFeedView(),
        ),
      ),
    );
  }

  Widget _buildUserProfileView() {
    return Navigator(
      key: _nestedNavigatorKey,
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => UserProfileScreen(
            username: _selectedUsername ?? '',
            avatarUrl: _selectedAvatarUrl ?? '',
            userId: _selectedUserId,
            onBackPressed: _goBackToHomeFeed,
            nestedNavigatorKey:
                _nestedNavigatorKey, // Pass navigator key for nested navigation
          ),
        );
      },
    );
  }

  Widget _buildHomeFeedView() {
    return Column(
      children: [
        // Top bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
          child: Row(
            children: [
              Text(
                "SongBuddy",
                style: AppTextStyles.heading2OnDark.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  letterSpacing: 0.6,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => NotificationScreen()));
                },
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: AppColors.onDarkSecondary,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Divider(color: Colors.white.withOpacity(0.04), height: 1),
        ),

        // Feed
        Expanded(
          child: _buildFeedContent(),
        ),
      ],
    );
  }

  Future<void> _loadSuggestedUsers() async {
    setState(() {
      _loadingSuggestedUsers = true;
    });

    try {
      // Try multiple search strategies to find users
      List<Map<String, dynamic>> allUsers = [];

      // Strategy 1: Search with common letters
      final commonLetters = ['a', 'e', 'i', 'o', 'u'];
      for (final letter in commonLetters) {
        try {
          print('🔍 HomeFeedScreen: Trying search with letter "$letter"');
          final users = await _backendService.searchUsers(letter, limit: 2);
          print(
              '✅ HomeFeedScreen: Found ${users.length} users with letter "$letter"');
          allUsers.addAll(users);

          if (allUsers.length >= 6) break;
        } catch (e) {
          print('❌ HomeFeedScreen: Search failed for letter "$letter": $e');
        }
      }

      // Strategy 2: If still no users, try common words
      if (allUsers.isEmpty) {
        final commonWords = ['user', 'music', 'song'];
        for (final word in commonWords) {
          try {
            print('🔍 HomeFeedScreen: Trying search with word "$word"');
            final users = await _backendService.searchUsers(word, limit: 3);
            print(
                '✅ HomeFeedScreen: Found ${users.length} users with word "$word"');
            allUsers.addAll(users);

            if (allUsers.length >= 6) break;
          } catch (e) {
            print('❌ HomeFeedScreen: Search failed for word "$word": $e');
          }
        }
      }

      // Remove duplicates and current user, limit to 6
      final uniqueUsers = <String, Map<String, dynamic>>{};
      final currentUserId = _authProvider.userId;

      for (final user in allUsers) {
        final userId = user['id'] as String;

        // Skip current user and duplicates
        if (userId != currentUserId && !uniqueUsers.containsKey(userId)) {
          uniqueUsers[userId] = user;
        }
      }

      final finalUsers = uniqueUsers.values.take(6).toList();

      print(
          '✅ HomeFeedScreen: Final suggested users: ${finalUsers.length} (current user filtered out)');
      for (final user in finalUsers) {
        print('   - ${user['displayName']} (@${user['username']})');
      }

      setState(() {
        _suggestedUsers = finalUsers;
      });
    } catch (e) {
      print('❌ HomeFeedScreen: Failed to load suggested users: $e');
      // Set empty list on error
      setState(() {
        _suggestedUsers = [];
      });
    } finally {
      setState(() {
        _loadingSuggestedUsers = false;
      });
    }
  }

  Future<void> _handleFollowUser(String userId) async {
    try {
      await _backendService.followUser(_authProvider.userId!, userId);

      // Remove the followed user from suggestions
      setState(() {
        _suggestedUsers.removeWhere((user) => user['id'] == userId);
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User followed successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('❌ HomeFeedScreen: Failed to follow user: $e');
      if (mounted) {
        ErrorSnackbarUtils.showErrorSnackbar(context, e, operation: 'follow_user');
      }
    }
  }

  Widget _buildFeedContent() {
    if (!_initialized) {
      return ShimmerPostList(
        itemCount: 4,
        height: 180,
        borderRadius: 18,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      );
    }

    if (!_authProvider.isAuthenticated) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.music_note,
              size: 64,
              color: AppColors.onDarkSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'Connect to Spotify to see posts',
              style: AppTextStyles.bodyOnDark.copyWith(
                color: AppColors.onDarkSecondary,
              ),
            ),
          ],
        ),
      );
    }

    if (_loading) {
      return ShimmerPostList(
        itemCount: 4,
        height: 180,
        borderRadius: 18,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      );
    }

    if (_posts.isEmpty) {
      return _buildEmptyStateWithSuggestions();
    }

    return RefreshIndicator(
      onRefresh: () async {
        HapticFeedback.lightImpact();
        setState(() {
          _loading = true;
        });

        try {
          await _fetchFollowingPosts();
        } finally {
          if (mounted) {
            setState(() {
              _loading = false;
            });
          }
        }
        HapticFeedback.selectionClick();
      },
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        itemCount: _posts.length + (_loadingMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == _posts.length) {
            // Loading indicator at the bottom
            return _buildLoadingIndicator();
          }
          final post = _posts[index];
          return _buildPostCard(post);
        },
      ),
    );
  }

  Widget _buildEmptyStateWithSuggestions() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header
          const Icon(
            Icons.people_outline,
            size: 64,
            color: AppColors.onDarkSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'No posts from people you follow',
            style: AppTextStyles.heading2OnDark.copyWith(
              color: AppColors.onDarkSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Follow some users to see their posts here',
            style: AppTextStyles.bodyOnDark.copyWith(
              color: AppColors.onDarkSecondary,
            ),
          ),
          const SizedBox(height: 24),

          // Suggested users header
          Text(
            'Suggested for you',
            style: AppTextStyles.heading2OnDark.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),

          // Users list
          if (_loadingSuggestedUsers)
            const Center(
              child: CircularProgressIndicator(color: Colors.purple),
            )
          else if (_suggestedUsers.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.06),
                  width: 1,
                ),
              ),
              child: const Center(
                child: Text(
                  'No users to suggest at the moment',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _suggestedUsers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final user = _suggestedUsers[index];
                return _buildSuggestedUserCard(user);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSuggestedUserCard(Map<String, dynamic> user) {
    final displayName = user['displayName'] as String? ?? 'Unknown User';
    final username = user['username'] as String? ?? '';
    final followersCount = user['followersCount'] as int? ?? 0;
    final profilePicture = user['profilePicture'] as String? ?? '';
    final userId = user['id'] as String;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.06),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _navigateToUserProfile(user['id'],
                user['username'] ?? '', user['profilePicture'] ?? ''),
            child: CircleAvatar(
              radius: 24,
              backgroundColor: Colors.purple,
              backgroundImage: profilePicture.isNotEmpty
                  ? NetworkImage(profilePicture)
                  : null,
              child: profilePicture.isEmpty
                  ? const Icon(Icons.person, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: GestureDetector(
              onTap: () => _navigateToUserProfile(user['id'], user['username'] ?? '', user['profilePicture'] ?? ''),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  if (username.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      '@$username',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    '$followersCount followers',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () => _handleFollowUser(userId),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(80, 36),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: const Text(
              'Follow',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(Post post) {
    return MusicPostCard(
      username: post.username,
      avatarUrl: post.userProfilePicture,
      trackTitle: post.songName,
      artist: post.artistName,
      coverUrl: post.songImage,
      description: post.description ?? '',
      initialLikes: post.likeCount,
      isInitiallyLiked: post.isLikedByCurrentUser,
      timeAgo: post.timeline,
      height: 180,
      avatarVerticalPadding: 6,
      showUserInfo: true,
      onLikeChanged: (isLiked, likes) async {
        try {
          await _backendService.togglePostLike(
            post.id,
            _authProvider.userId!,
            !isLiked,
          );

          // Update the post in the list
          setState(() {
            final updatedPost = post.copyWith(
              likeCount: likes,
              isLikedByCurrentUser: isLiked,
            );
            final index = _posts.indexWhere((p) => p.id == post.id);
            if (index != -1) {
              _posts[index] = updatedPost;
            }
          });

          HapticFeedback.lightImpact();
        } catch (e) {
          print('❌ HomeFeedScreen: Failed to toggle like: $e');
          ErrorSnackbarUtils.showErrorSnackbar(context, e, operation: 'toggle_like');
        }
      },
      onShare: () {
        PostSharingUtils.sharePost(post);
      },
      onOpenInSpotify: () async {
        try {
          print(
              '🔗 HomeFeedScreen: Opening song in Spotify: ${post.songName} by ${post.artistName}');
          final success = await SpotifyDeepLinkService.openSongInSpotify(
            songName: post.songName,
            artistName: post.artistName,
          );

          if (success) {
            print('✅ HomeFeedScreen: Successfully opened song in Spotify');
            HapticFeedback.lightImpact();
          } else {
            print('❌ HomeFeedScreen: Failed to open song in Spotify');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content:
                    Text('Could not open Spotify. Please install Spotify app.'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );
          }
        } catch (e) {
          print('❌ HomeFeedScreen: Error opening Spotify: $e');
          ErrorSnackbarUtils.showErrorSnackbar(context, e, operation: 'open_spotify');
        }
      },
      onUserTap: () {
        print('👤 HomeFeedScreen: User tapped on ${post.username}');
        _navigateToUserProfile(
          post.userId,
          post.username,
          post.userProfilePicture,
        );
      },
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.onDarkSecondary,
        ),
      ),
    );
  }

  /// Scroll to top and refresh the home feed
  void scrollToTopAndRefresh() {
    // Show loading indicator immediately
    setState(() {
      _loading = true;
    });

    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );

      // Trigger refresh after scroll animation
      Future.delayed(const Duration(milliseconds: 350), () {
        _fetchFollowingPosts();
      });
    } else {
      // If scroll controller is not ready, just refresh
      _fetchFollowingPosts();
    }
  }
}

// Removed old _BlurPostCard in favor of reusable MusicPostCard
