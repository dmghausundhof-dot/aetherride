import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/community/ride_together.dart';
import 'public_profile_store.dart';
import 'ride_group_cloud.dart';
import 'ride_together_cloud.dart';

typedef TogetherLookFn = Future<TogetherLookSnap?> Function({
  required double lat,
  required double lng,
  String? label,
});

typedef TogetherStopLookFn = Future<TogetherLookSnap?> Function();

/// Look lebt mit der Fahrt, nicht mit dem Sheet.
class RideTogetherLook extends ChangeNotifier {
  RideTogetherLook({
    this.lookFn = RideTogetherCloud.look,
    this.stopLookFn = RideTogetherCloud.stopLook,
    this.requestFn = RideTogetherCloud.request,
    this.respondFn = RideTogetherCloud.respond,
    this.joinCodeFn = RideTogetherCloud.joinCode,
    this.sessionStateFn = RideGroupCloud.sessionState,
    this.labelFn,
    this.onAdopt,
    this.foregroundPoll = const Duration(seconds: 4),
    this.backgroundPoll = const Duration(seconds: 8),
  });

  final TogetherLookFn lookFn;
  final TogetherStopLookFn stopLookFn;
  final Future<RideGroupCloudResult?> Function({
    required String toUserId,
    String? label,
  }) requestFn;
  final Future<RideGroupCloudResult?> Function({
    required String requestId,
    required bool accept,
    String? label,
  }) respondFn;
  final Future<RideGroupCloudResult?> Function(String code, {String? label})
      joinCodeFn;
  final Future<String> Function() sessionStateFn;
  final Future<String> Function()? labelFn;
  final Future<void> Function(TogetherLookSnap snap)? onAdopt;
  final Duration foregroundPoll;
  final Duration backgroundPoll;

  TogetherLookSnap? snap;
  String? note;
  String? pendingTo;
  bool looking = false;
  bool busy = false;
  bool sheetOpen = false;

  double? _lat;
  double? _lng;
  bool _inZone = false;
  String? _label;
  String? _lastJoinCode;
  Timer? _poll;
  bool _disposed = false;

  String? get joinCode {
    final live = snap?.joinCode?.trim();
    if (live != null && live.isNotEmpty) return live;
    final kept = _lastJoinCode?.trim();
    if (kept != null && kept.isNotEmpty) return kept;
    return null;
  }

  TogetherOutbound? get outbound => snap?.activeOutbound;

  void setFix({double? lat, double? lng, bool inPrivacyZone = false}) {
    _lat = lat;
    _lng = lng;
    _inZone = inPrivacyZone;
  }

  void setBlocked(String nextNote) {
    note = nextNote;
    _emit();
  }

  void attachSheet() {
    sheetOpen = true;
    if (looking) _restartPoll();
  }

  /// Sheet zu — Look bleibt an, Poll etwas langsamer.
  void detachSheet() {
    sheetOpen = false;
    if (looking) _restartPoll();
  }

  Future<void> ensureStarted({
    required double? lat,
    required double? lng,
    required bool inPrivacyZone,
    required String needGpsNote,
    required String inZoneNote,
    required String needLoginNote,
  }) async {
    setFix(lat: lat, lng: lng, inPrivacyZone: inPrivacyZone);
    if (inPrivacyZone) {
      setBlocked(inZoneNote);
      return;
    }
    if (lat == null || lng == null) {
      setBlocked(needGpsNote);
      return;
    }
    if (looking) {
      await ping();
      return;
    }
    final session = await sessionStateFn();
    if (_disposed) return;
    if (session != 'signedIn') {
      setBlocked(needLoginNote);
      return;
    }
    looking = true;
    _restartPoll();
    _emit();
    await ping();
  }

