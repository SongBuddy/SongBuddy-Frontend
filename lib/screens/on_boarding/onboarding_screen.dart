import 'dart:ui';
import 'package:flutter/material.dart';
import 'onboarding_page.dart';
import '../../main.dart';
import '../../widgets/success_dialog.dart';
import '../../widgets/spotify_style_popup.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart' show AuthState;
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _controller = PageController();
  int _currentPage = 0;
  late final AuthProvider _authProvider;
  bool _isErrorDialogVisible = false; // Guard to prevent conflicting dialogs

  late AnimationController _backgroundAnimationController;
  late Animation<double> _backgroundAnimation;

  @override
  void initState() {
    super.initState();
    _authProvider = AuthProvider();
    _authProvider.addListener(_onAuthStateChanged);
    _authProvider.initialize();

    // Background animation for subtle movement
    _backgroundAnimationController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );
    _backgroundAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _backgroundAnimationController,
      curve: Curves.easeInOut,
    ));
    _backgroundAnimationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    // Ensure any error dialog is dismissed when leaving the screen
    _dismissErrorDialog();
    _authProvider.removeListener(_onAuthStateChanged);
    _backgroundAnimationController.dispose();
    super.dispose();
  }

  void _dismissErrorDialog() {
    if (_isErrorDialogVisible && mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      _isErrorDialogVisible = false;
    }
  }

  void _onAuthStateChanged() {
    // While authenticating, make sure no stale error dialog is visible
    if (_authProvider.state == AuthState.authenticating) {
      _dismissErrorDialog();
      return;
    }

    if (_authProvider.isAuthenticated) {
      _dismissErrorDialog();
      // Show success animation before navigating
      _showSuccessAnimation();
    } else if (_authProvider.state == AuthState.error) {
      if (_isErrorDialogVisible) return; // Avoid stacking dialogs
      _isErrorDialogVisible = true;
      SpotifyStylePopup.show(
        context: context,
        title: 'Connection Error',
        message: _authProvider.errorMessage ?? 'Something went wrong. Please try again.',
        onRetry: () {
          Navigator.of(context, rootNavigator: true).pop(); // Close dialog
          _isErrorDialogVisible = false;
          _handleGoogleLogin(); // Retry connection
        },
        onCancel: () {
          Navigator.of(context, rootNavigator: true).pop(); // Close dialog
          _isErrorDialogVisible = false;
        },
      );
    }
  }


  void _showSuccessAnimation() {
    // Show success dialog with animation
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) => const SuccessDialog(),
    );

    // Navigate after animation
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        Navigator.of(context).pop(); // Close dialog
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const MainScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(1.0, 0.0);
              const end = Offset.zero;
              const curve = Curves.easeInOut;

              var tween = Tween(begin: begin, end: end).chain(
                CurveTween(curve: curve),
              );

              return SlideTransition(
                position: animation.drive(tween),
                child: FadeTransition(
                  opacity: animation,
                  child: child,
                ),
              );
            },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    });
  }

  final List<OnboardingPage> _pages = const [
    OnboardingPage(
      title: "Welcome to SongBuddy",
      description: "Your ultimate music companion app. Discover, share, and connect with music lovers around the world.",
      icon: Icons.music_note_rounded,
    ),
    OnboardingPage(
      title: "Discover Amazing Features",
      description: "Stay updated with trending tracks, follow your favorite artists, and build your musical community.",
      icon: Icons.star_rounded,
    ),
    OnboardingPage(
      title: "Connect with Google",
      description: "Sign in with your Google account for a personalized experience and seamless music integration.",
      icon: Icons.login_rounded,
    ),
  ];

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    }
  }
 
  void _skip() {
    // Navigate to the last page (Spotify login page)
    _controller.animateToPage(
      _pages.length - 1,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
    );
  }

  void _handleGoogleLogin() async {
    // TODO: Implement Google login
    // For now, just navigate to main screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _backgroundAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(AppColors.darkBackgroundStart, AppColors.darkBackgroundEnd, _backgroundAnimation.value)!,
                  Color.lerp(AppColors.darkBackgroundEnd, AppColors.darkBackgroundStart, _backgroundAnimation.value)!,
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Modern skip button with glassmorphism (hide on last page)
                  if (_currentPage < _pages.length - 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                  ),
                                ),
                                child: TextButton(
                                  onPressed: _skip,
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  ),
                                  child: Text(
                                    "Skip",
                                    style: AppTextStyles.captionOnDark.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.onDarkSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // PageView with enhanced styling
                  Expanded(
                    child: PageView.builder(
                      controller: _controller,
                      itemCount: _pages.length,
                      onPageChanged: (index) {
                        setState(() => _currentPage = index);
                      },
                      itemBuilder: (context, index) => _pages[index],
                    ),
                  ),

                  // Modern bottom section with indicators and navigation
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: Column(
                      children: [
                        // Modern page indicators
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            _pages.length,
                            (index) => AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.symmetric(horizontal: 6),
                              height: 8,
                              width: _currentPage == index ? 32 : 8,
                              decoration: BoxDecoration(
                                gradient: _currentPage == index
                                    ? const LinearGradient(
                                        colors: [
                                          AppColors.accentMint,
                                          AppColors.accentGreen,
                                        ],
                                      )
                                    : null,
                                color: _currentPage == index
                                    ? null
                                    : Colors.white.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: _currentPage == index
                                    ? [
                                        BoxShadow(
                                          color: AppColors.accentMint.withOpacity(0.4),
                                          blurRadius: 12,
                                          spreadRadius: 2,
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Modern navigation button
                        _currentPage == _pages.length - 1
                            ? SizedBox(
                                width: double.infinity,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            AppColors.accentMint.withOpacity(0.2),
                                            AppColors.accentGreen.withOpacity(0.2),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.2),
                                        ),
                                      ),
                                      child: ElevatedButton(
                                        onPressed: _handleGoogleLogin,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 32,
                                            vertical: 16,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons.login,
                                              color: AppColors.onDarkPrimary,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              "Continue with Google",
                                              style: AppTextStyles.bodyOnDark.copyWith(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : SizedBox(
                                width: double.infinity,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            AppColors.accentMint.withOpacity(0.2),
                                            AppColors.accentGreen.withOpacity(0.2),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.2),
                                        ),
                                      ),
                                      child: ElevatedButton(
                                        onPressed: _nextPage,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 32,
                                            vertical: 16,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              "Continue",
                                              style: AppTextStyles.bodyOnDark.copyWith(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            const Icon(
                                              Icons.arrow_forward_rounded,
                                              color: AppColors.onDarkPrimary,
                                              size: 20,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
