import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../domain/routing/battery_preset.dart';

/// Light mid-ride preferences (battery preset, first-ask flag).
/// JSON file under app support — no SharedPreferences plugin required.
abstract final class RidePrefs {
  static const fileName = 'ride_prefs.json';

  static Future<File> _file() async {
    final dir = await getApplicationSupportDirectory();
    return File(p.join(dir.path, fileName));
  }

  static Future<Map<String, dynamic>> read() async {
    try {
      final f = await _file();
      if (!await f.exists()) return {};
      final decoded = jsonDecode(await f.readAsString());
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return {};
  }

  static Future<void> merge(Map<String, dynamic> patch) async {
    final f = await _file();
    final m = await read();
    for (final e in patch.entries) {
      if (e.value == null) {
        m.remove(e.key);
      } else {
        m[e.key] = e.value;
      }
    }
    await f.writeAsString(jsonEncode(m));
  }

  static Future<RideBatteryPreset> batteryPreset() async {
    final m = await read();
    return RideBatteryPresetX.fromId(m['batteryPreset'] as String?);
  }

  static Future<void> setBatteryPreset(RideBatteryPreset preset) async {
    await merge({
      'batteryPreset': preset.id,
      'batteryPresetChosen': true,
    });
  }

  /// True after the rider has explicitly picked a preset at least once.
  static Future<bool> batteryPresetChosen() async {
    final m = await read();
    return m['batteryPresetChosen'] == true;
  }
}