  Future<void> ping() async {
    if (!looking || _disposed) return;
    final lat = _lat;
    final lng = _lng;
    if (lat == null || lng == null || _inZone) return;
    TogetherLookSnap? next;
    try {
      next = await lookFn(
        lat: lat,
        lng: lng,
        label: _label ?? await _resolveLabel(),
      );
    } catch (_) {
      return;
    }
    if (_disposed) return;
    if (next == null) {
      return;
    }
    snap = next;
    note = next.note;
    final code = next.joinCode?.trim();
    if (code != null && code.isNotEmpty) _lastJoinCode = code;
    if (pendingTo != null) {
      final hit = next.outbound.where((o) => o.toUserId == pendingTo);
      if (hit.any((o) => o.status != 'pending')) pendingTo = null;
    }
    if (next.group != null && onAdopt != null) {
      try {
        await onAdopt!(next);
      } catch (_) {}
    }
    _emit();
  }

  Future<RideGroupCloudResult?> ask(TogetherNearby n) async {
    busy = true;
    pendingTo = n.userId;
    _emit();
    RideGroupCloudResult? res;
    try {
      res = await requestFn(
        toUserId: n.userId,
        label: _label ?? await _resolveLabel(),
      );
    } catch (_) {
      res = null;
    }
    if (_disposed) return res;
    busy = false;
    if (res != null && !res.ok && res.error != 'already') {
      pendingTo = null;
    }
    note = res?.note;
    _emit();
    await ping();
    return res;
  }

  Future<RideGroupCloudResult?> respond(
    TogetherInbound inbound,
    bool accept,
  ) async {
    busy = true;
    _emit();
    RideGroupCloudResult? res;
    try {
      res = await respondFn(
        requestId: inbound.id,
        accept: accept,
        label: _label ?? await _resolveLabel(),
      );
    } catch (_) {
      res = null;
    }
    if (_disposed) return res;
    busy = false;
    note = res?.note;
    _emit();
    if (accept && res != null && res.ok && res.bundle != null) {
      return res;
    }
    await ping();
    return res;
  }

  Future<RideGroupCloudResult?> joinByCode(String code) async {
    busy = true;
    _emit();
    RideGroupCloudResult? res;
    try {
      res = await joinCodeFn(code, label: _label ?? await _resolveLabel());
    } catch (_) {
      res = null;
    }
    if (_disposed) return res;
    busy = false;
    note = res?.note;
    _emit();
    return res;
  }

  /// Expliziter Stopp — Paar-Session bleibt. Solo-Code zu.
  Future<void> stop({bool clearSession = false}) async {
    _poll?.cancel();
    looking = false;
    pendingTo = null;
    busy = false;
    final members = snap?.members.length ?? 0;
    final solo = RideTogetherPolicy.stopLookClosesSoloSession() &&
        members < 2;
    if (clearSession || solo) _lastJoinCode = null;
    try {
      await stopLookFn();
    } catch (_) {}
    if (_disposed) return;
    snap = TogetherLookSnap(
      me: snap?.me ?? '',
      joinCode: (clearSession || solo) ? null : joinCode,
      members: snap?.members ?? const [],
      stopped: true,
    );
    if (clearSession || solo) note = null;
    _emit();
  }

  Future<String> _resolveLabel() async {
    if (_label != null) return _label!;
    try {
      _label = await (labelFn ?? defaultLabel)();
    } catch (_) {
      _label = '';
    }
    return _label!;
  }

  static Future<String> defaultLabel() async {
    final p = await PublicProfileStore().load();
    final name = p.displayName.trim();
    if (name.isNotEmpty) return RideTogetherPolicy.sanitizeLabel(name);
    final handle = p.handle.trim();
    if (handle.isNotEmpty) return RideTogetherPolicy.sanitizeLabel('@$handle');
    return '';
  }

  void _restartPoll() {
    _poll?.cancel();
    if (!looking || _disposed) return;
    _poll = Timer.periodic(
      sheetOpen ? foregroundPoll : backgroundPoll,
      (_) => unawaited(ping()),
    );
  }

  void _emit() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _poll?.cancel();
    super.dispose();
  }
}
