import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/app_text_styles.dart';
import '../screens/on_boarding/music_provider_selection_screen.dart';

class MusicLoginButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLoading;
  final MusicProvider provider;

  const MusicLoginButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final buttonConfig = _getButtonConfig(provider);

    return SizedBox(
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  buttonConfig.gradient.colors[0].withOpacity(0.2),
                  buttonConfig.gradient.colors[1].withOpacity(0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
              ),
            ),
            child: ElevatedButton(
              onPressed: isLoading ? null : onPressed,
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
              child: isLoading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          buttonConfig.gradient.colors[0],
                        ),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Provider Icon
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            gradient: buttonConfig.gradient,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            buttonConfig.icon,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          buttonConfig.buttonText,
                          style: AppTextStyles.bodyOnDark.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: buttonConfig.gradient.colors[0],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: buttonConfig.gradient.colors[0],
                          size: 20,
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  _ButtonConfig _getButtonConfig(MusicProvider provider) {
    switch (provider) {
      case MusicProvider.spotify:
        return _ButtonConfig(
          buttonText: "Connect with Spotify",
          icon: Icons.music_note,
          gradient: LinearGradient(
            colors: [
              const Color(0xFF1DB954), // Spotify Green
              const Color(0xFF1ed760),
            ],
          ),
        );
      case MusicProvider.soundcloud:
        return _ButtonConfig(
          buttonText: "Connect with SoundCloud",
          icon: Icons.cloud,
          gradient: LinearGradient(
            colors: [
              const Color(0xFFFF5500), // SoundCloud Orange
              const Color(0xFFFF7700),
            ],
          ),
        );
      case MusicProvider.youtube:
        return _ButtonConfig(
          buttonText: "Connect with YouTube Music",
          icon: Icons.play_circle,
          gradient: LinearGradient(
            colors: [
              const Color(0xFFFF0000), // YouTube Red
              const Color(0xFFCC0000),
            ],
          ),
        );
    }
  }
}

class _ButtonConfig {
  final String buttonText;
  final IconData icon;
  final LinearGradient gradient;

  _ButtonConfig({
    required this.buttonText,
    required this.icon,
    required this.gradient,
  });
}
