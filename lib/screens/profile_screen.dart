import 'package:flutter/material.dart';
import 'dart:ui';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../providers/google_auth_provider.dart';
import '../services/backend_service.dart';
import '../models/Post.dart';
import '../models/ProfileData.dart';
import '../screens/create_post_screen.dart';
import '../widgets/swipeable_post_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  late final ScrollController _scrollController;
  late final GoogleAuthProvider _authProvider;
  late final BackendService _backendService;
  late final AnimationController _fabAnimationController;
  late final AnimationController _headerAnimationController;
  
  bool _isLoading = true;
  ProfileData? _profileData;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _authProvider = GoogleAuthProvider();
    _backendService = BackendService();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fetchAll();
    _headerAnimationController.forward();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fabAnimationController.dispose();
    _headerAnimationController.dispose();
    super.dispose();
  }

  Future<void> _fetchAll() async {
    if (!mounted) return;
    
      setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Fetch user data from Google Auth
      final user = _authProvider.user;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Fetch profile data from backend
      final profileData = await _backendService.getUserProfile(_authProvider.userId!);
      
      if (mounted) {
              setState(() {
                _profileData = profileData;
          _isLoading = false;
              });
            }
          } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    await _fetchAll();
  }

  void scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
      return Scaffold(
      backgroundColor: AppColors.darkBackgroundStart,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.darkBackgroundStart,
              AppColors.darkBackgroundMid,
              AppColors.darkBackgroundEnd,
            ],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? _buildLoadingState()
              : _errorMessage != null
                  ? _buildErrorState()
                  : _buildContent(),
        ),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
          gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primaryAccent,
                ],
              ),
            ),
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 40,
                                ),
                              ),
                            const SizedBox(height: 24),
          Text(
            'Loading your profile...',
            style: AppTextStyles.heading3OnDark.copyWith(
              color: AppColors.onDarkSecondary,
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.error.withOpacity(0.1),
                border: Border.all(
                  color: AppColors.error.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.error_outline,
                color: AppColors.error,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
                        Text(
              'Something went wrong',
              style: AppTextStyles.heading3OnDark,
            ),
                          const SizedBox(height: 8),
                              Text(
              _errorMessage ?? 'Unknown error',
              style: AppTextStyles.bodyOnDark.copyWith(
                color: AppColors.onDarkSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchAll,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                              ),
                            ),
                          ],
                        ),
      ),
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: _refresh,
      color: AppColors.primary,
      backgroundColor: AppColors.darkSurface,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildProfileHeader(),
          _buildStatsSection(),
          _buildPostsSection(),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    final user = _authProvider.user;
    if (user == null) return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverToBoxAdapter(
      child: AnimatedBuilder(
        animation: _headerAnimationController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, 50 * (1 - _headerAnimationController.value)),
            child: Opacity(
              opacity: _headerAnimationController.value,
                  child: Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.glassBackgroundStrong,
                      AppColors.glassBackground,
                    ],
                  ),
              border: Border.all(
                    color: AppColors.glassBorder,
                width: 1,
              ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadowDark,
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                          child: Column(
                            children: [
                    // Profile Picture
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.primaryAccent,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                      child: ClipOval(
                        child: user['photoURL'] != null
                            ? Image.network(
                                user['photoURL'],
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: 50,
                                  );
                                },
                              )
                            : const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 50,
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // User Name
                    Text(
                      user['displayName'] ?? 'User',
                      style: AppTextStyles.heading2OnDark.copyWith(
                        fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                    
                    // User Email
                Text(
                      user['email'] ?? '',
                      style: AppTextStyles.bodyOnDark.copyWith(
                        color: AppColors.onDarkSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Action Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                        _buildActionButton(
                          icon: Icons.edit,
                          label: 'Edit Profile',
                          onTap: () {
                            // TODO: Implement edit profile
                          },
                        ),
                        _buildActionButton(
                          icon: Icons.settings,
                          label: 'Settings',
                          onTap: () {
                            // TODO: Navigate to settings
                          },
                        ),
                      ],
                    ),
                  ],
          ),
        ),
      ),
    );
        },
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: AppColors.glassBackground,
          border: Border.all(
            color: AppColors.glassBorder,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: AppColors.primary,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTextStyles.captionOnDark.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    final posts = _profileData?.posts ?? [];
    final followers = 0; // TODO: Add followers count to ProfileData
    final following = 0; // TODO: Add following count to ProfileData

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: AppColors.glassBackground,
          border: Border.all(
            color: AppColors.glassBorder,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('Posts', posts.length.toString()),
            _buildStatItem('Followers', followers.toString()),
            _buildStatItem('Following', following.toString()),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
                children: [
                  Text(
          value,
          style: AppTextStyles.heading3OnDark.copyWith(
                      fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.captionOnDark,
        ),
      ],
    );
  }

  Widget _buildPostsSection() {
    final posts = _profileData?.posts ?? [];

    if (posts.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: AppColors.glassBackground,
        border: Border.all(
              color: AppColors.glassBorder,
          width: 1,
        ),
      ),
            child: Column(
              children: [
              Icon(
                Icons.music_note_outlined,
                size: 60,
                color: AppColors.onDarkSecondary,
              ),
              const SizedBox(height: 16),
                Text(
                'No posts yet',
                style: AppTextStyles.heading3OnDark.copyWith(
                  color: AppColors.onDarkSecondary,
                ),
              ),
              const SizedBox(height: 8),
                  Text(
                'Share your favorite music with the world!',
                style: AppTextStyles.bodyOnDark.copyWith(
                  color: AppColors.onDarkTertiary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
      ),
    );
  }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final post = posts[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
            child: SwipeablePostCard(
              post: post,
            ),
            );
          },
          childCount: posts.length,
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return AnimatedBuilder(
      animation: _fabAnimationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _fabAnimationController.value,
        child: Container(
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primaryAccent,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreatePostScreen(),
                  ),
                ).then((_) {
                  _fetchAll(); // Refresh posts after creating
                });
              },
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 28,
              ),
        ),
      ),
    );
      },
    );
  }

}