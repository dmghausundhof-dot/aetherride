import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/config.dart';
import '../../domain/sensor.dart';
import 'app_database.dart';

/// Persistiert Sensor-Rohblöcke lokal (Consent `raw_data_upload`) und
/// queued Upload nach Supabase Storage via `POST /api/ride-chunks`.
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

  Future<List<RideChunksMetaData>> pendingUploads({String? rideId}) async {
    final q = _db.select(_db.rideChunksMeta)
      ..where((t) => t.uploadedAt.isNull());
    if (rideId != null) {
      q.where((t) => t.rideId.equals(rideId));
    }
    q.orderBy([(t) => OrderingTerm.asc(t.seq)]);
    return q.get();
  }

  Future<int> pendingCount() async {
    final rows = await pendingUploads();
    return rows.length;
  }

  Future<void> markUploaded({
    required String id,
    required String remotePath,
  }) async {
    await (_db.update(_db.rideChunksMeta)..where((t) => t.id.equals(id))).write(
      RideChunksMetaCompanion(
        uploadedAt: Value(DateTime.now().toUtc()),
        remotePath: Value(remotePath),
      ),
    );
  }

  Future<String?> _accessToken() async {
    if (!AppConfig.isSupabaseConfigured) return null;
    try {
      return Supabase.instance.client.auth.currentSession?.accessToken;
    } catch (_) {
      return null;
    }
  }

  /// Uploads pending chunks (gzip-base64). Returns number successfully uploaded.
  Future<int> uploadPending({
    String? rideId,
    int maxPerRun = 20,
  }) async {
    final token = await _accessToken();
    if (token == null) return 0;

    final pending = await pendingUploads(rideId: rideId);
    var ok = 0;
    for (final row in pending.take(maxPerRun)) {
      final path = row.localPath;
      if (path == null || path.isEmpty) continue;
      final file = File(path);
      if (!await file.exists()) continue;
      final raw = await file.readAsBytes();
      if (raw.length > 5 * 1024 * 1024) continue;
      final gz = gzip.encode(raw);
      final b64 = base64Encode(gz);
      try {
        final res = await http
            .post(
              Uri.parse('${AppConfig.apiBaseUrl}/api/ride-chunks'),
              headers: {
                'Authorization': 'Bearer $token',
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
              body: jsonEncode({
                'rideId': row.rideId,
                'seq': row.seq,
                'encoding': 'gzip-base64',
                'payload': b64,
              }),
            )
            .timeout(const Duration(seconds: 30));
        if (res.statusCode != 200) continue;
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final remote = data['storagePath'] as String? ?? '';
        await markUploaded(id: row.id, remotePath: remote);
        ok += 1;
      } catch (_) {
        // Retry on next pass.
      }
    }
    return ok;
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
