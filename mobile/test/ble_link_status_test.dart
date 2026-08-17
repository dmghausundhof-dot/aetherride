import 'package:aetherride_mobile/domain/ble.dart';
import 'package:aetherride_mobile/domain/ble/ble_link_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Bosch LDI storage shows as Intuvia', () {
    expect(
      bleDriveDisplayName(storedName: 'Bosch LDI', deviceId: boschLdiAccessoryId),
      'Intuvia',
    );
    expect(
      bleDriveDisplayName(storedName: null, deviceId: boschLdiAccessoryId),
      'Intuvia',
    );
    expect(
      bleDriveDisplayName(storedName: 'Intuvia 100', deviceId: 'AA:BB'),
      'Intuvia 100',
    );
  });

  test('LDI accessory counts as live for a saved Bosch drive', () {
    expect(
      bleBindingLive(
        ldiConnected: true,
        hasLiveMetrics: true,
        wheelId: null,
        driveId: boschLdiAccessoryId,
        driveKind: 'bosch',
        isRemoteLive: (_) => false,
      ),
      isTrue,
    );
    expect(
      bleBindingLive(
        ldiConnected: false,
        hasLiveMetrics: true,
        wheelId: null,
        driveId: boschLdiAccessoryId,
        driveKind: 'bosch',
        isRemoteLive: (_) => false,
      ),
      isFalse,
    );
    expect(
      bleBindingLive(
        ldiConnected: false,
        hasLiveMetrics: true,
        wheelId: 'csc-1',
        driveId: boschLdiAccessoryId,
        driveKind: 'bosch',
        isRemoteLive: (id) => id == 'csc-1',
      ),
      isTrue,
    );
  });
}
