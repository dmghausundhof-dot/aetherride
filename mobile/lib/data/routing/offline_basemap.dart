import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:maplibre_gl/maplibre_gl.dart' as ml;

import 'map_style_url.dart';
import 'offline_maps_prefs.dart';
import 'offline_pack_catalog.dart';

enum OfflineBasemapResult { success, failed, timedOut, skippedPmtiles }

/// MapLibre OfflineRegion download for a pack bbox (basemap tiles).
///
/// `downloadOfflineRegion` returns when the region is *created*, not when
/// tiles are on disk. Callers must wait for [OfflineBasemapResult.success].
abstract final class OfflineBasemap {
  static const tileCountLimit = 100000;
  static const downloadTimeout = Duration(seconds: 180);
  static const streetDownloadTimeout = Duration(minutes: 8);

  static Future<void> applyNetworkMode({required bool online}) async {
    try {
      await ml.setOffline(!online);
    } catch (_) {}
  }

  static Future<bool> hasNetwork({
    Duration timeout = const Duration(seconds: 2),
  }) async {
    try {
      final result =
          await InternetAddress.lookup('dns.google').timeout(timeout);
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static Future<void> applyDetectedNetworkMode() async {
    final online = await hasNetwork();
    await applyNetworkMode(online: online);
  }

  static Future<bool> onWifiLikely() async {
    try {
      final ifaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );
      var wifi = false;
      var cell = false;
      for (final i in ifaces) {
        if (networkInterfaceLooksLikeWifi(i.name)) wifi = true;
        if (networkInterfaceLooksLikeCellular(i.name)) cell = true;
      }
      if (wifi) return true;
      if (cell) return false;
      return false;
    } catch (_) {
      return false;
    }
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

  static Future<bool> hasStreetHudRegion(String packId) =>
      hasRegionId(streetHudRegionId(packId));

  static Future<bool> streetHudReadyForActivatedPack() async {
    try {
      final path = await OfflineMapsPrefs.activatedPackPath();
      final id = OfflineMapsPrefs.packIdFromActivatedPath(path);
      if (id == null || id.isEmpty) return false;
      return hasStreetHudRegion(id);
    } catch (_) {
      return false;
    }
  }

  /// True when Ride HUD tiles would actually paint at [lng]/[lat].
  static Future<bool> streetHudCoversActivatedPack({
    double? lng,
    double? lat,
  }) async {
    try {
      final path = await OfflineMapsPrefs.activatedPackPath();
      final id = OfflineMapsPrefs.packIdFromActivatedPath(path);
      if (id == null || id.isEmpty) return false;
      if (!await hasStreetHudRegion(id)) return false;
      final m = await OfflineMapsPrefs.read();
      if (OfflineMapsPrefs.streetHudPackIdFrom(m) != id) return true;
      return streetHudCoversHere(
        regionReady: true,
        kind: streetHudKindFromRaw(
          OfflineMapsPrefs.streetHudKindRawFrom(m),
        ),
        storedBbox: OfflineMapsPrefs.streetHudBboxFrom(m),
        userLng: lng,
        userLat: lat,
      );
    } catch (_) {
      return false;
    }
  }

  static Future<OfflineBasemapResult> downloadStreetHud({
    required String packId,
    required String name,
    required List<double> bbox,
    required String mapStyleUrl,
    void Function(double progress01)? onProgress,
  }) async {
    final maxZ = maxStreetZoomForBbox(bbox);
    if (maxZ < kStreetHudMinZoom) return OfflineBasemapResult.failed;
    if (!packOffersStreetHud(packId: packId, bbox: bbox)) {
      return OfflineBasemapResult.failed;
    }
    return download(
      regionId: streetHudRegionId(packId),
      name: name,
      bbox: bbox,
      mapStyleUrl: mapStyleUrl,
      minZoom: kStreetHudMinZoom,
      maxZoom: maxZ,
      timeout: streetDownloadTimeout,
      onProgress: onProgress,
    );
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
    double? minZoom,
    double? maxZoom,
    Duration? timeout,
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
    final zMin = minZoom ?? kBasemapMinZoom;
    final zMax = maxZoom ?? maxBasemapZoomForBbox(bbox);
    try {
      await ml.downloadOfflineRegion(
        ml.OfflineRegionDefinition(
          bounds: ml.LatLngBounds(
            southwest: ml.LatLng(bbox[1], bbox[0]),
            northeast: ml.LatLng(bbox[3], bbox[2]),
          ),
          mapStyleUrl: mapStyleUrl,
          minZoom: zMin,
          maxZoom: zMax,
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
        timeout ?? downloadTimeout,
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
