import 'package:aetherride_mobile/domain/routing/connectivity_chip.dart';
import 'package:aetherride_mobile/l10n/app_localizations_de.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveConnectivityChip', () {
    test('online with route → quiet Live (not Route offline)', () {
      final s = resolveConnectivityChip(
        online: true,
        hasRouteGeometry: true,
        offlineMapAvailable: false,
      );
      expect(s, ConnectivityChipState.live);
      expect(connectivityChipLabel(s), 'Live');
      expect(connectivityChipVisibleInClean(s), isFalse);
    });

    test('online freeride → quiet Live', () {
      final s = resolveConnectivityChip(
        online: true,
        hasRouteGeometry: false,
        offlineMapAvailable: false,
      );
      expect(s, ConnectivityChipState.live);
      expect(connectivityChipVisibleInClean(s), isFalse);
    });

    test('offline + geometry + map → Route offline', () {
      final s = resolveConnectivityChip(
        online: false,
        hasRouteGeometry: true,
        offlineMapAvailable: true,
      );
      expect(s, ConnectivityChipState.routeOffline);
      expect(connectivityChipLabel(s), 'Route offline');
      expect(connectivityChipVisibleInClean(s), isTrue);
    });

    test('offline + geometry without map → Route offline (TBT)', () {
      final s = resolveConnectivityChip(
        online: false,
        hasRouteGeometry: true,
        offlineMapAvailable: false,
      );
      expect(s, ConnectivityChipState.routeOffline);
      expect(connectivityChipLabel(s), 'Route offline');
    });

    test('offline freeride + map ok → locked chip string', () {
      final s = resolveConnectivityChip(
        online: false,
        hasRouteGeometry: false,
        offlineMapAvailable: true,
      );
      expect(s, ConnectivityChipState.offlineMapOk);
      expect(
        connectivityChipLabel(s),
        'Offline · Straßenkarte · Reroute: Netz',
      );
    });

    test('offline without map or route → Karten fehlen', () {
      final s = resolveConnectivityChip(
        online: false,
        hasRouteGeometry: false,
        offlineMapAvailable: false,
      );
      expect(s, ConnectivityChipState.mapsMissing);
      expect(connectivityChipLabel(s), 'Karten fehlen');
    });

    test('offline + graph, no street map, loaded route → Route offline', () {
      final s = resolveConnectivityChip(
        online: false,
        hasRouteGeometry: true,
        offlineMapAvailable: false,
        offlineRoutingReady: true,
      );
      expect(s, ConnectivityChipState.routeOffline);
    });

    test('offline + graph, freeride → Routing offline', () {
      final s = resolveConnectivityChip(
        online: false,
        hasRouteGeometry: false,
        offlineMapAvailable: false,
        offlineRoutingReady: true,
      );
      expect(s, ConnectivityChipState.routingOffline);
      expect(connectivityChipLabel(s), 'Routing offline · Karte: Netz');
      expect(connectivityChipVisibleInClean(s), isTrue);
      expect(
        connectivityChipVisibleBesideMapHint(
          state: s,
          mapHintVisible: true,
        ),
        isFalse,
      );
      expect(
        connectivityChipLabel(s, mapHintVisible: true),
        'Routing offline',
      );
    });

    test('maps-missing chip hides when the canvas already says so', () {
      final s = resolveConnectivityChip(
        online: false,
        hasRouteGeometry: false,
        offlineMapAvailable: false,
      );
      expect(s, ConnectivityChipState.mapsMissing);
      expect(
        connectivityChipVisibleBesideMapHint(
          state: s,
          mapHintVisible: true,
        ),
        isFalse,
      );
      expect(
        connectivityChipVisibleBesideMapHint(
          state: s,
          mapHintVisible: false,
        ),
        isTrue,
      );
    });

    test('loaded route wins over map-ok chip', () {
      final s = resolveConnectivityChip(
        online: false,
        hasRouteGeometry: true,
        offlineMapAvailable: true,
        offlineRoutingReady: true,
      );
      expect(s, ConnectivityChipState.routeOffline);
    });

    test('offline toast copy is action-oriented', () {
      expect(
        kOfflineRerouteToast,
        AppLocalizationsDe().rideOfflineRerouteToast,
      );
    });

    test('never claims offline reroute in labels', () {
      for (final online in [true, false]) {
        for (final route in [true, false]) {
          for (final map in [true, false]) {
            for (final graph in [true, false]) {
              final label = connectivityChipLabel(
                resolveConnectivityChip(
                  online: online,
                  hasRouteGeometry: route,
                  offlineMapAvailable: map,
                  offlineRoutingReady: graph,
                ),
              );
              expect(label.toLowerCase().contains('reroute offline'), isFalse);
              expect(label.toLowerCase().contains('offline-reroute'), isFalse);
            }
          }
        }
      }
    });
  });
}
