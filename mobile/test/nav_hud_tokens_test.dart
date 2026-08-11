import 'package:aetherride_mobile/core/theme/nav_hud_tokens.dart';
import 'package:aetherride_mobile/domain/routing/upcoming_rail.dart';
import 'package:aetherride_mobile/presentation/ride/widgets/ride_data_strip.dart';
import 'package:aetherride_mobile/presentation/ride/widgets/ride_next_turn_banner.dart';
import 'package:aetherride_mobile/presentation/ride/widgets/ride_pre_start_chrome.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('nav-hud-tokens-v1 locked values', () {
    test('next-turn / stat / upcoming / CTA constants', () {
      expect(NavHudTokens.nextTurnDistanceDp, 48);
      expect(NavHudTokens.nextTurnDistanceMinDp, 40);
      expect(NavHudTokens.nextTurnDistanceMaxDp, 56);
      expect(NavHudTokens.nextTurnDistanceWeight, FontWeight.w700);
      expect(NavHudTokens.nextTurnGlyphDp, inInclusiveRange(40, 48));
      expect(NavHudTokens.nextTurnStreetDp, inInclusiveRange(16, 18));
      expect(NavHudTokens.nextTurnStreetWeight, FontWeight.w600);
      expect(NavHudTokens.nextTurnStreetMaxLines, 1);
      expect(NavHudTokens.statValueDp, 22);
      expect(NavHudTokens.statValueWeight, FontWeight.w600);
      expect(NavHudTokens.statLabelDp, 11);
      expect(NavHudTokens.statLabelWeight, FontWeight.w500);
      expect(NavHudTokens.labelSpeed, 'Speed');
      expect(NavHudTokens.labelRestKm, 'Rest-km');
      expect(NavHudTokens.labelEta, 'ETA');
      expect(NavHudTokens.upcomingRailMaxEtaMin, kUpcomingRailMaxEtaMin);
      expect(NavHudTokens.upcomingRailMaxEtaMin, 15);
      expect(NavHudTokens.startCtaGreen, const Color(0xFF00C853));
    });

    testWidgets('distance size clamps 40–56 under large text scale',
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
      expect(size, 56);
    });
  });

  group('HUD widgets honor tokens', () {
    testWidgets('next-turn: Bold 48, glyph ≤48, street 1-line', (tester) async {
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
      expect(distance.style?.fontSize, 48);
      expect(distance.style?.fontWeight, FontWeight.w700);

      final street = tester.widget<Text>(
        find.text('Sehr langer Straßenname der abgeschnitten werden muss'),
      );
      expect(street.maxLines, 1);
      expect(street.overflow, TextOverflow.ellipsis);
      expect(street.style?.fontWeight, FontWeight.w600);
      expect(
        street.style?.fontSize,
        inInclusiveRange(16, 18),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.turn_left));
      expect(icon.size, inInclusiveRange(40, 48));
    });

    testWidgets('data strip: Speed · Rest-km · ETA at token type',
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

      final label = tester.widget<Text>(find.text(NavHudTokens.labelSpeed));
      expect(label.style?.fontSize, NavHudTokens.statLabelDp);
      expect(label.style?.fontWeight, NavHudTokens.statLabelWeight);
    });

    testWidgets('primary Losfahren CTA is green', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
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
