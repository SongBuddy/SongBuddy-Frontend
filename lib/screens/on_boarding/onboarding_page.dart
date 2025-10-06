import 'dart:ui';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';

class OnboardingPage extends StatefulWidget {
  final String title;
  final String description;
  final IconData icon;
  final String? illustration;

  const OnboardingPage({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    this.illustration,
  });

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
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

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.4, curve: Curves.elasticOut),
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

    // Scale factors for responsiveness
    final iconSize = screenWidth * 0.18; // relative to screen width
    final titleFontSize = screenWidth * 0.08; // relative to width
    final bodyFontSize = screenWidth * 0.045;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Icon
            FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: iconSize * 2,
                  height: iconSize * 2,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(iconSize),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentMint.withOpacity(0.2),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                      const BoxShadow(
                        color: AppColors.shadowBlack60,
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(iconSize),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withOpacity(0.1),
                              Colors.white.withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(iconSize),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          widget.icon,
                          size: iconSize,
                          color: AppColors.accentMint,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Title
            SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.heading1OnDark.copyWith(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),

            // Description
            SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.white.withOpacity(0.05),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Text(
                    widget.description,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyOnDark.copyWith(
                      fontSize: bodyFontSize,
                      height: 1.4,
                      color: AppColors.onDarkSecondary,
                    ),
                  ),
                ),
              ),
            ),

            // Decorative Dots
            // FadeTransition(
            //   opacity: _fadeAnimation,
            //   child: Row(
            //     mainAxisAlignment: MainAxisAlignment.center,
            //     children: [
            //       _buildDecorativeDot(AppColors.accentMint),
            //       const SizedBox(width: 12),
            //       _buildDecorativeDot(AppColors.accentGreen),
            //       const SizedBox(width: 12),
            //       _buildDecorativeDot(AppColors.accentMint),
            //     ],
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  // Widget _buildDecorativeDot(Color color) {
  //   return Container(
  //     width: 8,
  //     height: 8,
  //     decoration: BoxDecoration(
  //       color: color,
  //       shape: BoxShape.circle,
  //       boxShadow: [
  //         BoxShadow(
  //           color: color.withOpacity(0.4),
  //           blurRadius: 8,
  //           spreadRadius: 1,
  //         ),
  //       ],
  //     ),
  //   );
  // }
}
