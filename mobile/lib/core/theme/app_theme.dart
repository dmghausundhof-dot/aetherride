import 'package:flutter/material.dart';

/// Outdoor Design Tokens — an Web-Theme angelehnt (kein Purple-Default).
abstract final class AppColors {
  static const Color forest = Color(0xFF1B3A2F);
  static const Color trail = Color(0xFF2D6A4F);
  static const Color accent = Color(0xFFE07A3D);
  static const Color surface = Color(0xFFF4F6F3);
  static const Color surfaceDark = Color(0xFF121A16);
  static const Color muted = Color(0xFF6B7C72);

  // Spec §4.1 Sunlight
  static const Color sunBg = Color(0xFFFFFFFF);
  static const Color sunSurface = Color(0xFFF1F4F2);
  static const Color sunText = Color(0xFF05100C);
  static const Color sunMuted = Color(0xFF3C4C46);
  static const Color sunAccent = Color(0xFFB33F14);
  static const Color sunPrimary = Color(0xFF14503A);
}

abstract final class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.trail,
          primary: AppColors.forest,
          secondary: AppColors.accent,
          surface: AppColors.surface,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: AppColors.surface,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.forest,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        navigationBarTheme: NavigationBarThemeData(
          indicatorColor: AppColors.accent.withValues(alpha: 0.2),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.accent,
              );
            }
            return const TextStyle(fontSize: 11, color: AppColors.muted);
          }),
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF1A5C45),
          secondary: Color(0xFFFF6B35),
          surface: Color(0xFF14201C),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Color(0xFFE8EEEA),
        ),
        scaffoldBackgroundColor: const Color(0xFF0A1210),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF14201C),
          foregroundColor: Color(0xFFE8EEEA),
          elevation: 0,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0xFF14201C),
          indicatorColor: const Color(0xFFFF6B35).withValues(alpha: 0.2),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFFFF6B35),
              );
            }
            return const TextStyle(fontSize: 11, color: Color(0xFF8A9A90));
          }),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF14201C),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );

  /// Spec Sunlight Mode — nur Ride
  static ThemeData get sunlight => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: const ColorScheme.light(
          primary: AppColors.sunPrimary,
          secondary: AppColors.sunAccent,
          surface: AppColors.sunSurface,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: AppColors.sunText,
        ),
        scaffoldBackgroundColor: AppColors.sunBg,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.sunSurface,
          foregroundColor: AppColors.sunText,
          elevation: 0,
        ),
      );
}
