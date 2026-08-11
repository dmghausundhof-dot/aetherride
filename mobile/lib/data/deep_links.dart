import 'dart:async';
import 'dart:convert';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../core/config.dart';
import '../domain/active_route.dart';
import '../providers/app_providers.dart';
import '../providers/ride_providers.dart';
import 'routing/naehe_seeds.dart';

/// Parsed intent from a deep / app link.
enum DeepLinkKind { ride, tour, discover, ignore }

/// Pure parsing helpers (unit-tested).
class DeepLinkParse {
  DeepLinkParse._();

  static bool pathSegmentsContain(Uri uri, String seg) =>
      uri.pathSegments.map((s) => s.toLowerCase()).contains(seg);

  /// OAuth callbacks — never treat as ride.
  static bool isAuthCallback(Uri uri) {
    final host = uri.host.toLowerCase();
    final path = uri.path.toLowerCase();
    return host == 'login-callback' ||
        host == 'strava-callback' ||
        path.contains('login-callback') ||
        path.contains('strava-callback');
  }

  static DeepLinkKind kindOf(Uri uri) {
    if (isAuthCallback(uri)) return DeepLinkKind.ignore;

    final path = uri.path.toLowerCase();
    final host = uri.host.toLowerCase();
    final segs = uri.pathSegments.map((s) => s.toLowerCase()).toList();

    if (uri.scheme == 'aetherride') {
      if (host == 'discover' || path.contains('discover')) {
        return DeepLinkKind.discover;
      }
      if (host == 'tours' || pathSegmentsContain(uri, 'tours')) {
        return DeepLinkKind.tour;
      }
      if (host == 'ride' ||
          host == 'open' ||
          path.contains('ride') ||
          uri.queryParameters.containsKey('route') ||
          host.isEmpty) {
        return DeepLinkKind.ride;
      }
      return DeepLinkKind.ignore;
    }

    if (uri.scheme == 'https' || uri.scheme == 'http') {
      if (path.startsWith('/discover') || segs.contains('discover')) {
        return DeepLinkKind.discover;
      }
      if (path.startsWith('/tours') || segs.contains('tours')) {
        return DeepLinkKind.tour;
      }
      if (path.startsWith('/open/ride') ||
          path == '/ride' ||
          path.startsWith('/ride/') ||
          pathSegmentsContain(uri, 'ride')) {
        return DeepLinkKind.ride;
      }
      // /open without ride → discover
      if (path.startsWith('/open')) return DeepLinkKind.discover;
      return DeepLinkKind.ignore;
    }

    if (uri.scheme == 'io.aetherride.app') {
      if (path.contains('ride') || host == 'ride') return DeepLinkKind.ride;
      return DeepLinkKind.ignore;
    }

    return DeepLinkKind.ignore;
  }

  /// Route id from query `route=` or last path segment under tours/ride.
  static String? routeIdOf(Uri uri) {
    final q = uri.queryParameters['route']?.trim();
    if (q != null && q.isNotEmpty) return q;

    final segs = uri.pathSegments;
    if (segs.isEmpty) {
      // aetherride://tours/r-id style when host is tours
      if (uri.host.toLowerCase() == 'tours' ||
          uri.host.toLowerCase() == 'ride') {
        final rest = uri.path.replaceFirst(RegExp(r'^/'), '').trim();
        if (rest.isNotEmpty && !rest.contains('/')) return rest;
      }
      return null;
    }
    final lower = segs.map((s) => s.toLowerCase()).toList();
    for (var i = 0; i < lower.length; i++) {
      if ((lower[i] == 'tours' || lower[i] == 'ride') && i + 1 < segs.length) {
        final id = segs[i + 1].trim();
        if (id.isNotEmpty) return id;
      }
    }
    // aetherride://tours with path /r-id
    if (uri.host.toLowerCase() == 'tours' && segs.isNotEmpty) {
      return segs.last.trim();
    }
    return null;
  }

  /// Loop / seed id from `loop=` (D-60-05).
  static String? loopIdOf(Uri uri) {
    final q = uri.queryParameters['loop']?.trim();
    if (q != null && q.isNotEmpty) return q;
    return null;
  }

