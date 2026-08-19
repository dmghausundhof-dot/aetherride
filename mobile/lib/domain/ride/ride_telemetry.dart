import '../ride.dart';
import '../routing/route_progress.dart';

/// Post-Ride-Telemetrie — Spiegel [src/lib/ride/rideTelemetry.ts].
/// GPS-Höhe rauschig: Fenster-Neigung, Lücken bleiben Lücken.

enum GradeBand { steepUp, up, roll, down, steepDown, gap }

class RideSample {
  const RideSample({
    required this.distKm,
    required this.lat,
    required this.lng,
    this.elevM,
    this.gradePct,
    required this.band,
    this.speedKmh,
    this.hr,
    this.cad,
    this.power,
    this.lean,
    this.gPeak,
    this.impact = false,
  });

  final double distKm;
  final double lat;
  final double lng;
  final double? elevM;
  final double? gradePct;
  final GradeBand band;
  final double? speedKmh;
  final int? hr;
  final int? cad;
  final int? power;
  final double? lean;
  final double? gPeak;
  final bool impact;
}

class RideChannels {
  const RideChannels({
    required this.elev,
    required this.speed,
    required this.hr,
    required this.cad,
    required this.power,
    required this.lean,
    required this.g,
    required this.impact,
  });

  final bool elev;
  final bool speed;
  final bool hr;
  final bool cad;
  final bool power;
  final bool lean;
  final bool g;
  final bool impact;
}

class GradeLine {
  const GradeLine({
    required this.points,
    required this.colorHex,
    required this.band,
  });

  final List<({double lat, double lng})> points;
  final String colorHex;
  final GradeBand band;
}

class RideTelemetry {
  const RideTelemetry({
    required this.samples,
    required this.chart,
    required this.totalDistKm,
    required this.climbM,
    required this.descentM,
    required this.gapKm,
    this.maxGradePct,
    this.minGradePct,
    this.maxSpeedKmh,
    this.avgSpeedKmh,
    this.avgHr,
    this.maxHr,
    this.avgCad,
    this.avgPower,
    required this.impactCount,
    this.maxLean,
    this.maxG,
    required this.channels,
  });

  final List<RideSample> samples;
  final List<RideSample> chart;
  final double totalDistKm;
  final int climbM;
  final int descentM;
  final double gapKm;
  final double? maxGradePct;
  final double? minGradePct;
  final double? maxSpeedKmh;
  final double? avgSpeedKmh;
  final int? avgHr;
  final int? maxHr;
  final int? avgCad;
  final int? avgPower;
  final int impactCount;
  final double? maxLean;
  final double? maxG;
  final RideChannels channels;

  bool get hasElev => channels.elev;
}

const _gradeWindowM = 35.0;
const _gradeMinM = 18.0;
const _smoothRadiusM = 40.0;
const _climbStepM = 1.2;
const _maxAbsGrade = 45.0;
const _maxSpeedKmh = 85.0;
const _chartMax = 240;
const _mapMax = 90;

const Map<GradeBand, String> kGradeColors = {
  GradeBand.steepUp: '#C2410C',
  GradeBand.up: '#FF6A00',
  GradeBand.roll: '#7A8B73',
  GradeBand.down: '#5B8C9A',
  GradeBand.steepDown: '#3D6B8A',
  GradeBand.gap: '#6B7280',
};

GradeBand gradeBand(double? gradePct) {
  if (gradePct == null || gradePct.isNaN) return GradeBand.gap;
  if (gradePct > 8) return GradeBand.steepUp;
  if (gradePct > 3) return GradeBand.up;
  if (gradePct >= -3) return GradeBand.roll;
  if (gradePct >= -8) return GradeBand.down;
  return GradeBand.steepDown;
}

RideTelemetry emptyRideTelemetry() => const RideTelemetry(
      samples: [],
      chart: [],
      totalDistKm: 0,
      climbM: 0,
      descentM: 0,
      gapKm: 0,
      impactCount: 0,
      channels: RideChannels(
        elev: false,
        speed: false,
        hr: false,
        cad: false,
        power: false,
        lean: false,
        g: false,
        impact: false,
      ),
    );

