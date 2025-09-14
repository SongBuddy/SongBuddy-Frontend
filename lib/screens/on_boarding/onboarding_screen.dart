import 'package:flutter/material.dart';
import 'onboarding_page.dart';
import '../../main.dart';
import '../../widgets/spotify_login_button.dart';
import '../../widgets/success_dialog.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart' show AuthState;

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;
  late final AuthProvider _authProvider;

  @override
  void initState() {
    super.initState();
    _authProvider = AuthProvider();
    _authProvider.addListener(_onAuthStateChanged);
    _authProvider.initialize();
  }

  @override
  void dispose() {
    _authProvider.removeListener(_onAuthStateChanged);
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
          backgroundColor: Colors.red,
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
      title: "Welcome to SongBuddy App",
      description: "Your ultimate music companion app.",
      icon: Icons.music_note,
    ),
    OnboardingPage(
      title: "Discover Features",
      description:
          "Stay updated, track your favorites, and connect with music lovers.",
      icon: Icons.star,
    ),
    OnboardingPage(
      title: "Connect with Spotify",
      description: "Link your Spotify account for a personalized experience.",
      icon: Icons.link,
    ),
  ];

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
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
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _skip,
                child: const Text(
                  "Skip",
                  style: TextStyle(
                    color: Colors.black,
                  ),
                ),
              ),
            ),

            // PageView
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

            // Indicators + Next Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Page indicators
                  Row(
                    children: List.generate(
                      _pages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: _currentPage == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? Colors.deepPurple
                              : Colors.grey,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  // Next button or Spotify login button
                  _currentPage == _pages.length - 1
                      ? Row(
                          children: [
                            Expanded(
                              child: SpotifyLoginButton(
                                onPressed: _handleSpotifyLogin,
                                isLoading: _authProvider.state == AuthState.authenticating,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (_authProvider.state == AuthState.authenticating)
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _authProvider.cancelAuthentication,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey.shade600,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  child: const Text('Cancel'),
                                ),
                              ),
                          ],
                        )
                      : ElevatedButton(
                          onPressed: _nextPage,
                          style: ElevatedButton.styleFrom(
                            shape: const StadiumBorder(),
                            backgroundColor: Colors.deepPurple,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          child: const Text(
                            "Next",
                            style: TextStyle(
                              color: Colors.white,
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
  }
}
