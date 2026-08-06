import 'package:dsp_core/dsp_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('DspEngine fuseBlock detects impact', () {
    final engine = DspEngine(impactThresholdG: 2.8);
    final samples = <DspSample>[];
    for (var i = 0; i < 20; i++) {
      samples.add(
        DspSample(
          tMs: i * 10,
          ax: 0,
          ay: 0,
          az: i == 10 ? 9.81 * 5 : 9.81,
          gx: 0,
          gy: 0,
          gz: 0,
        ),
      );
    }
    final fused = engine.fuseBlock(samples);
    expect(fused, isNotNull);
    expect(fused!.gForcePeak, greaterThan(2.8));
    expect(fused.impactDetected, isTrue);
  });
}
