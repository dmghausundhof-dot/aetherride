import 'package:aetherride_mobile/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('night-orange uses charcoal ink, not white', () {
    expect(AppColors.onAccent, AppColors.hofGround);
    expect(AppColors.onAccent, const Color(0xFF121215));
    expect(AppColors.onSunAccent, const Color(0xFFFFFFFF));
  });

  test('dark elevation ladder is spread', () {
    expect(AppColors.hofGround, const Color(0xFF121215));
    expect(AppColors.surfaceDark, const Color(0xFF1E1E26));
    expect(AppColors.elevated, const Color(0xFF2A2A34));
    expect(AppColors.overlay, const Color(0xFF343440));
    expect(AppColors.border, const Color(0xFF484854));
    expect(AppColors.warning, const Color(0xFFEAB308));
    expect(AppColors.error, const Color(0xFFEF4444));
    expect(AppColors.sageOnLight, const Color(0xFF4F6B5A));
    expect(AppColors.mapWarnInk, AppColors.sunAccent);
    expect(AppColors.chipIdle, AppColors.surfaceDark);
    expect(AppTheme.dark.colorScheme.onSecondary, AppColors.onAccent);
    expect(AppTheme.sunlight.colorScheme.onSecondary, AppColors.onAccent);
    expect(
      AppTheme.dark.colorScheme.surfaceContainer,
      AppColors.elevated,
    );
    expect(
      AppTheme.dark.filledButtonTheme.style?.backgroundColor?.resolve({
        WidgetState.disabled,
      }),
      AppColors.elevated,
    );
  });

  test('product themes are dark and sunlight only', () {
    expect(AppTheme.dark.brightness, Brightness.dark);
    expect(AppTheme.sunlight.brightness, Brightness.light);
    expect(AppTheme.dark.extension<FlowLineKind>()?.sunlight, isFalse);
    expect(AppTheme.sunlight.extension<FlowLineKind>()?.sunlight, isTrue);
  });

  test('park CTA is light chip, ride-out is orange', () {
    final park = AppTheme.parkCta();
    expect(park.backgroundColor?.resolve({}), AppColors.chipIdleText);
    expect(park.foregroundColor?.resolve({}), AppColors.hofGround);
    final ride = AppTheme.rideOutCta();
    expect(ride.backgroundColor?.resolve({}), AppColors.accent);
    expect(ride.foregroundColor?.resolve({}), AppColors.onAccent);
    expect(
      ride.backgroundColor?.resolve({WidgetState.disabled}),
      AppColors.elevated,
    );
    expect(
      ride.foregroundColor?.resolve({WidgetState.disabled}),
      AppColors.muted,
    );
  });

  test('product typeface is Inter', () {
    expect(AppTheme.fontFamily, 'Inter');
    expect(AppTheme.dark.textTheme.bodyMedium?.fontFamily, 'Inter');
    expect(AppTheme.sunlight.textTheme.bodyMedium?.fontFamily, 'Inter');
  });

  testWidgets('dark ThemeData is not sunlight', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.dark,
        home: Builder(
          builder: (context) {
            expect(AppColors.isSunlight(context), isFalse);
            expect(AppColors.chromeFill(context), AppColors.accent);
            expect(AppColors.inkOnChrome(context), AppColors.onAccent);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  });

  testWidgets('sunlight ThemeData is detected', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.sunlight,
        darkTheme: AppTheme.sunlight,
        themeMode: ThemeMode.light,
        home: Builder(
          builder: (context) {
            expect(AppColors.isSunlight(context), isTrue);
            expect(AppColors.chromeFill(context), AppColors.sunAccent);
            expect(AppColors.inkOnChrome(context), AppColors.onSunAccent);
            expect(AppColors.meta(context), AppColors.sunMuted);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  });
}
