import 'package:flutter/foundation.dart';

/// Sync-Engine-Stub: zieht/pusht Snapshots im Hintergrund (Web: `/api/sync`).
/// UI bleibt offline-fähig — niemals direkter Netz-Lesepfad aus Widgets.
class SyncEngine {
  bool _running = false;

  bool get isRunning => _running;

  Future<void> start() async {
    if (_running) return;
    _running = true;
    debugPrint('SyncEngine: gestartet (Stub)');
  }

  Future<void> stop() async {
    _running = false;
  }

  Future<void> pullNow() async {
    debugPrint('SyncEngine: pullNow (Stub)');
  }

  Future<void> pushNow() async {
    debugPrint('SyncEngine: pushNow (Stub)');
  }
}
