import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:maplibre_gl/maplibre_gl.dart' as ml;

import 'map_style_url.dart';
import 'offline_pack_catalog.dart';

enum OfflineBasemapResult { success, failed, timedOut, skippedPmtiles }

/// MapLibre OfflineRegion download for a pack bbox (basemap tiles).
///
/// `downloadOfflineRegion` returns when the region is *created*, not when
/// tiles are on disk. Callers must wait for [OfflineBasemapResult.success].
abstract final class OfflineBasemap {
  static const tileCountLimit = 100000;
  static const downloadTimeout = Duration(seconds: 180);

  static Future<void> applyNetworkMode({required bool online}) async {
    try {
      await ml.setOffline(!online);
    } catch (_) {}
  }

  static Future<bool> hasNetwork({
    Duration timeout = const Duration(seconds: 2),
  }) async {
    try {
      final result = await InternetAddress.lookup('dns.google').timeout(timeout);
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static Future<void> applyDetectedNetworkMode() async {
    final online = await hasNetwork();
    await applyNetworkMode(online: online);
  }

  static Future<bool> hasAnyRegion() async {
    try {
      final list = await ml.getListOfRegions();
      return list.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> hasRegionId(String regionId) async {
    try {
      final list = await ml.getListOfRegions();
      return list.any((r) => '${r.metadata['regionId']}' == regionId);
    } catch (_) {
      return false;
    }
  }

  static Future<void> deleteRegionId(String regionId) async {
    try {
      final list = await ml.getListOfRegions();
      for (final r in list) {
        if ('${r.metadata['regionId']}' == regionId) {
          await ml.deleteOfflineRegion(r.id);
        }
      }
    } catch (_) {}
  }

  static Future<OfflineBasemapResult> download({
    required String regionId,
    required String name,
    required List<double> bbox,
    required String mapStyleUrl,
    void Function(double progress01)? onProgress,
  }) async {
    if (bbox.length < 4) return OfflineBasemapResult.failed;
    if (skipMapLibreOfflineRegion(mapStyleUrl)) {
      debugPrint(
        'OfflineBasemap: skip OfflineRegion for PMTiles/DACH style',
      );
      return OfflineBasemapResult.skippedPmtiles;
    }
    try {
      await ml.setOfflineTileCountLimit(tileCountLimit);
    } catch (_) {}
    await deleteRegionId(regionId);
    final done = Completer<OfflineBasemapResult>();
    try {
      await ml.downloadOfflineRegion(
        ml.OfflineRegionDefinition(
          bounds: ml.LatLngBounds(
            southwest: ml.LatLng(bbox[1], bbox[0]),
            northeast: ml.LatLng(bbox[3], bbox[2]),
          ),
          mapStyleUrl: mapStyleUrl,
          minZoom: kBasemapMinZoom,
          maxZoom: maxBasemapZoomForBbox(bbox),
          includeIdeographs: false,
        ),
        metadata: {'regionId': regionId, 'name': name},
        onEvent: (event) {
          if (event is ml.InProgress) {
            debugPrint(
              'OfflineBasemap progress ${event.progress}',
            );
            onProgress?.call(normalizeOfflineProgress(event.progress));
          } else if (event is ml.Success) {
            if (!done.isCompleted) {
              done.complete(OfflineBasemapResult.success);
            }
          } else if (event is ml.Error) {
            debugPrint('OfflineBasemap error: ${event.cause}');
            if (!done.isCompleted) {
              done.complete(OfflineBasemapResult.failed);
            }
          }
        },
      );
      return await done.future.timeout(
        downloadTimeout,
        onTimeout: () {
          debugPrint('OfflineBasemap.download: tile wait timed out');
          return OfflineBasemapResult.timedOut;
        },
      );
    } catch (e) {
      debugPrint('OfflineBasemap.download: $e');
      if (!done.isCompleted) {
        return OfflineBasemapResult.failed;
      }
      return done.future;
    }
  }
}