  /// `start=1` / `start=true` → ActiveRoute + Ride (D-60-05).
  static bool startRideOf(Uri uri) {
    final s = uri.queryParameters['start']?.trim().toLowerCase();
    return s == '1' || s == 'true' || s == 'yes';
  }

  /// Dauer-Lens aus `lens=` (z. B. 60).
  static int? lensMinutesOf(Uri uri) {
    final raw = uri.queryParameters['lens']?.trim();
    if (raw == null || raw.isEmpty) return null;
    if (raw == 'egal' || raw == 'any') return 0;
    return int.tryParse(raw);
  }
}

/// Handles:
/// - aetherride://ride?route=
/// - aetherride://tours/{id}
/// - aetherride://discover
/// - aetherride://discover?lens=60&loop=SEED_ID&start=1  (D-60-05 → Ride)
/// - https://aetherride.vercel.app/discover?lens=60&loop=SEED_ID&start=1
/// - https://aetherride.vercel.app/open/ride?route=
/// - https://…/ride?route=
/// - https://…/tours/{id}
///
/// Android paths (Manifest intent-filters):
/// - Custom: `aetherride://discover?loop=seed-loop-…&start=1`
/// - App Link: `https://aetherride.vercel.app/discover?loop=…&start=1`
/// - App Link alt: `https://aetherride.app/discover?…`
/// adb: `adb shell am start -a android.intent.action.VIEW \
///   -d 'aetherride://discover?lens=60&loop=seed-loop-tempelhofer-60&start=1' \
///   com.aetherride.aetherride_mobile`
class DeepLinkHandler {
  DeepLinkHandler(this._ref);

  final WidgetRef _ref;
  StreamSubscription<Uri>? _sub;
  String? _lastHandled;

  Future<void> start() async {
    final links = AppLinks();
    _sub = links.uriLinkStream.listen(
      _onUri,
      onError: (e) {
        debugPrint('DeepLink stream: $e');
      },
    );
    try {
      final initial = await links.getInitialLink();
      if (initial != null) await _onUri(initial);
    } catch (e) {
      debugPrint('DeepLink initial: $e');
    }
  }

  void dispose() {
    _sub?.cancel();
  }

  Future<void> _onUri(Uri uri) async {
    final key = uri.toString();
    if (_lastHandled == key) return;
    debugPrint('DeepLink: $uri');

    final kind = DeepLinkParse.kindOf(uri);
    if (kind == DeepLinkKind.ignore) return;
    _lastHandled = key;

    if (kind == DeepLinkKind.discover) {
      await _handleDiscover(uri);
      return;
    }

    final routeId = DeepLinkParse.routeIdOf(uri);

    // Ride or tour with optional geometry
    _ref.read(shellTabIndexProvider.notifier).state = 2;

    if (routeId == null || routeId.isEmpty) {
      if (kind == DeepLinkKind.tour) {
        _ref.read(shellTabIndexProvider.notifier).state = 3;
        _ref.read(discoverLaunchModeProvider.notifier).state =
            DiscoverLaunchMode.discover;
        return;
      }
      _ref.read(rideAutostartProvider.notifier).state = true;
      return;
    }

    await _loadRoute(routeId);
  }

  /// Discover-Intent: optional lens + loop + start=1 → Nav (D-60-05).
  Future<void> _handleDiscover(Uri uri) async {
    final loopId = DeepLinkParse.loopIdOf(uri);
    final start = DeepLinkParse.startRideOf(uri);
    final lens = DeepLinkParse.lensMinutesOf(uri);

    if (lens != null) {
      _ref.read(discoverPendingLensMinutesProvider.notifier).state = lens;
    }

    if (loopId != null && loopId.isNotEmpty && start) {
      final started = await _startSeedLoop(loopId);
      if (started) return;
      // Seed missing → Discover mit Highlight
    }

    _ref.read(shellTabIndexProvider.notifier).state = 3;
    _ref.read(discoverLaunchModeProvider.notifier).state =
        DiscoverLaunchMode.discover;
    if (loopId != null && loopId.isNotEmpty) {
      _ref.read(discoverPendingLoopIdProvider.notifier).state = loopId;
    }
  }

