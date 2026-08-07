import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../native/routing_core_ffi.dart';

/// Copies bundled `offline_graph.json` into app support for FFI file access.
///
/// Valhalla tile extracts need `librouting_core` built with `--features valhalla`
/// (see `RoutingCoreFfi.valhallaLinkStatus` / `RoutingCoreCodes.valhallaUnlinked`).
class OfflineTilesStore {
  OfflineTilesStore._();
  static final instance = OfflineTilesStore._();

  String? _cachedPath;
  final _ffi = RoutingCoreFfi();

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

  /// Human-readable Valhalla / offline engine status for UI.
  Future<String> valhallaLinkStatus({String? overridePath}) async {
    final path = await ensureTilesPath(overridePath: overridePath);
    if (path == null) return 'keine Tiles';
    if (!_ffi.available) {
      return 'FFI fehlt — graph-only / Valhalla-Flag nicht gelinkt';
    }
    final engine = _ffi.engineForTiles(path) ?? 'none';
    final linked = _ffi.isValhallaLinked();
    if (engine == 'valhalla') {
      return linked
          ? 'Valhalla-Tiles · libvalhalla gelinkt'
          : 'Valhalla-Tiles · UNLINKED (Code ${RoutingCoreCodes.valhallaUnlinked})';
    }
    return 'Engine: $engine'
        '${linked ? ' · Valhalla-Feature verfügbar' : ' · Valhalla nicht gelinkt'}';
  }
}
