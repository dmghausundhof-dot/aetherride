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
    expect(de.platzTogetherKicker, 'Gruppe');
    expect(de.platzCollectionsKicker, 'Sammlungen');
    expect(de.mappeTitle, 'Touren');
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
    expect(de.platzJoinLocalCta, 'Auf diesem Gerät merken');
    expect(de.platzJoinUnsignedHint, contains('sieht der Host dich nicht'));
    expect(de.stimmenShareNeedRelease, contains('Freigeben'));
    expect(de.stimmenShareNeedRelease, isNot(contains('Mein')));
    expect(de.akteHonestyCatalog, contains('freigegeben'));
    expect(de.akteHonestyCatalog, isNot(contains('öffentlich')));
    expect(de.akteHonestyCatalog, isNot(contains('Akte')));
    expect(de.consentHeatmapTitle, contains('Wo viele fahren'));
    expect(de.consentHeatmapTitle, isNot(contains('Heatmap')));
    expect(de.consentHeatmapBody, isNot(contains('k≥')));
    expect(de.discoverMenuPrivacy, contains('Privatsphäre'));
    expect(de.discoverMenuPrivacy, isNot(contains('Heatmap')));
    expect(de.platzCreateGroupHint, contains('sichtbar'));
    expect(de.platzCreateGroupHint, isNot(contains('Sichtbarkeit')));
    expect(de.discoverVisibility, 'Freigabe');
    expect(de.postRideOrtPrivateOnly, contains('freigegebene'));
    expect(de.hofTafelHint, contains('kein Feed'));
    expect(de.platzGroupListedNote, contains('Sichtbar gelistet'));
    expect(de.platzGroupPrivateHint, contains('Nicht gelistet'));
    expect(de.myRouteNotesHint, isNot(contains('Öffentlich')));
    expect(de.myRouteNotesHint, contains('unter Tipps'));
    expect(de.postRideOrtHint, isNot(contains('Öffentlich')));
    expect(de.postRideOrtHint, contains('Auf der Karte'));
    expect(de.stimmenStatusPending, 'In Prüfung');
    expect(de.stimmenCloudApproved, contains('sichtbar'));

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
    expect(en.platzTogetherKicker, 'Group');
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
    expect(fr.platzTogetherKicker, 'Groupe');
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
    expect(it.platzTogetherKicker, 'Gruppo');
    expect(it.platzCollectionsKicker, 'Raccolte');
  });
}
