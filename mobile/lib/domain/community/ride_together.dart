import 'ride_group.dart';
import 'ride_group_policy.dart';

/// Freeride-Zusammen — Session ohne Tour.
///
/// Straße: Zelle + Karte + Ja. 5–20 bleiben geschlossen.
/// Nearby nur Suchende. Stopp = Leave, nicht Close.
abstract final class RideTogetherPolicy {
  static const routeId = 'freeride';
  static const title = 'Zusammen';
  static const lookMs = 90 * 1000;
  static const requestMs = 90 * 1000;
  static const sessionHours = 8;
  static const memberCap = 20;
  static const cellRing = 2;

  static bool isSessionRouteId(String? id) => (id ?? '').trim() == routeId;

  static bool isFreerideRide(String? routeId) => (routeId ?? '').trim().isEmpty;

  static bool canJoinSessionByCode(String savedRouteId) =>
      isSessionRouteId(savedRouteId);

  static bool canAddMember(int count) => count < memberCap;

  static bool sessionClosesAfterLeave(int remaining) => remaining <= 0;

  /// Sheet zu: Session bleibt. Suche aus schließt keine Paar-Session.
  static bool stopLookClosesSession() => false;

  /// Suche aus + niemand dabei: Solo-Session zu, kein 8-h-Geistercode.
  static bool stopLookClosesSoloSession() => true;

  /// Straße (beide solo) → Fragender. Eine geschlossene Gruppe → die.
  /// Zwei geschlossene Gruppen → nicht mergen.
  static String pickRequestSession({
    required int fromCount,
    required int toCount,
  }) {
    final fromClosed = fromCount >= 2;
    final toClosed = toCount >= 2;
    if (fromClosed && toClosed) return 'none';
    if (toClosed) return 'to';
    return 'from';
  }

  static String sanitizeLabel(String? raw) =>
      (raw ?? '').trim().replaceAll(RegExp(r'\s+'), ' ').charactersTake(24);

  static ({String lo, String hi})? matePair(String a, String b) {
    final left = a.trim();
    final right = b.trim();
    if (left.isEmpty || right.isEmpty || left == right) return null;
    return left.compareTo(right) < 0
        ? (lo: left, hi: right)
        : (lo: right, hi: left);
  }

  static int chebyshevRing({
    required double lat,
    required double lng,
    required double otherLat,
    required double otherLng,
  }) {
    final a = RideGroupPolicy.quantize(lat, lng);
    final b = RideGroupPolicy.quantize(otherLat, otherLng);
    const step = RideGroupPolicy.quantizeDeg;
    final dy = ((b.lat - a.lat) / step).round();
    final dx = ((b.lng - a.lng) / step).round();
    return dx.abs() > dy.abs() ? dx.abs() : dy.abs();
  }

  static String? bucket({
    required double selfLat,
    required double selfLng,
    required double otherLat,
    required double otherLng,
  }) {
    final ring = chebyshevRing(
      lat: selfLat,
      lng: selfLng,
      otherLat: otherLat,
      otherLng: otherLng,
    );
    if (ring <= 1) return 'beside';
    if (ring <= cellRing) return 'near';
    return null;
  }

  static RideGroup? pickGroupForRide({
    required String? rideRouteId,
    String? catalogTourId,
    required List<RideGroup> groups,
    required Map<String, int> memberCounts,
  }) {
    final freeride = isFreerideRide(rideRouteId);
    RideGroup? newestSession;
    RideGroup? routeHit;
    final rideId = rideRouteId?.trim() ?? '';
    final catalogId = catalogTourId?.trim() ?? '';
    final ids = <String>{
      if (rideId.isNotEmpty) rideId,
      if (catalogId.isNotEmpty) catalogId,
    };

    for (final g in groups) {
      if (isSessionRouteId(g.savedRouteId)) {
        final n = memberCounts[g.id] ?? 0;
        if (n < 2) continue;
        if (newestSession == null ||
            g.createdAt.isAfter(newestSession.createdAt)) {
          newestSession = g;
        }
        continue;
      }
      if (freeride) continue;
      final match = ids.isNotEmpty &&
          (ids.contains(g.savedRouteId) ||
              (g.catalogTourId != null && ids.contains(g.catalogTourId)));
      if (match && routeHit == null) routeHit = g;
    }
    if (freeride) return newestSession;
    return routeHit;
  }
}