  /// Bundled Nähe-Seeds → ActiveRoute + Ride-Tab.
  Future<bool> _startSeedLoop(String loopId) async {
    try {
      final bundle = await NaeheSeedsBundle.load();
      final seed = bundle.byId(loopId);
      if (seed == null) {
        debugPrint('DeepLink: seed loop not found $loopId');
        return false;
      }
      _ref.read(activeRouteProvider.notifier).state = seed.toActiveRoute();
      // Same flag as Freeride / empty ride deep-link — RideScreen consumes it.
      _ref.read(rideAutostartProvider.notifier).state = true;
      _ref.read(shellTabIndexProvider.notifier).state = 2;
      debugPrint('DeepLink: seed loop $loopId → Ride (autostart)');
      return true;
    } catch (e) {
      debugPrint('DeepLink seed loop: $e');
      return false;
    }
  }

  Future<void> _loadRoute(String routeId) async {
    // 1) Local saved routes
    try {
      final saved = await _ref.read(savedRoutesProvider.future);
      for (final s in saved) {
        if (s.id == routeId) {
          _ref.read(activeRouteProvider.notifier).state = ActiveRoute(
            id: s.id,
            name: s.name,
            distanceKm: s.distanceKm,
            elevationM: s.elevationM,
            durationMin: s.durationMin,
            coordinates: s.coordinates,
          );
          debugPrint('DeepLink: loaded saved route $routeId');
          return;
        }
      }
    } catch (e) {
      debugPrint('DeepLink saved: $e');
    }

    // 1b) Bundled Nähe-Seeds (offline loops)
    try {
      final bundle = await NaeheSeedsBundle.load();
      final seed = bundle.byId(routeId);
      if (seed != null) {
        _ref.read(activeRouteProvider.notifier).state = seed.toActiveRoute();
        debugPrint('DeepLink: loaded seed route $routeId');
        return;
      }
    } catch (e) {
      debugPrint('DeepLink seed route: $e');
    }

    // 2) Live / editorial geometry from API
    try {
      final base = AppConfig.apiBaseUrl;
      final res = await http
          .get(
            Uri.parse(
              '$base/api/tours/geometry?id=${Uri.encodeComponent(routeId)}',
            ),
          )
          .timeout(const Duration(seconds: 25));
      if (res.statusCode == 200) {
        final j = jsonDecode(res.body) as Map<String, dynamic>;
        final geom = j['geometry'];
        final coords = <List<double>>[];
        if (geom is Map && geom['coordinates'] is List) {
          for (final c in geom['coordinates'] as List) {
            if (c is List && c.length >= 2) {
              coords.add([(c[0] as num).toDouble(), (c[1] as num).toDouble()]);
            }
          }
        }
        final name =
            (j['label'] as String?) ?? (j['name'] as String?) ?? routeId;
        _ref.read(activeRouteProvider.notifier).state = ActiveRoute(
          id: routeId,
          name: name,
          distanceKm: ((j['distanceM'] as num?)?.toDouble() ?? 0) / 1000,
          elevationM: ((j['distanceM'] as num?)?.toDouble() ?? 0) * 0.02,
          durationMin: (((j['durationS'] as num?)?.toDouble() ?? 0) / 60)
              .round(),
          coordinates: coords,
        );
        debugPrint(
          'DeepLink: geometry $routeId pts=${coords.length} engine=${j['engine']}',
        );
        return;
      }
      debugPrint('DeepLink geometry HTTP ${res.statusCode}');
    } catch (e) {
      debugPrint('DeepLink geometry: $e');
    }

    // 3) Fallback: open Discover with route highlight
    _ref.read(shellTabIndexProvider.notifier).state = 3;
    _ref.read(discoverLaunchModeProvider.notifier).state =
        DiscoverLaunchMode.discover;
  }
}
