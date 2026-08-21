import 'package:aetherride_mobile/domain/community/labeled_via.dart';
import 'package:aetherride_mobile/domain/community/map_place.dart';
import 'package:aetherride_mobile/domain/community/map_place_merge.dart';
import 'package:aetherride_mobile/domain/community/poi_from_vias.dart';
import 'package:aetherride_mobile/domain/community/stimme_pin.dart';
import 'package:aetherride_mobile/domain/community/stimme_tags.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('mapPlaceKindFromRaw', () {
    test('maps coverage kinds, never leaves bike_shop as other-POI', () {
      expect(mapPlaceKindFromRaw('bike_shop'), MapPlaceKind.shop);
      expect(mapPlaceKindFromRaw('cafe'), MapPlaceKind.cafe);
      expect(mapPlaceKindFromRaw('repair'), MapPlaceKind.repair);
      expect(mapPlaceKindFromRaw('viewpoint'), MapPlaceKind.viewpoint);
      expect(mapPlaceKindFromRaw(''), MapPlaceKind.other);
    });
  });

  group('moveLabeledVia', () {
    const a = LabeledVia(lat: 49.4, lng: 8.67, label: 'Café');
    const b = LabeledVia(lat: 49.41, lng: 8.68, label: 'Quelle');
    const c = LabeledVia(lat: 49.42, lng: 8.69, label: 'Laden');

    test('moves up and down, ids stay by label', () {
      final up = moveLabeledVia([a, b, c], 2, -1);
      expect(up.map((e) => e.label).toList(), ['Café', 'Laden', 'Quelle']);
      final down = moveLabeledVia([a, b, c], 0, 1);
      expect(down.map((e) => e.label).toList(), ['Quelle', 'Café', 'Laden']);
    });

    test('out of range is a no-op', () {
      const list = [a, b];
      expect(moveLabeledVia(list, 0, -1), list);
      expect(moveLabeledVia(list, 1, 1), list);
    });

    test('moveLabeledViaTo reorders by destination index', () {
      final moved = moveLabeledViaTo([a, b, c], 0, 2);
      expect(moved.map((e) => e.label).toList(), ['Quelle', 'Laden', 'Café']);
      expect(moveLabeledViaTo([a, b], 0, 0), [a, b]);
    });
  });

  group('parseStimmeTags', () {
    test('allowlist, max 3, stable order', () {
      expect(
        parseStimmeTags(['nass', 'top', 'zu', 'nass', 'unknown', 'baustelle']),
        ['nass', 'top', 'zu'],
      );
      expect(parseStimmeTags(null), isEmpty);
    });
  });

  group('poiStopsFromVias', () {
    // ~111 m north per 0.001° lat. Three points south→north.
    const line = <List<double>>[
      [8.67, 49.400],
      [8.67, 49.405],
      [8.67, 49.410],
    ];

    test('named vias on the line become monotonic atMin', () {
      final stops = poiStopsFromVias(
        vias: const [
          LabeledVia(lat: 49.403, lng: 8.67, label: 'A', kind: 'cafe'),
          LabeledVia(lat: 49.408, lng: 8.67, label: 'B', kind: 'water'),
          LabeledVia(lat: 49.409, lng: 8.67, label: 'C'),
        ],
        coordinates: line,
        durationMin: 60,
      );
      expect(stops.map((e) => e.title).toList(), ['A', 'B', 'C']);
      expect(stops[0].atMin, lessThan(stops[1].atMin));
      expect(stops[1].atMin, lessThanOrEqualTo(stops[2].atMin));
      expect(stops.first.kind, 'cafe');
    });

    test('appends geocoded destination once, short label', () {
      final stops = poiStopsFromVias(
        vias: const [
          LabeledVia(lat: 49.403, lng: 8.67, label: 'Quelle'),
        ],
        coordinates: line,
        durationMin: 40,
        destinationLabel:
            "Strohauer's Cafe Alt Heidelberg, Hauptstraße, 69117 Heidelberg",
      );
      expect(stops.map((e) => e.title).toList(), [
        'Quelle',
        "Strohauer's Cafe Alt Heidelberg",
      ]);
      expect(stops.last.atMin, 40);
    });

    test('namedPlaceHudTitle drops coords and empty', () {
      expect(namedPlaceHudTitle('Café am Markt, Heidelberg'), 'Café am Markt');
      expect(namedPlaceHudTitle('49.41, 8.69'), isNull);
      expect(namedPlaceHudTitle('Ziel-Vorschlag (anpassbar)',
          skipExact: 'Ziel-Vorschlag (anpassbar)'), isNull);
    });

    test('named via stays put, unlabeled map tap may snap', () {
      expect(viaMaySnapOntoTrail(label: 'Café am Markt, Heidelberg'), isFalse);
      expect(viaMaySnapOntoTrail(label: "Strohauer's Cafe Alt Heidelberg"),
          isFalse);
      expect(viaMaySnapOntoTrail(), isTrue);
      expect(viaMaySnapOntoTrail(label: '  '), isTrue);
      expect(viaMaySnapOntoTrail(label: '49.41, 8.69'), isTrue);
    });

    test('skips unlabeled and far-off vias', () {
      final stops = poiStopsFromVias(
        vias: const [
          LabeledVia(lat: 49.405, lng: 8.67),
          LabeledVia(lat: 49.405, lng: 9.2, label: 'Fern'),
        ],
        coordinates: line,
        durationMin: 40,
      );
      expect(stops, isEmpty);
    });
  });

  group('mergeMapPlaces', () {
    test('coverage wins same cell, meet is kept', () {
      const cafe = MapPlace(
        id: 'c',
        name: 'Café',
        kind: MapPlaceKind.cafe,
        lat: 49.41,
        lng: 8.67,
      );
      const dup = MapPlace(
        id: 'd',
        name: 'Café 2',
        kind: MapPlaceKind.cafe,
        lat: 49.41,
        lng: 8.67,
        source: MapPlaceSource.user,
      );
      const meet = MapPlace(
        id: 'm',
        name: 'Parkplatz',
        kind: MapPlaceKind.meet,
        lat: 49.4,
        lng: 8.66,
        source: MapPlaceSource.meet,
      );
      const extra = MapPlace(
        id: 'm2',
        name: 'Bahnhof',
        kind: MapPlaceKind.meet,
        lat: 49.39,
        lng: 8.68,
        source: MapPlaceSource.meet,
      );
      final merged = mergeMapPlaces(
        coverage: const [cafe],
        community: const [dup],
        meet: meet,
        meets: [extra],
      );
      expect(merged.map((e) => e.id).toList(), ['c', 'm', 'm2']);
    });
  });

  group('snapStimmePin / parseMeetingLatLng', () {
    const line = <List<double>>[
      [8.67, 49.400],
      [8.67, 49.405],
      [8.67, 49.410],
    ];

    test('snaps on-line, drops far', () {
      final on = snapStimmePin(
        coordinates: line,
        lat: 49.403,
        lng: 8.67,
      );
      expect(on, isNotNull);
      expect(on!.alongM, greaterThan(0));
      expect(
        snapStimmePin(coordinates: line, lat: 49.403, lng: 9.2),
        isNull,
      );
    });

    test('parses meeting text with coords', () {
      final p = parseMeetingLatLng('Parkplatz Zoo 49.4076, 8.6908');
      expect(p?.lat, 49.4076);
      expect(p?.lng, 8.6908);
      expect(p?.label, 'Parkplatz Zoo');
      expect(parseMeetingLatLng('Parkplatz Zoo'), isNull);
    });
  });
}
