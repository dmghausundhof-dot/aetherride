import 'package:aetherride_mobile/domain/community/ride_group_pin.dart';
import 'package:aetherride_mobile/l10n/app_localizations.dart';
import 'package:aetherride_mobile/presentation/ride/widgets/ride_group_live_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('HUD-Leiste zeigt Teilen und Restzeit', (tester) async {
    final snap = RideGroupHudSnap(
      groupId: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
      title: 'Zoo',
      optIn: true,
      sharing: 2,
      total: 3,
      windowEnd: DateTime.now().add(const Duration(minutes: 48)),
      mates: const [
        RideGroupHudMate(
          userId: 'me',
          label: 'Du',
          self: true,
          sharing: true,
        ),
        RideGroupHudMate(
          userId: 'friend',
          label: 'Sam',
          self: false,
          sharing: true,
          meters: 400,
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: RideGroupLiveBar(snap: snap, onToggleOptIn: (_) {}),
        ),
      ),
    );
    expect(find.byKey(const Key('ride-group-live-bar')), findsOneWidget);
    expect(find.textContaining('2/3 teilen'), findsOneWidget);
    expect(find.textContaining('1/1'), findsNothing);
    expect(find.byKey(const Key('ride-group-live-opt')), findsOneWidget);
  });

  testWidgets('HUD allein: Du teilst, kein 1/1', (tester) async {
    final snap = RideGroupHudSnap(
      groupId: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
      title: 'Zoo',
      optIn: true,
      sharing: 1,
      total: 1,
      windowEnd: DateTime.now().add(const Duration(hours: 2)),
      mates: const [
        RideGroupHudMate(
          userId: 'me',
          label: 'Du',
          self: true,
          sharing: true,
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: RideGroupLiveBar(snap: snap, onToggleOptIn: (_) {}),
        ),
      ),
    );
    expect(find.textContaining('Du teilst'), findsOneWidget);
    expect(find.textContaining('1/1'), findsNothing);
  });

  testWidgets('Roster: Auflösen und Verlängern nur als Host', (tester) async {
    final snap = RideGroupHudSnap(
      groupId: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
      title: 'Zoo',
      optIn: true,
      sharing: 1,
      total: 2,
      windowEnd: DateTime.now().add(const Duration(hours: 1)),
      selfIsHost: true,
      mates: const [
        RideGroupHudMate(
          userId: 'me',
          label: 'Du',
          self: true,
          sharing: true,
        ),
        RideGroupHudMate(
          userId: 'friend',
          label: 'Sam',
          self: false,
          sharing: true,
          meters: 400,
          lat: 49.41,
          lng: 8.69,
        ),
      ],
    );
    var left = false;
    var framed = false;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: RideGroupLiveBar(
            snap: snap,
            onToggleOptIn: (_) {},
            onFrameAll: () => framed = true,
            onExtend: () {},
            onLeave: () => left = true,
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('ride-group-live-bar')));
    await tester.pumpAndSettle();
    expect(find.text('Freund 1'), findsNothing);
    expect(find.text('Sam'), findsOneWidget);
    expect(find.byKey(const Key('ride-group-extend')), findsOneWidget);
    expect(find.text('Auflösen'), findsOneWidget);
    await tester.tap(find.byKey(const Key('ride-group-frame-all')));
    await tester.pumpAndSettle();
    expect(framed, isTrue);
    expect(left, isFalse);
  });

  testWidgets('Session-Roster: Code, holen, nicht auflösen', (tester) async {
    final snap = RideGroupHudSnap(
      groupId: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
      title: 'Zusammen',
      optIn: true,
      sharing: 3,
      total: 5,
      windowEnd: DateTime.now().add(const Duration(hours: 2)),
      selfIsHost: true,
      isSession: true,
      joinCode: 'AB12CD',
      atCap: false,
      mates: const [
        RideGroupHudMate(
          userId: 'me',
          label: 'Du',
          self: true,
          sharing: true,
        ),
      ],
    );
    var invited = false;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: RideGroupLiveBar(
            snap: snap,
            onToggleOptIn: (_) {},
            onInvite: () => invited = true,
            onLeave: () {},
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('ride-group-live-bar')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('ride-together-roster-code')), findsOneWidget);
    expect(find.text('AB12CD'), findsOneWidget);
    expect(find.textContaining('Geschlossen'), findsOneWidget);
    expect(find.text('Auflösen'), findsNothing);
    expect(find.text('Verlassen'), findsOneWidget);
    await tester.tap(find.byKey(const Key('ride-together-invite')));
    await tester.pumpAndSettle();
    expect(invited, isTrue);
  });
}
