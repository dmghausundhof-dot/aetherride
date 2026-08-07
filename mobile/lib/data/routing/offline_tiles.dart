import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Copies bundled `offline_graph.json` into app support for FFI file access.
class OfflineTilesStore {
  OfflineTilesStore._();
  static final instance = OfflineTilesStore._();

  String? _cachedPath;

  /// Directory containing `offline_graph.json` (or override via [overridePath]).
  Future<String?> ensureTilesPath({String? overridePath}) async {
    if (overridePath != null && overridePath.isNotEmpty) {
      final f = File(overridePath);
      if (await f.exists()) return overridePath;
      final d = Directory(overridePath);
      if (await d.exists()) return overridePath;
    }
    if (_cachedPath != null) return _cachedPath;

    final support = await getApplicationSupportDirectory();
    final dir = Directory(p.join(support.path, 'routing'));
    await dir.create(recursive: true);
    final target = File(p.join(dir.path, 'offline_graph.json'));
    if (!await target.exists()) {
      final data = await rootBundle.load('assets/routing/offline_graph.json');
      await target.writeAsBytes(data.buffer.asUint8List());
    }
    _cachedPath = dir.path;
    return _cachedPath;
  }
}
