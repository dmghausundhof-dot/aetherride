import '../ride.dart';
import '../ride_journal.dart';

/// Mid-ride snapshot so a process kill can restore the live track.
///
/// Kept as plain JSON (same shape [TrackPoint.toJson] already persists on
/// stop) — not a finished [RideRecord], so history/stats/sync stay clean.
class RideInProgressDraft {
  const RideInProgressDraft({
    required this.rideId,
    required this.startedAt,
    required this.savedAt,
    required this.track,
    this.distanceM = 0,
    this.elapsedSec = 0,
    this.usingGps = false,
    this.drawingTour = false,
    this.paused = false,
    this.peakG = 1,
    this.flowSum = 0,
    this.flowN = 0,
    this.simDistanceM = 0,
    this.simMotionUsed = false,
    this.routeId,
    this.routeName,
    this.journal = RideJournal.empty,
  });

  final String rideId;
  final DateTime startedAt;
  final DateTime savedAt;
  final List<TrackPoint> track;
  final double distanceM;
  final int elapsedSec;
  final bool usingGps;
  final bool drawingTour;
  final bool paused;
  final double peakG;
  final double flowSum;
  final int flowN;
  final double simDistanceM;
  final bool simMotionUsed;
  final String? routeId;
  final String? routeName;
  final RideJournal journal;

  Map<String, dynamic> toJson() => {
        'v': 1,
        'rideId': rideId,
        'startedAtMs': startedAt.millisecondsSinceEpoch,
        'savedAtMs': savedAt.millisecondsSinceEpoch,
        'distanceM': distanceM,
        'elapsedSec': elapsedSec,
        'usingGps': usingGps,
        'drawingTour': drawingTour,
        'paused': paused,
        'peakG': peakG,
        'flowSum': flowSum,
        'flowN': flowN,
        'simDistanceM': simDistanceM,
        'simMotionUsed': simMotionUsed,
        if (routeId != null && routeId!.trim().isNotEmpty) 'routeId': routeId,
        if (routeName != null && routeName!.trim().isNotEmpty)
          'routeName': routeName,
        'track': [for (final p in track) p.toJson()],
        if (!journal.isEmpty) 'journal': journal.toSummaryPatch(),
      };

  static RideInProgressDraft? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final m = Map<String, dynamic>.from(raw);
    final rideId = (m['rideId'] as String?)?.trim() ?? '';
    if (rideId.isEmpty) return null;
    final startedAt = _timeOf(m['startedAtMs'] ?? m['startedAt']);
    final savedAt = _timeOf(m['savedAtMs'] ?? m['savedAt']) ?? startedAt;
    if (startedAt == null || savedAt == null) return null;
    final trackRaw = m['track'];
    final track = <TrackPoint>[];
    if (trackRaw is List) {
      for (final e in trackRaw) {
        final p = TrackPoint.tryParse(e);
        if (p != null) track.add(p);
      }
    }
    final journalRaw = m['journal'];
    final journal = journalRaw is Map
        ? RideJournal.fromSummary(Map<String, dynamic>.from(journalRaw))
        : RideJournal.empty;
    final routeId = (m['routeId'] as String?)?.trim();
    final routeName = (m['routeName'] as String?)?.trim();
    return RideInProgressDraft(
      rideId: rideId,
      startedAt: startedAt,
      savedAt: savedAt,
      track: track,
      distanceM: (m['distanceM'] as num?)?.toDouble() ?? 0,
      elapsedSec: (m['elapsedSec'] as num?)?.toInt() ?? 0,
      usingGps: m['usingGps'] == true,
      drawingTour: m['drawingTour'] == true,
      paused: m['paused'] == true,
      peakG: (m['peakG'] as num?)?.toDouble() ?? 1,
      flowSum: (m['flowSum'] as num?)?.toDouble() ?? 0,
      flowN: (m['flowN'] as num?)?.toInt() ?? 0,
      simDistanceM: (m['simDistanceM'] as num?)?.toDouble() ?? 0,
      simMotionUsed: m['simMotionUsed'] == true,
      routeId: routeId == null || routeId.isEmpty ? null : routeId,
      routeName: routeName == null || routeName.isEmpty ? null : routeName,
      journal: journal,
    );
  }
}

/// Empty / corrupt / abandoned drafts stay discarded.
bool rideInProgressIsRecoverable(
  RideInProgressDraft? draft, {
  DateTime? now,
}) {
  if (draft == null) return false;
  if (draft.rideId.trim().isEmpty) return false;
  if (draft.track.isNotEmpty) return true;
  final n = now ?? DateTime.now();
  if (draft.elapsedSec < 5) return false;
  return n.difference(draft.savedAt).inHours < 48;
}

/// Throttle disk writes: first point, every [minNewPoints], or [minInterval].
bool rideInProgressShouldCheckpoint({
  required DateTime? lastAt,
  required int lastLen,
  required int trackLen,
  required DateTime now,
  bool force = false,
  Duration minInterval = const Duration(seconds: 8),
  int minNewPoints = 8,
}) {
  if (force) return trackLen > 0 || lastAt == null;
  if (trackLen <= 0) return lastAt == null;
  if (lastAt == null) return true;
  if (trackLen - lastLen >= minNewPoints) return true;
  return now.difference(lastAt) >= minInterval;
}

DateTime? _timeOf(Object? raw) {
  if (raw is num) {
    final ms = raw.toInt();
    if (ms <= 0) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
  }
  if (raw is String && raw.trim().isNotEmpty) {
    return DateTime.tryParse(raw)?.toUtc();
  }
  return null;
}
