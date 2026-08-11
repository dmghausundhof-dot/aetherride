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

/// Handles:
/// - aetherride://ride?route=
/// - https://aetherride.vercel.app/open/ride?route=
/// - https://…/ride?route=
class DeepLinkHandler {
  DeepLinkHandler(this._ref);

  final WidgetRef _ref;
  StreamSubscription<Uri>? _sub;
  String? _lastHandled;

  Future<void> start() async {
    final links = AppLinks();
    _sub = links.uriLinkStream.listen(_onUri, onError: (e) {
      debugPrint('DeepLink stream: $e');
    });
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

  bool _isRideUri(Uri uri) {
    final path = uri.path.toLowerCase();
    final host = uri.host.toLowerCase();
    if (uri.scheme == 'aetherride') {
      return host == 'ride' ||
          path.contains('ride') ||
          host.isEmpty ||
          uri.queryParameters.containsKey('route');
    }
    if (uri.scheme == 'https' || uri.scheme == 'http') {
      return path.startsWith('/open/ride') ||
          path == '/ride' ||
          path.startsWith('/ride/') ||
          pathSegmentsContain(uri, 'ride');
    }
    // legacy io.aetherride.app — only ride if path says so
    if (uri.scheme == 'io.aetherride.app') {
      return path.contains('ride') || host == 'ride';
    }
    return false;
  }

  static bool pathSegmentsContain(Uri uri, String seg) =>
      uri.pathSegments.map((s) => s.toLowerCase()).contains(seg);

  Future<void> _onUri(Uri uri) async {
    final key = uri.toString();
    if (_lastHandled == key) return;
    debugPrint('DeepLink: $uri');

    if (uri.host == 'login-callback' ||
        uri.host == 'strava-callback' ||
        uri.path.contains('login-callback') ||
        uri.path.contains('strava-callback')) {
      return;
    }

    if (!_isRideUri(uri)) return;
    _lastHandled = key;

    final routeId = uri.queryParameters['route']?.trim();
    // Ensure Ride tab is mounted
    _ref.read(shellTabIndexProvider.notifier).state = 2;

    if (routeId == null || routeId.isEmpty) {
      _ref.read(rideAutostartProvider.notifier).state = true;
      return;
    }

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

    // 2) Live / editorial geometry from API
    try {
      final base = AppConfig.apiBaseUrl;
      final res = await http.get(
        Uri.parse(
          '$base/api/tours/geometry?id=${Uri.encodeComponent(routeId)}',
        ),
      ).timeout(const Duration(seconds: 25));
      if (res.statusCode == 200) {
        final j = jsonDecode(res.body) as Map<String, dynamic>;
        final geom = j['geometry'];
        final coords = <List<double>>[];
        if (geom is Map && geom['coordinates'] is List) {
          for (final c in geom['coordinates'] as List) {
            if (c is List && c.length >= 2) {
              coords.add([
                (c[0] as num).toDouble(),
                (c[1] as num).toDouble(),
              ]);
            }
          }
        }
        final name = (j['label'] as String?) ??
            (j['name'] as String?) ??
            routeId;
        _ref.read(activeRouteProvider.notifier).state = ActiveRoute(
          id: routeId,
          name: name,
          distanceKm: ((j['distanceM'] as num?)?.toDouble() ?? 0) / 1000,
          elevationM: ((j['distanceM'] as num?)?.toDouble() ?? 0) * 0.02,
          durationMin:
              (((j['durationS'] as num?)?.toDouble() ?? 0) / 60).round(),
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
