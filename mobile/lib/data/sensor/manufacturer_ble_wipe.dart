import '../../native/ble_core_channel.dart';
import 'bike_ble_store.dart';

/// Drop live links and delete every manufacturer pairing file on this device.
/// Ride tracks stay in SQLite — this is only Bosch/Shimano/SIG ids.
Future<void> wipeManufacturerBleData({
  required BikeBleStore store,
  required BleCoreChannel ble,
}) async {
  try {
    await ble.disconnect();
  } catch (_) {}
  try {
    await ble.forgetAllPairedIds();
  } catch (_) {}
  await store.clearAll();
}
