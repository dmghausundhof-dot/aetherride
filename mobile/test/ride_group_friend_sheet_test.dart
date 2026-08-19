import 'package:aetherride_mobile/domain/community/ride_group_pin.dart';
import 'package:aetherride_mobile/l10n/app_localizations.dart';
import 'package:aetherride_mobile/presentation/ride/widgets/ride_group_friend_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Freund-Sheet: Distanz und Karte, kein Warte-Status', (tester) async {
    var flown = false;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: RideGroupFriendSheet(
            mate: const RideGroupHudMate(
              userId: 'sam',
              label: 'Sam',
              self: false,
              sharing: true,
              meters: 400,
              lat: 49.41,
              lng: 8.69,
              rel: FriendRel.behind,
            ),
            onFlyTo: () => flown = true,
          ),
        ),
      ),
    );
    expect(find.textContaining('400 m hinter dir'), findsOneWidget);
    expect(find.textContaining('wartet'), findsNothing);
    expect(find.textContaining('kommt'), findsNothing);
    await tester.tap(find.byKey(const Key('ride-group-fly-to')));
    await tester.pump();
    expect(flown, isTrue);
  });
}
