import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../domain/ble/bike_ble_kind.dart';
import '../../domain/ble/ble_link_status.dart';

/// Gekoppelter BLE-Sensor je Bike (Komoot-Klasse-UX: Rad auswählen ⇒ Sensor
/// verbindet automatisch). JSON-Datei statt Drift-Migration — das Mapping ist
/// klein, gerätelokal und unkritisch.
class BikeBleDevice {
  const BikeBleDevice({required this.deviceId, this.name, this.kind});

  final String deviceId;
  final String? name;

  /// `bosch` | `shimano` | `yamaha` | `csc` | `power` | `otherDrive`
  final String? kind;

  Map<String, dynamic> toJson() => {
        'deviceId': deviceId,
        if (name != null) 'name': name,
        if (kind != null) 'kind': kind,
      };

  static BikeBleDevice? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['deviceId'];
    if (id is! String || id.isEmpty) return null;
    final kind = raw['kind'];
    return BikeBleDevice(
      deviceId: id,
      name: raw['name'] as String?,
      kind: kind is String && kind.isNotEmpty ? kind : null,
    );
  }
}

/// Antrieb-Identität und Radsensor getrennt — sonst überschreibt Intuvia den CSC.
class BikeBleBinding {
  const BikeBleBinding({this.wheel, this.drive});

  final BikeBleDevice? wheel;
  final BikeBleDevice? drive;

  bool get isEmpty => wheel == null && drive == null;

  BikeBleBinding copyWith({
    BikeBleDevice? wheel,
    BikeBleDevice? drive,
    bool clearWheel = false,
    bool clearDrive = false,
  }) {
    return BikeBleBinding(
      wheel: clearWheel ? null : (wheel ?? this.wheel),
      drive: clearDrive ? null : (drive ?? this.drive),
    );
  }

  Map<String, dynamic> toJson() => {
        if (wheel != null) 'wheel': wheel!.toJson(),
        if (drive != null) 'drive': drive!.toJson(),
      };

  static BikeBleBinding fromJson(Object? raw) {
    if (raw is! Map) return const BikeBleBinding();
    if (raw.containsKey('deviceId')) {
      final d = BikeBleDevice.fromJson(raw);
      if (d == null) return const BikeBleBinding();
      return splitLegacyDevice(d);
    }
    return BikeBleBinding(
      wheel: BikeBleDevice.fromJson(raw['wheel']),
      drive: BikeBleDevice.fromJson(raw['drive']),
    );
  }
}

/// Altbestand: ein Gerät pro Bike. Drive-Kind → drive-Slot, sonst Rad.
BikeBleBinding splitLegacyDevice(BikeBleDevice device) {
  final kind = bikeBleKindFromStorage(device.kind);
  if (kind != null && bikeBleKindIsDrive(kind)) {
    return BikeBleBinding(drive: device);
  }
  return BikeBleBinding(wheel: device);
}

bool bikeBleDeviceIsDrive(BikeBleDevice device) {
  final kind = bikeBleKindFromStorage(device.kind);
  return kind != null && bikeBleKindIsDrive(kind);
}

/// Ride auto-connect: nur der Radsensor ist ein GATT-Ziel.
({String? deviceId, BikeBleKind? kindHint}) rideBlePreferredTarget(
  BikeBleBinding binding,
) {
  final wheel = binding.wheel;
  if (wheel == null) return (deviceId: null, kindHint: null);
  return (
    deviceId: wheel.deviceId,
    kindHint: bikeBleKindFromStorage(wheel.kind),
  );
}

/// Werkstatt: gespeicherten CSC wecken, Bosch-LDI zusätzlich anbieten.
/// Kein Scan — sonst klaut die Suche die Kopplungs-Sheet-Session.
({String? wheelId, BikeBleKind? wheelKind, bool startLdi}) garageBleWakePlan(
  BikeBleBinding binding,
) {
  final wheel = binding.wheel;
  final drive = binding.drive;
  final wheelId =
      (wheel != null && wheel.deviceId.isNotEmpty) ? wheel.deviceId : null;
  return (
    wheelId: wheelId,
    wheelKind: wheel == null ? null : bikeBleKindFromStorage(wheel.kind),
    startLdi: drive != null &&
        bleDriveIsBoschLdi(deviceId: drive.deviceId, kind: drive.kind),
  );
}

