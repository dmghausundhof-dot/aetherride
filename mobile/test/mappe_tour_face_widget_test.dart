import 'package:aetherride_mobile/data/community/tour_community_store.dart';
import 'package:aetherride_mobile/domain/saved_route.dart';
import 'package:aetherride_mobile/domain/saved_route_note.dart';
import 'package:aetherride_mobile/l10n/app_localizations.dart';
import 'package:aetherride_mobile/presentation/discover/widgets/saved_mappe_tile.dart';
import 'package:aetherride_mobile/presentation/library/mappe_empty.dart';
import 'package:aetherride_mobile/presentation/library/mappe_stimme_row.dart';
import 'package:aetherride_mobile/presentation/library/mappe_tour_card.dart';
import 'package:aetherride_mobile/presentation/library/tour_line_thumb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    locale: const Locale('de', 'DE'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

SavedRouteEntry _route({
  required String name,
  List<List<double>> coords = const [],
  double elevationM = 120,
}) {
  return SavedRouteEntry(
    id: 'saved-1',
    name: name,
    distanceKm: 16,
    elevationM: elevationM,
    durationMin: 40,
    savedAt: DateTime.utc(2026, 8, 18),
    coordinates: coords,
  );
}

void main() {
  testWidgets('Mappe-Karte zeigt Spur, Stats und Losfahren', (tester) async {
    await tester.pumpWidget(
      _wrap(
        MappeTourCard(
          route: _route(
            name: 'Neckar',
            coords: const [
              [8.6, 49.4],
              [8.7, 49.5],
            ],
          ),
          meta: null,
          onOpen: () {},
          onGoRide: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Neckar'), findsOneWidget);
    expect(find.text('16 km'), findsOneWidget);
    expect(find.text('120 hm'), findsOneWidget);
    expect(find.text('40 min'), findsOneWidget);
    expect(find.text('Kein Track'), findsNothing);
    expect(find.byType(TourLineThumb), findsOneWidget);
    expect(find.byKey(const Key('platz-tour-ride-saved-1')), findsOneWidget);
  });

  testWidgets('Source-Chip und Runde nur als Glyph auf der Spur',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        MappeTourCard(
          route: _route(
            name: 'Rundkurs',
            coords: const [
              [8.68, 49.4],
              [8.7, 49.41],
              [8.72, 49.4],
              [8.7, 49.39],
              [8.68, 49.4],
            ],
          ),
          meta: null,
          onOpen: () {},
          onGoRide: () {},
          sourceChip: 'Import',
          awayLabel: '12 km entfernt',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Import'), findsOneWidget);
    expect(find.text('12 km entfernt'), findsOneWidget);
    expect(find.text('Runde'), findsNothing);
    expect(find.byType(TourLineThumb), findsOneWidget);
  });

  testWidgets('ohne Spur: Kein Track, kein Losfahren, Runde bei Ring',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        MappeTourCard(
          route: _route(name: 'Skizze'),
          meta: null,
          onOpen: () {},
          onGoRide: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Kein Track'), findsOneWidget);
    expect(find.text('16 km'), findsNothing);
    expect(find.byKey(const Key('platz-tour-ride-saved-1')), findsNothing);

    await tester.pumpWidget(
      _wrap(
        MappeTourCard(
          route: _route(
            name: 'Rundkurs',
            coords: const [
              [8.68, 49.4],
              [8.7, 49.41],
              [8.72, 49.4],
              [8.7, 49.39],
              [8.68, 49.4],
            ],
          ),
          meta: null,
          onOpen: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Rundkurs'), findsOneWidget);
    expect(find.text('Runde'), findsNothing);
    expect(find.byType(TourLineThumb), findsOneWidget);
    expect(find.byKey(const Key('platz-tour-ride-saved-1')), findsNothing);
  });

  testWidgets('Karte-Sheet-Kachel: Quer-Streifen, Face, Akte und Entfernen',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        SavedMappeTile(
          route: _route(
            name: 'Import-Tour',
            coords: const [
              [8.6, 49.4],
              [8.7, 49.5],
            ],
          ),
          meta: null,
          sourceBadge: 'Import',
          onOpen: () {},
          onDetail: () {},
          onDelete: () async {},
          onGoRide: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Import-Tour'), findsOneWidget);
    expect(find.text('Import'), findsOneWidget);
    expect(find.byTooltip('Akte'), findsOneWidget);
    expect(find.byTooltip('Entfernen'), findsOneWidget);
    expect(find.byKey(const Key('mappe-tile-akte-saved-1')), findsOneWidget);
    expect(find.byType(TourLineThumb), findsOneWidget);
    expect(
        tester.widget<TourLineThumb>(find.byType(TourLineThumb)).wide, isTrue);
    expect(find.byKey(const Key('mappe-tile-ride-saved-1')), findsOneWidget);
  });

  testWidgets('Karte ohne ehrliche hm zeigt keine 0 hm', (tester) async {
    await tester.pumpWidget(
      _wrap(
        MappeTourCard(
          route: _route(
            name: 'Flach',
            elevationM: 0,
            coords: const [
              [8.6, 49.4],
              [8.7, 49.5],
            ],
          ),
          meta: null,
          onOpen: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('16 km'), findsOneWidget);
    expect(find.text('0 hm'), findsNothing);
    expect(find.text('40 min'), findsOneWidget);
  });

  testWidgets('Freigabe-Chip nur wenn geteilt, nie privat auf jeder Karte',
      (tester) async {
    final coords = const [
      [8.6, 49.4],
      [8.7, 49.5],
    ];
    await tester.pumpWidget(
      _wrap(
        MappeTourCard(
          route: _route(name: 'Privat', coords: coords),
          meta: null,
          onOpen: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('privat'), findsNothing);
    expect(find.text('freigegeben'), findsNothing);

    await tester.pumpWidget(
      _wrap(
        MappeTourCard(
          route: _route(name: 'Offen', coords: coords),
          meta: const SavedRouteMeta(visibility: 'shared'),
          onOpen: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('freigegeben'), findsOneWidget);
    expect(find.text('privat'), findsNothing);
  });

  testWidgets('Sammlung zeigt Restzahl über drei echte Spuren', (tester) async {
    await tester.pumpWidget(
      _wrap(
        MappeTrackStack(
          tracks: const [
            [
              [8.6, 49.4],
              [8.7, 49.5],
            ],
            [
              [8.8, 49.2],
              [8.9, 49.3],
            ],
          ],
          extraCount: 2,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('+2'), findsOneWidget);
    expect(find.byType(TourLineThumb), findsNWidgets(2));
  });

  testWidgets('Stimmen-Inbox nutzt Spur-Thumb und Zustand-Tag', (tester) async {
    await tester.pumpWidget(
      _wrap(
        MappeStimmeRow(
          review: TourCommunityReview(
            id: 's1',
            tourId: 'saved-1',
            rating: 4,
            body: 'Nasser Belag am See.',
            authorLabel: 'Du',
            createdAt: DateTime.utc(2026, 8, 19),
            tags: const ['nass'],
          ),
          route: _route(
            name: 'Neckar',
            coords: const [
              [8.6, 49.4],
              [8.7, 49.5],
            ],
          ),
          onOpen: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Neckar'), findsOneWidget);
    expect(find.text('nass'), findsOneWidget);
    expect(find.text('Nasser Belag am See.'), findsOneWidget);
    expect(find.byType(TourLineThumb), findsOneWidget);
    expect(find.byType(ListTile), findsNothing);
  });

  testWidgets('Stimmen ohne Tour zeigt Text, nie die ID', (tester) async {
    await tester.pumpWidget(
      _wrap(
        MappeStimmeRow(
          review: TourCommunityReview(
            id: 's2',
            tourId: 'saved-1',
            rating: 3,
            body: 'Nasser Belag am See.',
            authorLabel: 'Du',
            createdAt: DateTime.utc(2026, 8, 19),
          ),
          onOpen: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nasser Belag am See.'), findsOneWidget);
    expect(find.text('saved-1'), findsNothing);
    expect(find.text('Stimme'), findsNothing);
  });

  testWidgets('Leerzustand trägt Titel und Mappe-Glyphe', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const MappeEmptyBlock(
          title: 'Noch keine Linie',
          hint: 'Merke eine Tour oder importiere GPX.',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Noch keine Linie'), findsOneWidget);
    expect(find.text('Merke eine Tour oder importiere GPX.'), findsOneWidget);
  });

  testWidgets('Leerzustand zeigt Aktionen', (tester) async {
    await tester.pumpWidget(
      _wrap(
        MappeEmptyBlock(
          title: 'Noch keine Linie',
          hint: 'Hint',
          actions: const [
            Text('Auf der Karte merken'),
            Text('GPX importieren'),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Auf der Karte merken'), findsOneWidget);
    expect(find.text('GPX importieren'), findsOneWidget);
  });
}