RideTelemetry buildRideTelemetry(List<Map<String, dynamic>> track) {
  if (track.length < 2) return emptyRideTelemetry();

  final raw = <_Raw>[];
  for (final p in track) {
    final lat = (p['lat'] as num?)?.toDouble() ??
        (p['latitude'] as num?)?.toDouble();
    final lng = (p['lng'] as num?)?.toDouble() ??
        (p['lon'] as num?)?.toDouble() ??
        (p['longitude'] as num?)?.toDouble();
    if (lat == null || lng == null) continue;
    if (lat.abs() < 1e-6 && lng.abs() < 1e-6) continue;
    final elev = _elev(p);
    raw.add(
      _Raw(
        lat: lat,
        lng: lng,
        elev: elev,
        timeMs: _timeMs(p),
        hr: liveHrFromTrackPoint(p),
        cad: liveCadFromTrackPoint(p),
        power: livePowerFromTrackPoint(p),
        lean: liveLeanFromTrackPoint(p),
        gPeak: liveGFromTrackPoint(p),
        impact: liveImpactFromTrackPoint(p),
        spd: liveSpeedFromTrackPoint(p),
      ),
    );
  }
  if (raw.length < 2) return emptyRideTelemetry();

  final distM = List<double>.filled(raw.length, 0);
  for (var i = 1; i < raw.length; i++) {
    distM[i] = distM[i - 1] +
        haversineM(raw[i - 1].lat, raw[i - 1].lng, raw[i].lat, raw[i].lng);
  }

  final smoothed = List<double?>.filled(raw.length, null);
  for (var i = 0; i < raw.length; i++) {
    final e = raw[i].elev;
    if (e == null) continue;
    final lo = distM[i] - _smoothRadiusM;
    final hi = distM[i] + _smoothRadiusM;
    var sum = 0.0;
    var n = 0;
    for (var j = 0; j < raw.length; j++) {
      final ej = raw[j].elev;
      if (ej == null) continue;
      if (distM[j] < lo) continue;
      if (distM[j] > hi) break;
      sum += ej;
      n += 1;
    }
    smoothed[i] = n == 0 ? e : sum / n;
  }

  var climbM = 0.0;
  var descentM = 0.0;
  var gapKm = 0.0;
  var prevElev = smoothed[0];
  var prevDist = 0.0;
  for (var i = 1; i < raw.length; i++) {
    final e = smoothed[i];
    final dKm = (distM[i] - prevDist) / 1000;
    if (e == null) {
      gapKm += dKm;
      prevDist = distM[i];
      continue;
    }
    if (prevElev != null) {
      final d = e - prevElev;
      if (d > _climbStepM) {
        climbM += d;
      } else if (d < -_climbStepM) {
        descentM += -d;
      }
    }
    prevElev = e;
    prevDist = distM[i];
  }

  final samples = <RideSample>[];
  for (var i = 0; i < raw.length; i++) {
    double? gradePct;
    if (smoothed[i] != null && i > 0) {
      final j = _lookBack(distM, i, _gradeWindowM);
      final span = distM[i] - distM[j];
      final a = smoothed[j];
      final b = smoothed[i];
      if (a != null && b != null && span >= _gradeMinM) {
        final g = ((b - a) / span) * 100;
        if (g.isFinite) {
          gradePct = ((g.clamp(-_maxAbsGrade, _maxAbsGrade)) * 10).round() / 10;
        }
      }
    }

    var speed = raw[i].spd;
    final t0 = raw[i].timeMs;
    final t1 = i > 0 ? raw[i - 1].timeMs : null;
    if (speed == null && t0 != null && t1 != null) {
      final dt = (t0 - t1) / 1000.0;
      final hop = distM[i] - distM[i - 1];
      final maxDt = hop >= 15 ? 900 : 30;
      if (dt >= 0.4 && dt <= maxDt && hop >= 0) {
        final v = (hop / dt) * 3.6;
        if (v >= 0.4 && v <= _maxSpeedKmh) {
          speed = (v * 10).round() / 10;
        }
      }
    }

    samples.add(
      RideSample(
        distKm: ((distM[i] / 1000) * 1000).round() / 1000,
        lat: raw[i].lat,
        lng: raw[i].lng,
        elevM: smoothed[i] == null
            ? null
            : (smoothed[i]! * 10).round() / 10,
        gradePct: gradePct,
        band: gradeBand(gradePct),
        speedKmh: speed,
        hr: raw[i].hr,
        cad: raw[i].cad,
        power: raw[i].power,
        lean: raw[i].lean,
        gPeak: raw[i].gPeak,
        impact: raw[i].impact,
      ),
    );
  }

  final elevs = [for (final s in samples) if (s.elevM != null) s.elevM!];
  final grades = [for (final s in samples) if (s.gradePct != null) s.gradePct!];
  final speeds = [for (final s in samples) if (s.speedKmh != null) s.speedKmh!];
  final hrs = [for (final s in samples) if (s.hr != null) s.hr!];
  final cads = [for (final s in samples) if (s.cad != null) s.cad!];
  final powers = [for (final s in samples) if (s.power != null) s.power!];
  final leans = [for (final s in samples) if (s.lean != null) s.lean!];
  final gs = [for (final s in samples) if (s.gPeak != null) s.gPeak!];
  final impacts = samples.where((s) => s.impact).length;

  final channels = RideChannels(
    elev: elevs.length >= 2,
    speed: speeds.length >= 2,
    hr: hrs.length >= 2,
    cad: cads.length >= 2,
    power: powers.length >= 2,
    lean: leans.length >= 2,
    g: gs.length >= 2,
    impact: impacts > 0,
  );

  return RideTelemetry(
    samples: samples,
    chart: _downsample(samples, _chartMax, (s) => s.impact),
    totalDistKm: ((distM.last / 1000) * 100).round() / 100,
    climbM: climbM.round(),
    descentM: descentM.round(),
    gapKm: (gapKm * 100).round() / 100,
    maxGradePct: grades.isEmpty ? null : grades.reduce((a, b) => a > b ? a : b),
    minGradePct: grades.isEmpty ? null : grades.reduce((a, b) => a < b ? a : b),
    maxSpeedKmh: speeds.isEmpty ? null : speeds.reduce((a, b) => a > b ? a : b),
    avgSpeedKmh: _mean(speeds),
    avgHr: hrs.isEmpty ? null : (_sumInt(hrs) / hrs.length).round(),
    maxHr: hrs.isEmpty ? null : hrs.reduce((a, b) => a > b ? a : b),
    avgCad: cads.isEmpty ? null : (_sumInt(cads) / cads.length).round(),
    avgPower: powers.isEmpty ? null : (_sumInt(powers) / powers.length).round(),
    impactCount: impacts,
    maxLean: leans.isEmpty
        ? null
        : leans.map((e) => e.abs()).reduce((a, b) => a > b ? a : b),
    maxG: gs.isEmpty ? null : gs.reduce((a, b) => a > b ? a : b),
    channels: channels,
  );
}

