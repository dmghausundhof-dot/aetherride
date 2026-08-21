import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config.dart';
import 'offline_pack_catalog.dart';
import 'overlay_regions.dart';

List<OfflinePackRow>? _cachedMerged;
Future<List<OfflinePackRow>>? _inflight;

/// API + CDN catalog, merged with local overlay stubs. Shared by Hof, Discover, Sheet.
Future<List<OfflinePackRow>> loadOfflinePackCatalog({
  bool force = false,
}) async {
  if (!force && _cachedMerged != null) return _cachedMerged!;
  if (!force && _inflight != null) return _inflight!;
  final future = _fetchMerged();
  _inflight = future;
  try {
    final rows = await future;
    _cachedMerged = rows;
    return rows;
  } finally {
    if (identical(_inflight, future)) _inflight = null;
  }
}

Future<List<OfflinePackRow>> _fetchMerged() async {
  List<OfflinePackRow> api = const [];
  List<OfflinePackRow> cdn = const [];
  try {
    final res = await http
        .get(
          Uri.parse('${AppConfig.apiBaseUrl}/api/offline/packs'),
          headers: {'Accept': 'application/json'},
        )
        .timeout(const Duration(seconds: 8));
    if (res.statusCode == 200) {
      api = parseOfflineCatalogPacks(jsonDecode(res.body));
    }
  } catch (_) {}
  try {
    final res = await http
        .get(
          Uri.parse(AppConfig.offlinePacksCatalogCdnUrl),
          headers: {'Accept': 'application/json'},
        )
        .timeout(const Duration(seconds: 8));
    if (res.statusCode == 200) {
      cdn = parseOfflineCatalogPacks(jsonDecode(res.body));
    }
  } catch (_) {}
  return mergeOfflineCatalog(
    api: mergePreferReady(api, cdn),
    local: kOverlayRegions,
  );
}

void resetOfflinePackCatalogCache() {
  _cachedMerged = null;
  _inflight = null;
}
