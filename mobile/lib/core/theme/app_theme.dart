import 'package:flutter/material.dart';

/// FlowLine design tokens — Outdoor Cycling.
/// Orange = primary action / active chrome / route.
/// Sage = success / nature. Charcoal = text & dark surfaces.
/// Keep in sync with `src/lib/hof/tokens.ts` and `src/app/globals.css`.
abstract final class AppColors {
  static const Color charcoal = Color(0xFF1F1F1F);

  /// Legacy alias — charcoal, not green.
  static const Color forest = charcoal;

  /// Sage — success / nature (historisch „trail“).
  static const Color trail = Color(0xFF7A8B73);
  static const Color sage = Color(0xFF7A8B73);
  static const Color sageOnDark = Color(0xFF7FA38D);
  static const Color accent = Color(0xFFFF6A00);
  static const Color accentHover = Color(0xFFFF8533);

  /// Cards on [hofGround]. Step 1 of the dark ladder.
  static const Color surfaceDark = Color(0xFF1E1E26);

  /// Sheets, raised cards. Step 2.
  static const Color elevated = Color(0xFF2A2A34);

  /// Menus, HUD islands. Step 3.
  static const Color overlay = Color(0xFF343440);

  /// Meta/secondary on **dark** Hof surfaces.
  static const Color muted = Color(0xFF9CA3AF);
  static const Color warning = Color(0xFFEAB308);
  static const Color error = Color(0xFFEF4444);
  static const Color inkOnLight = sunText;
  static const Color mutedOnLight = sunMuted;

  /// Ink on night-orange `#FF6A00` — charcoal, not white (~6.6:1 vs ~2.9:1).
  static const Color onAccent = hofGround;

  /// Ink on sunlight-orange `#B34700`.
  static const Color onSunAccent = Color(0xFFFFFFFF);
  static const Color chipIdle = surfaceDark;
  static const Color chipIdleText = Color(0xFFF2F2F2);
  static const Color border = Color(0xFF484854);
  static const Color borderLight = Color(0xFFE5E7EB);

  // Spec §4.1 Sunlight
  static const Color sunBg = Color(0xFFFFFFFF);
  static const Color sunSurface = Color(0xFFF1F4F2);
  static const Color sunText = Color(0xFF1F1F1F);
  static const Color sunMuted = Color(0xFF6B7280);
  static const Color sunAccent = Color(0xFFB34700);
  static const Color sunPrimary = Color(0xFF1F1F1F);

  /// Sage ink on sunlight / OSM-bright chips (~4.6:1 on [sunSurface]).
  static const Color sageOnLight = Color(0xFF4F6B5A);

  /// Warning chip on the bright basemap — not shell chrome.
  static const Color mapWarnFill = Color(0xFFFFE0B2);
  static const Color mapWarnInk = sunAccent;
  static const Color mapCautionFill = Color(0xFFFEF3C7);

  /// Active chrome on dark — FlowLine orange.
  static const Color chrome = accent;

  /// Legacy alias for [chrome].
  static const Color forestOnDark = chrome;

  /// Dunkler Grund — Splash, Statusleiste, Scaffold.
  static const Color hofGround = Color(0xFF121215);

  /// Ride sunlight is marked by [FlowLineKind], not by light+white onPrimary
  /// (default Material light also uses white onPrimary).
  static bool isSunlight(BuildContext context) =>
      Theme.of(context).extension<FlowLineKind>()?.sunlight ?? false;

  static Color meta(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light ? mutedOnLight : muted;

  static Color chromeFill(BuildContext context) =>
      isSunlight(context) ? sunAccent : accent;

  static Color inkOnChrome(BuildContext context) =>
      isSunlight(context) ? onSunAccent : onAccent;

  static Color sheetInk(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light ? sunText : chipIdleText;
}

/// 4-px-Raster. FlowLine spacing: 4, 8, 12, 16, 24, 32, 48, 64.
abstract final class AppSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double s = 8;
  static const double m = 12;
  static const double l = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
}

/// Radius — Style-Guide 12px controls; 16px cards; pills for CTAs.
abstract final class AppRadius {
  static const double chip = 12.0;
  static const double card = 16.0;
  static const double sheet = 20.0;
  static const double pill = 999.0;
}

/// Distinguishes Ride sunlight from Material light defaults.
@immutable
class FlowLineKind extends ThemeExtension<FlowLineKind> {
  const FlowLineKind({required this.sunlight});

  final bool sunlight;

  @override
  FlowLineKind copyWith({bool? sunlight}) =>
      FlowLineKind(sunlight: sunlight ?? this.sunlight);

