import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Shared prefs file for offline maps / region packs (`offline_maps_prefs.json`).
abstract final class OfflineMapsPrefs {
  static const fileName = 'offline_maps_prefs.json';

  static Future<File> file() async {
    final dir = await getApplicationSupportDirectory();
    return File(p.join(dir.path, fileName));
  }

  static Future<Map<String, dynamic>> read() async {
    try {
      final f = await file();
      if (!await f.exists()) return {};
      final decoded = jsonDecode(await f.readAsString());
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return {};
  }

  static Future<void> merge(Map<String, dynamic> patch) async {
    final f = await file();
    final m = await read();
    m.addAll(patch);
    await f.writeAsString(jsonEncode(m));
  }

  /// Activated region directory (contains `offline_graph.json`) or null.
  static Future<String?> activatedPackPath() async {
    final m = await read();
    final path = m['activatedPackPath'] as String?;
    if (path == null || path.isEmpty) return null;
    return path;
  }
}
