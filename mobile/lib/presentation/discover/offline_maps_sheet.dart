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
import '../../data/routing/coverage_graph_ring.dart';
import '../../data/routing/coverage_label.dart';
import '../../data/routing/offline_basemap.dart';
import '../../data/routing/offline_maps_prefs.dart';
import '../../data/routing/offline_pack_catalog.dart';
import '../../data/routing/offline_pack_catalog_client.dart';
import '../../data/routing/offline_pack_dirs.dart';
import '../../data/routing/offline_pmtiles_store.dart';
import '../../data/routing/offline_tiles.dart';
import '../../data/routing/map_style_url.dart';
import 'offline_coverage_sketch.dart';
import '../../data/routing/bike_overlay.dart';
import '../../data/routing/overlay_regions.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_ext.dart';
import '../shared/chrome_glyph.dart';

/// Offline-Routing: gebaute Region-Packs (Graph + optionale Übersicht).
///
/// [userLng]/[userLat] = rider GPS (honesty / Street-Korridor).
/// [nearLng]/[nearLat] = optional map/dest bias for catalog sort only.
Future<bool?> openOfflineMapsSheet(
  BuildContext context, {
  double? userLng,
  double? userLat,
  double? nearLng,
  double? nearLat,
  List<double>? routeBbox,
  List<List<double>>? routeLine,
  String? focusPackId,
  VoidCallback? onDownloadPaused,
  ValueChanged<List<double>>? onShowOnMap,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (_) => OfflineMapsSheet(
      userLng: userLng,
      userLat: userLat,
      nearLng: nearLng,
      nearLat: nearLat,
      routeBbox: routeBbox,
      routeLine: routeLine,
      focusPackId: focusPackId,
      onDownloadPaused: onDownloadPaused,
      onShowOnMap: onShowOnMap,
    ),
  );
}

class OfflineMapsSheet extends StatefulWidget {
  const OfflineMapsSheet({
    super.key,
    this.userLng,
    this.userLat,
    this.nearLng,
    this.nearLat,
    this.routeBbox,
    this.routeLine,
    this.focusPackId,
    this.onDownloadPaused,
    this.onShowOnMap,
  });

  final double? userLng;
  final double? userLat;
  /// Map center / destination — sorts the catalog, never fakes GPS honesty.
  final double? nearLng;
  final double? nearLat;
  final List<double>? routeBbox;
  final List<List<double>>? routeLine;
  final String? focusPackId;
  final VoidCallback? onDownloadPaused;
  final ValueChanged<List<double>>? onShowOnMap;

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
  bool _catalogReady = false;
  bool _busy = false;
  bool _downloadCancelled = false;
  http.Client? _downloadClient;
  String? _progress;
  double? _progressValue;
  String? _catalogNote;
  bool _basemapReady = false;
  bool _streetReady = false;
  Set<String> _installed = {};
  Map<String, String> _localBuiltAt = {};
  List<double>? _packBbox;
  List<List<double>>? _packRing;
  List<List<double>>? _packDots;
  List<List<double>>? _packTraces;
  List<double>? _streetBbox;
  StreetHudOfferKind? _streetKind;
  int _storageBytes = 0;
  bool _prefsChanged = false;
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

  /// Catalog bias: map/dest first, else real GPS — never invents a rider fix.
  double? get _sortLng => widget.nearLng ?? widget.userLng;
  double? get _sortLat => widget.nearLat ?? widget.userLat;

  @override
  void initState() {
    super.initState();
    _load();
    _fetchCatalog();
  }

