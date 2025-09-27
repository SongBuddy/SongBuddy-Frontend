import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:songbuddy/constants/app_colors.dart';
import 'package:songbuddy/constants/app_text_styles.dart';
import 'package:songbuddy/providers/auth_provider.dart';
import 'package:songbuddy/services/backend_service.dart';
import 'package:songbuddy/models/Post.dart';
import 'package:songbuddy/models/ProfileData.dart';
import 'package:songbuddy/widgets/swipeable_post_card.dart';
import 'package:songbuddy/services/spotify_deep_link_service.dart';

class UserProfileScreen extends StatefulWidget {
  final String username;
  final String avatarUrl;
  final String? userId;

  const UserProfileScreen({
    super.key,
    required this.username,
    required this.avatarUrl,
    this.userId,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  late final AuthProvider _authProvider;
  late final BackendService _backendService;

  bool _loading = false;
  ProfileData? _profileData;
  List<Post> _userPosts = [];
  bool _loadingPosts = false;
  bool _isFollowing = false;
  bool _isPending = false;
  bool _isLoadingFollow = false;

  @override
  void initState() {
    super.initState();
    _authProvider = AuthProvider();
    _backendService = BackendService();
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() { _loading = true; });
    try {
      await _authProvider.initialize();
      if (_authProvider.isAuthenticated && widget.userId != null) {
        await _fetchUserProfile();
      }
    } catch (e) {
      print('❌ UserProfileScreen: Failed to initialize: $e');
    } finally {
      if (mounted) {
        setState(() { _loading = false; });
      }
    }
  }

  Future<void> _fetchUserProfile() async {
    if (widget.userId == null) return;
    setState(() { _loadingPosts = true; });
    try {
      final profileData = await _backendService.getUserProfile(
        widget.userId!,
        currentUserId: _authProvider.userId,
      );
      setState(() {
        _profileData = profileData;
        _userPosts = profileData.posts;
        _isFollowing = profileData.user.isFollowing;
      });
    } catch (e) {
      print('❌ UserProfileScreen: Failed to fetch user profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load profile: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() { _loadingPosts = false; });
    }
  }

  Future<void> _handleFollow() async {
    if (widget.userId == null || _authProvider.userId == null) return;
    setState(() { _isLoadingFollow = true; });
    try {
      await _backendService.followUser(widget.userId!, _authProvider.userId!);
      setState(() { _isFollowing = true; _isPending = false; });
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
      await _backendService.unfollowUser(widget.userId!, _authProvider.userId!);
      setState(() { _isFollowing = false; _isPending = false; });
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
                    await _fetchUserProfile();
                    HapticFeedback.selectionClick();
                  },
                  child: ListView(
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
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: AppColors.onDarkSecondary),
        ),
        const Spacer(),
        Text(
          widget.username,
          style: AppTextStyles.heading2OnDark.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            letterSpacing: 0.6,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.more_vert, color: AppColors.onDarkSecondary),
        ),
      ],
    );
  }

  Widget _buildProfileHeader() {
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
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.onDarkPrimary.withOpacity(0.12),
                backgroundImage: NetworkImage(widget.avatarUrl),
                child: const Icon(Icons.person, color: AppColors.onDarkPrimary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.username,
                      style: AppTextStyles.heading2OnDark.copyWith(fontSize: 18),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_profileData != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${_profileData!.user.postsCount} posts',
                        style: AppTextStyles.captionOnDark.copyWith(fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (_profileData != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.people, size: 12, color: AppColors.onDarkSecondary),
                          const SizedBox(width: 4),
                          Text(
                            '${_profileData!.user.followersCount} followers',
                            style: AppTextStyles.captionOnDark.copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (_authProvider.userId != widget.userId)
                _buildFollowUnfollowButton(),
            ],
          ),
          const SizedBox(height: 12),
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

  Widget _buildCurrentlyPlaying() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: _EmptyCard(
        icon: Icons.music_off,
        title: 'Currently Playing',
        subtitle: 'No current activity',
      ),
    );
  }

  Widget _buildTopArtistsWidget() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: _EmptyCard(
        icon: Icons.people_outline,
        title: 'Top Artists',
        subtitle: 'Artist data not available',
      ),
    );
  }

  Widget _buildTopTracksWidget(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: _EmptyCard(
        icon: Icons.music_note,
        title: 'Top Tracks',
        subtitle: 'Track data not available',
      ),
    );
  }

  Widget _buildRecentlyPlayedWidget() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: _EmptyCard(
        icon: Icons.history,
        title: 'Recently Played',
        subtitle: 'Play history not available',
      ),
    );
  }

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

    if (_userPosts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: _EmptyCard(
          icon: Icons.music_off,
          title: 'No posts yet',
          subtitle: '${widget.username} hasn\'t shared any music yet.',
        ),
      );
    }

    return Column(
      children: _userPosts.map((post) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: SwipeablePostCard(
            post: post,
            onDelete: null,
            onEditDescription: null,
            onOpenInSpotify: () async {
              try {
                final success = await SpotifyDeepLinkService.openSongInSpotify(
                  songName: post.songName,
                  artistName: post.artistName,
                );
                if (success) {
                  HapticFeedback.lightImpact();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Could not open Spotify. Please install Spotify app.'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error opening Spotify: $e'), backgroundColor: Colors.red),
                );
              }
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(title, style: AppTextStyles.heading2OnDark),
    );
  }

  List<Widget> _buildSkeletonWidgets(BuildContext context) {
    return [
      Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.onDarkPrimary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.onDarkPrimary.withOpacity(0.1), width: 1),
        ),
        child: Row(
          children: [
            const _SkeletonCircle(diameter: 48),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SkeletonBox(width: 120, height: 18, radius: 6),
                  const SizedBox(height: 8),
                  const _SkeletonBox(width: 80, height: 12, radius: 6),
                ],
              ),
            ),
          ],
        ),
      ),
      _buildSectionTitle('Currently Playing'),
      const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: _SkeletonTile()),
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
          itemCount: 4,
        ),
      ),
      _buildSectionTitle('Top Tracks'),
      ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 3,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: const _SkeletonTile(),
        ),
      ),
      _buildSectionTitle('Recently Played'),
      ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 3,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: const _SkeletonTile(),
        ),
      ),
      _buildSectionTitle('Posts'),
      ...List.generate(3, (index) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: const _SkeletonTile(),
      )),
    ];
  }

  Future<void> _showFollowersDialog() async {
    if (_profileData == null) return;
    try {
      final followers = await _backendService.getUserFollowers(widget.userId!);
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => _FollowersFollowingDialog(
          title: 'Followers',
          users: followers,
          currentUserId: _authProvider.userId,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load followers: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _showFollowingDialog() async {
    if (_profileData == null) return;
    try {
      final following = await _backendService.getUserFollowing(widget.userId!);
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => _FollowersFollowingDialog(
          title: 'Following',
          users: following,
          currentUserId: _authProvider.userId,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load following: $e'), backgroundColor: Colors.red),
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
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.onDarkPrimary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.onDarkPrimary.withOpacity(0.08), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: AppColors.onDarkSecondary),
          const SizedBox(height: 16),
          Text(title, style: AppTextStyles.heading2OnDark.copyWith(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(subtitle, style: AppTextStyles.captionOnDark, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _FollowersFollowingDialog extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> users;
  final String? currentUserId;

  const _FollowersFollowingDialog({required this.title, required this.users, this.currentUserId});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.onDarkPrimary.withOpacity(0.9),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: users.isEmpty
            ? Center(child: Text('No $title yet', style: const TextStyle(color: Colors.white54)))
            : ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  final displayName = user['displayName'] as String? ?? 'Unknown User';
                  final username = user['username'] as String? ?? '';
                  final profilePicture = user['profilePicture'] as String? ?? '';
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.purple,
                      backgroundImage: profilePicture.isNotEmpty ? NetworkImage(profilePicture) : null,
                      child: profilePicture.isEmpty ? const Icon(Icons.person, color: Colors.white) : null,
                    ),
                    title: Text(displayName, style: const TextStyle(color: Colors.white)),
                    subtitle: username.isNotEmpty ? Text('@$username', style: const TextStyle(color: Colors.white70)) : null,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UserProfileScreen(
                            username: displayName,
                            avatarUrl: profilePicture.isNotEmpty ? profilePicture : "https://i.pravatar.cc/150?img=1",
                            userId: user['id'] as String?,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close', style: TextStyle(color: Colors.white)),
        ),
      ],
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
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();
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
