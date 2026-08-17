import 'package:aetherride_mobile/domain/ble.dart';
import 'package:aetherride_mobile/domain/ble/garage_ble_live.dart';
import 'package:aetherride_mobile/domain/bike.dart';
import 'package:flutter_test/flutter_test.dart';

BoschLiveData _live({
  double speed = 0,
  double cadence = 0,
  double? soc,
  double? watts,
  bool charger = false,
}) {
  return BoschLiveData(
    speedKmh: speed,
    cadenceRpm: cadence,
    batterySocPercent: soc,
    riderPowerW: watts,
    odometerKm: 0,
    lightStatus: false,
    ambientBrightness: 0,
    systemLock: false,
    bikeNotDriving: speed < 1,
    chargerConnected: charger,
    timestampMs: 1,
  );
}

void main() {
  group('blePairSheetBodyHeight', () {
    test('A54-sized screen stays under the status bar', () {
      const screen = 2340.0;
      const top = 40.0;
      const bottom = 64.0;
      final h = blePairSheetBodyHeight(
        screenHeight: screen,
        safeTop: top,
        safeBottom: bottom,
      );
      expect(h, lessThanOrEqualTo(screen - top));
      expect(h, greaterThanOrEqualTo(320));
      expect(h, lessThan(screen));
    });

    test('tiny screen does not go negative', () {
      final h = blePairSheetBodyHeight(
        screenHeight: 200,
        safeTop: 40,
        safeBottom: 40,
      );
      expect(h, greaterThanOrEqualTo(0));
      expect(h, lessThanOrEqualTo(160));
    });
  });

  group('wheelCircumferenceM', () {
    test('700c and 29 share garage and HUD', () {
      expect(wheelCircumferenceM(WheelSize.c700), 2.130);
      expect(wheelCircumferenceM(WheelSize.w29), 2.105);
      expect(wheelCircumferenceM(null), 2.105);
    });
  });

  group('garageBleLiveChips', () {
    test('saved MAC invents nothing', () {
      expect(
        garageBleLiveChipsFromData(
          live: false,
          hasCrank: true,
          data: _live(speed: 22, cadence: 80, soc: 64),
        ),
        isEmpty,
      );
    });

    test('CSC speed and cadence while connected', () {
      expect(
        garageBleLiveChipsFromData(
          live: true,
          hasCrank: true,
          data: _live(speed: 24.14, cadence: 78.4),
        ),
        ['24.1 km/h', '78 rpm'],
      );
    });

    test('GPS-still speed under 0.5 is omitted', () {
      expect(
        garageBleLiveChips(
          live: true,
          hasCrank: false,
          speedKmh: 0.4,
        ),
        isEmpty,
      );
    });

    test('SoC and charger only when the drive actually sent them', () {
      expect(
        garageBleLiveChipsFromData(
          live: true,
          hasCrank: false,
          data: _live(soc: 64.2, charger: true),
        ),
        ['64 %', 'Lader'],
      );
    });

    test('spin hint when live but the wheel is still', () {
      expect(
        garageBleShowSpinHint(live: true, chips: const []),
        isTrue,
      );
      expect(
        garageBleShowSpinHint(live: true, chips: const ['24.1 km/h']),
        isFalse,
      );
      expect(
        garageBleShowSpinHint(live: false, chips: const []),
        isFalse,
      );
    });
  });

  group('garageBleShowBatteryHonesty', () {
    test('empty e-bike does not lecture about SoC', () {
      expect(
        garageBleShowBatteryHonesty(
          isEbike: true,
          hasBinding: false,
          batterySocPercent: null,
        ),
        isFalse,
      );
    });

    test('acoustic bike never claims a drive battery', () {
      expect(
        garageBleShowBatteryHonesty(
          isEbike: false,
          hasBinding: true,
          batterySocPercent: null,
        ),
        isFalse,
      );
    });

    test('paired e-bike without live SoC stays honest', () {
      expect(
        garageBleShowBatteryHonesty(
          isEbike: true,
          hasBinding: true,
          batterySocPercent: null,
        ),
        isTrue,
      );
    });

    test('live SoC hides the honesty line', () {
      expect(
        garageBleShowBatteryHonesty(
          isEbike: true,
          hasBinding: true,
          batterySocPercent: 64,
        ),
        isFalse,
      );
    });
  });
}
