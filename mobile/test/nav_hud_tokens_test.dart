import 'package:aetherride_mobile/core/theme/app_theme.dart';
import 'package:aetherride_mobile/core/theme/nav_hud_tokens.dart';
import 'package:aetherride_mobile/domain/routing/upcoming_rail.dart';
import 'package:aetherride_mobile/l10n/app_localizations.dart';
import 'package:aetherride_mobile/l10n/app_localizations_de.dart';
import 'package:aetherride_mobile/l10n/app_localizations_en.dart';
import 'package:aetherride_mobile/l10n/l10n_ext.dart';
import 'package:aetherride_mobile/presentation/ride/widgets/ride_data_strip.dart';
import 'package:aetherride_mobile/presentation/ride/widgets/ride_next_turn_banner.dart';
import 'package:aetherride_mobile/presentation/ride/widgets/ride_pre_start_chrome.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('nav-hud-tokens-v1 locked values', () {
    test('next-turn / stat / upcoming / CTA constants', () {
      expect(NavHudTokens.nextTurnDistanceDp, 32);
      expect(NavHudTokens.nextTurnDistanceMinDp, 28);
      expect(NavHudTokens.nextTurnDistanceMaxDp, 40);
      expect(NavHudTokens.nextTurnDistanceWeight, FontWeight.w700);
      expect(NavHudTokens.nextTurnGlyphDp, inInclusiveRange(24, 32));
      expect(NavHudTokens.nextTurnStreetDp, inInclusiveRange(13, 16));
      expect(NavHudTokens.nextTurnStreetWeight, FontWeight.w600);
      expect(NavHudTokens.nextTurnStreetMaxLines, 1);
      expect(NavHudTokens.statValueDp, 22);
      expect(NavHudTokens.statValueWeight, FontWeight.w600);
      expect(NavHudTokens.statLabelDp, 11);
      expect(NavHudTokens.statLabelWeight, FontWeight.w500);
      expect(NavHudTokens.labelSpeed, 'Tempo');
      expect(NavHudTokens.labelRestKm, 'noch km');
      expect(NavHudTokens.labelEta, 'Ziel');
      expect(NavHudTokens.emptyStat, '—');
      expect(NavHudTokens.upcomingRailMaxEtaMin, kUpcomingRailMaxEtaMin);
      expect(NavHudTokens.upcomingRailMaxEtaMin, 15);
      expect(NavHudTokens.pauseFabDp, 56);
      expect(NavHudTokens.layerLabelDp, 13);
      expect(NavHudTokens.layerLabelWeight, FontWeight.w600);
      expect(NavHudTokens.layerIconDp, 18);
      expect(NavHudTokens.layerBarMinHeightDp, 48);
      expect(NavHudTokens.startCtaGreen, const Color(0xFFFF6A00));
    });

    test('HUD labels map through l10n', () {
      final de = AppLocalizationsDe();
      expect(de.hudSpeedCaptionFor(NavHudTokens.labelSpeed), de.rideSpeed);
      expect(de.hudSpeedCaptionFor('Speed'), 'Tempo');
      expect(de.rideRestKm, 'noch km');
      expect(de.rideEta, 'Ziel');
      expect(de.hudPeekLabelFor('Lean'), 'Neigung');
      final en = AppLocalizationsEn();
      expect(en.hudSpeedCaptionFor('Tempo'), 'Speed');
      expect(en.rideRestKm, 'km left');
      expect(en.rideEta, 'ETA');
    });

    testWidgets('distance size clamps 28–40 under large text scale',
        (tester) async {
      late double size;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Builder(
            builder: (context) {
              size = NavHudTokens.nextTurnDistanceSize(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(size, 40);
    });
  });

  group('HUD widgets honor tokens', () {
    testWidgets('next-turn: Bold 32, glyph ≤32, street 1-line', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: RideNextTurnBanner(
                distance: '120 m',
                instruction:
                    'Sehr langer Straßenname der abgeschnitten werden muss',
                icon: Icons.turn_left,
              ),
            ),
          ),
        ),
      );

      final distance = tester.widget<Text>(find.text('120 m'));
      expect(distance.style?.fontSize, 32);
      expect(distance.style?.fontWeight, FontWeight.w700);

      final street = tester.widget<Text>(
        find.text('Sehr langer Straßenname der abgeschnitten werden muss'),
      );
      expect(street.maxLines, 1);
      expect(street.overflow, TextOverflow.ellipsis);
      expect(street.style?.fontWeight, FontWeight.w600);
      expect(
        street.style?.fontSize,
        inInclusiveRange(13, 16),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.turn_left));
      expect(icon.size, inInclusiveRange(24, 32));
    });

    testWidgets('data strip: Tempo · noch km · Ziel at token type',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RideDataStrip(
              speedLabel: '22',
              midValue: '4.2',
              midLabel: NavHudTokens.labelRestKm,
              rightValue: '18:40',
              rightLabel: NavHudTokens.labelEta,
            ),
          ),
        ),
      );

      expect(find.text(NavHudTokens.labelSpeed), findsOneWidget);
      expect(find.text(NavHudTokens.labelRestKm), findsOneWidget);
      expect(find.text(NavHudTokens.labelEta), findsOneWidget);

      final value = tester.widget<Text>(find.text('22'));
      expect(value.style?.fontSize, NavHudTokens.statValueDp);
      expect(value.style?.fontWeight, NavHudTokens.statValueWeight);
      expect(value.style?.color, AppColors.hofGround);

      final label = tester.widget<Text>(find.text(NavHudTokens.labelSpeed));
      expect(label.style?.fontSize, NavHudTokens.statLabelDp);
      expect(label.style?.fontWeight, NavHudTokens.statLabelWeight);

      final fill = tester.widget<Material>(
        find
            .descendant(
              of: find.byType(RideDataStrip),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(fill.color, AppColors.accent);
    });

    testWidgets('freeride strip keeps Tempo · noch km · Ziel chrome',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RideDataStrip(
              speedLabel: '0',
              midValue: NavHudTokens.emptyStat,
              midLabel: NavHudTokens.labelRestKm,
              rightValue: NavHudTokens.emptyStat,
              rightLabel: NavHudTokens.labelEta,
            ),
          ),
        ),
      );

      expect(find.text(NavHudTokens.labelSpeed), findsOneWidget);
      expect(find.text(NavHudTokens.labelRestKm), findsOneWidget);
      expect(find.text(NavHudTokens.labelEta), findsOneWidget);
      expect(find.text('km/h'), findsNothing);
      expect(find.text('km'), findsNothing);
      expect(find.text('Zeit'), findsNothing);
      expect(find.text(NavHudTokens.emptyStat), findsNWidgets(2));
    });

    testWidgets('primary Losfahren CTA is green', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: RidePreStartChrome(
              routeName: 'Tempelhofer 60',
              onStart: () {},
            ),
          ),
        ),
      );

      final button = tester.widget<FilledButton>(
        find.byKey(const Key('ride-primary-start')),
      );
      final bg = button.style?.backgroundColor?.resolve({});
      expect(bg, NavHudTokens.startCtaGreen);
      expect(find.text('Losfahren'), findsOneWidget);
    });
  });
}
