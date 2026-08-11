import 'package:aetherride_mobile/domain/routing/connectivity_chip.dart';
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

    test('offline freeride + map ok → locked chip string', () {
      final s = resolveConnectivityChip(
        online: false,
        hasRouteGeometry: false,
        offlineMapAvailable: true,
      );
      expect(s, ConnectivityChipState.offlineMapOk);
      expect(
        connectivityChipLabel(s),
        'Offline · Karte ok · Reroute: Netz',
      );
    });

    test('offline without map → Karten fehlen', () {
      final s = resolveConnectivityChip(
        online: false,
        hasRouteGeometry: true,
        offlineMapAvailable: false,
      );
      expect(s, ConnectivityChipState.mapsMissing);
      expect(connectivityChipLabel(s), 'Karten fehlen');
    });

    test('offline toast copy is action-oriented', () {
      expect(
        kOfflineRerouteToast,
        'Reroute braucht Internet. Auf der geladenen Route bleiben.',
      );
    });

    test('never claims offline reroute in labels', () {
      for (final online in [true, false]) {
        for (final route in [true, false]) {
          for (final map in [true, false]) {
            final label = connectivityChipLabel(
              resolveConnectivityChip(
                online: online,
                hasRouteGeometry: route,
                offlineMapAvailable: map,
              ),
            );
            expect(label.toLowerCase().contains('reroute offline'), isFalse);
            expect(label.toLowerCase().contains('offline-reroute'), isFalse);
          }
        }
      }
    });
  });
}
