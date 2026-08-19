import 'package:aetherride_mobile/data/community/ride_group_invite.dart';
import 'package:aetherride_mobile/domain/community/ride_group.dart';
import 'package:aetherride_mobile/l10n/app_localizations.dart';
import 'package:aetherride_mobile/presentation/library/platz_join_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Join-Feld nimmt Code oder Link', (tester) async {
    String? pasted;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (ctx) => Scaffold(
            body: TextButton(
              onPressed: () async {
                pasted = await showModalBottomSheet<String>(
                  context: ctx,
                  isScrollControlled: true,
                  builder: (_) => const PlatzJoinSheet(signedIn: true),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('platz-join-field')), findsOneWidget);
    expect(find.byKey(const Key('platz-join-code')), findsNothing);
    expect(find.text('Verbinden'), findsWidgets);

    await tester.enterText(find.byKey(const Key('platz-join-field')), 'K7M2NP');
    await tester.tap(find.byKey(const Key('platz-join-submit')));
    await tester.pumpAndSettle();
    expect(RideGroupInvite.parsePastedJoin(pasted!)?.code, 'K7M2NP');

    pasted = null;
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    final group = RideGroup(
      id: '11111111-1111-1111-1111-111111111111',
      hostUserId: 'host-1',
      savedRouteId: 'r-bodensee-road',
      title: 'Bodensee',
      startWindowStart: DateTime.utc(2026, 8, 15, 8),
      startWindowEnd: DateTime.utc(2026, 8, 15, 12),
      joinCode: 'K7M2NP',
      status: RideGroupStatus.open,
      livePinsAllowed: true,
      createdAt: DateTime.utc(2026, 8, 15, 8),
    );
    final token = RideGroupInvite.encode(group);
    final url = RideGroupInvite.httpsUrl(
      groupId: group.id,
      token: token,
      origin: 'https://aetherride.vercel.app',
    );
    await tester.enterText(find.byKey(const Key('platz-join-field')), url);
    await tester.tap(find.byKey(const Key('platz-join-submit')));
    await tester.pumpAndSettle();
    expect(RideGroupInvite.parsePastedJoin(pasted!)?.token, token);
  });

  testWidgets('Join-Sheet bleibt bei Keyboard scrollbar', (tester) async {
    tester.view.viewInsets = const FakeViewPadding(bottom: 380);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: PlatzJoinSheet(signedIn: false),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('platz-join-field')), findsOneWidget);
    expect(find.byKey(const Key('platz-join-signin')), findsOneWidget);
    expect(find.textContaining('sieht der Host dich nicht'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('platz-join-submit')));
    expect(find.byKey(const Key('platz-join-submit')), findsOneWidget);
  });
}
