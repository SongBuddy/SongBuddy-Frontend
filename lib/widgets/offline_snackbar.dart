import 'package:flutter/material.dart';
import 'package:songbuddy/constants/app_text_styles.dart';

/// Thin snackbar shown at the bottom for connection status
class OfflineSnackbar extends StatelessWidget {
  final bool isOffline;

  const OfflineSnackbar({super.key, required this.isOffline});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 32,
      decoration: BoxDecoration(
        color: isOffline ? Colors.black87 : Colors.green,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Center(
        child: Text(
          isOffline ? "You're offline" : "Internet connected",
          style: AppTextStyles.bodyOnDark.copyWith(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  /// Show the offline snackbar
  static void show(BuildContext context) {
    // Remove any existing snackbar first
    ScaffoldMessenger.of(context).clearSnackBars();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: OfflineSnackbar(isOffline: true),
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: Duration(days: 1), // Show until connection is restored
        behavior: SnackBarBehavior.fixed,
        padding: EdgeInsets.zero,
      ),
    );
  }

  /// Show the online snackbar
  static void showOnline(BuildContext context) {
    // Remove any existing snackbar first
    ScaffoldMessenger.of(context).clearSnackBars();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: OfflineSnackbar(isOffline: false),
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: Duration(seconds: 3), // Show for 3 seconds
        behavior: SnackBarBehavior.fixed,
        padding: EdgeInsets.zero,
      ),
    );
  }

  /// Hide the snackbar
  static void hide(BuildContext context) {
    ScaffoldMessenger.of(context).clearSnackBars();
  }
}
