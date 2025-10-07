import 'dart:ui';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';

enum MusicProvider {
  spotify,
  soundcloud,
  youtube,
}

class MusicProviderSelectionScreen extends StatefulWidget {
  final Function(MusicProvider) onProviderSelected;

  const MusicProviderSelectionScreen({
    super.key,
    required this.onProviderSelected,
  });

  @override
  State<MusicProviderSelectionScreen> createState() =>
      _MusicProviderSelectionScreenState();
}

class _MusicProviderSelectionScreenState
    extends State<MusicProviderSelectionScreen> with TickerProviderStateMixin {
  MusicProvider? _selectedProvider;
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

  void _selectProvider(MusicProvider provider) {
    setState(() {
      _selectedProvider = provider;
    });

    // Add haptic feedback
    // HapticFeedback.lightImpact();

    // Navigate after a short delay for visual feedback
    Future.delayed(const Duration(milliseconds: 300), () {
      widget.onProviderSelected(provider);
    });
  }

  @override
  Widget build(BuildContext context) {
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
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Title Section
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      children: [
                        // Icon
                        ScaleTransition(
                          scale: _scaleAnimation,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(60),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.accentMint.withOpacity(0.2),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                ),
                                BoxShadow(
                                  color: AppColors.shadowBlack60,
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(60),
                              child: BackdropFilter(
                                filter:
                                    ImageFilter.blur(sigmaX: 10, sigmaY: 10),
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
                                    borderRadius: BorderRadius.circular(60),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.2),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.music_note_rounded,
                                    size: 60,
                                    color: AppColors.accentMint,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        Text(
                          "Choose Your Music Platform",
                          textAlign: TextAlign.center,
                          style: AppTextStyles.heading1OnDark.copyWith(
                            fontSize: screenWidth * 0.08,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),

                        const SizedBox(height: 16),

                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: Colors.white.withOpacity(0.05),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.1)),
                          ),
                          child: Text(
                            "Select your preferred music platform to connect with SongBuddy and start sharing your musical journey.",
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyOnDark.copyWith(
                              fontSize: screenWidth * 0.045,
                              height: 1.4,
                              color: AppColors.onDarkSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Provider Selection Cards
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      children: [
                        _buildProviderCard(
                          provider: MusicProvider.spotify,
                          title: "Spotify",
                          description: "Connect with your Spotify account",
                          icon: Icons.music_note,
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF1DB954), // Spotify Green
                              const Color(0xFF1ed760),
                            ],
                          ),
                          isSelected:
                              _selectedProvider == MusicProvider.spotify,
                        ),
                        const SizedBox(height: 12),
                        _buildProviderCard(
                          provider: MusicProvider.soundcloud,
                          title: "SoundCloud",
                          description: "Connect with your SoundCloud account",
                          icon: Icons.cloud,
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFFF5500), // SoundCloud Orange
                              const Color(0xFFFF7700),
                            ],
                          ),
                          isSelected:
                              _selectedProvider == MusicProvider.soundcloud,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProviderCard({
    required MusicProvider provider,
    required String title,
    required String description,
    required IconData icon,
    required LinearGradient gradient,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => _selectProvider(provider),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    gradient.colors[0].withOpacity(0.2),
                    gradient.colors[1].withOpacity(0.2),
                  ],
                )
              : LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.05),
                    Colors.white.withOpacity(0.02),
                  ],
                ),
          border: Border.all(
            color: isSelected
                ? gradient.colors[0].withOpacity(0.6)
                : Colors.white.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: gradient.colors[0].withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Icon Container
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: gradient.colors[0].withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
            ),

            const SizedBox(width: 16),

            // Text Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.heading2OnDark.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: isSelected
                          ? gradient.colors[0]
                          : AppColors.onDarkPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: AppTextStyles.bodyOnDark.copyWith(
                      fontSize: 12,
                      color: isSelected
                          ? gradient.colors[0].withOpacity(0.8)
                          : AppColors.onDarkSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Selection Indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? gradient.colors[0] : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? gradient.colors[0]
                      : Colors.white.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 12,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
