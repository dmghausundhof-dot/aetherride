import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:aetherride_mobile/data/routing/offline_tiles.dart';
import 'package:aetherride_mobile/native/routing_core_ffi.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Android jniLibs: routing_core offline_graph route', (tester) async {
    final ffi = RoutingCoreFfi();
    expect(ffi.available, isTrue, reason: 'librouting_core.so from jniLibs must load');

    final tiles = await OfflineTilesStore.instance.ensureTilesPath();
    expect(tiles, isNotNull);
    expect(ffi.tilesOk(tiles!), isTrue);
    expect(ffi.engineForTiles(tiles), 'offline_graph');

    final r = ffi.tryOfflineRoute(
      fromLat: 47.99,
      fromLng: 7.85,
      toLat: 47.95,
      toLng: 7.92,
      profile: 'mtb_enduro',
      tilesPath: tiles,
    );
    expect(r, isNotNull);
    expect(r!.distanceM, greaterThan(100));
    expect(r.coordinatesLngLat.length, greaterThan(2));
  });
}
