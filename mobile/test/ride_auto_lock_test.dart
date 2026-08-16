import 'package:aetherride_mobile/core/theme/app_theme.dart';
import 'package:aetherride_mobile/domain/ride_auto_lock.dart';
import 'package:aetherride_mobile/presentation/ride/widgets/ride_auto_lock_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RideAutoLockPolicy', () {
    test('does not arm when not riding', () {
      expect(
        RideAutoLockPolicy.shouldArm(
          riding: false,
          paused: true,
          speedKmh: 0,
        ),
        isFalse,
      );
    });

    test('arms when paused', () {
      expect(
        RideAutoLockPolicy.shouldArm(
          riding: true,
          paused: true,
          speedKmh: 22,
        ),
        isTrue,
      );
    });

    test('arms when standing still', () {
      expect(
        RideAutoLockPolicy.shouldArm(
          riding: true,
          paused: false,
          speedKmh: 1.2,
        ),
        isTrue,
      );
    });

    test('does not arm while moving — nav HUD must stay visible', () {
      expect(
        RideAutoLockPolicy.shouldArm(
          riding: true,
          paused: false,
          speedKmh: 18,
        ),
        isFalse,
      );
    });

    test('unlocks for motion so overlay cannot cover nav permanently', () {
      expect(
        RideAutoLockPolicy.shouldUnlockForMotion(
          locked: true,
          paused: false,
          speedKmh: 12,
        ),
        isTrue,
      );
      expect(
        RideAutoLockPolicy.shouldUnlockForMotion(
          locked: true,
          paused: true,
          speedKmh: 12,
        ),
        isFalse,
      );
      expect(
        RideAutoLockPolicy.shouldUnlockForMotion(
          locked: true,
          paused: false,
          speedKmh: 0,
        ),
        isFalse,
      );
    });
  });

  group('RideAutoLockOverlay', () {
    testWidgets('single tap unlocks (not double-tap)', (tester) async {
      var unlocked = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                const Positioned.fill(child: ColoredBox(color: Colors.green)),
                RideAutoLockOverlay(
                  backgroundColor: Colors.black.withValues(alpha: 0.92),
                  onUnlock: () => unlocked++,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text(RideAutoLockOverlay.title), findsOneWidget);
      expect(find.text(RideAutoLockOverlay.hint), findsOneWidget);
      expect(find.text('Doppeltipp zum Aufwecken'), findsNothing);
      expect(find.byKey(RideAutoLockOverlay.overlayKey), findsOneWidget);

      // Corner: opaque barrier, not the centered Aufwecken button.
      await tester.tapAt(const Offset(24, 24));
      await tester.pump();
      expect(unlocked, 1);
    });

    testWidgets('Aufwecken button unlocks', (tester) async {
      var unlocked = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                RideAutoLockOverlay(
                  backgroundColor: Colors.black,
                  onUnlock: () => unlocked = true,
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(RideAutoLockOverlay.unlockButtonKey));
      await tester.pump();
      expect(unlocked, isTrue);
    });

    testWidgets('opaque barrier fills the stack and wins hit tests',
        (tester) async {
      var mapTapped = false;
      var unlocked = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () => mapTapped = true,
                    child: const ColoredBox(color: Colors.blue),
                  ),
                ),
                RideAutoLockOverlay(
                  backgroundColor: AppColors.overlay.withValues(alpha: 0.92),
                  onUnlock: () => unlocked = true,
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tapAt(const Offset(20, 20));
      await tester.pump();
      expect(unlocked, isTrue);
      expect(mapTapped, isFalse);
    });

    testWidgets('shows tour name while locked', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                RideAutoLockOverlay(
                  backgroundColor: Colors.black,
                  routeName: 'Heidelberg — Neckarwiese',
                  onUnlock: () {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Heidelberg — Neckarwiese'), findsOneWidget);
      expect(find.text(RideAutoLockOverlay.title), findsOneWidget);
    });
  });
}
