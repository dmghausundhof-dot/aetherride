import 'package:flutter/material.dart';

/// Outdoor Design Tokens — an Web-Theme angelehnt (kein Purple-Default).
abstract final class AppColors {
  static const Color forest = Color(0xFF1B3A2F);
  static const Color trail = Color(0xFF2D6A4F);
  static const Color accent = Color(0xFFE07A3D);
  static const Color surface = Color(0xFFF4F6F3);
  static const Color surfaceDark = Color(0xFF121A16);
  static const Color muted = Color(0xFF6B7C72);
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
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.trail,
          primary: AppColors.trail,
          secondary: AppColors.accent,
          surface: AppColors.surfaceDark,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: AppColors.surfaceDark,
      );
}
