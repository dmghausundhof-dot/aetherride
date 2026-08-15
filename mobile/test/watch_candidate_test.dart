import 'package:aetherride_mobile/domain/ble/watch_candidate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Heart Rate 0x180D advertisement is a candidate', () {
    expect(
      isWatchCandidate(
        platformName: '',
        advertisedServiceUuids: const [
          '0000180d-0000-1000-8000-00805f9b34fb',
        ],
      ),
      isTrue,
    );
  });

  test('watch-ish names are candidates even without 0x180D in ads', () {
    expect(
      isWatchCandidate(
        platformName: 'Polar Vantage M2',
        advertisedServiceUuids: const [],
      ),
      isTrue,
    );
    expect(
      isWatchCandidate(
        platformName: 'Garmin Fenix 7',
        advertisedServiceUuids: const ['0000fe00-0000-1000-8000-00805f9b34fb'],
      ),
      isTrue,
    );
    expect(
      isWatchCandidate(
        platformName: 'Galaxy Watch6',
        advertisedServiceUuids: const [],
      ),
      isTrue,
    );
    expect(
      isWatchCandidate(
        platformName: 'Apple Watch',
        advertisedServiceUuids: const [],
      ),
      isTrue,
    );
  });

  test('buds, TVs and generic galaxy/watch tokens are not candidates', () {
    expect(
      isWatchCandidate(
        platformName: 'Galaxy Buds2 Pro',
        advertisedServiceUuids: const [],
      ),
      isFalse,
    );
    expect(
      isWatchCandidate(
        platformName: 'Powerbeats Pro',
        advertisedServiceUuids: const [],
      ),
      isFalse,
    );
    expect(
      isWatchCandidate(
        platformName: 'Samsung TV',
        advertisedServiceUuids: const [],
      ),
      isFalse,
    );
    expect(
      isWatchCandidate(
        platformName: 'Galaxy',
        advertisedServiceUuids: const [],
      ),
      isFalse,
    );
  });

  test('CSC / power boxes are not watches even with Garmin in the name', () {
    expect(
      isWatchCandidate(
        platformName: 'Magene S3+',
        advertisedServiceUuids: const [
          '00001816-0000-1000-8000-00805f9b34fb',
        ],
      ),
      isFalse,
    );
    expect(
      isWatchCandidate(
        platformName: 'Garmin Rally',
        advertisedServiceUuids: const [
          '00001818-0000-1000-8000-00805f9b34fb',
        ],
      ),
      isFalse,
    );
  });

  test('vendor UUID without watch name is not a candidate', () {
    expect(
      isWatchCandidate(
        platformName: 'Unknown Peripheral',
        advertisedServiceUuids: const [
          '0000fe00-0000-1000-8000-00805f9b34fb',
        ],
      ),
      isFalse,
    );
  });

  test('honesty labels match brand', () {
    expect(
      watchHonestyForName('Polar H10'),
      WatchHonesty.hrBroadcast,
    );
    expect(
      watchHonestyForName('Wahoo TICKR'),
      WatchHonesty.hrBroadcast,
    );
    expect(
      watchHonestyForName('Garmin Fenix 7'),
      WatchHonesty.garminNeedsBroadcast,
    );
    expect(
      watchHonestyForName('Apple Watch'),
      WatchHonesty.appleUnsupported,
    );
    expect(
      watchHonestyForName('Galaxy Watch6'),
      WatchHonesty.galaxyLimited,
    );
    expect(watchHonestyPairable(WatchHonesty.appleUnsupported), isFalse);
    expect(watchHonestyPairable(WatchHonesty.garminNeedsBroadcast), isTrue);
  });

  test('Apple Watch without advertised 0x180D is not pairable', () {
    const hit = WatchBleScanHit(
      deviceId: 'AW',
      name: 'Apple Watch',
      rssi: -50,
      hasHrService: false,
      honesty: WatchHonesty.appleUnsupported,
    );
    expect(hit.pairable, isFalse);
  });

  test('Polar with 0x180D is pairable', () {
    const hit = WatchBleScanHit(
      deviceId: 'P',
      name: 'Polar H10',
      rssi: -45,
      hasHrService: true,
      honesty: WatchHonesty.hrBroadcast,
    );
    expect(hit.pairable, isTrue);
  });
}
