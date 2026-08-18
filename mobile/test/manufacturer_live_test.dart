import 'package:aetherride_mobile/domain/ble.dart';
import 'package:aetherride_mobile/domain/ble/bike_ble_kind.dart';
import 'package:aetherride_mobile/domain/ble/bosch_ldi_proto.dart';
import 'package:aetherride_mobile/domain/ble/manufacturer_live.dart';
import 'package:flutter_test/flutter_test.dart';

BoschLiveData _ldi({
  double speed = 0,
  double cadence = 0,
  double? soc,
  double? watts,
  double odo = 0,
  bool charger = false,
}) {
  return BoschLiveData(
    speedKmh: speed,
    cadenceRpm: cadence,
    batterySocPercent: soc,
    riderPowerW: watts,
    odometerKm: odo,
    lightStatus: false,
    ambientBrightness: 0,
    systemLock: false,
    bikeNotDriving: speed < 1,
    chargerConnected: charger,
    timestampMs: 1,
  );
}

void main() {
  test('CSC ticker does not wipe LDI SoC or odometer', () {
    var merge = const ManufacturerLiveMerge();
    merge = merge.applyLdi(_ldi(speed: 24.1, cadence: 78, soc: 64, odo: 412));
    final live = merge.emit(cscSpeedKmh: 0, cscCadenceRpm: 0);
    expect(live.batterySocPercent, 64);
    expect(live.odometerKm, 412);
    expect(live.speedKmh, closeTo(24.1, 0.01));
    expect(live.cadenceRpm, 78);
  });

  test('CSC fills speed when LDI frame is sparse', () {
    var merge = const ManufacturerLiveMerge();
    merge = merge.applyLdi(_ldi(soc: 51));
    final live = merge.emit(cscSpeedKmh: 18.2, cscCadenceRpm: 70);
    expect(live.speedKmh, closeTo(18.2, 0.01));
    expect(live.cadenceRpm, 70);
    expect(live.batterySocPercent, 51);
  });

  test('GATT power is not invented; LDI watts win', () {
    var merge = const ManufacturerLiveMerge();
    merge = merge.applyLdi(_ldi(watts: 140));
    final live = merge.emit(
      cscSpeedKmh: 10,
      cscCadenceRpm: 60,
      gattPowerW: 90,
    );
    expect(live.riderPowerW, 140);
  });

  test('raw LDI protobuf bytes merge like a map event', () {
    var merge = const ManufacturerLiveMerge();
    merge = merge.applyLdiFrame(
      decodeBoschLdiFrame(
        encodeBoschLdiTestFrame(
          speedHundredths: 2200,
          batterySoc: 40,
          odometerM: 8000,
        ),
      ),
    );
    final live = merge.emit(cscSpeedKmh: 0, cscCadenceRpm: 0);
    expect(live.speedKmh, closeTo(22, 0.01));
    expect(live.batterySocPercent, 40);
    expect(live.odometerKm, closeTo(8, 0.01));
  });

  test('Bosch pair without live metrics starts LDI, not pop', () {
    expect(
      blePairNextStep(
        connected: true,
        kind: BikeBleKind.bosch,
        hasLiveMetrics: false,
      ),
      BlePairNextStep.tryBoschLdi,
    );
    expect(
      blePairNextStep(
        connected: false,
        kind: BikeBleKind.bosch,
        hasLiveMetrics: false,
      ),
      BlePairNextStep.tryBoschLdi,
    );
    expect(
      blePairNextStep(
        connected: true,
        kind: BikeBleKind.bosch,
        hasLiveMetrics: true,
      ),
      BlePairNextStep.done,
    );
  });

  test('Shimano without live metrics keeps scanning for CSC', () {
    expect(
      blePairNextStep(
        connected: true,
        kind: BikeBleKind.shimano,
        hasLiveMetrics: false,
      ),
      BlePairNextStep.keepScanningWheel,
    );
    expect(
      blePairNextStep(
        connected: false,
        kind: BikeBleKind.csc,
        hasLiveMetrics: false,
      ),
      BlePairNextStep.failed,
    );
  });

  test('LDI accessory always advertises eb20 solicitation', () {
    expect(boschLdiAdvertiseSolicitation(pairing: true), isTrue);
    expect(boschLdiAdvertiseSolicitation(pairing: false), isTrue);
  });

  test('live wheel speed at rest beats GPS drift', () {
    expect(
      rideEffectiveSpeedKmh(
        liveSpeedKmh: 24.1,
        wheelLive: true,
        gpsSpeedKmh: 3.2,
      ),
      closeTo(24.1, 0.01),
    );
    expect(
      rideEffectiveSpeedKmh(
        liveSpeedKmh: 0,
        wheelLive: true,
        gpsSpeedKmh: 2.8,
      ),
      0,
    );
    expect(
      rideEffectiveSpeedKmh(
        liveSpeedKmh: null,
        wheelLive: false,
        gpsSpeedKmh: 18,
      ),
      18,
    );
  });

  test('Bosch LDI retries while the ride is on and the bike is still waking', () {
    expect(
      rideLdiRetryPlan(
        startLdi: true,
        ldiLive: false,
        stillRiding: true,
        attempt: 0,
      ).shouldRetry,
      isTrue,
    );
    expect(
      rideLdiRetryPlan(
        startLdi: true,
        ldiLive: true,
        stillRiding: true,
        attempt: 0,
      ).shouldRetry,
      isFalse,
    );
    expect(
      rideLdiRetryPlan(
        startLdi: true,
        ldiLive: false,
        stillRiding: false,
        attempt: 0,
      ).shouldRetry,
      isFalse,
    );
    expect(
      rideLdiRetryPlan(
        startLdi: true,
        ldiLive: false,
        stillRiding: true,
        attempt: 4,
      ).shouldRetry,
      isFalse,
    );
  });

  test('LDI odometer seeds empty garage km and advances behind values', () {
    expect(
      shouldImportManufacturerOdometer(
        bikeOdometerKm: 0,
        liveOdometerKm: 412,
        fromLdi: true,
      ),
      isTrue,
    );
    expect(
      shouldImportManufacturerOdometer(
        bikeOdometerKm: 400,
        liveOdometerKm: 412,
        fromLdi: true,
      ),
      isTrue,
    );
    expect(
      shouldImportManufacturerOdometer(
        bikeOdometerKm: 412,
        liveOdometerKm: 412.2,
        fromLdi: true,
      ),
      isFalse,
    );
    expect(
      shouldImportManufacturerOdometer(
        bikeOdometerKm: 0,
        liveOdometerKm: 412,
        fromLdi: false,
      ),
      isFalse,
    );
  });
}
