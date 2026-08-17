import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/config.dart';
import '../../core/theme/app_theme.dart';
import '../../data/routing/offline_basemap.dart';
import '../../data/routing/offline_maps_prefs.dart';
import '../../data/routing/offline_pack_catalog.dart';
import '../../data/routing/offline_pack_dirs.dart';
import '../../data/routing/offline_pmtiles_store.dart';
import '../../data/routing/offline_tiles.dart';
import '../../data/routing/map_style_url.dart';
import '../../data/routing/bike_overlay.dart';
import '../../data/routing/overlay_regions.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_ext.dart';

/// Offline-Karten: gebaute Region-Packs (Graph + MapLibre-Kacheln).
class OfflineMapsSheet extends StatefulWidget {
  const OfflineMapsSheet({
    super.key,
    this.userLng,
    this.userLat,
  });

  final double? userLng;
  final double? userLat;

  @override
  State<OfflineMapsSheet> createState() => _OfflineMapsSheetState();
}

class _OfflineMapsSheetState extends State<OfflineMapsSheet> {
  final _urlCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  String? _regionPref;
  String? _activatedPath;
  String? _valhallaStatus;
  String? _engineHint;
  bool _loading = true;
  bool _busy = false;
  String? _progress;
  double? _progressValue;
  String? _catalogNote;
  bool _basemapReady = false;
  Set<String> _installed = {};
  List<OfflinePackRow> _regions = [
    for (final r in kOverlayRegions)
      OfflinePackRow(
        id: r.id,
        name: r.name,
        bbox: r.bbox,
        downloadable: false,
        status: 'stub',
      ),
  ];

  @override
  void initState() {
    super.initState();
    _load();
    _fetchCatalog();
  }

