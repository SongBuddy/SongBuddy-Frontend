import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:songbuddy/constants/app_colors.dart';
import 'package:songbuddy/constants/app_text_styles.dart';
import 'package:songbuddy/providers/google_auth_provider.dart';
import 'package:songbuddy/services/backend_service.dart';
import 'package:songbuddy/models/Post.dart';
import 'package:songbuddy/models/ProfileData.dart';
import 'package:songbuddy/widgets/swipeable_post_card.dart';
import 'package:songbuddy/screens/create_post_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  late final GoogleAuthProvider _authProvider;
  late final BackendService _backendService;
  late final ScrollController _scrollController;

  bool _initialized = false;
  bool _loading = false;

  Map<String, dynamic>? _user;
  ProfileData? _profileData;

  // User posts
  List<Post> _userPosts = [];
  bool _loadingPosts = false;

  // FAB state
  bool _showFAB = true;

  @override
  void initState() {
    super.initState();
    _authProvider = GoogleAuthProvider();
    _authProvider.addListener(_onAuthChanged);
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

  /// Handle scroll events for smart FAB behavior
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    
    final currentScrollPosition = _scrollController.position.pixels;
    
    // Show FAB when at top, hide when scrolling down
    final shouldShowFAB = currentScrollPosition < 100;
    
    if (shouldShowFAB != _showFAB) {
      setState(() {
        _showFAB = shouldShowFAB;
      });
    }
  }

  Future<void> _fetchAll() async {
    if (!_authProvider.isAuthenticated) return;
    setState(() {
      _loading = true;
    });
    
    print('[Profile] Fetch start');
    try {
      // Get user data from Google Auth
      final user = _authProvider.user;
      if (user != null) {
        setState(() {
          _user = user;
        });
        print('[Profile] Google user data loaded: ${user['displayName']}, ${user['email']}');
      }
      
      // Essential backend profile data (posts count, followers, following, username)
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
      
      // Fetch user posts separately (heavier data, can load after essential info)
      _fetchUserPosts();
      
      print('[Profile] Fetch success: user=${_user?['id']}');
    } catch (e) {
      print('[Profile] Fetch error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  /// Fetch user posts only
  Future<void> _fetchUserPosts() async {
    if (_authProvider.userId == null) {
      print('❌ ProfileScreen: User ID is null, cannot fetch posts');
      return;
    }

    setState(() {
      _loadingPosts = true;
    });

    try {
      final posts = await _backendService.getUserPosts(_authProvider.userId!);
      setState(() {
        _userPosts = posts;
      });
      print('✅ ProfileScreen: Loaded ${posts.length} user posts');
    } catch (e) {
      print('❌ ProfileScreen: Failed to fetch user posts: $e');
    } finally {
      if (mounted) {
        setState(() {
          _loadingPosts = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized || _loading) {
      return _buildSkeleton();
    }

    if (!_authProvider.isAuthenticated) {
      return _buildNotAuthenticated();
    }

    return Scaffold(
      backgroundColor: AppColors.darkBackgroundStart,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Profile Header
          SliverToBoxAdapter(
            child: _buildProfileHeader(),
          ),
          
          // User Posts
          SliverToBoxAdapter(
            child: _buildPostsSection(),
          ),
        ],
      ),
      floatingActionButton: _showFAB ? _buildFAB() : null,
    );
  }

  Widget _buildSkeleton() {
    return Scaffold(
      backgroundColor: AppColors.darkBackgroundStart,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _buildProfileHeaderSkeleton(),
          ),
          SliverToBoxAdapter(
            child: _buildPostsSkeleton(),
          ),
        ],
      ),
    );
  }

  Widget _buildNotAuthenticated() {
    return Scaffold(
      backgroundColor: AppColors.darkBackgroundStart,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_off,
              size: 64,
              color: AppColors.onDarkSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'Not Signed In',
              style: AppTextStyles.heading2OnDark,
            ),
            const SizedBox(height: 8),
            Text(
              'Please sign in to view your profile',
              style: AppTextStyles.bodyOnDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    final avatarUrl = _user?['photoURL'] as String?;
    final displayName = _user?['displayName'] as String? ?? 'Google User';
    final email = _user?['email'] as String?;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(16),
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
          // User info row
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.onDarkPrimary.withOpacity(0.12),
                backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                child: avatarUrl == null
                    ? const Icon(Icons.person, color: AppColors.onDarkPrimary, size: 32)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: AppTextStyles.heading2OnDark.copyWith(fontSize: 20),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Show email if available from Google Auth
                    if (email != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: AppTextStyles.captionOnDark.copyWith(
                          fontSize: 14,
                          color: AppColors.onDarkSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    // Show posts count if available
                    if (_profileData != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.post_add, size: 16, color: AppColors.onDarkSecondary),
                          const SizedBox(width: 6),
                          Text(
                            '${_profileData!.user.postsCount} posts',
                            style: AppTextStyles.captionOnDark.copyWith(fontSize: 12),
                          ),
                          const SizedBox(width: 16),
                          const Icon(Icons.people, size: 16, color: AppColors.onDarkSecondary),
                          const SizedBox(width: 6),
                          Text(
                            '${_profileData!.user.followersCount} followers',
                            style: AppTextStyles.captionOnDark.copyWith(fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeaderSkeleton() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.onDarkPrimary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.onDarkPrimary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.onDarkPrimary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 20,
                  width: 150,
                  decoration: BoxDecoration(
                    color: AppColors.onDarkPrimary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 16,
                  width: 200,
                  decoration: BoxDecoration(
                    color: AppColors.onDarkPrimary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostsSection() {
    if (_loadingPosts) {
      return _buildPostsSkeleton();
    }

    if (_userPosts.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(32),
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
            Icon(
              Icons.post_add,
              size: 48,
              color: AppColors.onDarkSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No Posts Yet',
              style: AppTextStyles.heading2OnDark,
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first post to share your music!',
              style: AppTextStyles.bodyOnDark,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                'Your Posts',
                style: AppTextStyles.heading2OnDark,
              ),
              const Spacer(),
              Text(
                '${_userPosts.length} posts',
                style: AppTextStyles.captionOnDark,
              ),
            ],
          ),
        ),
        ..._userPosts.map((post) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: SwipeablePostCard(
            post: post,
          ),
        )),
      ],
    );
  }

  Widget _buildPostsSkeleton() {
    return Column(
      children: List.generate(3, (index) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
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
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.onDarkPrimary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 16,
                        width: 100,
                        decoration: BoxDecoration(
                          color: AppColors.onDarkPrimary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: 12,
                        width: 60,
                        decoration: BoxDecoration(
                          color: AppColors.onDarkPrimary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 60,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.onDarkPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ),
      )),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton(
      onPressed: () {
        // Navigate to create post screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const CreatePostScreen(),
          ),
        ).then((success) {
          if (success == true) {
            // Post created successfully, refresh posts
            _fetchUserPosts();
            HapticFeedback.lightImpact();
          }
        });
      },
      backgroundColor: AppColors.primary,
      child: const Icon(Icons.add, color: Colors.white),
    );
  }

  /// Scroll to top of the profile
  void scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }
}