class BikeBleStore {
  BikeBleStore({Future<Directory> Function()? dirProvider})
      : _dirProvider = dirProvider ?? getApplicationDocumentsDirectory;

  final Future<Directory> Function() _dirProvider;
  Map<String, BikeBleBinding>? _cache;

  Future<File> _file() async {
    final dir = await _dirProvider();
    return File(p.join(dir.path, 'bike_ble_devices.json'));
  }

  Future<Map<String, BikeBleBinding>> _load() async {
    final cached = _cache;
    if (cached != null) return cached;
    try {
      final f = await _file();
      if (!await f.exists()) return _cache = {};
      final decoded = jsonDecode(await f.readAsString());
      if (decoded is! Map) return _cache = {};
      final out = <String, BikeBleBinding>{};
      for (final e in decoded.entries) {
        final b = BikeBleBinding.fromJson(e.value);
        if (!b.isEmpty) out['${e.key}'] = b;
      }
      return _cache = out;
    } catch (_) {
      return _cache = {};
    }
  }

  Future<void> _save(Map<String, BikeBleBinding> map) async {
    _cache = map;
    try {
      final f = await _file();
      await f.writeAsString(
        jsonEncode({for (final e in map.entries) e.key: e.value.toJson()}),
      );
    } catch (_) {}
  }

  Future<BikeBleBinding> bindingForBike(String bikeId) async {
    final map = await _load();
    return map[bikeId] ?? const BikeBleBinding();
  }

  /// Rad-Slot, sonst Drive — nur für „irgendetwas gemerkt“, nicht für GATT.
  Future<BikeBleDevice?> deviceForBike(String bikeId) async {
    final b = await bindingForBike(bikeId);
    return b.wheel ?? b.drive;
  }

  Future<void> saveWheel(String bikeId, BikeBleDevice device) async {
    final map = Map<String, BikeBleBinding>.from(await _load());
    final prev = map[bikeId] ?? const BikeBleBinding();
    map[bikeId] = prev.copyWith(wheel: device);
    await _save(map);
  }

  Future<void> saveDrive(String bikeId, BikeBleDevice device) async {
    final map = Map<String, BikeBleBinding>.from(await _load());
    final prev = map[bikeId] ?? const BikeBleBinding();
    map[bikeId] = prev.copyWith(drive: device);
    await _save(map);
  }

  /// Paar-Sheet: Drive und Rad landen in getrennten Slots.
  Future<void> saveForBike(String bikeId, BikeBleDevice device) async {
    if (bikeBleDeviceIsDrive(device)) {
      await saveDrive(bikeId, device);
    } else {
      await saveWheel(bikeId, device);
    }
  }

  Future<void> removeWheel(String bikeId) async {
    final map = Map<String, BikeBleBinding>.from(await _load());
    final prev = map[bikeId];
    if (prev == null) return;
    final next = prev.copyWith(clearWheel: true);
    if (next.isEmpty) {
      map.remove(bikeId);
    } else {
      map[bikeId] = next;
    }
    await _save(map);
  }

  Future<void> removeDrive(String bikeId) async {
    final map = Map<String, BikeBleBinding>.from(await _load());
    final prev = map[bikeId];
    if (prev == null) return;
    final next = prev.copyWith(clearDrive: true);
    if (next.isEmpty) {
      map.remove(bikeId);
    } else {
      map[bikeId] = next;
    }
    await _save(map);
  }

  Future<void> removeForBike(String bikeId) async {
    final map = Map<String, BikeBleBinding>.from(await _load());
    map.remove(bikeId);
    await _save(map);
  }

  /// Rider-level smartwatch / HR strap — not a bike part, separate file
  /// so pairing a watch never overwrites the CSC mapping or the bike record.
  Future<File> _watchFile() async {
    final dir = await _dirProvider();
    return File(p.join(dir.path, 'watch_ble_device.json'));
  }

  Future<BikeBleDevice?> savedWatch() async {
    try {
      final f = await _watchFile();
      if (!await f.exists()) return null;
      return BikeBleDevice.fromJson(jsonDecode(await f.readAsString()));
    } catch (_) {
      return null;
    }
  }

  Future<void> saveWatch(BikeBleDevice device) async {
    try {
      final f = await _watchFile();
      await f.writeAsString(jsonEncode(device.toJson()));
    } catch (_) {}
  }

  Future<void> removeWatch() async {
    try {
      final f = await _watchFile();
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }
}
