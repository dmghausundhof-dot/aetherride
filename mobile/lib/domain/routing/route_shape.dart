import 'dart:math' as math;

/// Form einer Tour, ausschließlich aus ihrer Geometrie abgeleitet.
///
/// Bewusst kein Quellen-Feld: Outdooractive und OSM liefern keine verlässliche
/// Angabe, ob eine Tour geschlossen ist. Wer sie trotzdem pro Quelle hart
/// setzt, zeigt Nutzer:innen eine erfundene Eigenschaft als Tatsache an.
enum RouteShape {
  /// Start und Ziel fallen zusammen.
  loop,

  /// Start und Ziel liegen auseinander.
  pointToPoint,
}

double _haversineKm(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371.0;
  final dLat = (lat2 - lat1) * math.pi / 180;
  final dLng = (lng2 - lng1) * math.pi / 180;
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(lat1 * math.pi / 180) *
          math.cos(lat2 * math.pi / 180) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  return 2 * r * math.asin(math.sqrt(a.clamp(0.0, 1.0)));
}

/// Form einer Polyline `[[lng, lat], …]`.
///
/// Gibt `null` zurück, wenn die Geometrie keine belastbare Aussage zulässt —
/// zu wenige Punkte oder unter 1 km Gesamtlänge. `null` heißt „unbekannt"
/// und gehört als Leerstelle in die UI, nicht als Rateversuch.
RouteShape? routeShapeOf(List<List<double>>? track) {
  if (track == null || track.length < 4) return null;

  var lengthKm = 0.0;
  for (var i = 1; i < track.length; i++) {
    final a = track[i - 1];
    final b = track[i];
    if (a.length < 2 || b.length < 2) return null;
    lengthKm += _haversineKm(a[1], a[0], b[1], b[0]);
  }
  if (lengthKm < 1) return null;

  final gapKm = _haversineKm(
    track.first[1],
    track.first[0],
    track.last[1],
    track.last[0],
  );
  // Lücke unter 5 % der Streckenlänge (mindestens 250 m Toleranz für
  // GPS-Rauschen und Trailhead-Parkplätze) gilt als geschlossen.
  return gapKm < math.max(0.25, lengthKm * 0.05)
      ? RouteShape.loop
      : RouteShape.pointToPoint;
}

/// Anzeigetext, oder `null` wenn die Form unbekannt ist.
String? routeShapeLabel(List<List<double>>? track) =>
    switch (routeShapeOf(track)) {
      RouteShape.loop => 'Rundkurs',
      RouteShape.pointToPoint => 'Strecke',
      null => null,
    };
