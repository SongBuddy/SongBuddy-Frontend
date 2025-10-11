import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  static const TextStyle heading1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 14,
    color: AppColors.textSecondary,
  );

  // On-dark variants (for dark backgrounds)
  static const TextStyle heading1OnDark = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.onDarkPrimary,
  );

  static const TextStyle heading2OnDark = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.onDarkPrimary,
  );

  static const TextStyle bodyOnDark = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.onDarkPrimary,
  );

  static const TextStyle captionOnDark = TextStyle(
    fontSize: 14,
    color: AppColors.onDarkSecondary,
  );

  static const TextStyle heading3OnDark = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.onDarkPrimary,
  );
}
