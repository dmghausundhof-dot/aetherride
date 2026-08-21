import 'package:aetherride_mobile/domain/community/ride_group.dart';
import 'package:aetherride_mobile/l10n/app_localizations.dart';
import 'package:aetherride_mobile/presentation/library/platz_group_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

RideGroup _group({
  String host = 'host',
  RideGroupVisibility visibility = RideGroupVisibility.private,
  DateTime? start,
}) {
  final now = start ?? DateTime(2026, 8, 19, 18);
  return RideGroup(
    id: 'g1',
    hostUserId: host,
    savedRouteId: 'tour-1',
    title: 'Schloss–Rhein',
    startWindowStart: now,
    startWindowEnd: now.add(const Duration(hours: 3, minutes: 30)),
    joinCode: '8SGSL9',
    status: RideGroupStatus.scheduled,
    livePinsAllowed: true,
    createdAt: now,
    visibility: visibility,
    onServer: true,
  );
}

RideGroupMember _member(String id, String label) => RideGroupMember(
      groupId: 'g1',
      userId: id,
      displayLabel: label,
      joinedAt: DateTime(2026, 8, 19, 15),
    );

Future<void> _pump(
  WidgetTester tester, {
  required RideGroup group,
  required List<RideGroupMember> members,
  required Set<String> selfIds,
  DateTime? now,
}) {
  final clock = now ?? DateTime(2026, 8, 19, 11, 20);
  return tester.pumpWidget(
    MaterialApp(
      locale: const Locale('de'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: PlatzGroupCard(
          group: group,
          members: members,
          selfIds: selfIds,
          signedIn: true,
          optIn: false,
          now: clock,
          onInvite: () {},
          onRide: () {},
          onLeave: () {},
          onCopyLink: () {},
          onCopyCode: () {},
          onToggleListing: () {},
          onEditTime: () {},
          onOptIn: (_) {},
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('Host allein: Einladen primary, kein Code privat', (tester) async {
    await _pump(
      tester,
      group: _group(),
      members: [_member('host', 'Du')],
      selfIds: {'host'},
    );
    expect(find.byKey(const Key('platz-group-invite-g1')), findsOneWidget);
    expect(find.byKey(const Key('platz-group-ride-g1')), findsNothing);
    expect(find.text('Einladen'), findsOneWidget);
    expect(find.text('8SGSL9'), findsNothing);
    expect(find.textContaining('Du · Gastgeber'), findsOneWidget);
    expect(find.textContaining('1/1'), findsNothing);
    expect(find.textContaining('3,5 h'), findsOneWidget);
    expect(find.text('Tippen zum Ändern'), findsOneWidget);
    expect(find.text('Auflösen'), findsOneWidget);
    expect(find.byKey(const Key('platz-group-leave-g1')), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget);
  });

  testWidgets('Host mit Gast: Losfahren primary, Code nur öffentlich',
      (tester) async {
    await _pump(
      tester,
      group: _group(visibility: RideGroupVisibility.public),
      members: [_member('host', 'Du'), _member('sam', 'Sam')],
      selfIds: {'host'},
    );
    expect(find.byKey(const Key('platz-group-ride-g1')), findsOneWidget);
    expect(find.byKey(const Key('platz-group-invite-g1')), findsNothing);
    expect(find.text('Losfahren'), findsOneWidget);
    expect(find.text('8SGSL9'), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget);
  });

  testWidgets('Gast: Losfahren primary', (tester) async {
    await _pump(
      tester,
      group: _group(),
      members: [_member('host', 'Anna'), _member('me', 'Du')],
      selfIds: {'me'},
    );
    expect(find.byKey(const Key('platz-group-ride-g1')), findsOneWidget);
    expect(find.byKey(const Key('platz-group-invite-g1')), findsNothing);
    expect(find.text('Losfahren'), findsOneWidget);
  });

  testWidgets('Host allein, Fenster offen: Losfahren primary', (tester) async {
    final start = DateTime(2026, 8, 19, 10);
    await _pump(
      tester,
      group: RideGroup(
        id: 'g1',
        hostUserId: 'host',
        savedRouteId: 'tour-1',
        title: 'Schloss–Rhein',
        startWindowStart: start,
        startWindowEnd: start.add(const Duration(hours: 3, minutes: 30)),
        joinCode: '8SGSL9',
        status: RideGroupStatus.open,
        livePinsAllowed: true,
        createdAt: start,
        visibility: RideGroupVisibility.private,
        onServer: true,
      ),
      members: [_member('host', 'Du')],
      selfIds: {'host'},
      now: DateTime(2026, 8, 19, 11, 20),
    );
    expect(find.byKey(const Key('platz-group-ride-g1')), findsOneWidget);
    expect(find.byKey(const Key('platz-group-invite-g1')), findsNothing);
    expect(find.text('Losfahren'), findsOneWidget);
  });
}
