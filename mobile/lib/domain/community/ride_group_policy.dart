import 'dart:math' as math;

import '../privacy/consents.dart';
import '../saved_route.dart';
import '../saved_route_note.dart';
import '../tours/route_visibility.dart';
import '../tours/tour_akte.dart';
import 'ride_group.dart';

/// Dart-Spiegel von `src/lib/community/rideGroup.ts`.
abstract final class RideGroupPolicy {
  static const joinCodeLen = 6;
  static final _uuid = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  static bool isGroupId(String raw) => _uuid.hasMatch(raw.trim());
  static const staleAfterMs = 90 * 1000;
  static const dropAfterMs = 5 * 60 * 1000;
  static const quantizeDeg = 0.0005;
  static const joinAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  static String generateJoinCode([double Function()? rng]) {
    final fallback = math.Random();
    final r = rng ?? fallback.nextDouble;
    final buf = StringBuffer();
    for (var i = 0; i < joinCodeLen; i++) {
      final idx = (r() * joinAlphabet.length).floor() % joinAlphabet.length;
      buf.write(joinAlphabet[idx]);
    }
    return buf.toString();
  }

  static bool canAttachCourse(String routeId, SavedRouteMeta? meta) {
    if (RouteVisibility.isShared(meta)) return true;
    return catalogTourIdOf(routeId, meta ?? SavedRouteMeta.empty) != null;
  }

  static bool canAttachSaved(SavedRouteEntry route, SavedRouteMeta? meta) {
    return canAttachCourse(route.id, meta);
  }

  static bool groupListedOnExplore() => false;

  static bool isEventWindowOpen({
    required DateTime now,
    required DateTime start,
    required DateTime end,
    required RideGroupStatus status,
  }) {
    if (status == RideGroupStatus.closed) return false;
    return !now.isBefore(start) && !now.isAfter(end);
  }

  /// Join bis Fensterende. Vor dem Start erlaubt — Pins erst im Fenster.
  static bool canJoin({
    required DateTime now,
    required DateTime end,
    required RideGroupStatus status,
  }) {
    if (status == RideGroupStatus.closed) return false;
    return !now.isAfter(end);
  }

  static const _weekdays = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];

  static String formatWhen(
    DateTime start,
    DateTime end, {
    DateTime? now,
  }) {
    final n = now ?? DateTime.now();
    final local = start.toLocal();
    final hours = end.difference(start).inMinutes / 60.0;
    final dur = hours >= 1 && (hours - hours.round()).abs() < 0.05
        ? '${hours.round()} h'
        : '${hours.toStringAsFixed(1)} h';
    final wd = _weekdays[local.weekday - 1];
    final hm =
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    if (n.toUtc().isAfter(end.toUtc())) return 'zu — $wd $hm';
    final today = DateTime(n.year, n.month, n.day);
    final startDay = DateTime(local.year, local.month, local.day);
    if (startDay == today) return 'heute $hm · $dur';
    if (startDay == today.add(const Duration(days: 1))) {
      return 'morgen $hm · $dur';
    }
    return '$wd $hm · $dur';
  }

  static ({double lat, double lng}) quantize(double lat, double lng) {
    return (
      lat: (lat / quantizeDeg).round() * quantizeDeg,
      lng: (lng / quantizeDeg).round() * quantizeDeg,
    );
  }

  static bool pointInPrivacyZones(
    double lat,
    double lng,
    List<PrivacyZone> zones,
  ) {
    for (final z in zones) {
      if (_distM(lng, lat, z.lng, z.lat) < z.radiusM) return true;
    }
    return false;
  }

  static RideGroupPresenceVisibility resolvePresence({
    required bool isMember,
    required bool livePinsAllowed,
    required bool liveOptIn,
    required bool inEventWindow,
    required bool inPrivacyZone,
    required bool hasFix,
    required int? ageMs,
  }) {
    if (!isMember) return RideGroupPresenceVisibility.hiddenNotMember;
    if (!livePinsAllowed || !liveOptIn) {
      return RideGroupPresenceVisibility.hiddenOptOut;
    }
    if (!inEventWindow) return RideGroupPresenceVisibility.hiddenWindow;
    if (inPrivacyZone) return RideGroupPresenceVisibility.hiddenZone;
    if (!hasFix || ageMs == null) {
      return RideGroupPresenceVisibility.hiddenOffline;
    }
    if (ageMs > dropAfterMs) return RideGroupPresenceVisibility.hiddenOffline;
    if (ageMs > staleAfterMs) return RideGroupPresenceVisibility.stale;
    return RideGroupPresenceVisibility.live;
  }

  static bool pinVisible(RideGroupPresenceVisibility v) =>
      v == RideGroupPresenceVisibility.live ||
      v == RideGroupPresenceVisibility.stale;

  /// Nach erfolgreichem Cloud-GET: lokale Karte behalten?
  /// Host offline angelegt: ja. Gast-Token oder alte Server-Karte: nein.
  static bool keepLocalAfterCloud({
    required bool onServer,
    required bool selfIsHost,
  }) {
    if (onServer) return false;
    return selfIsHost;
  }

  static double _distM(double lng1, double lat1, double lng2, double lat2) {
    const r = 6371000.0;
    final la1 = lat1 * math.pi / 180;
    final la2 = lat2 * math.pi / 180;
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLng = (lng2 - lng1) * math.pi / 180;
    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(la1) * math.cos(la2) * math.sin(dLng / 2) * math.sin(dLng / 2);
    return 2 * r * math.asin(math.sqrt(h.clamp(0.0, 1.0)));
  }
}
