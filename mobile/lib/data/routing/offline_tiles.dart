import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../native/routing_core_ffi.dart';
import 'offline_maps_prefs.dart';
import 'offline_pack_dirs.dart';

/// Copies bundled `offline_graph.json` into app support for FFI file access.
///
/// Prefers an activated region pack path from [OfflineMapsPrefs]
/// (`offline_maps_prefs.json` → `activatedPackPath`).
///
/// Valhalla tile extracts need `librouting_core` built with `--features valhalla`
/// (see `RoutingCoreFfi.valhallaLinkStatus` / `RoutingCoreCodes.valhallaUnlinked`).
class OfflineTilesStore {
  OfflineTilesStore._();
  static final instance = OfflineTilesStore._();

  String? _cachedPath;
  final _ffi = RoutingCoreFfi();

  void clearCache() => _cachedPath = null;

  /// Directory containing `offline_graph.json` (or override via [overridePath]).
  ///
  /// [bundledFallback] copies the Schwarzwald demo graph when no pack is
  /// activated — routing must pass `false` so Heidelberg never gets Todtnau.
  Future<String?> ensureTilesPath({
    String? overridePath,
    bool bundledFallback = true,
  }) async {
    if (overridePath != null && overridePath.isNotEmpty) {
      final asFile = File(overridePath);
      if (await asFile.exists()) {
        return p.dirname(overridePath);
      }
      final asDir = Directory(overridePath);
      if (await asDir.exists()) return overridePath;
    }

    final activated = await OfflineMapsPrefs.activatedPackPath();
    if (activated != null && activated.isNotEmpty) {
      final activatedDir = Directory(activated);
      final legitimate = await OfflinePackDirs.directoryIsLegitimate(
        activatedDir,
      );
      if (legitimate) {
        final graphInDir = File(p.join(activated, 'offline_graph.json'));
        final valhallaInDir = File(p.join(activated, 'valhalla.json'));
        final tilesDir = Directory(p.join(activated, 'tiles'));
        if (await graphInDir.exists() ||
            await valhallaInDir.exists() ||
            await tilesDir.exists()) {
          _cachedPath = activated;
          return activated;
        }
        final asFile = File(activated);
        if (await asFile.exists()) {
          _cachedPath = p.dirname(activated);
          return _cachedPath;
        }
        final asDir = Directory(activated);
        if (await asDir.exists()) {
          _cachedPath = activated;
          return activated;
        }
      }
    }

    if (_cachedPath != null) return _cachedPath;

    if (!bundledFallback) return null;

    final support = await getApplicationSupportDirectory();
    final dir = Directory(p.join(support.path, 'routing'));
    await dir.create(recursive: true);
    final target = File(p.join(dir.path, 'offline_graph.json'));
    if (!await target.exists()) {
      final data = await rootBundle.load('assets/routing/offline_graph.json');
      await target.writeAsBytes(data.buffer.asUint8List());
    }
    // Do not cache the bundled demo path — routing uses bundledFallback: false.
    return dir.path;
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
    return '$engine'
        '${linked ? ' · Valhalla-Feature verfügbar' : ' · Valhalla nicht gelinkt'}';
  }
}
