import 'package:flutter/material.dart';
import 'package:songbuddy/constants/app_colors.dart';

class BeautifulErrorDialog extends StatelessWidget {
  final String errorMessage;
  final VoidCallback? onRetry;
  final VoidCallback? onCancel;

  const BeautifulErrorDialog({
    super.key,
    required this.errorMessage,
    this.onRetry,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.darkBackgroundEnd,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildIcon(),
              const SizedBox(height: 24),
              _buildTitle(),
              const SizedBox(height: 16),
              _buildMessage(),
              const SizedBox(height: 32),
              _buildButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.red.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: const Icon(
        Icons.error_outline,
        color: Colors.red,
        size: 40,
      ),
    );
  }

  Widget _buildTitle() {
    return const Text(
      'Connection Failed',
      style: TextStyle(
        color: Colors.white,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Text(
        errorMessage,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 16,
          height: 1.5,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildButtons(BuildContext context) {
    return Row(
      children: [
        if (onCancel != null) ...[
          Expanded(
            child: _buildButton(
              context: context,
              text: 'Cancel',
              onPressed: onCancel!,
              isSecondary: true,
            ),
          ),
          const SizedBox(width: 16),
        ],
        if (onRetry != null) ...[
          Expanded(
            child: _buildButton(
              context: context,
              text: 'Try Again',
              onPressed: onRetry!,
              isSecondary: false,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildButton({
    required BuildContext context,
    required String text,
    required VoidCallback onPressed,
    required bool isSecondary,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isSecondary 
            ? Colors.transparent 
            : AppColors.primary,
        foregroundColor: isSecondary 
            ? Colors.white70 
            : Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: isSecondary 
              ? BorderSide(color: Colors.white.withOpacity(0.3))
              : BorderSide.none,
        ),
        elevation: isSecondary ? 0 : 8,
        shadowColor: AppColors.primary.withOpacity(0.3),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Show the beautiful error dialog
  static Future<void> show({
    required BuildContext context,
    required String errorMessage,
    VoidCallback? onRetry,
    VoidCallback? onCancel,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BeautifulErrorDialog(
        errorMessage: errorMessage,
        onRetry: onRetry,
        onCancel: onCancel,
      ),
    );
  }
}
