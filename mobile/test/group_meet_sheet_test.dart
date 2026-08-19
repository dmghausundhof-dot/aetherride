import 'package:aetherride_mobile/domain/community/ride_group.dart';
import 'package:aetherride_mobile/l10n/app_localizations.dart';
import 'package:aetherride_mobile/presentation/discover/widgets/group_meet_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

RideGroup _group() => RideGroup(
      id: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
      hostUserId: 'h',
      savedRouteId: 'tour-1',
      title: 'Zoo-Runde',
      startWindowStart: DateTime(2026, 8, 18, 10),
      startWindowEnd: DateTime(2026, 8, 18, 13),
      joinCode: 'ABCDEF',
      status: RideGroupStatus.open,
      livePinsAllowed: true,
      createdAt: DateTime(2026, 8, 18, 8),
      visibility: RideGroupVisibility.public,
      meetingPoint: 'Parkplatz Zoo 49.4076, 8.6908',
    );

void main() {
  testWidgets('Gast sieht Beitreten, Mitglied Losfahren', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: GroupMeetSheet(group: _group(), isMember: false)),
      ),
    );
    expect(find.text('Zoo-Runde'), findsOneWidget);
    expect(find.byKey(const Key('group-meet-join')), findsOneWidget);
    expect(find.byKey(const Key('group-meet-ride')), findsNothing);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: GroupMeetSheet(group: _group(), isMember: true)),
      ),
    );
    expect(find.byKey(const Key('group-meet-ride')), findsOneWidget);
    expect(find.byKey(const Key('group-meet-join')), findsNothing);
  });
}
