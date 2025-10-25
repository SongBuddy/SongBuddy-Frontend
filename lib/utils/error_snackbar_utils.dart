import 'package:flutter/material.dart';
import 'api_error_handler.dart';

/// Professional error snackbar utilities
class ErrorSnackbarUtils {
  /// Show a professional error snackbar with appropriate styling
  /// Smart conflict resolution - won't show snackbar for network errors
  static void showErrorSnackbar(
    BuildContext context,
    dynamic error, {
    String? operation,
    Duration duration = const Duration(seconds: 4),
  }) {
    if (!context.mounted) return;

    print('🔍 ErrorSnackbarUtils: Attempting to show error snackbar');
    print('🔍 ErrorSnackbarUtils: Error: $error');
    print('🔍 ErrorSnackbarUtils: Operation: $operation');

    final message = operation != null
        ? ApiErrorHandler.getOperationErrorMessage(operation, error)
        : ApiErrorHandler.getUserFriendlyMessage(error);

    print('🔍 ErrorSnackbarUtils: Generated message: $message');

    // Temporarily show all errors for debugging
    if (message == null) {
      print('🔍 ErrorSnackbarUtils: Message is null, not showing snackbar');
      return;
    }

    final severity = ApiErrorHandler.getErrorSeverity(error);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _getBackgroundColor(severity),
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Show a success snackbar
  static void showSuccessSnackbar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Show an info snackbar
  static void showInfoSnackbar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Show a loading snackbar
  static void showLoadingSnackbar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Get background color based on error severity
  static Color _getBackgroundColor(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.info:
        return Colors.blue;
      case ErrorSeverity.warning:
        return Colors.orange;
      case ErrorSeverity.error:
        return Colors.red;
    }
  }
}
