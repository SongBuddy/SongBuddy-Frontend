import 'package:flutter/material.dart';

class AppColors {
  // Modern Primary colors - Vibrant purple/blue gradient
  static const Color primary = Color(0xFF6366F1); // Indigo
  static const Color primaryDark = Color(0xFF4F46E5); // Darker indigo
  static const Color primaryLight = Color(0xFF818CF8); // Light indigo
  static const Color primaryAccent = Color(0xFF8B5CF6); // Purple accent

  // Secondary colors - Cyan/teal
  static const Color secondary = Color(0xFF06B6D4); // Cyan
  static const Color secondaryDark = Color(0xFF0891B2); // Darker cyan
  static const Color secondaryLight = Color(0xFF22D3EE); // Light cyan

  // Background colors - Deep dark with subtle gradients
  static const Color darkBackgroundStart = Color(0xFF0F0F23); // Very dark blue
  static const Color darkBackgroundEnd = Color(0xFF1A1A2E); // Dark blue
  static const Color darkBackgroundMid = Color(0xFF16213E); // Medium dark blue
  static const Color lightBackground = Color(0xFFFAFAFA); // Off white

  // Surface colors with glassmorphism
  static const Color darkSurface = Color(0xFF1E1E2E); // Dark surface
  static const Color darkSurfaceElevated =
      Color(0xFF2A2A3E); // Elevated surface
  static const Color lightSurface = Color(0xFFF8FAFC); // Light surface
  static const Color glassSurface = Color(0x1AFFFFFF); // Glass surface

  // Text colors
  static const Color onDarkPrimary = Color(0xFFFFFFFF); // Pure white
  static const Color onDarkSecondary = Color(0xFFB4B4B8); // Light gray
  static const Color onDarkTertiary = Color(0xFF8E8E93); // Medium gray
  static const Color onLightPrimary = Color(0xFF1A1A1A); // Dark text
  static const Color onLightSecondary = Color(0xFF6B7280); // Medium gray

  // Accent colors - Vibrant and modern
  static const Color accent = Color(0xFFF59E0B); // Amber
  static const Color accentDark = Color(0xFFD97706); // Dark amber
  static const Color accentLight = Color(0xFFFBBF24); // Light amber

  // Status colors - Modern and vibrant
  static const Color success = Color(0xFF10B981); // Emerald
  static const Color successLight = Color(0xFF34D399); // Light emerald
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color warningLight = Color(0xFFFBBF24); // Light amber
  static const Color error = Color(0xFFEF4444); // Red
  static const Color errorLight = Color(0xFFF87171); // Light red
  static const Color info = Color(0xFF3B82F6); // Blue
  static const Color infoLight = Color(0xFF60A5FA); // Light blue

  // Gradient colors for modern effects
  static const Color gradientStart = Color(0xFF6366F1); // Indigo
  static const Color gradientMid = Color(0xFF8B5CF6); // Purple
  static const Color gradientEnd = Color(0xFFEC4899); // Pink

  // Glassmorphism colors
  static const Color glassBackground = Color(0x1AFFFFFF); // 10% white
  static const Color glassBackgroundStrong = Color(0x33FFFFFF); // 20% white
  static const Color glassBorder = Color(0x33FFFFFF); // 20% white border
  static const Color glassBorderStrong = Color(0x4DFFFFFF); // 30% white border
  static const Color glassShadow = Color(0x1A000000); // 10% black shadow

  // Shadow colors for depth
  static const Color shadowLight = Color(0x0A000000); // 4% black
  static const Color shadowMedium = Color(0x1A000000); // 10% black
  static const Color shadowDark = Color(0x33000000); // 20% black
  static const Color shadowStrong = Color(0x4D000000); // 30% black

  // Special effect colors
  static const Color neon = Color(0xFF00F5FF); // Neon cyan
  static const Color neonPink = Color(0xFFFF10F0); // Neon pink
  static const Color neonGreen = Color(0xFF39FF14); // Neon green

  // Overlay colors
  static const Color overlayLight = Color(0x1AFFFFFF); // Light overlay
  static const Color overlayMedium = Color(0x4DFFFFFF); // Medium overlay
  static const Color overlayDark = Color(0x80000000); // Dark overlay

  // Legacy support
  static const Color background = lightBackground;
  static const Color surface = lightSurface;
  static const Color textPrimary = onLightPrimary;
  static const Color textSecondary = onLightSecondary;
  static const Color border = Color(0xFFE5E7EB);
  static const Color black = Colors.black;
}
