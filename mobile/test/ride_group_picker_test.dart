import 'package:aetherride_mobile/domain/community/ride_group_picker.dart';
import 'package:aetherride_mobile/domain/saved_route.dart';
import 'package:aetherride_mobile/domain/saved_route_note.dart';
import 'package:flutter_test/flutter_test.dart';

SavedRouteEntry _saved(
  String id, {
  DateTime? savedAt,
  List<List<double>> coordinates = const [],
}) {
  return SavedRouteEntry(
    id: id,
    name: id,
    distanceKm: 10,
    elevationM: 100,
    durationMin: 40,
    savedAt: savedAt ?? DateTime.utc(2026, 8, 1),
    coordinates: coordinates,
  );
}

void main() {
  test('Picker: private eigene Touren, kein freeride', () {
    final items = RideGroupPicker.build(
      saved: [
        _saved('gpx-neckar'),
        _saved('freeride'),
        _saved(
          'r-bodensee-road',
          savedAt: DateTime.utc(2026, 8, 2),
        ),
      ],
      metas: {
        'r-bodensee-road': const SavedRouteMeta(catalogTourId: 'r-bodensee-road'),
      },
    );
    expect(items.map((e) => e.id), ['r-bodensee-road', 'gpx-neckar']);
    expect(
      items.where((e) => e.id == 'gpx-neckar').single.privateTour,
      isTrue,
    );
  });

  test('Picker: mehr als zwei Katalog-Touren im Umkreis, ohne Duplikat', () {
    const hdLat = 49.41;
    const hdLng = 8.705;
    final catalog = [
      const RideGroupCatalogHit(
        id: 'r-heidelberg-city',
        name: 'HD',
        lat: 49.41,
        lng: 8.705,
      ),
      const RideGroupCatalogHit(
        id: 'idea-koenigstuhl',
        name: 'Königstuhl',
        lat: 49.398,
        lng: 8.726,
      ),
      const RideGroupCatalogHit(
        id: 'r-karlsruhe-urban',
        name: 'KA',
        lat: 49.01,
        lng: 8.4,
      ),
      const RideGroupCatalogHit(
        id: 'r-stuttgart-urban',
        name: 'S',
        lat: 48.76,
        lng: 9.16,
      ),
      const RideGroupCatalogHit(
        id: 'r-kitz-gravel',
        name: 'Kitz',
        lat: 47.45,
        lng: 12.39,
      ),
    ];
    final items = RideGroupPicker.build(
      saved: [_saved('local-hd')],
      metas: {
        'local-hd': const SavedRouteMeta(catalogTourId: 'r-heidelberg-city'),
      },
      catalog: catalog,
      originLat: hdLat,
      originLng: hdLng,
    );
    final nearby = items
        .where((e) => e.section == RideGroupPickerSection.nearby)
        .toList();
    expect(nearby.length, greaterThan(2));
    expect(nearby.any((e) => e.id == 'r-heidelberg-city'), isFalse);
    expect(
      nearby.every((e) => (e.distanceKm ?? 999) <= RideGroupPicker.nearbyRadiusKm),
      isTrue,
    );
    expect(nearby.any((e) => e.id == 'r-kitz-gravel'), isFalse);
  });

  test('resolveOrigin: GPS vor Karte vor gespeichertem Start', () {
    final saved = _saved(
      'gpx-neckar',
      coordinates: const [
        [8.68, 49.40],
        [8.70, 49.41],
      ],
    );
    final gps = RideGroupPicker.resolveOrigin(
      gpsLat: 49.5,
      gpsLng: 8.5,
      mapLat: 48.1,
      mapLng: 11.5,
      saved: [saved],
    );
    expect(gps?.kind, RideGroupPickerOriginKind.gps);
    expect(gps?.lat, 49.5);
    final map = RideGroupPicker.resolveOrigin(
      mapLat: 48.1,
      mapLng: 11.5,
      saved: [saved],
    );
    expect(map?.kind, RideGroupPickerOriginKind.map);
    final fromSaved = RideGroupPicker.resolveOrigin(saved: [saved]);
    expect(fromSaved?.kind, RideGroupPickerOriginKind.saved);
    expect(fromSaved?.lat, 49.40);
    expect(RideGroupPicker.resolveOrigin(), isNull);
  });
}
