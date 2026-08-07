import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:aetherride_mobile/native/routing_core_ffi.dart';

/// Host smoke for `routing_core` FFI.
///
/// ```bash
/// cd mobile/packages/routing_core/native && cargo build
/// cd ../../.. && ROUTING_CORE_LIB=\$PWD/packages/routing_core/native/target/debug/librouting_core.so \
///   flutter test test/routing_core_ffi_smoke_test.dart
/// ```
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('routing_core FFI offline_graph smoke', () {
    if (!Platform.isLinux && !Platform.isAndroid) {
      return;
    }

    final ffi = RoutingCoreFfi();
    if (!ffi.available) {
      final hint = Platform.environment['ROUTING_CORE_LIB'] ?? '(unset)';
      fail(
        'librouting_core not loaded. Set ROUTING_CORE_LIB to the cargo .so '
        '(current: $hint).',
      );
    }

    final graphFile = File('assets/routing/offline_graph.json');
    expect(graphFile.existsSync(), isTrue);
    final tilesPath = graphFile.parent.path;

    expect(ffi.tilesOk(tilesPath), isTrue);
    expect(ffi.engineForTiles(tilesPath), 'offline_graph');

    final r = ffi.tryOfflineRoute(
      fromLat: 47.99,
      fromLng: 7.85,
      toLat: 47.95,
      toLng: 7.92,
      profile: 'mtb_enduro',
      tilesPath: tilesPath,
    );
    expect(r, isNotNull);
    expect(r!.distanceM, greaterThan(100));
    expect(r.coordinatesLngLat.length, greaterThan(2));
    expect(r.engine, 'offline_graph');
  });
}