  Future<void> _fetchCatalog() async {
    try {
      final merged = await loadOfflinePackCatalog();
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      final ready = merged.where((p) => p.isReady).length;
      setState(() {
        _regions = sortOfflinePacks(
          merged,
          userLng: _sortLng,
          userLat: _sortLat,
        );
        _catalogNote = ready == 0 ? l10n.offlineDachCatalog : null;
        _catalogReady = true;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _catalogNote = AppLocalizations.of(context).offlineDachCatalog;
          _catalogReady = true;
        });
      }
      _sortRegions();
    }
  }

  void _sortRegions() {
    if (!mounted) return;
    setState(() {
      _regions = sortOfflinePacks(
        _regions,
        userLng: _sortLng,
        userLat: _sortLat,
      );
    });
  }

  @override
  void dispose() {
    if (_busy) widget.onDownloadPaused?.call();
    _downloadCancelled = true;
    _downloadClient?.close();
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
    List<double>? packBbox;
    try {
      final m = await OfflineMapsPrefs.read();
      override = (m['pmtilesUrl'] as String?) ?? '';
      region = m['regionPack'] as String?;
      activated = (m['activatedPackPath'] as String?)?.trim();
      if (activated != null && activated.isEmpty) activated = null;
      engineHint = m['engineHint'] as String?;
      basemapReady = m['basemapReady'] == true;
      packBbox = await OfflinePackDirs.activatedCoverageBbox() ??
          OfflineMapsPrefs.packBboxFrom(m);
    } catch (_) {}
    List<List<double>>? packRing;
    List<List<double>>? packDots;
    List<List<double>>? packTraces;
    try {
      final ringHit = await OfflinePackDirs.activatedCoverageRingResult();
      packRing = ringHit?.outline;
      packDots = ringHit?.dots;
      packTraces = ringHit?.traces;
    } catch (_) {}
    if (activated != null && activated.isNotEmpty) {
      final dir = Directory(activated);
      if (!await OfflinePackDirs.directoryIsLegitimate(dir)) {
        _prefsChanged = true;
        await OfflineMapsPrefs.merge({
          'regionPack': null,
          'activatedPackPath': null,
          'engineHint': null,
          'packBbox': null,
          'basemapReady': null,
          'activatedAt': null,
        });
        region = null;
        activated = null;
        engineHint = null;
        basemapReady = false;
        packBbox = null;
        packRing = null;
        packDots = null;
        packTraces = null;
        OfflineTilesStore.instance.clearCache();
      }
    }
    final installed = await _scanInstalled();
    final builtAt = await OfflinePackDirs.builtAtById();
    final status = await OfflineTilesStore.instance.valhallaLinkStatus();
    final storage = await _scanStorage();
    var streetReady = false;
    List<double>? streetBbox;
    StreetHudOfferKind? streetKind;
    try {
      final id = OfflineMapsPrefs.packIdFromActivatedPath(activated);
      if (id != null) {
        final meta = await _streetHudMeta(id);
        streetReady = meta.ready;
        streetBbox = meta.bbox;
        streetKind = meta.kind;
      }
    } catch (_) {}
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
      _streetReady = streetReady;
      _installed = installed;
      _localBuiltAt = builtAt;
      _packBbox = packBbox;
      _packRing = packRing;
      _packDots = packDots;
      _packTraces = packTraces;
      _streetBbox = streetBbox;
      _streetKind = streetKind;
      _storageBytes = storage;
      _loading = false;
    });
  }

  Future<int> _scanStorage() async {
    final g = await OfflinePackDirs.totalBytes();
    final b = await OfflinePmtilesStore.totalBytes();
    return g + b;
  }

  Future<void> _savePrefs({
    String? pmtilesUrl,
    String? regionPack,
    String? activatedPackPath,
    String? engineHint,
    List<double>? packBbox,
    bool? basemapReady,
  }) async {
    _prefsChanged = true;
    await OfflineMapsPrefs.merge({
      if (pmtilesUrl != null) 'pmtilesUrl': pmtilesUrl,
      if (regionPack != null) 'regionPack': regionPack,
      if (activatedPackPath != null) 'activatedPackPath': activatedPackPath,
      if (activatedPackPath != null)
        'activatedAt': DateTime.now().toUtc().toIso8601String(),
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
    if (_downloadCancelled || !mounted) return null;
    final client = http.Client();
    _downloadClient = client;
    try {
      final req = http.Request('GET', url);
      final res = await client.send(req).timeout(const Duration(seconds: 20));
      if (res.statusCode != 200) return null;
      final total = res.contentLength;
      final out = BytesBuilder(copy: false);
      var got = 0;
      await for (final chunk
          in res.stream.timeout(const Duration(seconds: 45))) {
        if (_downloadCancelled || !mounted) return null;
        out.add(chunk);
        got += chunk.length;
        onBytes?.call(got, total);
      }
      if (out.length == 0) return null;
      return out.takeBytes();
    } catch (_) {
      if (_downloadCancelled) return null;
      rethrow;
    } finally {
      client.close();
      if (identical(_downloadClient, client)) _downloadClient = null;
    }
  }

  Future<Uint8List?> _downloadVerified(
    List<Uri> urls,
    String? expectedSha,
  ) async {
    Uint8List? last;
    for (final url in urls) {
      if (_downloadCancelled || !mounted) return null;
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
    final path = (_activatedPath ?? '').replaceAll('\\', '/');
    if (path.isEmpty) return false;
    return p.basename(path) == r.id;
  }

  Future<void> _activateExisting(OfflinePackRow region) async {
    final docs = await getApplicationDocumentsDirectory();
    final regionDir = Directory(p.join(docs.path, 'regions', region.id));
    if (!await OfflinePackDirs.directoryIsLegitimate(regionDir)) {
      throw Exception(
        mounted
            ? AppLocalizations.of(context).offlineInvalidGraphFolder(region.id)
            : 'Ordner ${region.id} enthält keinen gültigen Graph für dieses Pack',
      );
    }
    final mapOk = await OfflinePmtilesStore.isReady(
      basemapArchiveIdForBbox(region.bbox),
    );
    await _savePrefs(
      regionPack: region.name,
      activatedPackPath: regionDir.path,
      engineHint: 'offline_graph',
      packBbox: region.bbox,
      basemapReady: mapOk,
    );
    OfflineTilesStore.instance.clearCache();
    final status = await OfflineTilesStore.instance.valhallaLinkStatus();
    if (mounted) {
      setState(() {
        _progress = AppLocalizations.of(context).offlineProgressActivating;
      });
    }
    final ring = await OfflinePackDirs.coverageRingResultForDir(regionDir);
    final street = await _streetHudMeta(region.id);
    if (!mounted) return;
    setState(() {
      _regionPref = region.name;
      _activatedPath = regionDir.path;
      _engineHint = 'offline_graph';
      _valhallaStatus = status;
      _basemapReady = mapOk;
      _packBbox = region.bbox;
      _packRing = ring?.outline;
      _packDots = ring?.dots;
      _packTraces = ring?.traces;
      _streetReady = street.ready;
      _streetBbox = street.bbox;
      _streetKind = street.kind;
    });
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
      _progress =
          AppLocalizations.of(context).offlineProgressBasemap(archiveId);
      _progressValue = 0;
    });
    try {
      await OfflinePmtilesStore.downloadArchive(
        id: archiveId,
        onProgress: (got, total) {
          if (!mounted || _downloadCancelled) return;
          final t = total != null && total > 0 ? formatPackBytes(total) : '?';
          setState(() {
            _progressValue =
                total != null && total > 0 ? (got / total).clamp(0, 1) : null;
            _progress =
                AppLocalizations.of(context).offlineProgressBasemapBytes(
              formatPackBytes(got),
              t,
            );
          });
        },
        isCancelled: () => _downloadCancelled || !mounted,
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
    } on OfflineDownloadCancelled {
      return OfflineBasemapResult.failed;
    } catch (e) {
      debugPrint('PMTiles archive $archiveId: $e');
    }
    if (_downloadCancelled || !mounted) {
      return OfflineBasemapResult.failed;
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

  Future<void> _onRegionTap(
    OfflinePackRow region, {
    bool forceDownload = false,
  }) async {
    if (_busy) return;
    if (!region.isReady && region.id != kBundledOfflineGraphRegionId) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)
                .offlinePackNotBuilt(_regionLabel(region)),
          ),
        ),
      );
      return;
    }
    final installed = _installed.contains(region.id);
    if (installed && !forceDownload) {
      if (_isActive(region)) {
        if (mounted) Navigator.of(context).pop(_prefsChanged);
        return;
      }
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
        Navigator.of(context).pop(_prefsChanged);
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
    if (packNeedsDownloadConfirm(region)) {
      final l10n = AppLocalizations.of(context);
      final size = formatPackBytes(region.bytes);
      final ok = await _confirmSize(
        title: l10n.offlineConfirmLargeTitle,
        body: l10n.offlineConfirmLargeBody(_regionLabel(region), size),
      );
      if (!ok) return;
    }
    await _downloadAndActivate(region);
  }

  Future<bool> _confirmSize({
    required String title,
    required String body,
    String? confirmLabel,
  }) async {
    if (!mounted) return false;
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmLabel ?? l10n.offlineConfirmLoad),
          ),
        ],
      ),
    );
    return ok == true;
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
      if (_downloadCancelled || !mounted) {
        throw const OfflineDownloadCancelled();
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
            if ((region.builtAt ?? manifest?['builtAt']) != null)
              'builtAt': region.builtAt ?? manifest?['builtAt'],
          }),
        );
      } else {
        try {
          final existing = jsonDecode(await manOut.readAsString());
          if (existing is Map &&
              (existing['builtAt'] == null ||
                  '${existing['builtAt']}'.trim().isEmpty)) {
            final stamp = region.builtAt ?? manifest?['builtAt'];
            if (stamp is String && stamp.trim().isNotEmpty) {
              existing['builtAt'] = stamp;
              existing['id'] = existing['id'] ?? region.id;
              await manOut.writeAsString(jsonEncode(existing));
            }
          }
        } catch (_) {}
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
      final archiveId = basemapArchiveIdForBbox(bbox);
      final mapOk = await OfflinePmtilesStore.isReady(archiveId);
      await _savePrefs(basemapReady: mapOk);

      final installed = await _scanInstalled();
      final builtAt = await OfflinePackDirs.builtAtById();
      final storage = await _scanStorage();
      if (mounted) {
        setState(() => _progress = l10n.offlineProgressActivating);
      }
      final ring = await OfflinePackDirs.coverageRingResultForDir(regionDir);
      final street = await _streetHudMeta(region.id);
      if (!mounted) return;
      setState(() {
        _regionPref = (manifest?['name'] as String?) ?? region.name;
        _activatedPath = regionDir.path;
        _engineHint = hint;
        _valhallaStatus = status;
        _installed = installed;
        _localBuiltAt = builtAt;
        _packBbox = bbox;
        _packRing = ring?.outline;
        _packDots = ring?.dots;
        _packTraces = ring?.traces;
        _basemapReady = mapOk;
        _streetReady = street.ready;
        _streetBbox = street.bbox;
        _streetKind = street.kind;
        _storageBytes = storage;
        _progress = null;
        _progressValue = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            sourceLabel == 'bundle'
                ? l10n.offlineDemoGraph(_regionLabel(region))
                : l10n.offlineSnackRoutingOnly(_regionLabel(region)),
          ),
        ),
      );
      if (mounted) Navigator.of(context).pop(_prefsChanged);
    } catch (e) {
      if (tmpDir != null && await tmpDir.exists()) {
        try {
          await tmpDir.delete(recursive: true);
        } catch (_) {}
      }
      if (_downloadCancelled || e is OfflineDownloadCancelled) return;
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
    Navigator.of(context).pop(_prefsChanged);
  }

  Future<void> _clearActivatedPack() async {
    await OfflineMapsPrefs.merge({
      'regionPack': null,
      'activatedPackPath': null,
      'engineHint': null,
      'packBbox': null,
      'basemapReady': null,
      'activatedAt': null,
    });
    _prefsChanged = true;
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
      _packBbox = null;
      _packRing = null;
      _packDots = null;
      _packTraces = null;
      _streetReady = false;
      _streetBbox = null;
      _streetKind = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).offlineRemoved),
      ),
    );
  }

  Future<void> _deleteInstalled(OfflinePackRow region) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await OfflineBasemap.deleteRegionId(region.id);
      await OfflineBasemap.deleteRegionId(streetHudRegionId(region.id));
      await OfflinePackDirs.deleteId(region.id);
      _prefsChanged = true;
      final wasActive = _isActive(region);
      if (wasActive) {
        await OfflineMapsPrefs.merge({
          'regionPack': null,
          'activatedPackPath': null,
          'engineHint': null,
          'packBbox': null,
          'basemapReady': null,
          'activatedAt': null,
        });
      }
      OfflineTilesStore.instance.clearCache();
      final installed = await _scanInstalled();
      final builtAt = await OfflinePackDirs.builtAtById();
      final storage = await _scanStorage();
      final status = await OfflineTilesStore.instance.valhallaLinkStatus();
      if (!mounted) return;
      setState(() {
        _installed = installed;
        _localBuiltAt = builtAt;
        _storageBytes = storage;
        _valhallaStatus = status;
        if (wasActive) {
          _regionPref = null;
          _activatedPath = null;
          _engineHint = null;
          _packBbox = null;
          _packRing = null;
          _packDots = null;
          _packTraces = null;
          _basemapReady = false;
          _streetReady = false;
          _streetBbox = null;
          _streetKind = null;
        }
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _onOverviewTap() async {
    if (_busy) return;
    OfflinePackRow? region;
    for (final r in _regions) {
      if (_isActive(r)) {
        region = r;
        break;
      }
    }
    final bbox = region?.bbox ?? _packBbox;
    if (bbox == null || bbox.length < 4) return;
    region ??= OfflinePackRow(
      id: _activatedPath != null ? p.basename(_activatedPath!) : 'active',
      name: _regionPref ?? '',
      bbox: bbox,
      downloadable: true,
      status: 'ready',
    );
    final overviewMb = formatPackBytes(
      estimatedBasemapBytesForBbox(bbox),
    );
    final archiveId = basemapArchiveIdForBbox(bbox);
    final l10n = AppLocalizations.of(context);
    final ok = await _confirmSize(
      title: l10n.offlineConfirmOverviewTitle,
      body: l10n.offlineConfirmOverviewBody(archiveId, overviewMb),
    );
    if (!ok) return;
    if (!await OfflineBasemap.onWifiLikely()) {
      final cellOk = await _confirmSize(
        title: l10n.offlineConfirmCellularTitle,
        body: l10n.offlineConfirmCellularBody(overviewMb),
        confirmLabel: l10n.offlineConfirmCellularAnyway,
      );
      if (!cellOk) return;
    }
    setState(() => _busy = true);
    try {
      final result = await _downloadBasemap(region);
      final storage = await _scanStorage();
      if (!mounted || _downloadCancelled) return;
      setState(() => _storageBytes = storage);
      final loc = AppLocalizations.of(context);
      final msg = switch (result) {
        OfflineBasemapResult.success => loc.offlineOverviewReady,
        OfflineBasemapResult.skippedPmtiles => loc.offlineBasemapFail,
        OfflineBasemapResult.timedOut => loc.offlineRoutingBg,
        OfflineBasemapResult.failed => loc.offlineTilesMissing,
      };
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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

  Future<void> _onStreetTap() async {
    if (_busy) return;
    OfflinePackRow? region;
    for (final r in _regions) {
      if (_isActive(r)) {
        region = r;
        break;
      }
    }
    final packId = region?.id ??
        OfflineMapsPrefs.packIdFromActivatedPath(_activatedPath) ??
        '';
    if (packId.isEmpty) return;
    final offer = streetHudOffer(
      packId: packId,
      occupancyBbox: _packRing != null && _packRing!.length >= 4
          ? coverageBboxOfRing(_packRing!)
          : null,
      catalogBbox: region?.bbox ?? _packBbox,
      routeBbox: widget.routeBbox,
      userLng: widget.userLng,
      userLat: widget.userLat,
    );
    final bbox = offer?.bbox;
    if (bbox == null || bbox.length < 4) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).offlineStreetTooBig),
        ),
      );
      return;
    }
    region ??= OfflinePackRow(
      id: packId,
      name: _regionPref ?? packId,
      bbox: bbox,
      downloadable: true,
      status: 'ready',
    );
    final l10n = AppLocalizations.of(context);
    final size = formatPackBytes(estimatedStreetHudBytes(bbox));
    final body = switch (offer!.kind) {
      StreetHudOfferKind.route =>
        l10n.offlineConfirmStreetRouteBody(_regionLabel(region), size),
      StreetHudOfferKind.corridor =>
        l10n.offlineConfirmStreetCorridorBody(_regionLabel(region), size),
      StreetHudOfferKind.pack =>
        l10n.offlineConfirmStreetBody(_regionLabel(region), size),
    };
    final ok = await _confirmSize(
      title: l10n.offlineConfirmStreetTitle,
      body: body,
    );
    if (!ok) return;
    if (!await OfflineBasemap.onWifiLikely()) {
      final cellOk = await _confirmSize(
        title: l10n.offlineConfirmCellularTitle,
        body: l10n.offlineConfirmCellularBody(size),
        confirmLabel: l10n.offlineConfirmCellularAnyway,
      );
      if (!cellOk) return;
    }
    setState(() {
      _busy = true;
      _progress = l10n.offlineProgressMapZoom(
        '${kStreetHudMinZoom.toInt()}',
        '${maxStreetZoomForBbox(bbox).toInt()}',
      );
      _progressValue = 0;
    });
    try {
      final result = await OfflineBasemap.downloadStreetHud(
        packId: packId,
        name: region.name,
        bbox: bbox,
        mapStyleUrl: AppConfig.mapStyleUrl,
        onProgress: (p) {
          if (!mounted) return;
          setState(() {
            _progressValue = p;
            _progress = l10n.offlineProgressMapPercent('${(p * 100).round()}');
          });
        },
      );
      if (!mounted || _downloadCancelled) return;
      final ready = result == OfflineBasemapResult.success;
      if (ready) {
        _prefsChanged = true;
        await OfflineMapsPrefs.merge({
          'streetHudAt': DateTime.now().toUtc().toIso8601String(),
          'streetHudBbox': bbox,
          'streetHudKind': offer.kind.name,
          'streetHudPackId': packId,
        });
      }
      if (!mounted) return;
      setState(() {
        _streetReady = ready;
        if (ready) {
          _streetBbox = bbox;
          _streetKind = offer.kind;
        }
      });
      final msg = switch (result) {
        OfflineBasemapResult.success => l10n.offlineStreetReady,
        OfflineBasemapResult.skippedPmtiles => l10n.offlineBasemapFail,
        OfflineBasemapResult.timedOut => l10n.offlineRoutingBg,
        OfflineBasemapResult.failed => l10n.offlineTilesMissing,
      };
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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

  String _regionLabel(OfflinePackRow r) =>
      AppLocalizations.of(context).overlayRegionNameFor(r.id, r.name);

  Future<({bool ready, List<double>? bbox, StreetHudOfferKind? kind})>
      _streetHudMeta(String packId) async {
    var ready = false;
    try {
      ready = await OfflineBasemap.hasStreetHudRegion(packId);
    } catch (_) {}
    if (!ready) {
      return (ready: false, bbox: null, kind: null);
    }
    try {
      final prefs = await OfflineMapsPrefs.read();
      if (OfflineMapsPrefs.streetHudPackIdFrom(prefs) != packId) {
        return (ready: true, bbox: null, kind: null);
      }
      return (
        ready: true,
        bbox: OfflineMapsPrefs.streetHudBboxFrom(prefs),
        kind: streetHudKindFromRaw(
          OfflineMapsPrefs.streetHudKindRawFrom(prefs),
        ),
      );
    } catch (_) {
      return (ready: true, bbox: null, kind: null);
    }
  }

  StreetHudOffer? get _streetHudOffer {
    final packId =
        OfflineMapsPrefs.packIdFromActivatedPath(_activatedPath) ?? '';
    final ring = _packRing;
    return streetHudOffer(
      packId: packId,
      occupancyBbox:
          ring != null && ring.length >= 4 ? coverageBboxOfRing(ring) : null,
      catalogBbox: _packBbox,
      routeBbox: widget.routeBbox,
      userLng: widget.userLng,
      userLat: widget.userLat,
    );
  }

  bool get _streetStale => streetHudCoverageStale(
        kind: _streetKind,
        storedBbox: _streetBbox,
        userLng: widget.userLng,
        userLat: widget.userLat,
      );

  bool get _routingAway => coverageRiderOutside(
        lng: widget.userLng,
        lat: widget.userLat,
        bbox: _packBbox,
        routingReady: _activatedPath != null && _activatedPath!.isNotEmpty,
        ring: _packRing,
      );

  String _readyStatusLine(AppLocalizations l10n, {required bool hasPack}) {
    return offlineReadyStatusLine(
      hasPack: hasPack,
      routingAway: _routingAway,
      streetReady: _streetReady,
      streetStale: _streetStale,
      basemapReady: _basemapReady,
      loadBelow: l10n.offlineLoadBelow,
      bothAway: l10n.offlineReadyBothAway,
      streetHereRoutingAway: l10n.offlineReadyStreetHereRoutingAway,
      routingAwayLine: l10n.offlineReadyRoutingAway,
      allAway: l10n.offlineReadyAllAway,
      streetAway: l10n.offlineReadyStreetAway,
      allReady: l10n.offlineReadyAll,
      streetReadyLine: l10n.offlineReadyStreet,
      bothReady: l10n.offlineReadyBoth,
      routingReady: l10n.offlineReadyRouting,
    );
  }

  Future<void> _onStreetRemove() async {
    if (_busy) return;
    final packId =
        OfflineMapsPrefs.packIdFromActivatedPath(_activatedPath) ?? '';
    if (packId.isEmpty) return;
    final l10n = AppLocalizations.of(context);
    final ok = await _confirmSize(
      title: l10n.offlineConfirmStreetRemoveTitle,
      body: l10n.offlineConfirmStreetRemoveBody,
      confirmLabel: l10n.offlineStreetRemove,
    );
    if (!ok) return;
    setState(() => _busy = true);
    try {
      await OfflineBasemap.deleteRegionId(streetHudRegionId(packId));
      _prefsChanged = true;
      await OfflineMapsPrefs.merge({
        'streetHudAt': null,
        'streetHudBbox': null,
        'streetHudKind': null,
        'streetHudPackId': null,
      });
      if (!mounted) return;
      setState(() {
        _streetReady = false;
        _streetBbox = null;
        _streetKind = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.offlineStreetRemoved)),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

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
    final l10n = AppLocalizations.of(context);
    return [
      for (final r in _regions)
        if (r.name.toLowerCase().contains(q) ||
            r.id.contains(q) ||
            _regionLabel(r).toLowerCase().contains(q) ||
            packCountryCode(r).toLowerCase() == q ||
            l10n
                .offlineCountryLabelFor(packCountryCode(r))
                .toLowerCase()
                .contains(q))
          r,
    ];
  }

  Widget _sketchLegendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.muted),
        ),
      ],
    );
  }

  Widget _regionTile(
    OfflinePackRow r, {
    bool showDelete = false,
    bool highlight = false,
  }) {
    final l10n = AppLocalizations.of(context);
    final active = _isActive(r);
    final installed = _installed.contains(r.id);
    final hasUpdate = installed &&
        packRemoteIsNewer(
          localBuiltAt: _localBuiltAt[r.id],
          remoteBuiltAt: r.builtAt,
        );
    final enabled = !_busy &&
        (r.isReady || installed || r.id == kBundledOfflineGraphRegionId);
    var subtitle = l10n.offlinePackSubtitleFor(
      r,
      active: active,
      installed: installed,
    );
    if (hasUpdate) {
      final size = formatPackBytes(r.routingBytes);
      subtitle = size.isEmpty
          ? l10n.offlineSubUpdate
          : l10n.offlineSubUpdateSized(size);
    }
    final sizeLabel = formatPackBytes(r.routingBytes);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: enabled ? () => _onRegionTap(r) : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    ChromeGlyph(
                      active
                          ? 'check'
                          : hasUpdate
                              ? 'download'
                              : installed
                                  ? 'layers'
                                  : !r.isReady
                                      ? 'recent'
                                      : isEnvelopePackId(r.id)
                                          ? 'karte'
                                          : 'download',
                      color: active || hasUpdate
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
                    if (hasUpdate)
                      IconButton(
                        tooltip: l10n.offlineUpdatePack,
                        onPressed: _busy
                            ? null
                            : () => _onRegionTap(r, forceDownload: true),
                        icon: const ChromeGlyph('download',
                            size: 20, color: AppColors.chrome),
                        color: AppColors.chrome,
                      ),
                    if (showDelete && installed)
                      IconButton(
                        tooltip: l10n.offlineDeletePack,
                        onPressed: _busy ? null : () => _deleteInstalled(r),
                        icon: const ChromeGlyph('trash', size: 20),
                        color: AppColors.muted,
                      ),
                  ],
                ),
              ),
            ),
            if (highlight && enabled && !installed && r.isReady)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.chrome,
                  ),
                  onPressed: _busy ? null : () => _onRegionTap(r),
                  child: Text(
                    sizeLabel.isEmpty
                        ? l10n.offlineSubLoad
                        : '${l10n.offlineSubLoad} · $sizeLabel',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _countryGroup(
    OfflinePackCountryGroup g, {
    required bool expand,
    required bool searching,
    String? pinId,
  }) {
    final l10n = AppLocalizations.of(context);
    final split = collapseCountryPacks(
      packs: g.packs,
      userLng: _sortLng,
      userLat: _sortLat,
      pinId: pinId,
      searching: searching,
    );
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        key: ValueKey('offline-country-${g.code}-$searching'),
        initiallyExpanded: expand,
        tilePadding: EdgeInsets.zero,
        title: Text(
          l10n.offlineCountryLabelFor(g.code),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          l10n.offlineCountrySubtitleFor(
            packCount: g.packs.length,
            envelopeCount: g.envelopes.length,
          ),
          style: const TextStyle(color: AppColors.muted, fontSize: 12),
        ),
        children: [
          for (final r in split.shown) _regionTile(r),
          if (split.more.isNotEmpty)
            Theme(
              data:
                  Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.only(left: 8),
                title: Text(
                  l10n.offlineCountryMorePacks(split.more.length),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                children: [
                  for (final r in split.more) _regionTile(r),
                ],
              ),
            ),
          if (g.envelopes.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 4, 0, 8),
              child: Text(
                l10n.offlineEnvelopesHint,
                style: const TextStyle(color: AppColors.muted, fontSize: 11),
              ),
            ),
            for (final r in g.envelopes) _regionTile(r),
          ],
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final hasPack = (_activatedPath ?? '').trim().isNotEmpty;
    final filtered = _filtered;
    final searching = _searchCtrl.text.trim().isNotEmpty;
    final sections = groupOfflinePacks(
      filtered: filtered,
      installed: _installed,
      userLng: _sortLng,
      userLat: _sortLat,
      searching: searching,
      focusPackId: widget.focusPackId,
    );
    final l10n = AppLocalizations.of(context);
    final overviewMb = formatPackBytes(
      estimatedBasemapBytesForBbox(_packBbox ?? sections.suggested?.bbox),
    );
    final archiveId = basemapArchiveIdForBbox(
      _packBbox ?? sections.suggested?.bbox,
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        Navigator.of(context).pop(_prefsChanged);
      },
      child: Padding(
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              ChromeGlyph(
                                hasPack ? 'check' : 'download',
                                size: 22,
                                color: hasPack
                                    ? AppColors.chrome
                                    : AppColors.muted,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  hasPack
                                      ? _activeRegionTitle(l10n)
                                      : l10n.offlineNoRegion,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              Chip(
                                key: const Key('offline-routing-chip'),
                                visualDensity: VisualDensity.compact,
                                avatar: ChromeGlyph(
                                  !hasPack
                                      ? 'split'
                                      : _routingAway
                                          ? 'offline'
                                          : 'check',
                                  size: 16,
                                  color: hasPack && !_routingAway
                                      ? AppColors.chrome
                                      : AppColors.muted,
                                ),
                                label: Text(
                                  !hasPack
                                      ? l10n.offlineRoutingOff
                                      : _routingAway
                                          ? l10n.offlineRoutingAway
                                          : l10n.offlineRoutingOn,
                                ),
                              ),
                              Chip(
                                key: const Key('offline-overview-chip'),
                                visualDensity: VisualDensity.compact,
                                avatar: ChromeGlyph(
                                  _basemapReady ? 'check' : 'karte',
                                  size: 16,
                                  color: _basemapReady
                                      ? AppColors.chrome
                                      : AppColors.muted,
                                ),
                                label: Text(
                                  _basemapReady
                                      ? l10n.offlineOverviewOn
                                      : l10n.offlineOverviewOff,
                                ),
                              ),
                              Chip(
                                key: const Key('offline-street-chip'),
                                visualDensity: VisualDensity.compact,
                                avatar: ChromeGlyph(
                                  !_streetReady
                                      ? 'nav'
                                      : _streetStale
                                          ? 'offline'
                                          : 'check',
                                  size: 16,
                                  color: _streetReady && !_streetStale
                                      ? AppColors.chrome
                                      : AppColors.muted,
                                ),
                                label: Text(
                                  !_streetReady
                                      ? l10n.offlineStreetOff
                                      : _streetStale
                                          ? l10n.offlineStreetAway
                                          : l10n.offlineStreetOn,
                                ),
                              ),
                            ],
                          ),
                          if (_storageBytes > 0) ...[
                            const SizedBox(height: 8),
                            Text(
                              l10n.offlineStorageLine(
                                formatPackBytes(_storageBytes),
                              ),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                          const SizedBox(height: 4),
                          Text(
                            _readyStatusLine(l10n, hasPack: hasPack),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                            ),
                          ),
                          if (_packBbox != null &&
                              _packBbox!.length >= 4 &&
                              !skipFitCameraForPackId(
                                OfflineMapsPrefs.packIdFromActivatedPath(
                                  _activatedPath,
                                ),
                              )) ...[
                            const SizedBox(height: 10),
                            OfflineCoverageSketch(
                              bbox: _packBbox!,
                              ring: _packRing,
                              dots: _packDots,
                              traces: _packTraces,
                              streetBbox: _streetBbox ??
                                  ((_streetHudOffer?.isPartial ?? false)
                                      ? _streetHudOffer!.bbox
                                      : null),
                              streetLine: widget.routeLine,
                              userLng: widget.userLng,
                              userLat: widget.userLat,
                              overviewReady: _basemapReady,
                              streetReady: _streetReady,
                              progress: _busy ? _progressValue : null,
                              semanticLabel: l10n.offlineCoverageShowOnMap,
                              onTap: widget.onShowOnMap == null
                                  ? null
                                  : () {
                                      final ring = _packRing;
                                      final fromRing = ring != null &&
                                              ring.length >= 4
                                          ? coverageBboxOfRing(ring)
                                          : null;
                                      final show =
                                          (fromRing != null &&
                                                  fromRing.length >= 4)
                                              ? fromRing
                                              : _packBbox!;
                                      widget.onShowOnMap!(show);
                                      Navigator.of(context).pop(false);
                                    },
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                _sketchLegendDot(
                                  AppColors.chrome,
                                  l10n.offlineSketchRouting,
                                ),
                                if ((_packTraces != null &&
                                        _packTraces!.isNotEmpty) ||
                                    (_packDots != null &&
                                        _packDots!.isNotEmpty)) ...[
                                  const SizedBox(width: 12),
                                  _sketchLegendDot(
                                    AppColors.chrome.withValues(alpha: 0.7),
                                    l10n.offlineSketchGraph,
                                  ),
                                ],
                                if (_basemapReady) ...[
                                  const SizedBox(width: 12),
                                  _sketchLegendDot(
                                    AppColors.sage,
                                    l10n.offlineSketchOverview,
                                  ),
                                ],
                                if (_streetReady ||
                                    (_streetHudOffer?.isPartial ?? false)) ...[
                                  const SizedBox(width: 12),
                                  _sketchLegendDot(
                                    AppColors.sageOnDark,
                                    l10n.offlineSketchStreet,
                                  ),
                                ],
                              ],
                            ),
                          ],
                          if (hasPack &&
                              _streetHudOffer != null &&
                              (!_streetReady || _streetStale)) ...[
                            const SizedBox(height: 10),
                            FilledButton(
                              key: const Key('offline-street-download'),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.sageOnDark,
                              ),
                              onPressed: _busy ? null : _onStreetTap,
                              child: Text(
                                () {
                                  final offer = _streetHudOffer!;
                                  final size = formatPackBytes(
                                    estimatedStreetHudBytes(offer.bbox),
                                  );
                                  if (_streetReady && _streetStale) {
                                    return l10n.offlineStreetRefreshCta(size);
                                  }
                                  if (offer.isRoute) {
                                    return l10n.offlineStreetRouteCta(size);
                                  }
                                  if (offer.isCorridor) {
                                    return l10n.offlineStreetCorridorCta(size);
                                  }
                                  return l10n.offlineStreetCta(size);
                                }(),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _streetHudOffer!.isPartial
                                  ? l10n.offlineStreetCorridorExplain
                                  : l10n.offlineStreetExplain,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                          if (hasPack &&
                              !_streetReady &&
                              _streetHudOffer == null) ...[
                            const SizedBox(height: 8),
                            Text(
                              widget.userLng == null || widget.userLat == null
                                  ? l10n.offlineStreetNeedGps
                                  : l10n.offlineStreetTooBig,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                          if (hasPack && _streetReady) ...[
                            const SizedBox(height: 4),
                            TextButton(
                              key: const Key('offline-street-remove'),
                              onPressed: _busy ? null : _onStreetRemove,
                              child: Text(l10n.offlineStreetRemove),
                            ),
                          ],
                          if (hasPack &&
                              !_basemapReady &&
                              _packBbox != null &&
                              _packBbox!.length >= 4) ...[
                            const SizedBox(height: 10),
                            FilledButton(
                              key: const Key('offline-overview-download'),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.chrome,
                              ),
                              onPressed: _busy ? null : _onOverviewTap,
                              child: Text(
                                l10n.offlineOverviewCta(archiveId, overviewMb),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n.offlineOverviewExplain,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                          if (AppConfig.showRoutingDebug &&
                              _valhallaStatus != null) ...[
                            const SizedBox(height: 6),
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
                    if (_progress != null) ...[
                      const SizedBox(height: 12),
                      Text(_progress!, style: const TextStyle(fontSize: 12)),
                      const SizedBox(height: 6),
                      LinearProgressIndicator(value: _progressValue),
                    ],
                    if (sections.suggested != null) ...[
                      _sectionTitle(l10n.offlineSuggested),
                      _regionTile(
                        sections.suggested!,
                        highlight: true,
                        showDelete: _installed.contains(sections.suggested!.id),
                      ),
                    ],
                    if (sections.installed.isNotEmpty) ...[
                      _sectionTitle(l10n.offlineInstalledSection),
                      for (final r in sections.installed)
                        _regionTile(r, showDelete: true),
                    ],
                    if (_catalogNote != null) ...[
                      const SizedBox(height: 8),
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
                          prefixIcon: const ChromeGlyph(
                            'search',
                            size: 20,
                            color: AppColors.muted,
                          ),
                          hintText: l10n.offlineSearchRegion,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
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
                    for (final g in sections.countries)
                      _countryGroup(
                        g,
                        expand: searching || g.code == sections.focusCountry,
                        searching: searching,
                        pinId: sections.suggested?.id,
                      ),
                    if (sections.stubs.isNotEmpty)
                      Theme(
                        data: Theme.of(context).copyWith(
                          dividerColor: Colors.transparent,
                        ),
                        child: ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          title: Text(
                            l10n.offlineNotBuilt(sections.stubs.length),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            l10n.offlineStubsHint,
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                          children: [
                            for (final r in sections.stubs) _regionTile(r),
                          ],
                        ),
                      ),
                    if (_catalogReady &&
                        !searching &&
                        sections.countries.isEmpty &&
                        sections.installed.isEmpty &&
                        sections.stubs.isNotEmpty)
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
                    if (hasPack)
                      TextButton(
                        onPressed: _busy ? null : _clearActivatedPack,
                        child: Text(l10n.offlineRemoveRegion),
                      ),
                    if (AppConfig.showRoutingDebug) ...[
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
                                hintText:
                                    'https://…/basemap/dach-z11-style.json',
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
                  ],
                ),
              ),
      ),
    );
  }
}
