import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import 'music_provider_selection_screen.dart';

class CustomLoginScreen extends StatefulWidget {
  final Function(MusicProvider) onProviderLogin;
  final bool isLoading;

  const CustomLoginScreen({
    super.key,
    required this.onProviderLogin,
    this.isLoading = false,
  });

  @override
  State<CustomLoginScreen> createState() => _CustomLoginScreenState();
}

class _CustomLoginScreenState extends State<CustomLoginScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.darkBackgroundStart,
              AppColors.darkBackgroundEnd,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top Section - Lottie Animation (50% of screen)
              Expanded(
                flex: 5,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Lottie Animation
                          Container(
                            height: screenHeight * 0.25,
                            width: screenWidth * 0.8,
                            child: Lottie.asset(
                              'assets/animations/music_waves.json',
                              fit: BoxFit.contain,
                              repeat: true,
                              animate: true,
                            ),
                          ),

                          const SizedBox(height: 12),

                          // App Logo/Title
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: Colors.white.withOpacity(0.1),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.music_note_rounded,
                                  color: AppColors.accentMint,
                                  size: 20,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'SongBuddy',
                                  style: AppTextStyles.heading2OnDark.copyWith(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Middle Section - Text Message (15% of screen)
              Expanded(
                flex: 1,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Millions of songs.",
                          style: AppTextStyles.heading1OnDark.copyWith(
                            fontSize: screenWidth * 0.07,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Free on SongBuddy.",
                          style: AppTextStyles.heading2OnDark.copyWith(
                            fontSize: screenWidth * 0.05,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onDarkSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Bottom Section - Login Buttons (35% of screen)
              Expanded(
                flex: 4,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Padding(
                      padding: const EdgeInsets.only(
                          left: 24, right: 24, top: 8, bottom: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Continue with Spotify
                          SizedBox(
                            width: double.infinity,
                            child: _buildProviderButton(
                              provider: MusicProvider.spotify,
                              title: "Continue with Spotify",
                              icon: Icons.music_note,
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF1DB954), // Spotify Green
                                  const Color(0xFF1ed760),
                                ],
                              ),
                              onPressed: () =>
                                  widget.onProviderLogin(MusicProvider.spotify),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Continue with SoundCloud
                          SizedBox(
                            width: double.infinity,
                            child: _buildProviderButton(
                              provider: MusicProvider.soundcloud,
                              title: "Continue with SoundCloud",
                              icon: Icons.cloud,
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFFFF5500), // SoundCloud Orange
                                  const Color(0xFFFF7700),
                                ],
                              ),
                              onPressed: () => widget
                                  .onProviderLogin(MusicProvider.soundcloud),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Continue with YouTube Music
                          SizedBox(
                            width: double.infinity,
                            child: _buildProviderButton(
                              provider: MusicProvider.youtube,
                              title: "Continue with YouTube Music",
                              icon: Icons.play_circle,
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFFFF0000), // YouTube Red
                                  const Color(0xFFCC0000),
                                ],
                              ),
                              onPressed: () => widget
                                  .onProviderLogin(MusicProvider.youtube),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProviderButton({
    required MusicProvider provider,
    required String title,
    required IconData icon,
    required LinearGradient gradient,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Provider Icon
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 16,
                  ),
                ),

                const SizedBox(width: 16),

                // Title
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.bodyOnDark.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),

                // Arrow
                Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.onDarkSecondary,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