List<GradeLine> gradeMapLayers(RideTelemetry telemetry) {
  final pts = _downsample(telemetry.samples, _mapMax, (_) => false);
  if (pts.length < 2) return const [];
  final out = <GradeLine>[];
  var start = 0;
  var band = pts.first.band;
  void flush(int end) {
    final slice = pts.sublist(start, end + 1);
    if (slice.length < 2) return;
    out.add(
      GradeLine(
        points: [
          for (final p in slice) (lat: p.lat, lng: p.lng),
        ],
        colorHex: kGradeColors[band]!,
        band: band,
      ),
    );
  }

  for (var i = 1; i < pts.length; i++) {
    if (pts[i].band != band) {
      flush(i);
      start = i;
      band = pts[i].band;
    }
  }
  flush(pts.length - 1);
  return out;
}

class _Raw {
  const _Raw({
    required this.lat,
    required this.lng,
    required this.elev,
    required this.timeMs,
    required this.hr,
    required this.cad,
    required this.power,
    required this.lean,
    required this.gPeak,
    required this.impact,
    required this.spd,
  });

  final double lat;
  final double lng;
  final double? elev;
  final int? timeMs;
  final int? hr;
  final int? cad;
  final int? power;
  final double? lean;
  final double? gPeak;
  final bool impact;
  final double? spd;
}

double? _elev(Map<String, dynamic> p) {
  final v = p['elev'] ?? p['ele'] ?? p['altitude'];
  if (v is! num) return null;
  final n = v.toDouble();
  if (n < -50 || n > 8900) return null;
  return n;
}

int? _timeMs(Map<String, dynamic> p) {
  final v = p['time'] ?? p['timeMs'];
  if (v is! num) return null;
  final n = v.toDouble();
  if (n >= 1e12) return n.round();
  if (n >= 1e9) return (n * 1000).round();
  return n.round();
}

int _lookBack(List<double> distM, int i, double windowM) {
  var j = i;
  while (j > 0 && distM[i] - distM[j] < windowM) {
    j -= 1;
  }
  return j;
}

List<T> _downsample<T>(
  List<T> items,
  int max,
  bool Function(T) keep,
) {
  if (items.length <= max) return items;
  final taken = <int>{};
  final step = (items.length - 1) / (max - 1);
  for (var i = 0; i < max; i++) {
    taken.add((i * step).round());
  }
  for (var i = 0; i < items.length; i++) {
    if (keep(items[i])) taken.add(i);
  }
  final idxs = taken.toList()..sort();
  return [for (final i in idxs) items[i]];
}

double? _mean(List<double> values) {
  if (values.isEmpty) return null;
  return (values.reduce((a, b) => a + b) / values.length * 10).round() / 10;
}

/// Persistierte Höhenmeter: Telemetrie-Anstieg, sonst gespeicherter Wert.
int honestClimbM(List<Map<String, dynamic>> track, [num storedM = 0]) {
  final tel = buildRideTelemetry(track);
  if (tel.hasElev) return tel.climbM;
  final s = storedM.round();
  return s > 0 ? s : 0;
}

RideSample? nearestSample(RideTelemetry telemetry, double distKm) {
  final pts = telemetry.chart.isNotEmpty ? telemetry.chart : telemetry.samples;
  if (pts.isEmpty) return null;
  var best = pts.first;
  var bestD = (best.distKm - distKm).abs();
  for (final p in pts.skip(1)) {
    final d = (p.distKm - distKm).abs();
    if (d < bestD) {
      best = p;
      bestD = d;
    }
  }
  return best;
}

/// Kurze Zeile für Peek — nur was der Track wirklich trägt.
String? terrainCaption(RideTelemetry telemetry, [String hm = 'hm']) {
  if (!telemetry.hasElev) return null;
  final parts = <String>['${telemetry.climbM} $hm'];
  if (telemetry.descentM > 0) parts.add('${telemetry.descentM} $hm ↓');
  if (telemetry.maxGradePct != null) {
    final g = telemetry.maxGradePct!;
    parts.add('${g > 0 ? '+' : ''}${g.toStringAsFixed(0)} %');
  }
  return parts.join(' · ');
}

int _sumInt(List<int> values) => values.fold(0, (a, b) => a + b);
