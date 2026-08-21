/// Pin-Cluster für Discover — Komoot stapelt, wir blenden nicht einfach weg.
library;

import 'dart:math' as math;

import 'browse_lod.dart';

class BrowseMapPoint {
  const BrowseMapPoint({
    required this.id,
    required this.lat,
    required this.lng,
    required this.popularity,
    this.selected = false,
    this.hasPhoto = false,
  });

  final String id;
  final double lat;
  final double lng;
  final int popularity;
  final bool selected;
  final bool hasPhoto;
}

class BrowseCluster {
  const BrowseCluster({
    required this.lat,
    required this.lng,
    required this.members,
  });

  final double lat;
  final double lng;
  final List<BrowseMapPoint> members;

  int get count => members.length;
  bool get isSingle => members.length == 1;
  BrowseMapPoint get primary => members.first;
  int get popularity {
    var m = 0;
    for (final p in members) {
      if (p.popularity > m) m = p.popularity;
    }
    return m;
  }

  bool get hasPhoto => members.any((m) => m.hasPhoto);
}

/// Radius in km. 0 = nicht clustern.
double browseClusterRadiusKm(BrowseLodId lod) => switch (lod) {
      BrowseLodId.overview => 18,
      BrowseLodId.network => 5,
      BrowseLodId.character => 0.7,
      BrowseLodId.detail => 0,
    };

double browseHaversineKm(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371.0;
  const rad = math.pi / 180;
  final p1 = lat1 * rad;
  final p2 = lat2 * rad;
  final dLat = (lat2 - lat1) * rad;
  final dLng = (lng2 - lng1) * rad;
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(p1) * math.cos(p2) * math.sin(dLng / 2) * math.sin(dLng / 2);
  return 2 * r * math.asin(math.sqrt(a.clamp(0.0, 1.0)));
}

/// Greedy cluster: beliebte zuerst, Selected bleibt allein.
List<BrowseCluster> clusterBrowsePins({
  required List<BrowseMapPoint> points,
  required BrowseLodId lod,
}) {
  final radius = browseClusterRadiusKm(lod);
  if (radius <= 0 || points.length <= 1) {
    return [
      for (final p in points)
        BrowseCluster(lat: p.lat, lng: p.lng, members: [p]),
    ];
  }

  final selected = [for (final p in points) if (p.selected) p];
  final rest = [for (final p in points) if (!p.selected) p];
  rest.sort((a, b) => b.popularity.compareTo(a.popularity));

  final out = <BrowseCluster>[
    for (final p in selected)
      BrowseCluster(lat: p.lat, lng: p.lng, members: [p]),
  ];
  final used = <String>{for (final p in selected) p.id};

  for (final p in rest) {
    if (used.contains(p.id)) continue;
    final members = <BrowseMapPoint>[p];
    used.add(p.id);
    for (final q in rest) {
      if (used.contains(q.id)) continue;
      if (browseHaversineKm(p.lat, p.lng, q.lat, q.lng) <= radius) {
        members.add(q);
        used.add(q.id);
      }
    }
    var lat = 0.0, lng = 0.0;
    for (final m in members) {
      lat += m.lat;
      lng += m.lng;
    }
    out.add(
      BrowseCluster(
        lat: lat / members.length,
        lng: lng / members.length,
        members: members,
      ),
    );
  }
  return out;
}
