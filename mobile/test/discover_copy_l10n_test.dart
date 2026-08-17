import 'package:aetherride_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('discoverCatalogTours is singular for one', (tester) async {
    late AppLocalizations de;
    late AppLocalizations en;
    late AppLocalizations fr;
    late AppLocalizations it;
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
    expect(de.discoverCatalogTours(1), 'Katalog 1 Tour');
    expect(de.discoverCatalogTours(2), 'Katalog 2 Touren');
    expect(de.discoverCatalogTours(0), 'Katalog 0 Touren');
    expect(de.discoverToursNearbyCount(1), '1 Tour in der Nähe');
    expect(de.discoverToursNearbyCount(2), '2 Touren in der Nähe');
    expect(de.discoverToursNearbyCount(0), '0 Touren in der Nähe');
    expect(de.discoverOaCount(1), '1 Tour in der Nähe');
    expect(de.discoverOaCount(2), '2 Touren in der Nähe');
    expect(de.filterShowTours(1), '1 Tour zeigen');
    expect(de.filterShowTours(2), '2 Touren zeigen');

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
    expect(en.discoverCatalogTours(1), 'Catalog 1 tour');
    expect(en.discoverCatalogTours(2), 'Catalog 2 tours');
    expect(en.discoverToursNearbyCount(1), '1 tour nearby');
    expect(en.discoverToursNearbyCount(2), '2 tours nearby');
    expect(en.discoverOaCount(1), '1 tour nearby');
    expect(en.discoverOaCount(2), '2 tours nearby');

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
    expect(fr.discoverCatalogTours(1), 'Catalogue 1 tour');
    expect(fr.discoverCatalogTours(2), 'Catalogue 2 tours');
    expect(fr.discoverToursNearbyCount(1), '1 tour à proximité');
    expect(fr.discoverToursNearbyCount(2), '2 tours à proximité');
    expect(
      fr.discoverOaCount(1),
      'Outdooractive 1 tour · OSM/traces suivent',
    );
    expect(
      fr.discoverOaCount(2),
      'Outdooractive 2 tours · OSM/traces suivent',
    );

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
    expect(it.discoverCatalogTours(1), 'Catalogo 1 tour');
    expect(it.discoverCatalogTours(2), 'Catalogo 2 tour');
    expect(it.discoverToursNearbyCount(1), '1 tour nelle vicinanze');
    expect(it.discoverToursNearbyCount(2), '2 tour nelle vicinanze');
    expect(it.discoverOaCount(1), '1 tour qui vicino');
    expect(it.discoverOaCount(2), '2 tour qui vicino');
  });
}
