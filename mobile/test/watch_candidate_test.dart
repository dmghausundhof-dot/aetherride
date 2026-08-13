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
  });

  test('CSC box is not a watch candidate', () {
    expect(
      isWatchCandidate(
        platformName: 'Magene S3+',
        advertisedServiceUuids: const [
          '00001816-0000-1000-8000-00805f9b34fb',
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
}
