import 'package:flutter/material.dart';

class SpotifyLoginButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final String text;

  const SpotifyLoginButton({
    super.key,
    this.onPressed,
    this.isLoading = false,
    this.text = "Continue with Spotify",
  });

  @override
  State<SpotifyLoginButton> createState() => _SpotifyLoginButtonState();
}

class _SpotifyLoginButtonState extends State<SpotifyLoginButton> {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: widget.isLoading ? null : widget.onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1DB954), // Spotify green
        foregroundColor: Colors.white,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 12,
        ),
        elevation: 2,
        shadowColor: const Color(0xFF1DB954).withOpacity(0.3),
      ),
      child: widget.isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Spotify logo icon
                Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.music_note,
                    color: Color(0xFF1DB954),
                    size: 14,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  widget.text,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
    );
  }
}
