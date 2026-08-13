import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

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

class BikeBleStore {
  BikeBleStore({Future<Directory> Function()? dirProvider})
      : _dirProvider = dirProvider ?? getApplicationDocumentsDirectory;

  final Future<Directory> Function() _dirProvider;
  Map<String, BikeBleDevice>? _cache;

  Future<File> _file() async {
    final dir = await _dirProvider();
    return File(p.join(dir.path, 'bike_ble_devices.json'));
  }

  Future<Map<String, BikeBleDevice>> _load() async {
    final cached = _cache;
    if (cached != null) return cached;
    try {
      final f = await _file();
      if (!await f.exists()) return _cache = {};
      final decoded = jsonDecode(await f.readAsString());
      if (decoded is! Map) return _cache = {};
      final out = <String, BikeBleDevice>{};
      for (final e in decoded.entries) {
        final d = BikeBleDevice.fromJson(e.value);
        if (d != null) out['${e.key}'] = d;
      }
      return _cache = out;
    } catch (_) {
      return _cache = {};
    }
  }

  Future<void> _save(Map<String, BikeBleDevice> map) async {
    _cache = map;
    try {
      final f = await _file();
      await f.writeAsString(
        jsonEncode({for (final e in map.entries) e.key: e.value.toJson()}),
      );
    } catch (_) {}
  }

  Future<BikeBleDevice?> deviceForBike(String bikeId) async {
    final map = await _load();
    return map[bikeId];
  }

  Future<void> saveForBike(String bikeId, BikeBleDevice device) async {
    final map = Map<String, BikeBleDevice>.from(await _load());
    map[bikeId] = device;
    await _save(map);
  }

  Future<void> removeForBike(String bikeId) async {
    final map = Map<String, BikeBleDevice>.from(await _load());
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
