import 'package:flutter/material.dart';
import 'dart:ui';
import '../providers/auth_provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../screens/on_boarding/onboarding_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final AuthProvider _authProvider;

  @override
  void initState() {
    super.initState();
    _authProvider = AuthProvider();
    _initializeAuth();
  }

  @override
  void dispose() {
    _authProvider.removeListener(_onAuthStateChanged);
    super.dispose();
  }

  Future<void> _initializeAuth() async {
    await _authProvider.initialize();
    _authProvider.addListener(_onAuthStateChanged);
    if (mounted) {
      setState(() {});
    }
  }

  void _onAuthStateChanged() {
    if (mounted) {
      setState(() {});
    }
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
      await _authProvider.logout();
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
    try {
      await _authProvider.deleteAccount();
      // Navigate to onboarding screen
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const OnboardingScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete account: $e'),
            backgroundColor: Colors.red,
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
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 4),
        Text(
          'Settings',
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
      ],
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
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.person,
            color: AppColors.primary,
          ),
        ),
        title: Text(
          'Spotify Account',
          style: AppTextStyles.bodyOnDark.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          _authProvider.userId ?? 'Connected',
          style: AppTextStyles.captionOnDark,
        ),
        trailing: const Icon(Icons.check_circle, color: AppColors.primary),
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
        subtitle: Text(
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
        trailing: Icon(Icons.arrow_forward_ios, color: AppColors.onDarkSecondary, size: 16),
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
        subtitle: Text(
          '1.0.0',
          style: AppTextStyles.captionOnDark,
        ),
      ),
    );
  }
}
