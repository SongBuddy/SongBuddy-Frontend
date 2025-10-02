import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:songbuddy/constants/app_colors.dart';
import 'package:songbuddy/constants/app_text_styles.dart';
import 'package:songbuddy/screens/notification_screen.dart';
import 'package:songbuddy/widgets/music_post_card.dart';
import 'package:songbuddy/widgets/shimmer_post_card.dart';
import 'package:songbuddy/services/backend_service.dart';
import 'package:songbuddy/providers/auth_provider.dart';
import 'package:songbuddy/models/Post.dart';
import 'package:songbuddy/services/spotify_deep_link_service.dart';
import 'package:songbuddy/utils/post_sharing_utils.dart';

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
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMorePosts();
    }
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
    } catch (e) {
      print('❌ HomeFeedScreen: Failed to fetch posts: $e');
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
      print('🔍 HomeFeedScreen: Is authenticated: ${_authProvider.isAuthenticated}');
      
      final posts = await _backendService.getFeedPosts(
        _authProvider.userId!,
        currentUserId: _authProvider.userId,
        limit: _postsPerPage,
        offset: 0,
      );
      
      print('📊 HomeFeedScreen: Received ${posts.length} posts from API');
      print('📊 HomeFeedScreen: Posts details: ${posts.map((p) => '${p.songName} by ${p.artistName}').toList()}');
      
      setState(() {
        _posts = posts;
        _currentPage = 1;
        _hasMorePosts = posts.length >= _postsPerPage;
      });
      
      print('✅ HomeFeedScreen: Successfully fetched ${posts.length} feed posts');
    } catch (e) {
      print('❌ HomeFeedScreen: Failed to fetch feed posts: $e');
      print('❌ HomeFeedScreen: Error type: ${e.runtimeType}');
      print('❌ HomeFeedScreen: Error details: $e');
      
      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load posts: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
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
      
      print('🔗 HomeFeedScreen: Loading more posts - Page: $nextPage, Offset: $offset');
      
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
      
      print('✅ HomeFeedScreen: Successfully loaded ${newPosts.length} more posts. Total: ${_posts.length}');
    } catch (e) {
      print('❌ HomeFeedScreen: Failed to load more posts: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load more posts: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
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
          child: Column(
            children: [
              // Top bar
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
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
                        Navigator.push(context, MaterialPageRoute(builder: (context)=> NotificationScreen()));
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
          ),
        ),
      ),
    );
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
            ElevatedButton(
              onPressed: _fetchFollowingPosts,
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
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

  Widget _buildPostCard(Post post) {
    return MusicPostCard(
      username: post.username,
      avatarUrl: post.userProfilePicture,
      trackTitle: post.songName,
      artist: post.artistName,
      coverUrl: post.songImage,
      description: post.description ?? '',
      initialLikes: post.likeCount,
      isInitiallyLiked: post.isLikedByCurrentUser ?? false,
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update like: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      onShare: () {
        PostSharingUtils.sharePost(post);
      },
      onOpenInSpotify: () async {
        try {
          print('🔗 HomeFeedScreen: Opening song in Spotify: ${post.songName} by ${post.artistName}');
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
                content: Text('Could not open Spotify. Please install Spotify app.'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );
          }
        } catch (e) {
          print('❌ HomeFeedScreen: Error opening Spotify: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error opening Spotify: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
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