extension on String {
  String charactersTake(int n) => length <= n ? this : substring(0, n);
}

class TogetherNearby {
  const TogetherNearby({
    required this.userId,
    required this.label,
    required this.bucket,
  });

  final String userId;
  final String label;
  final String bucket;

  static TogetherNearby? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final id = '${raw['userId'] ?? ''}'.trim();
    if (id.isEmpty) return null;
    final bucket = '${raw['bucket'] ?? ''}'.trim();
    if (bucket != 'beside' && bucket != 'near') return null;
    return TogetherNearby(
      userId: id,
      label: '${raw['label'] ?? ''}'.trim(),
      bucket: bucket,
    );
  }
}

class TogetherInbound {
  const TogetherInbound({
    required this.id,
    required this.fromUserId,
    required this.label,
  });

  final String id;
  final String fromUserId;
  final String label;

  static TogetherInbound? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final id = '${raw['id'] ?? ''}'.trim();
    final from = '${raw['fromUserId'] ?? ''}'.trim();
    if (id.isEmpty || from.isEmpty) return null;
    return TogetherInbound(
      id: id,
      fromUserId: from,
      label: '${raw['label'] ?? ''}'.trim(),
    );
  }
}

class TogetherOutbound {
  const TogetherOutbound({
    required this.id,
    required this.toUserId,
    required this.label,
    required this.status,
  });

  final String id;
  final String toUserId;
  final String label;
  final String status;

  static TogetherOutbound? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final id = '${raw['id'] ?? ''}'.trim();
    final to = '${raw['toUserId'] ?? ''}'.trim();
    final status = '${raw['status'] ?? ''}'.trim();
    if (id.isEmpty || to.isEmpty) return null;
    if (status != 'pending' && status != 'accepted' && status != 'declined') {
      return null;
    }
    return TogetherOutbound(
      id: id,
      toUserId: to,
      label: '${raw['label'] ?? ''}'.trim(),
      status: status,
    );
  }
}

/// Chip-Zeile ohne Sheet — Code / Warten / Anfrage.
enum TogetherChipKind { idle, code, soloWait, wait, accepted, declined, inbound }

TogetherChipKind togetherChipKind({
  required bool looking,
  String? joinCode,
  int inboundCount = 0,
  String? outboundStatus,
}) {
  final code = (joinCode ?? '').trim();
  if (outboundStatus == 'declined') return TogetherChipKind.declined;
  if (outboundStatus == 'accepted') return TogetherChipKind.accepted;
  if (outboundStatus == 'pending') return TogetherChipKind.wait;
  if (code.isNotEmpty) return TogetherChipKind.code;
  if (looking) return TogetherChipKind.soloWait;
  if (inboundCount > 0) return TogetherChipKind.inbound;
  return TogetherChipKind.idle;
}

class TogetherLookSnap {
  const TogetherLookSnap({
    required this.me,
    this.joinCode,
    this.lookingUntil,
    this.nearby = const [],
    this.inbound = const [],
    this.outbound = const [],
    this.group,
    this.members = const [],
    this.note,
    this.stub = false,
    this.stopped = false,
  });

  final String me;
  final String? joinCode;
  final DateTime? lookingUntil;
  final List<TogetherNearby> nearby;
  final List<TogetherInbound> inbound;
  final List<TogetherOutbound> outbound;
  final RideGroup? group;
  final List<RideGroupMember> members;
  final String? note;
  final bool stub;
  final bool stopped;

  TogetherOutbound? get activeOutbound {
    for (final o in outbound) {
      if (o.status == 'pending') return o;
    }
    return outbound.isEmpty ? null : outbound.first;
  }
}
