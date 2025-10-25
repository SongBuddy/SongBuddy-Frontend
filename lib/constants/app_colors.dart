import 'package:flutter/material.dart';

class AppColors {
  // Core brand palette
  static const Color primary = Color(0xFF6C63FF); // Deep purple
  static const Color secondary = Color(0xFFFF6584); // Accent pink
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color border = Color(0xFFE0E0E0);

  // States
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFF44336);
  static const Color warning = Color(0xFFFFC107);

  // Dark theme additions
  static const Color darkBackgroundStart = Color(0xFF071028);
  static const Color darkBackgroundEnd = Color(0xFF0B0B0D);

  // Accent colors
  static const Color accentMint = Color(0xFF5EEAD4);
  static const Color accentGreen = Color(0xFF3DDC97);

  // On-dark text colors
  static const Color onDarkPrimary = Colors.white; // 100%
  static const Color onDarkSecondary = Colors.white70; // ~70%
  static const Color onDarkTertiary = Colors.white54; // ~54%
  static const Color onDarkMuted = Colors.white38; // ~38%

  // Utility
  static const Color black = Colors.black;
  static const Color shadowBlack60 = Color(0x99000000); // 60% black
}
