import '../../data/routing/naehe_seeds.dart';
import '../bike.dart';
import '../ride.dart';
import '../routing/duration_lens.dart';
import '../routing/route_progress.dart';
import '../routing/tour_filters.dart';
import '../saved_route.dart';

/// Honesty of the hour at the gate — never invent a loop for the wrong region.
enum HofGateHonesty {
  /// A real ~60 min loop (seed or saved) in the rider's region.
  loop,

  /// Trails wet and no honest asphalt alternative nearby.
  wetClosed,

  /// No GPS-region loop and no saved route in the time window.
  none,
}

class HofGatePick {
  const HofGatePick({
    this.seed,
    this.saved,
    this.honesty = HofGateHonesty.none,
    this.distanceKm,
  });

  final NaeheSeedRoute? seed;
  final SavedRouteEntry? saved;
  final HofGateHonesty honesty;
  final double? distanceKm;

  bool get hasLoop => seed != null || saved != null;

  String get title => seed?.title ?? saved?.name ?? '';

  int get durationMin => seed?.durationMin ?? saved?.durationMin ?? 0;

  String? get id => seed?.id ?? saved?.id;
}

/// GPS-Abstand zum Loop vor dem Tor. Spürbar näher als eine 40-km-„Stunde“.
const double kHofGateMaxDistanceKm = 15;

/// One nearby ~60 min loop. GPS picks the region — never a Rhein-Neckar default.
///
/// [maxDistanceKm] keeps Hamburg from seeing the Alps. Without GPS, seeds are
/// skipped (wrong landscape); a saved route in the duration band may still show.
/// [preferred] / [preferredSports] rank matching sports first (Haupt, dann
/// übrige), then the nearest honest loop.
HofGatePick pickHofGate({
  required List<NaeheSeedRoute> loops,
  List<SavedRouteEntry> saved = const [],
  double? lat,
  double? lng,
  bool trailsWet = false,
  int targetMin = 60,
  double maxDistanceKm = kHofGateMaxDistanceKm,
  BikeCategory? preferred,
  List<BikeCategory> preferredSports = const [],
}) {
  SavedRouteEntry? savedInWindow() {
    // Hof ist persönlich: eigene private Touren dürfen am Tor stehen.
    for (final r in saved) {
      if (DurationLens.inBand(r.durationMin, targetMin) &&
          r.distanceKm > 0 &&
          r.distanceKm <= 40) {
        return r;
      }
    }
    return null;
  }

  if (lat != null && lng != null) {
    final ranked = <(NaeheSeedRoute, double)>[];
    for (final r in loops) {
      if (!r.isLoop || !r.isRoute) continue;
      if (!DurationLens.inBand(r.durationMin, targetMin)) continue;
      final d = haversineM(lat, lng, r.centerLat, r.centerLng) / 1000.0;
      if (d > maxDistanceKm) continue;
      ranked.add((r, d));
    }
    ranked.sort((a, b) => a.$2.compareTo(b.$2));

    if (trailsWet) {
      for (final e in ranked) {
        if (!isTrailHeavyLoop(e.$1)) {
          return HofGatePick(
            seed: e.$1,
            honesty: HofGateHonesty.loop,
            distanceKm: e.$2,
          );
        }
      }
      return const HofGatePick(honesty: HofGateHonesty.wetClosed);
    }

    if (ranked.isNotEmpty) {
      final prefs = <BikeCategory>[
        if (preferred != null) preferred,
        for (final s in preferredSports)
          if (s != preferred) s,
      ];
      for (final pref in prefs) {
        for (final e in ranked) {
          if (TourFilters.softSportMatch(e.$1.categories, pref)) {
            return HofGatePick(
              seed: e.$1,
              honesty: HofGateHonesty.loop,
              distanceKm: e.$2,
            );
          }
        }
      }
      return HofGatePick(
        seed: ranked.first.$1,
        honesty: HofGateHonesty.loop,
        distanceKm: ranked.first.$2,
      );
    }
  }

  if (!trailsWet) {
    final s = savedInWindow();
    if (s != null) {
      return HofGatePick(saved: s, honesty: HofGateHonesty.loop);
    }
  } else {
    return const HofGatePick(honesty: HofGateHonesty.wetClosed);
  }

  return const HofGatePick(honesty: HofGateHonesty.none);
}

/// Title when the gate has no loop. Wet-closed is not “no loop exists”.
String hofGateEmptyTitle({
  required HofGateHonesty honesty,
  required String wetClosed,
  required String noLoop,
}) {
  return honesty == HofGateHonesty.wetClosed ? wetClosed : noLoop;
}

/// Trail/MTB loops are not an honest gate hour when the ground is wet.
bool isTrailHeavyLoop(NaeheSeedRoute route) {
  final id = route.id.toLowerCase();
  if (id.contains('mtb') || id.contains('trail')) return true;
  final key = TourFilters.parseSurface(route.surfaceTag);
  return key == TourSurfaceKey.trail || key == TourSurfaceKey.gravel;
}

/// Unter dieser Distanz/Zeit zählt die Fahrt nicht als „gerade zurück“.
const double kMinJustBackDistanceKm = 1.0;
const int kMinJustBackMovingSec = 180;

bool isCountableRide({
  required double distanceKm,
  required int movingTimeSec,
}) {
  return distanceKm >= kMinJustBackDistanceKm &&
      movingTimeSec >= kMinJustBackMovingSec;
}

