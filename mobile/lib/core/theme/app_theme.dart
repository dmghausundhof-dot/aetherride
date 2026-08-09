import 'package:flutter/material.dart';

/// Outdoor Design Tokens — forest + trail orange (kein Purple-Default).
abstract final class AppColors {
  static const Color forest = Color(0xFF1B3A2F);
  static const Color trail = Color(0xFF2D6A4F);
  static const Color accent = Color(0xFFFF6B35);
  static const Color surface = Color(0xFFF4F6F3);
  static const Color surfaceDark = Color(0xFF14201C);
  static const Color muted = Color(0xFF9AABA2);
  static const Color onAccent = Color(0xFFFFFFFF);
  static const Color chipIdle = Color(0xFF1A2822);
  static const Color chipIdleText = Color(0xFFE8EEEA);
  static const Color border = Color(0xFF2A3D34);

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
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: AppColors.onAccent,
            minimumSize: const Size.fromHeight(48),
          ),
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
          secondary: AppColors.accent,
          surface: AppColors.surfaceDark,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Color(0xFFE8EEEA),
        ),
        scaffoldBackgroundColor: const Color(0xFF0A1210),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.surfaceDark,
          foregroundColor: Color(0xFFE8EEEA),
          elevation: 0,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: AppColors.onAccent,
            disabledBackgroundColor: Color(0xFF3A2A22),
            disabledForegroundColor: Color(0xFFB0A090),
            minimumSize: const Size.fromHeight(48),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFE8EEEA),
            side: const BorderSide(color: AppColors.border),
            minimumSize: const Size.fromHeight(48),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: AppColors.muted),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.chipIdle,
          labelStyle: const TextStyle(color: AppColors.muted),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
          ),
        ),
        dropdownMenuTheme: const DropdownMenuThemeData(
          textStyle: TextStyle(color: Color(0xFFE8EEEA)),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: AppColors.surfaceDark,
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
        cardTheme: CardThemeData(
          color: AppColors.surfaceDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.border),
          ),
        ),
        sliderTheme: SliderThemeData(
          activeTrackColor: AppColors.accent,
          thumbColor: AppColors.accent,
          inactiveTrackColor: AppColors.border,
        ),
        segmentedButtonTheme: SegmentedButtonThemeData(
          style: ButtonStyle(
            foregroundColor: WidgetStateProperty.resolveWith((s) {
              if (s.contains(WidgetState.selected)) return AppColors.onAccent;
              return const Color(0xFFE8EEEA);
            }),
            backgroundColor: WidgetStateProperty.resolveWith((s) {
              if (s.contains(WidgetState.selected)) return AppColors.accent;
              return AppColors.chipIdle;
            }),
          ),
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
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.sunAccent,
            foregroundColor: Colors.white,
          ),
        ),
      );
}