  @override
  FlowLineKind lerp(ThemeExtension<FlowLineKind>? other, double t) => this;
}

abstract final class AppTheme {
  static const String fontFamily = 'Inter';

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        fontFamily: fontFamily,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.accent,
          secondary: AppColors.sageOnDark,
          surface: AppColors.surfaceDark,
          surfaceContainerLowest: AppColors.hofGround,
          surfaceContainerLow: AppColors.surfaceDark,
          surfaceContainer: AppColors.elevated,
          surfaceContainerHigh: AppColors.overlay,
          surfaceContainerHighest: AppColors.overlay,
          onPrimary: AppColors.onAccent,
          onSecondary: AppColors.onAccent,
          onSurface: Color(0xFFF2F2F2),
          outline: AppColors.border,
          error: AppColors.error,
          onError: AppColors.chipIdleText,
        ),
        scaffoldBackgroundColor: AppColors.hofGround,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.surfaceDark,
          foregroundColor: Color(0xFFF2F2F2),
          elevation: 0,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: AppColors.onAccent,
            disabledBackgroundColor: AppColors.elevated,
            disabledForegroundColor: AppColors.muted,
            minimumSize: const Size(0, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.chip),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFF2F2F2),
            side: const BorderSide(color: AppColors.border),
            minimumSize: const Size(0, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.chip),
            ),
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
            borderRadius: BorderRadius.circular(AppRadius.chip),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.chip),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.chip),
            borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
          ),
        ),
        dropdownMenuTheme: const DropdownMenuThemeData(
          textStyle: TextStyle(color: Color(0xFFF2F2F2)),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: AppColors.surfaceDark,
          indicatorColor: AppColors.accent.withValues(alpha: 0.16),
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
            borderRadius: BorderRadius.circular(AppRadius.card),
            side: const BorderSide(color: AppColors.border),
          ),
        ),
        sliderTheme: SliderThemeData(
          activeTrackColor: AppColors.accent,
          thumbColor: AppColors.accent,
          inactiveTrackColor: AppColors.border,
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((s) {
            return Colors.white;
          }),
          trackColor: WidgetStateProperty.resolveWith((s) {
            if (s.contains(WidgetState.selected)) return AppColors.accent;
            return AppColors.border;
          }),
        ),
        segmentedButtonTheme: SegmentedButtonThemeData(
          style: ButtonStyle(
            foregroundColor: WidgetStateProperty.resolveWith((s) {
              if (s.contains(WidgetState.selected)) return AppColors.onAccent;
              return const Color(0xFFF2F2F2);
            }),
            backgroundColor: WidgetStateProperty.resolveWith((s) {
              if (s.contains(WidgetState.selected)) {
                return AppColors.accent;
              }
              return AppColors.chipIdle;
            }),
          ),
        ),
        chipTheme: ChipThemeData(
          selectedColor: AppColors.accent,
          checkmarkColor: AppColors.onAccent,
          labelStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 12,
            color: AppColors.chipIdleText,
          ),
          secondaryLabelStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.onAccent,
          ),
        ),
        extensions: const [FlowLineKind(sunlight: false)],
      );

  /// Spec Sunlight Mode — nur Ride. Marked via [FlowLineKind].
  static ThemeData get sunlight => ThemeData(
        useMaterial3: true,
        fontFamily: fontFamily,
        brightness: Brightness.light,
        colorScheme: const ColorScheme.light(
          primary: AppColors.sunAccent,
          secondary: AppColors.sage,
          surface: AppColors.sunSurface,
          onPrimary: AppColors.onSunAccent,
          onSecondary: AppColors.onAccent,
          onSurface: AppColors.sunText,
          error: AppColors.error,
          onError: AppColors.onSunAccent,
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
            foregroundColor: AppColors.onSunAccent,
            minimumSize: const Size(0, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.chip),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.sunText,
            side: const BorderSide(color: AppColors.borderLight),
            minimumSize: const Size(0, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.chip),
            ),
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.sunSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.card),
            side: const BorderSide(color: AppColors.borderLight),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.sunSurface,
          labelStyle: const TextStyle(color: AppColors.sunMuted),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.chip),
            borderSide: const BorderSide(color: AppColors.borderLight),
          ),
        ),
        chipTheme: ChipThemeData(
          selectedColor: AppColors.sunAccent,
          checkmarkColor: AppColors.onSunAccent,
          labelStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 12,
            color: AppColors.sunText,
          ),
          secondaryLabelStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.onSunAccent,
          ),
        ),
        extensions: const [FlowLineKind(sunlight: true)],
      );

  /// Park / abstellen — not the orange ride-out.
  static ButtonStyle parkCta({double height = 52}) => FilledButton.styleFrom(
        backgroundColor: AppColors.chipIdleText,
        foregroundColor: AppColors.hofGround,
        minimumSize: Size(0, height),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.chip),
        ),
      );

  /// Primary ride CTA — FlowLine orange.
  static ButtonStyle rideOutCta({double height = 52}) => FilledButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.onAccent,
        disabledBackgroundColor: AppColors.elevated,
        disabledForegroundColor: AppColors.muted,
        minimumSize: Size(0, height),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.chip),
        ),
      );
}
