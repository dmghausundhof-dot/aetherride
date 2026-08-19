import 'dart:ui' as ui;

import 'package:aetherride_mobile/presentation/map/rider_map_image.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Rider-Map-PNG ist zugeschnittenes 128er Quadrat', () async {
    final live = await buildRiderMapPng(live: true, pixelSize: 128);
    final stale = await buildRiderMapPng(live: false, pixelSize: 128);
    expect(live.sublist(0, 8), [137, 80, 78, 71, 13, 10, 26, 10]);
    expect(stale.sublist(0, 8), [137, 80, 78, 71, 13, 10, 26, 10]);
    expect(live, isNot(equals(stale)));
    final codec = await ui.instantiateImageCodec(live);
    final frame = await codec.getNextFrame();
    expect(frame.image.width, 128);
    expect(frame.image.height, 128);
  });
}
