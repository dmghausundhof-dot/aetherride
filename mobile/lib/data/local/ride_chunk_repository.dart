import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../domain/sensor.dart';
import 'app_database.dart';

/// Persistiert Sensor-Rohblöcke lokal (Consent `raw_data_upload`).
class RideChunkRepository {
  RideChunkRepository(this._db);

  final AppDatabase _db;
  final _uuid = const Uuid();

  /// Schreibt einen Chunk aus gesammelten [SensorBlock]s.
  /// Datei: `Documents/ride_chunks/{rideId}/{seq}.json` + Meta in Drift.
  Future<void> appendChunk({
    required String rideId,
    required int seq,
    required List<SensorBlock> blocks,
  }) async {
    if (blocks.isEmpty) return;

    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'ride_chunks', rideId));
    await dir.create(recursive: true);
    final file = File(p.join(dir.path, '$seq.json'));

    final windowStart = DateTime.fromMillisecondsSinceEpoch(
      blocks.first.windowStartMs,
      isUtc: true,
    );
    final windowEnd = DateTime.fromMillisecondsSinceEpoch(
      blocks.last.windowEndMs,
      isUtc: true,
    );

    final payload = {
      'rideId': rideId,
      'seq': seq,
      'windowStartMs': blocks.first.windowStartMs,
      'windowEndMs': blocks.last.windowEndMs,
      'blocks': [for (final b in blocks) _blockToJson(b)],
    };
    await file.writeAsString(jsonEncode(payload));

    await _db.into(_db.rideChunksMeta).insert(
          RideChunksMetaCompanion.insert(
            id: _uuid.v4(),
            rideId: rideId,
            seq: seq,
            windowStart: windowStart,
            windowEnd: windowEnd,
            localPath: Value(file.path),
          ),
        );
  }

  Map<String, dynamic> _blockToJson(SensorBlock b) => {
        'windowStartMs': b.windowStartMs,
        'windowEndMs': b.windowEndMs,
        'sampleRateHz': b.sampleRateHz,
        'sampleCount': b.samples.length,
        if (b.fused != null)
          'fused': {
            'timestampMs': b.fused!.timestampMs,
            'gForcePeak': b.fused!.gForcePeak,
            'gForceRms': b.fused!.gForceRms,
            'leanAngleDeg': b.fused!.leanAngleDeg,
            'impactDetected': b.fused!.impactDetected,
            'impactMagnitude': b.fused!.impactMagnitude,
            'flowContribution': b.fused!.flowContribution,
            if (b.fused!.estimatedTravelUsagePct != null)
              'estimatedTravelUsagePct': b.fused!.estimatedTravelUsagePct,
          },
        // Rohsamples nur kompakt (t + accel) — Upload später
        'samples': [
          for (final s in b.samples)
            {
              't': s.tMs,
              'ax': s.ax,
              'ay': s.ay,
              'az': s.az,
            },
        ],
      };
}
