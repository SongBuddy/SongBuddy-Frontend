import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shimmer/shimmer.dart';
import '../providers/auth_provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../screens/on_boarding/onboarding_screen.dart';
import '../services/spotify_service.dart';
import '../widgets/riverpod_connection_overlay.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
  late final AuthProvider _authProvider;
  late final SpotifyService _spotifyService;
  late final ScrollController _scrollController;

  bool _loading = false;
  Map<String, dynamic>? _user;

  @override
  void initState() {
    super.initState();
    _authProvider = AuthProvider();
    _spotifyService = SpotifyService();
    _scrollController = ScrollController();
    _initializeAuth();
  }

  @override
  void dispose() {
    _authProvider.removeListener(_onAuthStateChanged);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeAuth() async {
    setState(() {
      _loading = true;
    });
    try {
      await _authProvider.initialize();
      _authProvider.addListener(_onAuthStateChanged);
      if (_authProvider.isAuthenticated) {
        await _fetchUserData();
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

  void _onAuthStateChanged() {
    if (!mounted) return;
    setState(() {});

    // If user just logged in, fetch user data
    if (_authProvider.isAuthenticated && _user == null) {
      _fetchUserData();
    }
  }

  Future<void> _fetchUserData() async {
    if (!_authProvider.isAuthenticated || _authProvider.accessToken == null)
      return;
    setState(() {
      _loading = true;
    });
    final token = _authProvider.accessToken;
    if (token == null) return;

    try {
      // Get user data directly from Spotify API (same as profile screen)
      final user = await _spotifyService.getCurrentUser(token);
      setState(() {
        _user = user;
      });
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

  Future<void> _refreshData() async {
    if (!_authProvider.isAuthenticated) return;

    try {
      await _fetchUserData();
    } catch (e) {
      // Handle error silently
    }
  }

  String _getDisplayName() {
    return _user?['display_name'] as String? ?? 'Spotify Account';
  }

  String _getUserEmail() {
    return _user?['email'] as String? ?? _authProvider.userId ?? 'Connected';
  }

  NetworkImage? _getProfileImage() {
    final images = (_user?['images'] as List<dynamic>?) ?? const [];
    if (images.isNotEmpty && images.first['url'] != null) {
      return NetworkImage(images.first['url'] as String);
    }
    return null;
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout from Spotify?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logging out...'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      final result = await _authProvider.logout();

      if (mounted) {
        if (result.isSuccess) {
          // Success - navigate to onboarding
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
                builder: (context) => const RiverpodConnectionOverlay(
                      child: OnboardingScreen(),
                    )),
            (route) => false,
          );
        } else {
          // Show error snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.errorMessage ?? 'Logout failed'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    }
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone and will remove all your data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _handleDeleteAccount();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDeleteAccount() async {
    // Show loading indicator
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Deleting account...'),
          duration: Duration(seconds: 3),
        ),
      );
    }

    final result = await _authProvider.deleteAccount();

    if (mounted) {
      if (result.isSuccess) {
        // Success - navigate to onboarding
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
              builder: (context) => const RiverpodConnectionOverlay(
                    child: OnboardingScreen(),
                  )),
          (route) => false,
        );
      } else {
        // Show error snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorMessage ?? 'Account deletion failed'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
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
            colors: [
              AppColors.darkBackgroundStart,
              AppColors.darkBackgroundEnd
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    HapticFeedback.lightImpact();
                    await _refreshData();
                    HapticFeedback.selectionClick();
                  },
                  child: ListView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: _loading
                        ? _buildSkeletonWidgets()
                        : [
                            _buildSectionTitle('Account'),
                            if (_authProvider.isAuthenticated) ...[
                              _buildAccountCard(),
                              const SizedBox(height: 16),
                              _buildActionButton(
                                icon: Icons.logout,
                                title: 'Logout',
                                subtitle: 'Sign out from Spotify',
                                onTap: _handleLogout,
                                color: Colors.orange,
                              ),
                              const SizedBox(height: 12),
                              _buildActionButton(
                                icon: Icons.delete_forever,
                                title: 'Delete Account',
                                subtitle: 'Permanently delete your account',
                                onTap: _showDeleteAccountDialog,
                                color: Colors.red,
                              ),
                            ] else ...[
                              _buildNotConnectedCard(),
                            ],
                            const SizedBox(height: 32),
                            _buildSectionTitle('App Info'),
                            const SizedBox(height: 16),
                            _buildInfoCard(),
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

  /// Scroll to top of the settings screen
  void scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// Build skeleton widgets for loading state
  List<Widget> _buildSkeletonWidgets() {
    return [
      // Account section skeleton
      _buildSectionTitle('Account'),
      _buildSkeletonAccountCard(),
      const SizedBox(height: 16),
      _buildActionButton(
        icon: Icons.logout,
        title: 'Logout',
        subtitle: 'Sign out from Spotify',
        onTap: _handleLogout,
        color: Colors.orange,
      ),
      const SizedBox(height: 12),
      _buildActionButton(
        icon: Icons.delete_forever,
        title: 'Delete Account',
        subtitle: 'Permanently delete your account',
        onTap: _showDeleteAccountDialog,
        color: Colors.red,
      ),
      const SizedBox(height: 32),
      _buildSectionTitle('App Info'),
      const SizedBox(height: 16),
      _buildInfoCard(),
    ];
  }

  Widget _buildSkeletonAccountCard() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.onDarkPrimary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.onDarkPrimary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Shimmer.fromColors(
        baseColor: AppColors.onDarkPrimary.withOpacity(0.1),
        highlightColor: AppColors.onDarkPrimary.withOpacity(0.2),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 120,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 60,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: AppTextStyles.heading2OnDark.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
      ),
    );
  }

  Widget _buildAccountCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.onDarkPrimary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.onDarkPrimary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: _getProfileImage(),
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: _getProfileImage() == null
                  ? const Icon(
                      Icons.person,
                      color: AppColors.primary,
                      size: 20,
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getDisplayName(),
                    style: AppTextStyles.bodyOnDark
                        .copyWith(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getUserEmail(),
                    style: AppTextStyles.captionOnDark,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_user == null && !_loading)
                  IconButton(
                    onPressed: () async {
                      try {
                        await _fetchUserData();
                      } catch (e) {
                        // Ignore errors
                      }
                    },
                    icon: const Icon(Icons.refresh,
                        color: AppColors.primary, size: 20),
                  ),
                const Icon(Icons.check_circle, color: AppColors.primary),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotConnectedCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.onDarkPrimary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.onDarkPrimary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.person_off,
            color: Colors.orange,
          ),
        ),
        title: Text(
          'Not Connected',
          style: AppTextStyles.bodyOnDark.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: const Text(
          'Connect your Spotify account',
          style: AppTextStyles.captionOnDark,
        ),
        trailing: const Icon(Icons.warning, color: Colors.orange),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.onDarkPrimary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.onDarkPrimary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: AppTextStyles.bodyOnDark.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          style: AppTextStyles.captionOnDark,
        ),
        trailing: const Icon(Icons.arrow_forward_ios,
            color: AppColors.onDarkSecondary, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.onDarkPrimary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.onDarkPrimary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.onDarkSecondary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.info,
            color: AppColors.onDarkSecondary,
          ),
        ),
        title: Text(
          'Version',
          style: AppTextStyles.bodyOnDark.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: const Text(
          '1.0.0',
          style: AppTextStyles.captionOnDark,
        ),
      ),
    );
  }
}