  Future<void> _fetchCatalog() async {
    try {
      final res = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/api/offline/packs'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 8));
      List<OfflinePackRow> apiPacks = [];
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map) {
          for (final raw in (data['packs'] as List? ?? const [])) {
            final row = parseOfflinePackRow(raw);
            if (row != null) apiPacks.add(row);
          }
        }
      }
      final cdnPacks = await _fetchCdnCatalog();
      final packs = mergePreferReady(apiPacks, cdnPacks);
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      final merged = mergeOfflineCatalog(
        api: packs,
        local: kOverlayRegions,
      );
      final ready = merged.where((p) => p.isReady).length;
      setState(() {
        _regions = sortOfflinePacks(
          merged,
          userLng: widget.userLng,
          userLat: widget.userLat,
        );
        _catalogNote = packs.isEmpty
            ? l10n.offlineNoRemoteDach
            : ready == 0
                ? l10n.offlineNoBuiltPacks
                : l10n.offlinePacksReadyLabel(ready);
      });
    } catch (_) {
      try {
        final cdnPacks = await _fetchCdnCatalog();
        if (cdnPacks.isNotEmpty && mounted) {
          final merged = mergeOfflineCatalog(
            api: cdnPacks,
            local: kOverlayRegions,
          );
          final ready = merged.where((p) => p.isReady).length;
          setState(() {
            _regions = sortOfflinePacks(
              merged,
              userLng: widget.userLng,
              userLat: widget.userLat,
            );
            _catalogNote = ready == 0
                ? AppLocalizations.of(context).offlineDachCatalog
                : AppLocalizations.of(context).offlinePacksReadyLabel(ready);
          });
          return;
        }
      } catch (_) {}
      if (mounted) {
        setState(
          () => _catalogNote = AppLocalizations.of(context).offlineDachCatalog,
        );
      }
      _sortRegions();
    }
  }

  Future<List<OfflinePackRow>> _fetchCdnCatalog() async {
    try {
      final res = await http.get(
        Uri.parse(AppConfig.offlinePacksCatalogCdnUrl),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return const [];
      final data = jsonDecode(res.body);
      if (data is! Map) return const [];
      final packs = <OfflinePackRow>[];
      for (final raw in (data['packs'] as List? ?? const [])) {
        final row = parseOfflinePackRow(raw);
        if (row != null) packs.add(row);
      }
      return packs;
    } catch (_) {
      return const [];
    }
  }

  void _sortRegions() {
    if (!mounted) return;
    setState(() {
      _regions = sortOfflinePacks(
        _regions,
        userLng: widget.userLng,
        userLat: widget.userLat,
      );
    });
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<Set<String>> _scanInstalled() => OfflinePackDirs.legitimateIds();

  Future<void> _load() async {
    final compileTime = AppConfig.pmtilesUrl;
    var override = '';
    String? region;
    String? activated;
    String? engineHint;
    var basemapReady = false;
    try {
      final m = await OfflineMapsPrefs.read();
      override = (m['pmtilesUrl'] as String?) ?? '';
      region = m['regionPack'] as String?;
      activated = m['activatedPackPath'] as String?;
      engineHint = m['engineHint'] as String?;
      basemapReady = m['basemapReady'] == true;
    } catch (_) {}
    if (activated != null && activated.isNotEmpty) {
      final dir = Directory(activated);
      if (!await OfflinePackDirs.directoryIsLegitimate(dir)) {
        await OfflineMapsPrefs.merge({
          'regionPack': null,
          'activatedPackPath': null,
          'engineHint': null,
          'packBbox': null,
          'basemapReady': null,
        });
        region = null;
        activated = null;
        engineHint = null;
        basemapReady = false;
        OfflineTilesStore.instance.clearCache();
      }
    }
    final installed = await _scanInstalled();
    final status = await OfflineTilesStore.instance.valhallaLinkStatus();
    if (!mounted) return;
    setState(() {
      _urlCtrl.text = override.isNotEmpty
          ? override
          : (compileTime.isNotEmpty
              ? compileTime
              : AppConfig.dachBasemapStyleUrl);
      _regionPref = region;
      _activatedPath = activated;
      _engineHint = engineHint;
      _valhallaStatus = status;
      _basemapReady = basemapReady;
      _installed = installed;
      _loading = false;
    });
  }

  Future<void> _savePrefs({
    String? pmtilesUrl,
    String? regionPack,
    String? activatedPackPath,
    String? engineHint,
    List<double>? packBbox,
    bool? basemapReady,
  }) async {
    await OfflineMapsPrefs.merge({
      if (pmtilesUrl != null) 'pmtilesUrl': pmtilesUrl,
      if (regionPack != null) 'regionPack': regionPack,
      if (activatedPackPath != null) 'activatedPackPath': activatedPackPath,
      if (engineHint != null) 'engineHint': engineHint,
      if (packBbox != null) 'packBbox': packBbox,
      if (basemapReady != null) 'basemapReady': basemapReady,
    });
  }

  Future<Map<String, dynamic>?> _fetchManifest(String id) async {
    final urls = [
      Uri.parse(AppConfig.offlinePackObjectUrl(id, 'manifest.json')),
      Uri.parse('${AppConfig.apiBaseUrl}/api/offline/packs/$id'),
      Uri.parse('${AppConfig.apiBaseUrl}/offline/$id/manifest.json'),
    ];
    for (final url in urls) {
      try {
        final res = await http.get(url).timeout(const Duration(seconds: 12));
        if (res.statusCode == 200 && res.body.isNotEmpty) {
          final decoded = jsonDecode(res.body);
          if (decoded is Map<String, dynamic>) return decoded;
        }
      } catch (_) {}
    }
    return null;
  }

  Future<Uint8List?> _streamDownload(
    Uri url, {
    void Function(int received, int? total)? onBytes,
  }) async {
    final client = http.Client();
    try {
      final req = http.Request('GET', url);
      final res = await client.send(req).timeout(const Duration(seconds: 20));
      if (res.statusCode != 200) return null;
      final total = res.contentLength;
      final out = BytesBuilder(copy: false);
      var got = 0;
      await for (final chunk
          in res.stream.timeout(const Duration(seconds: 45))) {
        out.add(chunk);
        got += chunk.length;
        onBytes?.call(got, total);
      }
      if (out.length == 0) return null;
      return out.takeBytes();
    } finally {
      client.close();
    }
  }

  Future<Uint8List?> _downloadVerified(
    List<Uri> urls,
    String? expectedSha,
  ) async {
    Uint8List? last;
    for (final url in urls) {
      try {
        final bytes = await _streamDownload(
          url,
          onBytes: (got, total) {
            if (!mounted) return;
            final t = total != null && total > 0 ? formatPackBytes(total) : '?';
            setState(() {
              _progress = AppLocalizations.of(context).offlineProgressPack(
                formatPackBytes(got),
                t,
              );
              _progressValue =
                  total != null && total > 0 ? (got / total).clamp(0, 1) : null;
            });
          },
        );
        if (bytes == null || bytes.isEmpty) continue;
        last = bytes;
        if (expectedSha == null || expectedSha.isEmpty) return bytes;
        final got = sha256.convert(bytes).toString();
        if (got.toLowerCase() == expectedSha.toLowerCase()) return bytes;
        debugPrint('SHA mismatch for $url (got $got)');
      } catch (e) {
        debugPrint('download $url: $e');
      }
    }
    if (last != null && expectedSha != null && expectedSha.isNotEmpty) {
      throw Exception(
        mounted
            ? AppLocalizations.of(context).offlineShaMismatch(expectedSha)
            : 'SHA-256 stimmt mit keinem Download überein (erwartet $expectedSha)',
      );
    }
    return last;
  }

  Future<void> _extractTarGz(Uint8List bytes, Directory dest) async {
    final archive = TarDecoder().decodeBytes(GZipDecoder().decodeBytes(bytes));
    for (final entry in archive) {
      final name = entry.name.replaceAll('\\', '/');
      if (name.contains('..')) continue;
      final outPath = p.join(dest.path, name);
      if (entry.isDirectory) {
        await Directory(outPath).create(recursive: true);
      } else {
        await File(outPath).parent.create(recursive: true);
        await File(outPath).writeAsBytes(entry.content as List<int>);
      }
    }
  }

  bool _isActive(OfflinePackRow r) {
    if (_regionPref == r.name) return true;
    return _activatedPath?.contains('/${r.id}') ?? false;
  }

  Future<void> _activateExisting(OfflinePackRow region) async {
    final docs = await getApplicationDocumentsDirectory();
    final regionDir = Directory(p.join(docs.path, 'regions', region.id));
    if (!await OfflinePackDirs.directoryIsLegitimate(regionDir)) {
      throw Exception(
        mounted
            ? AppLocalizations.of(context).offlineInvalidGraphFolder(region.id)
            : 'Ordner ${region.id} enthält keinen gültigen Graph für diese Region',
      );
    }
    final mapOk = await OfflineBasemap.hasRegionId(region.id);
    await _savePrefs(
      regionPack: region.name,
      activatedPackPath: regionDir.path,
      engineHint: 'offline_graph',
      packBbox: region.bbox,
      basemapReady: mapOk,
    );
    OfflineTilesStore.instance.clearCache();
    final status = await OfflineTilesStore.instance.valhallaLinkStatus();
    if (!mounted) return;
    setState(() {
      _regionPref = region.name;
      _activatedPath = regionDir.path;
      _engineHint = 'offline_graph';
      _valhallaStatus = status;
      _basemapReady = mapOk;
    });
    if (!mapOk && region.bbox != null) {
      await _downloadBasemap(region);
    }
  }

  Future<OfflineBasemapResult> _downloadBasemap(OfflinePackRow region) async {
    final bbox = region.bbox;
    if (bbox == null || bbox.length < 4) {
      return OfflineBasemapResult.failed;
    }
    if (!mounted) return OfflineBasemapResult.failed;
    final archiveId = basemapArchiveIdForBbox(bbox);
    if (await OfflinePmtilesStore.isReady(archiveId)) {
      final local = await OfflinePmtilesStore.localStyleUri(archiveId);
      if (local != null) {
        await _savePrefs(pmtilesUrl: local, basemapReady: true);
        if (mounted) {
          setState(() {
            _urlCtrl.text = local;
            _basemapReady = true;
          });
        }
        return OfflineBasemapResult.success;
      }
    }
    setState(() {
      _progress = AppLocalizations.of(context).offlineProgressBasemap(archiveId);
      _progressValue = 0;
    });
    try {
      await OfflinePmtilesStore.downloadArchive(
        id: archiveId,
        onProgress: (got, total) {
          if (!mounted) return;
          final t = total != null && total > 0 ? formatPackBytes(total) : '?';
          setState(() {
            _progressValue =
                total != null && total > 0 ? (got / total).clamp(0, 1) : null;
            _progress = AppLocalizations.of(context).offlineProgressBasemapBytes(
              formatPackBytes(got),
              t,
            );
          });
        },
      );
      final local = await OfflinePmtilesStore.localStyleUri(archiveId);
      if (local != null) {
        await _savePrefs(pmtilesUrl: local, basemapReady: true);
        if (mounted) {
          setState(() {
            _urlCtrl.text = local;
            _basemapReady = true;
          });
        }
        return OfflineBasemapResult.success;
      }
    } catch (e) {
      debugPrint('PMTiles archive $archiveId: $e');
    }
    final style = await AppConfig.resolveMapStyleUrl();
    if (skipMapLibreOfflineRegion(style)) {
      await _savePrefs(basemapReady: false);
      if (mounted) setState(() => _basemapReady = false);
      return OfflineBasemapResult.skippedPmtiles;
    }
    setState(() {
      _progress = AppLocalizations.of(context).offlineProgressMapZoom(
        '${kBasemapMinZoom.toInt()}',
        '${maxBasemapZoomForBbox(bbox).toInt()}',
      );
      _progressValue = 0;
    });
    final result = await OfflineBasemap.download(
      regionId: region.id,
      name: region.name,
      bbox: bbox,
      mapStyleUrl: style,
      onProgress: (p) {
        if (!mounted) return;
        setState(() {
          _progressValue = p;
          _progress = AppLocalizations.of(context).offlineProgressMapPercent(
            '${(p * 100).round()}',
          );
        });
      },
    );
    final ok = result == OfflineBasemapResult.success;
    await _savePrefs(basemapReady: ok);
    if (mounted) setState(() => _basemapReady = ok);
    return result;
  }

  Future<void> _onRegionTap(OfflinePackRow region) async {
    if (_busy) return;
    if (!region.isReady && region.id != kBundledOfflineGraphRegionId) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).offlinePackNotBuilt(_regionLabel(region)),
          ),
        ),
      );
      return;
    }
    final installed = _installed.contains(region.id);
    if (installed && !_isActive(region)) {
      setState(() {
        _busy = true;
        _progress = AppLocalizations.of(context).offlineProgressActivating;
      });
      try {
        await _activateExisting(region);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)
                  .offlineRegionActiveSnack(_regionLabel(region)),
            ),
          ),
        );
        Navigator.of(context).pop(true);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context).offlineActivateError(
                  AppLocalizations.of(context).offlineErrorDetail('$e'),
                ),
              ),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _busy = false;
            _progress = null;
            _progressValue = null;
          });
        }
      }
      return;
    }
    await _downloadAndActivate(region);
  }

  Future<void> _downloadAndActivate(OfflinePackRow region) async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _progress = l10n.offlineProgressManifest;
      _progressValue = null;
    });
    Directory? tmpDir;
    try {
      final docs = await getApplicationDocumentsDirectory();
      final regionDir = Directory(p.join(docs.path, 'regions', region.id));
      tmpDir = Directory('${regionDir.path}.tmp');
      if (await tmpDir.exists()) {
        await tmpDir.delete(recursive: true);
      }
      await tmpDir.create(recursive: true);

      final manifest = await _fetchManifest(region.id);
      final files = manifest?['files'] is Map
          ? Map<String, dynamic>.from(manifest!['files'] as Map)
          : <String, dynamic>{};
      final cdn = manifest?['cdn'] is Map
          ? Map<String, dynamic>.from(manifest!['cdn'] as Map)
          : <String, dynamic>{};
      final cdnBase =
          (cdn['baseUrl'] as String?)?.replaceAll(RegExp(r'/$'), '');
      final packGz = (cdn['packGz'] as String?) ?? '${region.id}.tar.gz';

      var sourceLabel = 'remote';
      var gotPack = false;

      if (region.isReady || files.containsKey(packGz) || files.isNotEmpty) {
        setState(() => _progress = l10n.offlineProgressPackFile(packGz));
        final meta = files[packGz] is Map
            ? Map<String, dynamic>.from(files[packGz] as Map)
            : null;
        final urls = <Uri>[
          if (cdnBase != null && cdnBase.isNotEmpty)
            Uri.parse('$cdnBase/$packGz'),
          Uri.parse(AppConfig.offlinePackObjectUrl(region.id, packGz)),
          Uri.parse(
            '${AppConfig.apiBaseUrl}/api/offline/packs/${region.id}/$packGz',
          ),
          Uri.parse('${AppConfig.apiBaseUrl}/offline/${region.id}/$packGz'),
        ];
        final bytes = await _downloadVerified(
          urls,
          meta?['sha256'] as String?,
        );
        if (bytes != null) {
          await _extractTarGz(bytes, tmpDir);
          gotPack = true;
        }
      }

      if (!gotPack && files.containsKey('offline_graph.json')) {
        setState(() => _progress = l10n.offlineProgressGraphFile);
        final graphMeta = files['offline_graph.json'] is Map
            ? Map<String, dynamic>.from(files['offline_graph.json'] as Map)
            : null;
        final graphUrls = <Uri>[
          if (cdnBase != null && cdnBase.isNotEmpty)
            Uri.parse('$cdnBase/offline_graph.json'),
          Uri.parse(
            AppConfig.offlinePackObjectUrl(region.id, 'offline_graph.json'),
          ),
          Uri.parse(
            '${AppConfig.apiBaseUrl}/api/offline/packs/${region.id}/offline_graph.json',
          ),
          Uri.parse(
            '${AppConfig.apiBaseUrl}/offline/${region.id}/offline_graph.json',
          ),
        ];
        final graphBytes = await _downloadVerified(
          graphUrls,
          graphMeta?['sha256'] as String?,
        );
        if (graphBytes != null) {
          await File(p.join(tmpDir.path, 'offline_graph.json'))
              .writeAsBytes(graphBytes);
          gotPack = true;
        }
      }

      if (!gotPack) {
        if (region.id != kBundledOfflineGraphRegionId) {
          if (!mounted) return;
          throw Exception(l10n.offlineNoRemotePack(_regionLabel(region)));
        }
        sourceLabel = 'bundle';
        setState(() => _progress = l10n.offlineProgressDemoGraph);
        final data = await rootBundle.load('assets/routing/offline_graph.json');
        await File(p.join(tmpDir.path, 'offline_graph.json'))
            .writeAsBytes(data.buffer.asUint8List());
        gotPack = true;
      }

      if (!gotPack) {
        throw Exception(l10n.offlineDownloadEmpty);
      }

      List<double>? bbox = region.bbox;
      final rawBbox = manifest?['bbox'];
      if (rawBbox is List && rawBbox.length >= 4) {
        bbox = [
          for (final x in rawBbox.take(4))
            if (x is num) x.toDouble(),
        ];
      }

      final graphFile = File(p.join(tmpDir.path, 'offline_graph.json'));
      if (!await graphFile.exists()) {
        throw Exception(l10n.offlineNoGraphAfterExtract);
      }
      final graphBytes = await graphFile.readAsBytes();
      final graphSha = sha256.convert(graphBytes).toString();
      final graphMeta = files['offline_graph.json'] is Map
          ? Map<String, dynamic>.from(files['offline_graph.json'] as Map)
          : null;
      final check = checkExtractedGraph(
        regionId: region.id,
        graphBytes: graphBytes.length,
        actualSha256: graphSha,
        expectedSha256: graphMeta?['sha256'] as String?,
        manifestId: manifest?['id'] as String?,
      );
      if (check != ExtractedGraphCheck.ok) {
        if (!mounted) return;
        throw Exception(
          l10n.extractedGraphErrorFor(check, _regionLabel(region)),
        );
      }

      final manOut = File(p.join(tmpDir.path, 'manifest.json'));
      if (!await manOut.exists()) {
        await manOut.writeAsString(
          jsonEncode({
            'id': region.id,
            'name': (manifest?['name'] as String?) ?? region.name,
            'bbox': bbox,
          }),
        );
      }

      if (await regionDir.exists()) {
        await regionDir.delete(recursive: true);
      }
      await tmpDir.rename(regionDir.path);
      tmpDir = null;

      final engines = manifest?['engines'] is Map
          ? Map<String, dynamic>.from(manifest!['engines'] as Map)
          : null;
      final hint =
          engines?['valhalla_tiles'] == true ? 'valhalla' : 'offline_graph';

      await _savePrefs(
        regionPack: (manifest?['name'] as String?) ?? region.name,
        activatedPackPath: regionDir.path,
        engineHint: hint,
        packBbox: bbox,
        basemapReady: false,
      );
      await downloadBikeOverlayIntoPack(regionDir, region.id);
      OfflineTilesStore.instance.clearCache();
      final status = await OfflineTilesStore.instance.valhallaLinkStatus();

      var mapResult = OfflineBasemapResult.failed;
      if (bbox != null && bbox.length >= 4) {
        mapResult = await _downloadBasemap(
          region.copyWith(bbox: bbox, name: region.name),
        );
      }

      final installed = await _scanInstalled();
      if (!mounted) return;
      setState(() {
        _regionPref = (manifest?['name'] as String?) ?? region.name;
        _activatedPath = regionDir.path;
        _engineHint = hint;
        _valhallaStatus = status;
        _installed = installed;
        _progress = null;
        _progressValue = null;
      });
      final mapNote = switch (mapResult) {
        OfflineBasemapResult.success => l10n.offlineReadyMapRouting,
        OfflineBasemapResult.timedOut => l10n.offlineRoutingBg,
        OfflineBasemapResult.skippedPmtiles => l10n.offlineBasemapFail,
        OfflineBasemapResult.failed => l10n.offlineTilesMissing,
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            sourceLabel == 'bundle'
                ? l10n.offlineDemoGraph(_regionLabel(region))
                : '${_regionLabel(region)}: $mapNote',
          ),
        ),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (tmpDir != null && await tmpDir.exists()) {
        try {
          await tmpDir.delete(recursive: true);
        } catch (_) {}
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).offlinePackError(
                AppLocalizations.of(context).offlineErrorDetail('$e'),
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _progress = null;
          _progressValue = null;
        });
      }
    }
  }

  /// True if URL looks like a MapLibre style JSON (not a raw .pmtiles file).
  static bool isStyleJsonUrl(String raw) => isMapLibreStyleJsonUrl(raw);

  String? _styleUrlError(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return null;
    final l10n = AppLocalizations.of(context);
    if (t.toLowerCase().endsWith('.pmtiles') ||
        t.toLowerCase().contains('.pmtiles?')) {
      return l10n.offlineRawPmtiles;
    }
    if (!isStyleJsonUrl(t) &&
        !t.startsWith('http://') &&
        !t.startsWith('https://')) {
      return l10n.offlineInvalidUrl;
    }
    if (!isStyleJsonUrl(t)) {
      return l10n.offlineExpectStyleJson;
    }
    return null;
  }

  Future<void> _saveStyleUrl() async {
    final url = _urlCtrl.text.trim();
    final err = _styleUrlError(url);
    if (err != null) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(err)));
      }
      return;
    }
    await _savePrefs(pmtilesUrl: url);
    if (!mounted) return;
    final resolved = await AppConfig.resolveMapStyleUrl();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          url.isEmpty
              ? AppLocalizations.of(context).offlineStyleCleared
              : AppLocalizations.of(context).offlineStyleSaved(resolved),
        ),
      ),
    );
    Navigator.of(context).pop(true);
  }

  Future<void> _clearActivatedPack() async {
    String? activeId;
    for (final r in _regions) {
      if (_isActive(r)) {
        activeId = r.id;
        break;
      }
    }
    if (activeId != null) {
      await OfflineBasemap.deleteRegionId(activeId);
      try {
        final docs = await getApplicationDocumentsDirectory();
        final dir = Directory(p.join(docs.path, 'regions', activeId));
        if (await dir.exists()) await dir.delete(recursive: true);
      } catch (_) {}
    }
    await OfflineMapsPrefs.merge({
      'regionPack': null,
      'activatedPackPath': null,
      'engineHint': null,
      'packBbox': null,
      'basemapReady': null,
    });
    OfflineTilesStore.instance.clearCache();
    final status = await OfflineTilesStore.instance.valhallaLinkStatus();
    final installed = await _scanInstalled();
    if (!mounted) return;
    setState(() {
      _regionPref = null;
      _activatedPath = null;
      _engineHint = null;
      _valhallaStatus = status;
      _basemapReady = false;
      _installed = installed;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).offlineRemoved),
      ),
    );
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  String _regionLabel(OfflinePackRow r) =>
      AppLocalizations.of(context).overlayRegionNameFor(r.id, r.name);

  String _activeRegionTitle(AppLocalizations l10n) {
    final path = _activatedPath;
    if (path != null && path.isNotEmpty) {
      return l10n.overlayRegionNameFor(p.basename(path), _regionPref);
    }
    return _regionPref ?? l10n.offlineRegionActive;
  }

  List<OfflinePackRow> get _filtered {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return _regions;
    return [
      for (final r in _regions)
        if (r.name.toLowerCase().contains(q) ||
            r.id.contains(q) ||
            _regionLabel(r).toLowerCase().contains(q))
          r,
    ];
  }

  Widget _regionTile(OfflinePackRow r) {
    final active = _isActive(r);
    final installed = _installed.contains(r.id);
    final enabled = !_busy &&
        (r.isReady || installed || r.id == kBundledOfflineGraphRegionId);
    final subtitle = AppLocalizations.of(context).offlinePackSubtitleFor(
      r,
      active: active,
      installed: installed,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _onRegionTap(r),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            child: Row(
              children: [
                Icon(
                  active
                      ? Icons.check_circle
                      : installed
                          ? Icons.sd_storage_outlined
                          : r.isReady
                              ? Icons.download_outlined
                              : Icons.hourglass_empty,
                  color: active
                      ? AppColors.chrome
                      : enabled
                          ? AppColors.muted
                          : AppColors.muted.withValues(alpha: 0.5),
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _regionLabel(r),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: enabled ? null : AppColors.muted,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final hasPack = _activatedPath != null;
    final filtered = _filtered;
    final searching = _searchCtrl.text.trim().isNotEmpty;
    final ready = visibleReadyPacks(
      filtered: filtered,
      installed: _installed,
      searching: searching,
    );
    final stubs = visibleStubPacks(
      filtered: filtered,
      installed: _installed,
      searching: searching,
    );
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottom),
      child: _loading
          ? const SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator()),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.offlineMapsTitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.offlineMapsHint,
                    style:
                        const TextStyle(color: AppColors.muted, fontSize: 13),
                  ),
                  if (AppConfig.showRoutingDebug) ...[
                    const SizedBox(height: 6),
                    Text(
                      'API ${AppConfig.apiBaseUrl}',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          hasPack
                              ? Icons.check_circle_outline
                              : Icons.cloud_download_outlined,
                          color: hasPack
                              ? AppColors.chrome
                              : AppColors.muted,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                hasPack
                                    ? _activeRegionTitle(l10n)
                                    : l10n.offlineNoRegion,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                hasPack
                                    ? (_basemapReady
                                        ? l10n.offlineReadyBoth
                                        : l10n.offlineReadyRouting)
                                    : l10n.offlineLoadBelow,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.muted,
                                ),
                              ),
                              if (AppConfig.showRoutingDebug &&
                                  _valhallaStatus != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  l10n.offlineEngineStatusLineFor(
                                    valhallaStatus: _valhallaStatus!,
                                    engineHint: _engineHint,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    l10n.offlineRegions,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  if (_catalogNote != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      _catalogNote!,
                      style: const TextStyle(
                        color: AppColors.warning,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Semantics(
                    label: l10n.offlineSearchRegion,
                    textField: true,
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        isDense: true,
                        prefixIcon: const Icon(Icons.search, size: 20),
                        hintText: l10n.offlineSearchRegion,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  if (_progress != null) ...[
                    const SizedBox(height: 10),
                    Text(_progress!, style: const TextStyle(fontSize: 12)),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(value: _progressValue),
                  ],
                  const SizedBox(height: 10),
                  if (searching && filtered.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        l10n.offlineNoneFound,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                  if (!searching && ready.isEmpty && stubs.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        l10n.offlineNoPacks,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                  for (final r in ready) _regionTile(r),
                  if (stubs.isNotEmpty)
                    Theme(
                      data: Theme.of(context).copyWith(
                        dividerColor: Colors.transparent,
                      ),
                      child: ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        title: Text(
                          l10n.offlineNotBuilt(stubs.length),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          l10n.offlineStubsHint,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                        children: [for (final r in stubs) _regionTile(r)],
                      ),
                    ),
                  if (hasPack)
                    TextButton(
                      onPressed: _busy ? null : _clearActivatedPack,
                      child: Text(l10n.offlineRemoveRegion),
                    ),
                  const SizedBox(height: 8),
                  Theme(
                    data: Theme.of(context).copyWith(
                      dividerColor: Colors.transparent,
                    ),
                    child: ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      childrenPadding: EdgeInsets.zero,
                      title: Text(
                        l10n.offlineStyleTitle,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        l10n.offlineStyleHint,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                      children: [
                        TextField(
                          controller: _urlCtrl,
                          decoration: InputDecoration(
                            labelText: l10n.offlineStyleUrl,
                            hintText: 'https://…/basemap/dach-z11-style.json',
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.chrome,
                          ),
                          onPressed: _busy ? null : _saveStyleUrl,
                          child: Text(l10n.offlineSaveStyle),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
