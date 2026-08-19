import 'dart:io';

import 'package:aetherride_mobile/data/community/ride_group_store.dart';
import 'package:aetherride_mobile/data/community/ride_together_look.dart';
import 'package:aetherride_mobile/domain/community/ride_group_pin.dart';
import 'package:aetherride_mobile/domain/community/ride_together.dart';
import 'package:aetherride_mobile/l10n/app_localizations.dart';
import 'package:aetherride_mobile/presentation/ride/widgets/ride_group_live_bar.dart';
import 'package:aetherride_mobile/presentation/ride/widgets/ride_hud_layer_bar.dart';
import 'package:aetherride_mobile/presentation/ride/widgets/ride_together_sheet.dart';
import 'package:aetherride_mobile/domain/active_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void _noop() {}

void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('together-');
  });

  tearDown(() async {
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  testWidgets('Chip heißt Zusammen', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: RideTogetherChip(onTap: () {}),
        ),
      ),
    );
    expect(find.byKey(const Key('ride-together-chip')), findsOneWidget);
    expect(find.text('Zusammen'), findsOneWidget);
  });

  testWidgets('Sheet ohne GPS sagt Standort', (tester) async {
    final store = RideGroupStore(dirProvider: () async => dir);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: RideTogetherSheet(groups: store, look: RideTogetherLook()),
        ),
      ),
    );
    await tester.pump();
    expect(find.textContaining('Standort'), findsOneWidget);
    expect(find.byKey(const Key('ride-together-code-field')), findsOneWidget);
  });

  testWidgets('Kurzer Code sagt sechs Zeichen', (tester) async {
    final store = RideGroupStore(dirProvider: () async => dir);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: RideTogetherSheet(groups: store, look: RideTogetherLook()),
        ),
      ),
    );
    await tester.pump();
    await tester.enterText(find.byKey(const Key('ride-together-code-field')), 'AB');
    await tester.tap(find.byKey(const Key('ride-together-join')));
    await tester.pump();
    expect(find.textContaining('Sechs Zeichen'), findsOneWidget);
  });

  testWidgets('Sheet-Close stoppt Look nicht', (tester) async {
    var stopped = 0;
    final look = RideTogetherLook(
      lookFn: ({required lat, required lng, String? label}) async =>
          const TogetherLookSnap(me: 'u', joinCode: 'ABCDEF'),
      stopLookFn: () async {
        stopped++;
        return const TogetherLookSnap(me: 'u', stopped: true);
      },
      labelFn: () async => 'Luka',
      sessionStateFn: () async => 'signedIn',
    );
    final store = RideGroupStore(dirProvider: () async => dir);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: RideTogetherSheet(
            groups: store,
            look: look,
            lat: 49.4,
            lng: 8.6,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(look.looking, isTrue);
    expect(stopped, 0);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(stopped, 0);
    expect(look.looking, isTrue);
    look.dispose();
  });

  testWidgets('Chip-Zeile behält Code bei Warten', (tester) async {
    late String line;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (ctx) {
            line = rideTogetherChipLine(
              AppLocalizations.of(ctx),
              kind: TogetherChipKind.wait,
              joinCode: 'ABCDEF',
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(line, 'ABCDEF · wartet…');
  });

  testWidgets('Chip zeigt Code bei laufendem Look', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: RideTogetherChip(onTap: _noop, line: 'ABCDEF'),
        ),
      ),
    );
    expect(find.text('ABCDEF'), findsOneWidget);
    expect(find.text('Zusammen'), findsNothing);
  });

  testWidgets('Ja-Karte ohne Sheet', (tester) async {
    var accepted = false;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: RideTogetherInboundCard(
            askLabel: 'Sam will zusammenfahren',
            acceptLabel: 'Ja',
            declineLabel: 'Nicht jetzt',
            onAccept: () => accepted = true,
            onDecline: () {},
          ),
        ),
      ),
    );
    expect(find.byType(RideTogetherSheet), findsNothing);
    expect(find.byKey(const Key('ride-together-accept')), findsOneWidget);
    expect(find.byKey(const Key('ride-together-decline')), findsOneWidget);
    expect(find.text('Sam will zusammenfahren'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('ride-together-accept'))).height,
      greaterThanOrEqualTo(48),
    );
    expect(
      tester.getSize(find.byKey(const Key('ride-together-decline'))).height,
      greaterThanOrEqualTo(48),
    );
    await tester.tap(find.byKey(const Key('ride-together-accept')));
    expect(accepted, isTrue);
  });

  testWidgets('HUD zu beendet Session nicht', (tester) async {
    var left = false;
    var clean = false;
    final snap = RideGroupHudSnap(
      groupId: 'g1',
      title: 'Zusammen',
      optIn: true,
      sharing: 1,
      total: 2,
      windowEnd: DateTime.now().add(const Duration(hours: 1)),
      mates: const [
        RideGroupHudMate(
          userId: 'me',
          label: 'Du',
          self: true,
          sharing: true,
        ),
      ],
      isSession: true,
      joinCode: 'ABCDEF',
    );
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Column(
            children: [
              RideGroupLiveBar(
                snap: snap,
                onToggleOptIn: (_) {},
                onLeave: () => left = true,
              ),
              RideHudLayerBar(
                selected: RideLiveLayer.map,
                mapLabel: 'Karte',
                dataLabel: 'Daten',
                onSelected: (_) {},
                onClose: () => clean = true,
                closeLabel: 'HUD zu',
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.byKey(const Key('ride-group-live-bar')), findsOneWidget);
    await tester.tap(find.byKey(const Key('ride-hud-close')));
    expect(clean, isTrue);
    expect(left, isFalse);
    expect(find.byKey(const Key('ride-group-live-bar')), findsOneWidget);
    expect(find.text('HUD zu'), findsOneWidget);
  });
}
