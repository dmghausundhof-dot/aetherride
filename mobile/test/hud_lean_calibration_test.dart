import 'package:aetherride_mobile/domain/hud_lean_calibration.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HudLeanCalibration', () {
    test('display subtracts mount offset', () {
      expect(HudLeanCalibration.displayDeg(18, 12), 6);
      expect(HudLeanCalibration.displayDeg(12, 12), 0);
      expect(HudLeanCalibration.displayDeg(-4, 8), -12);
    });

    test('wraps around ±180', () {
      expect(HudLeanCalibration.displayDeg(170, -20), -170);
      expect(HudLeanCalibration.displayDeg(-170, 20), 170);
    });

    test('calibrate uses the raw rest angle as zero', () {
      expect(HudLeanCalibration.offsetFromRaw(14.2), 14.2);
      expect(
        HudLeanCalibration.displayDeg(14.2, HudLeanCalibration.offsetFromRaw(14.2)),
        0,
      );
    });

    test('isCalibrated ignores tiny noise', () {
      expect(HudLeanCalibration.isCalibrated(0), isFalse);
      expect(HudLeanCalibration.isCalibrated(0.4), isFalse);
      expect(HudLeanCalibration.isCalibrated(0.5), isTrue);
      expect(HudLeanCalibration.isCalibrated(-3), isTrue);
    });

    test('format keeps a signed degree', () {
      expect(HudLeanCalibration.formatDeg(-12.4), '-12.4°');
      expect(HudLeanCalibration.formatDeg(0, fractionDigits: 0), '0°');
    });

    test('calibrate only when still and IMU has a sample', () {
      expect(
        HudLeanCalibration.canCalibrate(rawLeanDeg: null, speedKmh: 0),
        isFalse,
      );
      expect(
        HudLeanCalibration.canCalibrate(rawLeanDeg: 12, speedKmh: 0.5),
        isTrue,
      );
      expect(
        HudLeanCalibration.canCalibrate(rawLeanDeg: 12, speedKmh: 4),
        isFalse,
      );
      expect(
        HudLeanCalibration.canCalibrate(rawLeanDeg: 12, speedKmh: 22),
        isFalse,
      );
    });

    test('gauge visual clamps, numeral stays honest', () {
      expect(HudLeanCalibration.gaugeVisualDeg(12), 12);
      expect(HudLeanCalibration.gaugeVisualDeg(80), 50);
      expect(HudLeanCalibration.gaugeVisualDeg(-80), -50);
    });

    test('live sample does not wait for mount', () {
      expect(HudLeanCalibration.hasLiveSample(), isFalse);
      expect(HudLeanCalibration.hasLiveSample(leanDeg: 3), isTrue);
      expect(HudLeanCalibration.hasLiveSample(gPeak: 1.2), isTrue);
    });
  });
}
