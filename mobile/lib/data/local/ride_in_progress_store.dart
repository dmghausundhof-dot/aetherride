import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../domain/ride/ride_in_progress.dart';

/// Crash-recovery file next to [RidePrefs] — not the Drift `rides` table.
///
/// Finished tours still go through [RideRepository.endRide]. An in-progress
/// row would leak into history, stats, and garage sync.
abstract final class RideInProgressStore {
  static const fileName = 'ride_in_progress.json';

  /// Tests inject a temp dir so we do not touch the real app-support path.
  static Directory? debugDirectory;

  static File? _cached;

  static Future<File> _file() async {
    if (_cached != null && debugDirectory == null) return _cached!;
    final dir = debugDirectory ?? await getApplicationSupportDirectory();
    final f = File(p.join(dir.path, fileName));
    _cached = f;
    return f;
  }

  static Future<RideInProgressDraft?> read() async {
    try {
      final f = await _file();
      if (!await f.exists()) return null;
      final decoded = jsonDecode(await f.readAsString());
      return RideInProgressDraft.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  static Future<void> write(RideInProgressDraft draft) async {
    final f = await _file();
    await _writeAtomic(f, jsonEncode(draft.toJson()));
  }

  /// Best-effort flush when the OS is about to kill us (lifecycle pause).
  static void writeSync(RideInProgressDraft draft) {
    final f = _cached;
    if (f == null) return;
    try {
      _writeAtomicSync(f, jsonEncode(draft.toJson()));
    } catch (_) {}
  }

  static Future<void> clear() async {
    try {
      final f = await _file();
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }

  static Future<void> _writeAtomic(File f, String payload) async {
    final tmp = File('${f.path}.tmp');
    await tmp.writeAsString(payload, flush: true);
    try {
      await tmp.rename(f.path);
    } catch (_) {
      await f.writeAsString(payload, flush: true);
      try {
        await tmp.delete();
      } catch (_) {}
    }
  }

  static void _writeAtomicSync(File f, String payload) {
    final tmp = File('${f.path}.tmp');
    tmp.writeAsStringSync(payload, flush: true);
    try {
      tmp.renameSync(f.path);
    } catch (_) {
      f.writeAsStringSync(payload, flush: true);
      try {
        tmp.deleteSync();
      } catch (_) {}
    }
  }
}
