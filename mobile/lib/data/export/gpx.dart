import '../../domain/ride.dart';
import '../../domain/ride/ride_telemetry.dart';

/// True if the ride has enough GPS points for an honest track export.
bool rideHasExportableTrack(RideRecord ride) => ride.track.length >= 2;

/// F-ACC-003 — GPX export for a single ride (web `rideToGpx`).
/// Empty track → valid GPX with empty `<trkseg>` (no fake Berchtesgaden path).
String rideToGpx(RideRecord ride, {String? bikeName}) {
  final name =
      'FlowLine ${ride.startedAt.toUtc().toIso8601String().substring(0, 10)}';
  final pts = ride.track;

  final trkpts = StringBuffer();
  for (var i = 0; i < pts.length; i++) {
    final p = pts[i];
    final lat = (p['lat'] as num?)?.toDouble();
    final lng = (p['lng'] as num?)?.toDouble();
    if (lat == null || lng == null) continue;
    if (lat.abs() < 1e-6 && lng.abs() < 1e-6) continue;
    final elev = p['elev'] ?? p['elevation'];
    DateTime t;
    final timeRaw = p['time'] ?? p['timeMs'];
    if (timeRaw is num) {
      // Epoch-ms, Unix-Sekunden, sonst Sekunden ab Start — wie Web.
      if (timeRaw >= 1e12) {
        t = DateTime.fromMillisecondsSinceEpoch(timeRaw.toInt(), isUtc: true);
      } else if (timeRaw >= 1e9) {
        t = DateTime.fromMillisecondsSinceEpoch(
          (timeRaw * 1000).round(),
          isUtc: true,
        );
      } else {
        t = ride.startedAt
            .toUtc()
            .add(Duration(seconds: timeRaw.round()));
      }
    } else {
      final span = ride.movingTimeSec;
      final frac = pts.length <= 1 ? 0.0 : i / (pts.length - 1);
      t = ride.startedAt.toUtc().add(
            Duration(milliseconds: (span * 1000 * frac).round()),
          );
    }
    trkpts.writeln('      <trkpt lat="$lat" lon="$lng">');
    if (elev is num) {
      trkpts.writeln('        <ele>$elev</ele>');
    }
    trkpts.writeln('        <time>${t.toIso8601String()}</time>');
    final ext = _gpxPointExtensions(p);
    if (ext.isNotEmpty) trkpts.write(ext);
    trkpts.writeln('      </trkpt>');
  }

  final distanceM = (ride.distanceKm * 1000).round();
  final emptyNote = pts.isEmpty
      ? ' · kein GPS-Track'
      : '';
  return '''<?xml version="1.0" encoding="UTF-8"?>
<gpx version="1.1" creator="FlowLine" xmlns="http://www.topografix.com/GPX/1/1" xmlns:gpxtpx="http://www.garmin.com/xmlschemas/TrackPointExtension/v1" xmlns:gpxpx="http://www.garmin.com/xmlschemas/PowerExtension/v1">
  <metadata>
    <name>${_escapeXml(name)}</name>
    <desc>${_escapeXml(bikeName ?? 'Ride')} · $distanceM m · ${honestClimbM(ride.track, ride.elevationM)} hm$emptyNote</desc>
    <time>${ride.startedAt.toUtc().toIso8601String()}</time>
  </metadata>
  <trk>
    <name>${_escapeXml(name)}</name>
    <type>Ride</type>
    <trkseg>
$trkpts    </trkseg>
  </trk>
</gpx>''';
}

String _gpxPointExtensions(Map<String, dynamic> p) {
  final hr = liveHrFromTrackPoint(p);
  final cad = liveCadFromTrackPoint(p);
  final power = livePowerFromTrackPoint(p);
  if (hr == null && cad == null && power == null) return '';
  final b = StringBuffer('        <extensions>\n');
  if (hr != null || cad != null) {
    b.writeln('          <gpxtpx:TrackPointExtension>');
    if (hr != null) b.writeln('            <gpxtpx:hr>$hr</gpxtpx:hr>');
    if (cad != null) b.writeln('            <gpxtpx:cad>$cad</gpxtpx:cad>');
    b.writeln('          </gpxtpx:TrackPointExtension>');
  }
  if (power != null) {
    b.writeln('          <gpxpx:PowerExtension>');
    b.writeln('            <gpxpx:PowerInWatts>$power</gpxpx:PowerInWatts>');
    b.writeln('          </gpxpx:PowerExtension>');
  }
  b.writeln('        </extensions>');
  return b.toString();
}

String _escapeXml(String s) => s
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');
