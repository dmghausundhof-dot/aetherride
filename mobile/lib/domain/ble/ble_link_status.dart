import '../ble.dart';
import 'bike_ble_kind.dart';

/// Rider-facing name for a saved drive. Never "Bosch LDI" / GATT ids.
String bleDriveDisplayName({
  String? storedName,
  String? deviceId,
}) {
  final n = storedName?.trim() ?? '';
  final looksLdi = deviceId == boschLdiAccessoryId ||
      n.toLowerCase() == 'bosch ldi' ||
      n.toLowerCase() == 'ldi';
  if (n.isEmpty || looksLdi) {
    if (looksLdi || deviceId == boschLdiAccessoryId) return 'Intuvia';
    return 'Antrieb';
  }
  return n;
}

String bleWheelDisplayName({String? storedName}) {
  final n = storedName?.trim() ?? '';
  return n.isEmpty ? 'Tempo-Sensor' : n;
}

bool bleDriveIsBoschLdi({String? deviceId, String? kind}) {
  if (deviceId == boschLdiAccessoryId) return true;
  return bikeBleKindFromStorage(kind) == BikeBleKind.bosch;
}

/// Live = streaming metrics, not merely a remembered MAC / Flow pairing.
bool bleBindingLive({
  required bool ldiConnected,
  required bool hasLiveMetrics,
  required String? wheelId,
  required String? driveId,
  required String? driveKind,
  required bool Function(String? id) isRemoteLive,
}) {
  if (hasLiveMetrics &&
      ldiConnected &&
      bleDriveIsBoschLdi(deviceId: driveId, kind: driveKind)) {
    return true;
  }
  if (hasLiveMetrics && isRemoteLive(wheelId)) return true;
  if (hasLiveMetrics && isRemoteLive(driveId)) return true;
  return false;
}
