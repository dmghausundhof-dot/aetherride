import 'dart:math' as math;

import '../saved_route.dart';
import '../saved_route_note.dart';
import '../tours/route_visibility.dart';
import '../tours/tour_akte.dart';
import 'ride_group_policy.dart';

enum RideGroupPickerSection { mine, nearby }

enum RideGroupPickerOriginKind { gps, map, saved }

class RideGroupPickerOrigin {
  const RideGroupPickerOrigin({
    required this.lat,
    required this.lng,
    required this.kind,
  });

  final double lat;
  final double lng;
  final RideGroupPickerOriginKind kind;
}

class RideGroupPickerItem {
  const RideGroupPickerItem({
    required this.id,
    required this.name,
    required this.section,
    this.catalogTourId,
    this.privateTour = false,
    this.distanceKm,
  });

  final String id;
  final String name;
  final RideGroupPickerSection section;
  final String? catalogTourId;
  final bool privateTour;
  final double? distanceKm;
}

class RideGroupCatalogHit {
  const RideGroupCatalogHit({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
  });

  final String id;
  final String name;
  final double lat;
  final double lng;
}

/// Tour-Auswahl beim Anlegen einer Fahrgruppe.
/// Eigene (auch private) zuerst; Katalog in der Nähe extra — nicht Explore.
abstract final class RideGroupPicker {
  /// Weiter als Discover-Coverage (90 km), damit der Picker nicht bei 1–2 Pins endet.
  static const nearbyRadiusKm = 180.0;
  static const nearbyMax = 40;

  static ({double lat, double lng})? savedRouteStart(SavedRouteEntry route) {
    for (final w in route.waypoints) {
      if (w.role == 'start') return (lat: w.lat, lng: w.lng);
    }
    if (route.coordinates.isNotEmpty && route.coordinates.first.length >= 2) {
      return (
        lat: route.coordinates.first[1],
        lng: route.coordinates.first[0],
      );
    }
    return null;
  }

  /// GPS → letzte Discover-Karte → Start der neuesten eigenen Tour.
  static RideGroupPickerOrigin? resolveOrigin({
    double? gpsLat,
    double? gpsLng,
    double? mapLat,
    double? mapLng,
    List<SavedRouteEntry> saved = const [],
  }) {
    if (gpsLat != null &&
        gpsLng != null &&
        gpsLat.isFinite &&
        gpsLng.isFinite) {
      return RideGroupPickerOrigin(
        lat: gpsLat,
        lng: gpsLng,
        kind: RideGroupPickerOriginKind.gps,
      );
    }
    if (mapLat != null &&
        mapLng != null &&
        mapLat.isFinite &&
        mapLng.isFinite) {
      return RideGroupPickerOrigin(
        lat: mapLat,
        lng: mapLng,
        kind: RideGroupPickerOriginKind.map,
      );
    }
    final sorted = List<SavedRouteEntry>.from(saved)
      ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
    for (final s in sorted) {
      final start = savedRouteStart(s);
      if (start == null) continue;
      return RideGroupPickerOrigin(
        lat: start.lat,
        lng: start.lng,
        kind: RideGroupPickerOriginKind.saved,
      );
    }
    return null;
  }

  static List<RideGroupPickerItem> build({
    required List<SavedRouteEntry> saved,
    required Map<String, SavedRouteMeta> metas,
    List<RideGroupCatalogHit> catalog = const [],
    double? originLat,
    double? originLng,
  }) {
    final mine = <RideGroupPickerItem>[];
    final taken = <String>{};
    final sorted = List<SavedRouteEntry>.from(saved)
      ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
    for (final s in sorted) {
      if (!RideGroupPolicy.canAttachSaved(s, metas[s.id])) continue;
      final meta = metas[s.id] ?? SavedRouteMeta.empty;
      final catalogId = catalogTourIdOf(s.id, meta);
      mine.add(
        RideGroupPickerItem(
          id: s.id,
          name: s.name,
          section: RideGroupPickerSection.mine,
          catalogTourId: catalogId,
          privateTour: !RouteVisibility.isShared(meta) && catalogId == null,
        ),
      );
      taken.add(s.id);
      if (catalogId != null) taken.add(catalogId);
    }

    final nearby = <RideGroupPickerItem>[];
    if (originLat != null &&
        originLng != null &&
        originLat.isFinite &&
        originLng.isFinite) {
      final ranked = <({RideGroupCatalogHit hit, double km})>[];
      for (final hit in catalog) {
        if (hit.id.trim().isEmpty || taken.contains(hit.id)) continue;
        if (!RideGroupPolicy.canAttachCourse(hit.id, SavedRouteMeta.empty)) {
          continue;
        }
        final km = _haversineKm(originLat, originLng, hit.lat, hit.lng);
        if (km > nearbyRadiusKm) continue;
        ranked.add((hit: hit, km: km));
      }
      ranked.sort((a, b) => a.km.compareTo(b.km));
      for (final row in ranked.take(nearbyMax)) {
        nearby.add(
          RideGroupPickerItem(
            id: row.hit.id,
            name: row.hit.name,
            section: RideGroupPickerSection.nearby,
            catalogTourId: row.hit.id,
            distanceKm: row.km,
          ),
        );
      }
    }
    return [...mine, ...nearby];
  }

  static double _haversineKm(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const r = 6371.0;
    final la1 = lat1 * math.pi / 180;
    final la2 = lat2 * math.pi / 180;
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLng = (lng2 - lng1) * math.pi / 180;
    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(la1) * math.cos(la2) * math.sin(dLng / 2) * math.sin(dLng / 2);
    return 2 * r * math.asin(math.sqrt(h.clamp(0.0, 1.0)));
  }
}
