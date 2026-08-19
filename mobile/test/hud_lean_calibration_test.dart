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
  });
}
