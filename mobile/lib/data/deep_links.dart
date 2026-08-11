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

/// Handles aetherride://ride?route=… and https://…/open/ride?route=…
class DeepLinkHandler {
  DeepLinkHandler(this._ref);

  final WidgetRef _ref;
  StreamSubscription<Uri>? _sub;

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

  Future<void> _onUri(Uri uri) async {
    debugPrint('DeepLink: $uri');
    // OAuth callbacks handled elsewhere
    if (uri.host == 'login-callback' ||
        uri.host == 'strava-callback' ||
        uri.path.contains('login-callback') ||
        uri.path.contains('strava-callback')) {
      return;
    }

    final isRide = uri.host == 'ride' ||
        uri.pathSegments.contains('ride') ||
        uri.path.startsWith('/open/ride') ||
        uri.path == '/ride' ||
        (uri.scheme == 'aetherride' &&
            (uri.host == 'ride' || uri.path.contains('ride')));

    if (!isRide) return;

    final routeId = uri.queryParameters['route'];
    _ref.read(shellTabIndexProvider.notifier).state = 2; // Ride tab

    if (routeId == null || routeId.isEmpty) {
      _ref.read(rideAutostartProvider.notifier).state = true;
      return;
    }

    // 1) Local saved routes
    try {
      final saved = await _ref.read(savedRoutesProvider.future);
      for (final s in saved) {
        if (s.id == routeId) {
          final coords = s.coordinates;
          _ref.read(activeRouteProvider.notifier).state = ActiveRoute(
            id: s.id,
            name: s.name,
            distanceKm: s.distanceKm,
            elevationM: s.elevationM,
            durationMin: s.durationMin,
            coordinates: coords,
          );
          return;
        }
      }
    } catch (e) {
      debugPrint('DeepLink saved: $e');
    }

    // 2) Live geometry from API
    try {
      final base = AppConfig.apiBaseUrl;
      final res = await http.get(
        Uri.parse('$base/api/tours/geometry?id=${Uri.encodeComponent(routeId)}'),
      );
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
        _ref.read(activeRouteProvider.notifier).state = ActiveRoute(
          id: routeId,
          name: (j['name'] as String?) ?? routeId,
          distanceKm: ((j['distanceM'] as num?)?.toDouble() ?? 0) / 1000,
          elevationM: 0,
          durationMin: (((j['durationS'] as num?)?.toDouble() ?? 0) / 60).round(),
          coordinates: coords,
        );
      }
    } catch (e) {
      debugPrint('DeepLink geometry: $e');
    }
  }
}
