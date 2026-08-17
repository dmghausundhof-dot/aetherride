import 'package:aetherride_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('platzCollectionTours is singular for one', (tester) async {
    late AppLocalizations de;
    late AppLocalizations en;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            de = AppLocalizations.of(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(de.platzCollectionTours(1), '1 Tour');
    expect(de.platzCollectionTours(2), '2 Touren');
    expect(de.platzCollectionTours(0), '0 Touren');
    expect(de.platzTogetherKicker, 'Zusammen raus');
    expect(de.platzCollectionsKicker, 'Sammlungen');
    expect(de.mappeTitle, 'Die Mappe');
    expect(de.platzTogetherKicker, isNot(de.platzTogetherKicker.toUpperCase()));
    expect(de.filterVisibilityPublic, 'Freigegeben');
    expect(de.platzPinsOff, contains('Freunde'));
    expect(de.platzHostCannotSee, contains('Host sieht dich nicht'));
    expect(de.platzInviteAsYou, contains('als Du'));
    expect(de.postRideStimmePrivate, contains('privat'));
    expect(de.platzTogetherHint, contains('Deine Gruppen bleiben'));
    expect(de.platzTourNotInMappeHint, contains('kein erfundener Track'));
    expect(de.discoverShareRelease, 'Freigeben');
    expect(de.platzJoinLocal('Bodensee'), contains('Nur auf diesem Gerät'));
    expect(de.platzJoinLocal('Bodensee'), isNot(contains('Lokal dabei')));
    expect(de.stimmenShareNeedRelease, contains('Freigeben'));
    expect(de.stimmenShareNeedRelease, isNot(contains('Mein')));

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            en = AppLocalizations.of(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(en.platzCollectionTours(1), '1 tour');
    expect(en.platzCollectionTours(2), '2 tours');
    expect(en.platzTogetherKicker, 'Ride together');
    expect(en.platzCollectionsKicker, 'Collections');

    late AppLocalizations fr;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            fr = AppLocalizations.of(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(fr.platzTogetherKicker, 'Sortir ensemble');
    expect(fr.platzCollectionsKicker, 'Collections');

    late AppLocalizations it;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('it'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            it = AppLocalizations.of(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(it.platzTogetherKicker, 'Uscire insieme');
    expect(it.platzCollectionsKicker, 'Raccolte');
  });
}
