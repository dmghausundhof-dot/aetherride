import '../bike.dart';
import '../component.dart';
import '../ride.dart';
import '../ride/ride_telemetry.dart';

class WearForecast {
  const WearForecast({
    required this.slot,
    required this.remainingKmLow,
    required this.remainingKmHigh,
    required this.sourceLabel,
    required this.dueSoon,
  });

  final ComponentSlot slot;
  final int remainingKmLow;
  final int remainingKmHigh;
  final String sourceLabel;
  final bool dueSoon;
}

BikeComponent? _active(List<BikeComponent> comps, ComponentSlot slot) {
  for (final c in comps) {
    if (c.isInstalled && c.slot == slot) return c;
  }
  return null;
}

List<RideRecord> _ridesFor(
  BikeComponent comp,
  String bikeId,
  List<RideRecord> rides,
) {
  final start = comp.installedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
  final end = comp.removedAt ?? DateTime.now();
  return [
    for (final r in rides)
      if (r.bikeId == bikeId &&
          !r.startedAt.isBefore(start) &&
          !r.startedAt.isAfter(end))
        r,
  ];
}

double _sumKm(List<RideRecord> rides) =>
    rides.fold(0, (s, r) => s + r.distanceKm);

double _sumHours(List<RideRecord> rides) =>
    rides.fold(0, (s, r) => s + r.movingTimeSec / 3600);

int _sumImpacts(List<RideRecord> rides) {
  var n = 0;
  for (final r in rides) {
    final v = r.summary['impactCount'];
    if (v is num) n += v.toInt();
  }
  return n;
}

double _sumDescent(List<RideRecord> rides) {
  var m = 0.0;
  for (final r in rides) {
    m += honestClimbM(r.track, r.elevationM);
  }
  return m;
}

double _wetShare(List<RideRecord> rides) {
  if (rides.isEmpty) return 0.15;
  final wet = rides.where((r) {
    final notes = '${r.name ?? ''} ${r.summary['notes'] ?? ''}';
    return RegExp(r'nass|regen|wet|mud|matsch|schlamm', caseSensitive: false)
        .hasMatch(notes);
  }).length;
  return wet / rides.length;
}

({int low, int high, double ratio}) _remaining(
  double lifeLow,
  double lifeHigh,
  double used,
) {
  final mid = (lifeLow + lifeHigh) / 2;
  return (
    low: (lifeLow - used).clamp(0, 1e9).round(),
    high: (lifeHigh - used * 0.85).clamp(0, 1e9).round(),
    ratio: used / mid,
  );
}

/// Load-weighted range, never a point. Mirrors web `forecastWear`.
List<WearForecast> forecastWear({
  required Bike bike,
  required List<BikeComponent> components,
  required List<RideRecord> rides,
}) {
  final out = <WearForecast>[];
  final eFactor = bike.hasElectricAssist ? 0.7 : 1.0;
  final roadish = bike.category == BikeCategory.road ||
      bike.category == BikeCategory.gravel;

  final chain = _active(components, ComponentSlot.chain);
  if (chain != null) {
    final rr = _ridesFor(chain, bike.id, rides);
    final wet = _wetShare(rr);
    final effective =
        (_sumKm(rr) / eFactor) * (1 + wet * 0.35) + _sumHours(rr) * 8;
    final lifeLow = roadish ? 1500.0 : 1000.0;
    final lifeHigh = roadish ? 3000.0 : 1800.0;
    final rem = _remaining(lifeLow, lifeHigh, effective);
    out.add(
      WearForecast(
        slot: ComponentSlot.chain,
        remainingKmLow: rem.low,
        remainingKmHigh: rem.high,
        sourceLabel: 'Velopit 2026 · Bavarian Bike · BIKE Magazin · Linexo',
        dueSoon: rem.ratio >= 0.75,
      ),
    );
  }

  for (final slot in [ComponentSlot.brakeFront, ComponentSlot.brakeRear]) {
    final pads = _active(components, slot);
    if (pads == null) continue;
    final rr = _ridesFor(pads, bike.id, rides);
    final descent = _sumDescent(rr);
    final impacts = _sumImpacts(rr);
    final wet = _wetShare(rr);
    final rear = slot == ComponentSlot.brakeRear;
    final effective = rear
        ? descent / 35 +
            impacts * 2.2 +
            _sumKm(rr) * 0.35 +
            wet * _sumKm(rr) * 0.45
        : descent / 40 +
            impacts * 2 +
            _sumKm(rr) * 0.3 +
            wet * _sumKm(rr) * 0.4;
    final rem = _remaining(rear ? 700 : 800, rear ? 2200 : 2500, effective);
    out.add(
      WearForecast(
        slot: slot,
        remainingKmLow: rem.low,
        remainingKmHigh: rem.high,
        sourceLabel: 'Velopit MTB-Wartung · BIKE Magazin',
        dueSoon: rem.ratio >= 0.75,
      ),
    );
  }

  final cassette = _active(components, ComponentSlot.cassette);
  if (cassette != null) {
    final km = _sumKm(_ridesFor(cassette, bike.id, rides)) / eFactor;
    final rem = _remaining(3000, 5000, km);
    out.add(
      WearForecast(
        slot: ComponentSlot.cassette,
        remainingKmLow: rem.low,
        remainingKmHigh: rem.high,
        sourceLabel: 'Velopit 2026 · Bavarian Bike',
        dueSoon: rem.ratio >= 0.8,
      ),
    );
  }

  final tire = _active(components, ComponentSlot.tireFront);
  if (tire != null) {
    final km = _sumKm(_ridesFor(tire, bike.id, rides));
    final rem = _remaining(roadish ? 3000 : 1500, roadish ? 7000 : 4000, km);
    out.add(
      WearForecast(
        slot: ComponentSlot.tireFront,
        remainingKmLow: rem.low,
        remainingKmHigh: rem.high,
        sourceLabel: 'Velopit Serviceintervalle 2026',
        dueSoon: rem.ratio >= 0.85,
      ),
    );
  }

  return out;
}
