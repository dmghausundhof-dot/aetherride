import 'package:aetherride_mobile/domain/hud_media.dart';
import 'package:aetherride_mobile/l10n/app_localizations.dart';
import 'package:aetherride_mobile/presentation/profile/hud_media_connection_tile.dart';
import 'package:aetherride_mobile/presentation/ride/widgets/ride_media_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    locale: const Locale('de'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  group('HudNowPlaying.fromMap', () {
    test('idle on null or empty', () {
      expect(HudNowPlaying.fromMap(null), HudNowPlaying.idle);
      expect(HudNowPlaying.fromMap(<String, Object?>{}), HudNowPlaying.idle);
    });

    test('parses session snapshot', () {
      final np = HudNowPlaying.fromMap({
        'listenerEnabled': true,
        'musicActive': true,
        'active': true,
        'playing': true,
        'title': 'Bohemian Rhapsody',
        'artist': 'Queen',
        'appLabel': 'Spotify',
        'packageName': 'com.spotify.music',
        'canSkipNext': true,
        'canSkipPrevious': false,
      });
      expect(np.displayTitle, 'Bohemian Rhapsody');
      expect(np.subtitle, 'Queen · Spotify');
      expect(np.playing, isTrue);
      expect(np.canSkipPrevious, isFalse);
      expect(np.canSkipNext, isTrue);
    });

    test('blank title falls back to Musik', () {
      expect(HudNowPlaying.idle.displayTitle, 'Musik');
    });

    test('skip flags default true when omitted', () {
      final np = HudNowPlaying.fromMap({'active': true, 'title': 'X'});
      expect(np.canSkipNext, isTrue);
      expect(np.canSkipPrevious, isTrue);
    });
  });

  group('hudMediaChipKind', () {
    test('Clean hides chrome when nothing plays', () {
      expect(
        hudMediaChipKind(
          cleanMode: true,
          listenerEnabled: false,
          promptDismissed: false,
          hasSession: false,
          musicActive: false,
          optimisticHold: false,
        ),
        HudMediaChipKind.hidden,
      );
    });

    test('Clean shows controls while music is active', () {
      expect(
        hudMediaChipKind(
          cleanMode: true,
          listenerEnabled: false,
          promptDismissed: false,
          hasSession: false,
          musicActive: true,
          optimisticHold: false,
        ),
        HudMediaChipKind.controls,
      );
    });

    test('paused session stays visible', () {
      expect(
        hudMediaChipKind(
          cleanMode: true,
          listenerEnabled: true,
          promptDismissed: false,
          hasSession: true,
          musicActive: false,
          optimisticHold: false,
        ),
        HudMediaChipKind.controls,
      );
    });

    test('optimistic hold keeps chip after pause without session', () {
      expect(
        hudMediaChipKind(
          cleanMode: true,
          listenerEnabled: false,
          promptDismissed: true,
          hasSession: false,
          musicActive: false,
          optimisticHold: true,
        ),
        HudMediaChipKind.controls,
      );
    });

    test('Pro shows enable prompt once', () {
      expect(
        hudMediaChipKind(
          cleanMode: false,
          listenerEnabled: false,
          promptDismissed: false,
          hasSession: false,
          musicActive: false,
          optimisticHold: false,
        ),
        HudMediaChipKind.enablePrompt,
      );
    });

    test('Pro hides prompt after dismiss', () {
      expect(
        hudMediaChipKind(
          cleanMode: false,
          listenerEnabled: false,
          promptDismissed: true,
          hasSession: false,
          musicActive: false,
          optimisticHold: false,
        ),
        HudMediaChipKind.hidden,
      );
    });

    test('no prompt when listener already granted', () {
      expect(
        hudMediaChipKind(
          cleanMode: false,
          listenerEnabled: true,
          promptDismissed: false,
          hasSession: false,
          musicActive: false,
          optimisticHold: false,
        ),
        HudMediaChipKind.hidden,
      );
    });
  });

  group('hudMediaOptimisticHoldActive', () {
    test('active before until', () {
      final now = DateTime(2026, 8, 15, 12);
      expect(
        hudMediaOptimisticHoldActive(now.add(const Duration(seconds: 1)), now),
        isTrue,
      );
    });

    test('inactive when null or expired', () {
      final now = DateTime(2026, 8, 15, 12);
      expect(hudMediaOptimisticHoldActive(null, now), isFalse);
      expect(
        hudMediaOptimisticHoldActive(
          now.subtract(const Duration(seconds: 1)),
          now,
        ),
        isFalse,
      );
    });
  });

  group('RideMediaChip', () {
    testWidgets('hidden kind paints nothing', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RideMediaChip(
              kind: HudMediaChipKind.hidden,
              nowPlaying: HudNowPlaying.idle,
              compact: true,
              onPlayPause: _noop,
              onSkipNext: _noop,
              onSkipPrevious: _noop,
              onEnable: _noop,
              onDismissPrompt: _noop,
            ),
          ),
        ),
      );
      expect(find.byType(IconButton), findsNothing);
      expect(find.text('Musik'), findsNothing);
    });

    testWidgets('controls: play/skip and compact title', (tester) async {
      var play = 0;
      var next = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RideMediaChip(
              kind: HudMediaChipKind.controls,
              nowPlaying: const HudNowPlaying(
                listenerEnabled: true,
                musicActive: true,
                active: true,
                playing: true,
                title: 'Fast Car',
                artist: 'Tracy Chapman',
                appLabel: 'Spotify',
                packageName: 'com.spotify.music',
                canSkipNext: true,
                canSkipPrevious: true,
              ),
              compact: true,
              onPlayPause: () => play++,
              onSkipNext: () => next++,
              onSkipPrevious: _noop,
              onEnable: _noop,
              onDismissPrompt: _noop,
            ),
          ),
        ),
      );

      expect(find.text('Fast Car'), findsOneWidget);
      expect(find.textContaining('Tracy'), findsNothing);
      expect(find.byTooltip('Pause'), findsOneWidget);

      await tester.tap(find.byKey(RideMediaChip.playPauseKey));
      await tester.tap(find.byKey(RideMediaChip.skipNextKey));
      expect(play, 1);
      expect(next, 1);
    });

    testWidgets('Pro chip shows artist and app', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RideMediaChip(
              kind: HudMediaChipKind.controls,
              nowPlaying: const HudNowPlaying(
                listenerEnabled: true,
                musicActive: true,
                active: true,
                playing: false,
                title: 'Fast Car',
                artist: 'Tracy Chapman',
                appLabel: 'Spotify',
                packageName: 'com.spotify.music',
                canSkipNext: true,
                canSkipPrevious: true,
              ),
              compact: false,
              onPlayPause: _noop,
              onSkipNext: _noop,
              onSkipPrevious: _noop,
              onEnable: _noop,
              onDismissPrompt: _noop,
            ),
          ),
        ),
      );
      expect(find.text('Tracy Chapman · Spotify'), findsOneWidget);
      expect(find.byTooltip('Abspielen'), findsOneWidget);
    });

    testWidgets('enable prompt taps', (tester) async {
      var enable = 0;
      var dismiss = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RideMediaChip(
              kind: HudMediaChipKind.enablePrompt,
              nowPlaying: HudNowPlaying.idle,
              compact: false,
              onPlayPause: _noop,
              onSkipNext: _noop,
              onSkipPrevious: _noop,
              onEnable: () => enable++,
              onDismissPrompt: () => dismiss++,
            ),
          ),
        ),
      );
      expect(find.text('Musik im HUD'), findsOneWidget);
      await tester.tap(find.byKey(RideMediaChip.enableKey));
      await tester.tap(find.byKey(RideMediaChip.dismissKey));
      expect(enable, 1);
      expect(dismiss, 1);
    });
  });

  group('HudMediaConnectionTile', () {
    Future<void> pumpTile(
      WidgetTester tester, {
      required bool enabled,
      HudMediaConnectionCopy copy = HudMediaConnectionCopy.profile,
      Future<void> Function()? onOpen,
    }) {
      return tester.pumpWidget(
        _wrap(
          HudMediaConnectionTile(
            copy: copy,
            listenerEnabled: () => enabled,
            onOpenSettings: onOpen ?? () async {},
          ),
        ),
      );
    }

    testWidgets('shows Aus when listener is off', (tester) async {
      await pumpTile(tester, enabled: false);
      expect(find.text('Medien im HUD'), findsOneWidget);
      expect(find.text('Aus'), findsOneWidget);
      expect(find.text('An'), findsNothing);
      expect(
        find.textContaining('Play/Pause geht oft schon ohne'),
        findsOneWidget,
      );
    });

    testWidgets('shows An when listener is on', (tester) async {
      await pumpTile(tester, enabled: true);
      expect(find.text('An'), findsOneWidget);
      expect(find.text('Aus'), findsNothing);
    });

    testWidgets('privacy copy points to profile', (tester) async {
      await pumpTile(
        tester,
        enabled: false,
        copy: HudMediaConnectionCopy.privacy,
      );
      expect(find.textContaining('Einstellung unter Profil'), findsOneWidget);
      expect(find.textContaining('Play/Pause'), findsNothing);
    });

    testWidgets('tap opens listener settings', (tester) async {
      var opened = 0;
      await pumpTile(
        tester,
        enabled: false,
        onOpen: () async {
          opened++;
        },
      );
      await tester.tap(find.byKey(HudMediaConnectionTile.tileKey));
      await tester.pump();
      expect(opened, 1);
    });

    testWidgets('resumed lifecycle refreshes An/Aus', (tester) async {
      var enabled = false;
      await tester.pumpWidget(
        _wrap(
          HudMediaConnectionTile(
            listenerEnabled: () => enabled,
            onOpenSettings: () async {},
          ),
        ),
      );
      expect(find.text('Aus'), findsOneWidget);

      enabled = true;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(find.text('An'), findsOneWidget);
    });

    testWidgets('hidden without seams when MediaSession is unsupported',
        (tester) async {
      await tester.pumpWidget(
        _wrap(const HudMediaConnectionTile()),
      );
      await tester.pump();
      expect(find.byKey(HudMediaConnectionTile.tileKey), findsNothing);
      expect(find.text('Medien im HUD'), findsNothing);
    });
  });
}

void _noop() {}
