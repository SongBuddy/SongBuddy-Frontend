import 'package:flutter/material.dart';
import 'package:songbuddy/constants/app_text_styles.dart';

/// Popup dialog shown when there's no internet connection
/// Matches the design from the provided image
class NoInternetPopup extends StatelessWidget {
  const NoInternetPopup({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(

    
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Text(
              'No internet connection',
              style: AppTextStyles.heading2OnDark.copyWith(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            // Message
            Text(
              'Turn on mobile data or connect to Wi-Fi',
              style: AppTextStyles.bodyOnDark.copyWith(
                color: Colors.black87,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Show the no internet popup
  static void show(BuildContext context) {
    // Check if context is still valid
    if (!context.mounted) return;
    
    // Check if dialog is already showing
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      return;
    }
    
    showDialog(
      context: context,
      barrierColor: Colors.transparent, // remove black overlay
      barrierDismissible: true,
      builder: (context) => const NoInternetPopup(),
    );
  }

  /// Hide the no internet popup
  static void hide(BuildContext context) {
    if (!context.mounted) return;
    
    try {
      if (Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    } catch (e) {
      // Ignore errors when trying to pop
    }
  }
}
