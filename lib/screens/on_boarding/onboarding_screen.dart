import 'dart:ui';
import 'package:flutter/material.dart';
import 'onboarding_page.dart';
import '../../main.dart';
import '../../widgets/spotify_login_button.dart';
import '../../widgets/success_dialog.dart';
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
    _authProvider.removeListener(_onAuthStateChanged);
    _backgroundAnimationController.dispose();
    super.dispose();
  }

  void _onAuthStateChanged() {
    if (_authProvider.isAuthenticated) {
      
      // Show success animation before navigating
      _showSuccessAnimation();
    } else if (_authProvider.state == AuthState.error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Authentication failed: ${_authProvider.errorMessage}'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }


  void _showSuccessAnimation() {
    // Show success dialog with animation
    showDialog(
      context: context,
      barrierDismissible: false,
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
      title: "Connect with Spotify",
      description: "Link your Spotify account for a personalized experience and seamless music integration.",
      icon: Icons.link_rounded,
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
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainScreen()),
    );
  }

  void _handleSpotifyLogin() async {
    await _authProvider.login();
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
                  // Modern skip button with glassmorphism
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
                                    ? LinearGradient(
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
                        SizedBox(
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
                                child: _currentPage == _pages.length - 1
                                    ? SpotifyLoginButton(
                                        onPressed: _handleSpotifyLogin,
                                        isLoading: _authProvider.state == AuthState.authenticating,
                                      )
                                    : ElevatedButton(
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
                                            Icon(
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