/// Last ride on this bike — return, not a kudos wall.
RideReturn rideReturnForBike({
  required String bikeId,
  required List<RideRecord> rides,
  DateTime? now,
  Duration justBackWindow = const Duration(hours: 4),
}) {
  final clock = now ?? DateTime.now();
  RideRecord? last;
  for (final r in rides) {
    if (r.bikeId != bikeId) continue;
    if (r.endedAt == null) continue;
    last = r;
    break;
  }
  if (last == null) return const RideReturn(kind: RideReturnKind.neverOut);
  final end = last.endedAt ?? last.startedAt;
  final justBack = clock.difference(end) <= justBackWindow &&
      isCountableRide(
        distanceKm: last.distanceKm,
        movingTimeSec: last.movingTimeSec,
      );
  if (justBack) {
    return RideReturn(
      kind: RideReturnKind.justBack,
      rideId: last.id,
      distanceKm: last.distanceKm,
      movingTimeSec: last.movingTimeSec,
      endedAt: end,
      usedGps: last.summary['usingGps'] == true,
      name: last.name,
    );
  }
  final days = clock.difference(end).inDays;
  return RideReturn(
    kind: RideReturnKind.atHof,
    rideId: last.id,
    daysSince: days < 1 ? 1 : days,
    endedAt: end,
    usedGps: last.summary['usingGps'] == true,
    name: last.name,
  );
}

enum RideReturnKind { neverOut, justBack, atHof }

class RideReturn {
  const RideReturn({
    required this.kind,
    this.rideId,
    this.daysSince,
    this.distanceKm,
    this.movingTimeSec,
    this.endedAt,
    this.usedGps = false,
    this.name,
  });

  final RideReturnKind kind;
  final String? rideId;
  final int? daysSince;
  final double? distanceKm;
  final int? movingTimeSec;
  final DateTime? endedAt;
  final bool usedGps;
  final String? name;

  bool get hidesGate => kind == RideReturnKind.justBack;
}

String formatMovingTime(int sec) {
  final h = sec ~/ 3600;
  final m = ((sec % 3600) / 60).round();
  if (h <= 0) return '$m min';
  return '$h:${m.toString().padLeft(2, '0')}';
}

class HofAgo {
  const HofAgo(this.label, {required this.underHour});
  final String label;
  final bool underHour;
}

/// Sport-Zeile am Stand. Motor am Rad zählt als Assist — ohne Flag zu erfinden.
String hofResidentSport(Bike bike, {bool hasMotor = false}) {
  if (hasMotor && !bike.hasElectricAssist) {
    return bike.copyWith(isEbike: true).categoryLabel;
  }
  return bike.categoryLabel;
}

/// Stand-Meta: justBack ohne GPS zeigt keine 0 km / 0 min.
/// Nach einer Stunde fällt „gerade“ weg — die Zeit reicht.
HofAgo? hofAgoLabel({
  required DateTime? endedAt,
  required DateTime now,
  required String Function(int minutes) minutes,
  required String Function(int hours) hours,
}) {
  if (endedAt == null) return null;
  final m = now.difference(endedAt).inMinutes;
  if (m < 60) {
    return HofAgo(minutes(m < 1 ? 1 : m), underHour: true);
  }
  if (m < 24 * 60) {
    return HofAgo(hours((m / 60).floor().clamp(1, 23)), underHour: false);
  }
  return null;
}

/// GPS-Abstand zum Loop vor dem Tor. Kein Loop-Kilometer, kein Schätzwert.
String? formatHofGateAway({
  required double? distanceKm,
  required String underOne,
  required String Function(int km) km,
}) {
  final d = distanceKm;
  if (d == null || !d.isFinite || d <= 0) return null;
  if (d < 1) return underOne;
  return km(d.round().clamp(1, kHofGateMaxDistanceKm.round()));
}

String formatHofResidentMeta({
  required RideReturn ret,
  required String sport,
  required String justBackLabel,
  required String atHofLabel,
  required String notYetOutLabel,
  required String sinceOneDay,
  required String Function(int days) sinceDays,
  required String noGpsLabel,
  HofAgo? ago,
  String? garageTypeLabel,
}) {
  final type = (garageTypeLabel != null && garageTypeLabel.trim().isNotEmpty)
      ? garageTypeLabel.trim()
      : sport;
  switch (ret.kind) {
    case RideReturnKind.neverOut:
      return '$type · $atHofLabel · $notYetOutLabel';
    case RideReturnKind.justBack:
      final km = ret.distanceKm ?? 0;
      final hasDistance = ret.usedGps || km > 0.05;
      final parts = <String>[
        if (ago == null || ago.underHour) justBackLabel,
        if (ago != null) ago.label,
      ];
      if (hasDistance) {
        parts.add('${km.toStringAsFixed(1)} km');
        parts.add(formatMovingTime(ret.movingTimeSec ?? 0));
      }
      if (!ret.usedGps) parts.add(noGpsLabel);
      return parts.join(' · ');
    case RideReturnKind.atHof:
      final since = (ago != null && !ago.underHour)
          ? ago.label
          : (ret.daysSince == 1
              ? sinceOneDay
              : sinceDays(ret.daysSince ?? 1));
      final base = '$type · $atHofLabel · $since';
      return ret.usedGps ? base : '$base · $noGpsLabel';
  }
}
