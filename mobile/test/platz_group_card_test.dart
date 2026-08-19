import 'package:aetherride_mobile/domain/community/ride_group.dart';
import 'package:aetherride_mobile/l10n/app_localizations.dart';
import 'package:aetherride_mobile/presentation/library/platz_group_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

RideGroup _group({
  String host = 'host',
  RideGroupVisibility visibility = RideGroupVisibility.private,
}) {
  final now = DateTime(2026, 8, 19, 15);
  return RideGroup(
    id: 'g1',
    hostUserId: host,
    savedRouteId: 'tour-1',
    title: 'Schloss–Rhein',
    startWindowStart: now,
    startWindowEnd: now.add(const Duration(hours: 3, minutes: 30)),
    joinCode: '8SGSL9',
    status: RideGroupStatus.open,
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
}) {
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
}
