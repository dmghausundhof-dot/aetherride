import '../../data/routing/naehe_seeds.dart';
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

/// One nearby ~60 min loop. GPS picks the region — never a Rhein-Neckar default.
///
/// [maxDistanceKm] keeps Hamburg from seeing the Alps. Without GPS, seeds are
/// skipped (wrong landscape); a saved route in the duration band may still show.
HofGatePick pickHofGate({
  required List<NaeheSeedRoute> loops,
  List<SavedRouteEntry> saved = const [],
  double? lat,
  double? lng,
  bool trailsWet = false,
  int targetMin = 60,
  double maxDistanceKm = 80,
}) {
  SavedRouteEntry? savedInWindow() {
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

/// Trail/MTB loops are not an honest gate hour when the ground is wet.
bool isTrailHeavyLoop(NaeheSeedRoute route) {
  final id = route.id.toLowerCase();
  if (id.contains('mtb') || id.contains('trail')) return true;
  final key = TourFilters.parseSurface(route.surfaceTag);
  return key == TourSurfaceKey.trail || key == TourSurfaceKey.gravel;
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
  final justBack = clock.difference(end) <= justBackWindow;
  if (justBack) {
    return RideReturn(
      kind: RideReturnKind.justBack,
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
    this.daysSince,
    this.distanceKm,
    this.movingTimeSec,
    this.endedAt,
    this.usedGps = false,
    this.name,
  });

  final RideReturnKind kind;
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
