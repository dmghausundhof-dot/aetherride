import 'dart:math' as math;

import '../privacy/consents.dart';
import '../saved_route.dart';
import '../saved_route_note.dart';
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
  static const sessionRouteId = 'freeride';
  static const minDurationHours = 0.25;
  static const maxDurationHours = 12.0;
  static const extendCapHours = 12;
  static const startsAtMaxDays = 14;

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

  /// Leerzeichen, Bindestriche, I/O/0/1 — nur das Alphabet bleibt.
  static String normalizeJoinCode(String raw) {
    final upper = raw.trim().toUpperCase();
    final buf = StringBuffer();
    for (var i = 0; i < upper.length; i++) {
      final ch = upper[i];
      if (joinAlphabet.contains(ch)) buf.write(ch);
    }
    return buf.toString();
  }

  static bool isTypedJoinCode(String raw) {
    final t = raw.trim();
    if (t.isEmpty || isGroupId(t)) return false;
    return normalizeJoinCode(t).length == joinCodeLen;
  }

  /// Privat: nur Einladungslink (Token). Der 6-Zeichen-Code ist zum Abtippen
  /// gedacht, nicht als Geheimnis — gilt nur für öffentliche / auf dem Platz
  /// gelistete Gruppen. Private Gruppen bleiben Link-only.
  static bool canJoinByTypedCode(RideGroupVisibility visibility) =>
      visibility == RideGroupVisibility.public;

  /// Eigene gespeicherte/Katalog-Touren inkl. privater GPX.
  /// RideTogether/`freeride` ist keine Gruppen-Route.
  /// [meta] bleibt für Call-Sites — Sichtbarkeit der Tour steuert Explore nicht.
  static bool canAttachCourse(String routeId, SavedRouteMeta? _) {
    final id = routeId.trim();
    if (id.isEmpty || id == sessionRouteId) return false;
    return true;
  }

  static bool canAttachSaved(SavedRouteEntry route, SavedRouteMeta? meta) {
    return canAttachCourse(route.id, meta);
  }

  /// Live-GPS of members never on Explore / Browse.
  static bool groupListedOnExplore() => false;

  /// Static meeting pin (no live position) for public or own groups.
  static bool canShowMeetingOnExplore(
    RideGroup g, {
    required bool isMember,
    required DateTime now,
  }) {
    if (g.savedRouteId.trim() == sessionRouteId) return false;
    if (g.status == RideGroupStatus.closed) return false;
    if (!canJoin(now: now, end: g.startWindowEnd, status: g.status)) {
      return false;
    }
    if (g.visibility == RideGroupVisibility.public) return true;
    return isMember;
  }

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

  /// Host allein (keine anderen im Roster) → Einladen, sonst Losfahren.
  static bool platzPrimaryIsInvite({
    required bool selfIsHost,
    required int otherMemberCount,
  }) =>
      selfIsHost && otherMemberCount <= 0;

  static String formatDurationHours(num hours, {String decimalSep = '.'}) {
    final h = hours.toDouble();
    if (!h.isFinite || h <= 0) return '0 h';
    if (h >= 1 && (h - h.round()).abs() < 0.05) return '${h.round()} h';
    return '${h.toStringAsFixed(1).replaceAll('.', decimalSep)} h';
  }

  static String formatClock(DateTime local) {
    final l = local.toLocal();
    return '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
  }

  static String formatWhenLabeled({
    required DateTime start,
    required DateTime end,
    DateTime? now,
    required String Function(DateTime local) weekdayShort,
    required String Function(String time, String dur) today,
    required String Function(String time, String dur) tomorrow,
    required String Function(String wd, String time, String dur) other,
    required String Function(String wd, String time) closed,
    String decimalSep = ',',
  }) {
    final n = now ?? DateTime.now();
    final local = start.toLocal();
    final hours = end.difference(start).inMinutes / 60.0;
    final dur = formatDurationHours(hours, decimalSep: decimalSep);
    final wd = weekdayShort(local);
    final hm = formatClock(local);
    if (n.toUtc().isAfter(end.toUtc())) return closed(wd, hm);
    final todayDay = DateTime(n.year, n.month, n.day);
    final startDay = DateTime(local.year, local.month, local.day);
    if (startDay == todayDay) return today(hm, dur);
    if (startDay == todayDay.add(const Duration(days: 1))) {
      return tomorrow(hm, dur);
    }
    return other(wd, hm, dur);
  }

  static String formatWhen(
    DateTime start,
    DateTime end, {
    DateTime? now,
  }) {
    return formatWhenLabeled(
      start: start,
      end: end,
      now: now,
      weekdayShort: (local) => _weekdays[local.weekday - 1],
      today: (hm, dur) => 'heute $hm · $dur',
      tomorrow: (hm, dur) => 'morgen $hm · $dur',
      other: (wd, hm, dur) => '$wd $hm · $dur',
      closed: (wd, hm) => 'zu — $wd $hm',
      decimalSep: ',',
    );
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

  static double snapDurationHours(num hours) =>
      (hours.toDouble() * 60).round() / 60.0;

  static bool isValidDurationHours(num hours) {
    final h = hours.toDouble();
    return h.isFinite && h >= minDurationHours && h <= maxDurationHours;
  }

  static double? parseDurationHours(String raw) {
    final t = raw.trim().replaceAll(',', '.');
    if (t.isEmpty) return null;
    return double.tryParse(t);
  }

  static Duration durationFromHours(num hours) =>
      Duration(minutes: (hours.toDouble() * 60).round());

  static ({
    DateTime start,
    DateTime end,
    double durationHours,
    RideGroupStatus status,
  })? parseWindow({
    DateTime? startsAt,
    DateTime? endsAt,
    num? durationHours,
    required DateTime now,
  }) {
    final start = startsAt ?? now;
    var hours = 3.0;
    if (endsAt != null) {
      hours = endsAt.difference(start).inMilliseconds / 3600000.0;
    } else if (durationHours != null) {
      hours = durationHours.toDouble();
    }
    if (!isValidDurationHours(hours)) return null;
    hours = snapDurationHours(hours);
    final end = start.add(durationFromHours(hours));
    if (!end.isAfter(start)) return null;
    if (start.difference(now).inMilliseconds >
        startsAtMaxDays * 24 * 3600 * 1000) {
      return null;
    }
    final status = start.isAfter(now.add(const Duration(seconds: 60)))
        ? RideGroupStatus.scheduled
        : RideGroupStatus.open;
    return (
      start: start,
      end: end,
      durationHours: hours,
      status: status,
    );
  }

  /// Fenster verlängern (auch 30 min). Deckel jetzt+12 h. Abgelaufen: ab now.
  static DateTime extendWindowEnd({
    required DateTime now,
    required DateTime end,
    num hours = 1,
    DateTime? newEnd,
  }) {
    final n = now.toUtc();
    final cap = n.add(const Duration(hours: extendCapHours));
    final base = end.toUtc().isAfter(n) ? end.toUtc() : n;
    if (newEnd != null) {
      final next = newEnd.toUtc();
      if (!next.isAfter(base)) return base.isAfter(cap) ? cap : base;
      return next.isAfter(cap) ? cap : next;
    }
    final add = hours.toDouble().clamp(minDurationHours, maxDurationHours);
    final next = base.add(durationFromHours(add));
    return next.isAfter(cap) ? cap : next;
  }

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
