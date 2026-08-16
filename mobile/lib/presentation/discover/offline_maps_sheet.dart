import 'dart:convert';
import 'dart:io';

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
import '../../data/routing/offline_maps_prefs.dart';
import '../../data/routing/offline_tiles.dart';
import '../../data/routing/map_style_url.dart';
import '../../data/routing/bike_overlay.dart';
import '../../data/routing/offline_pmtiles_store.dart';

import '../../data/routing/overlay_regions.dart';

/// Fallback-Regionen (Komoot-ähnlich: DACH breit, nicht nur Schwarzwald).
/// Download nutzt API-Manifest; fehlt das Pack, greift Bundle-Fallback.
final _kFallbackRegions = [
  for (final r in kOverlayPackCatalog) (id: r.id, name: r.name),
];

/// Offline-Karten: Region-Packs zuerst (wie Komoot/AllTrails), Style optional.
class OfflineMapsSheet extends StatefulWidget {
  const OfflineMapsSheet({super.key});

  @override
  State<OfflineMapsSheet> createState() => _OfflineMapsSheetState();
}

class _OfflineMapsSheetState extends State<OfflineMapsSheet> {
  final _urlCtrl = TextEditingController();
  String? _regionPref;
  String? _activatedPath;
  String? _valhallaStatus;
  String? _engineHint;
  bool _loading = true;
  bool _busy = false;
  String? _progress;
  double? _progressValue;
  String? _catalogNote;
  List<({String id, String name})> _regions = List.from(_kFallbackRegions);

  @override
  void initState() {
    super.initState();
    _load();
    _fetchCatalog();
  }

  Future<void> _fetchCatalog() async {
    try {
      final res = await http
          .get(
            Uri.parse('${AppConfig.apiBaseUrl}/api/offline/packs'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) {
        if (mounted) {
          setState(
            () => _catalogNote =
                'Katalog online nicht erreichbar — DACH-Regionen lokal',
          );
        }
        return;
      }
      final data = jsonDecode(res.body);
      if (data is! Map) return;
      final packs = <({String id, String name})>[];
      for (final raw in (data['packs'] as List? ?? const [])) {
        if (raw is! Map) continue;
        final id = raw['id'] as String?;
        if (id == null || id.isEmpty) continue;
        packs.add((id: id, name: (raw['name'] as String?) ?? id));
      }
      if (!mounted) return;
      if (packs.isEmpty) {
        setState(
          () => _catalogNote = 'Keine Remote-Packs — DACH-Fallback aktiv',
        );
        return;
      }
      // Merge: API zuerst, dann Fallback-IDs die fehlen.
      final seen = {for (final p in packs) p.id};
      for (final f in _kFallbackRegions) {
        if (!seen.contains(f.id)) packs.add(f);
      }
      setState(() {
        _regions = packs;
        _catalogNote = null;
      });
    } catch (_) {
      if (mounted) {
        setState(
          () => _catalogNote =
              'Offline — DACH-Regionen aus App-Katalog',
        );
      }
    }
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final compileTime = AppConfig.pmtilesUrl;
    var override = '';
    String? region;
    String? activated;
    String? engineHint;
    try {
      final m = await OfflineMapsPrefs.read();
      override = (m['pmtilesUrl'] as String?) ?? '';
      region = m['regionPack'] as String?;
      activated = m['activatedPackPath'] as String?;
      engineHint = m['engineHint'] as String?;
    } catch (_) {}
    final status = await OfflineTilesStore.instance.valhallaLinkStatus();
    if (!mounted) return;
    setState(() {
      _urlCtrl.text = override.isNotEmpty ? override : compileTime;
      _regionPref = region;
      _activatedPath = activated;
      _engineHint = engineHint;
      _valhallaStatus = status;
      _loading = false;
    });
  }

  Future<void> _savePrefs({
    String? pmtilesUrl,
    String? regionPack,
    String? activatedPackPath,
    String? engineHint,
    List<double>? packBbox,
  }) async {
    await OfflineMapsPrefs.merge({
      if (pmtilesUrl != null) 'pmtilesUrl': pmtilesUrl,
      if (regionPack != null) 'regionPack': regionPack,
      if (activatedPackPath != null) 'activatedPackPath': activatedPackPath,
      if (engineHint != null) 'engineHint': engineHint,
      if (packBbox != null) 'packBbox': packBbox,
    });
  }

  Future<Map<String, dynamic>?> _fetchManifest(String id) async {
    final urls = [
      Uri.parse('${AppConfig.apiBaseUrl}/api/offline/packs/$id'),
      Uri.parse(AppConfig.offlinePackObjectUrl(id, 'manifest.json')),
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

  Future<Uint8List?> _downloadBytes(List<Uri> urls) async {
    for (final url in urls) {
      try {
        final res = await http.get(url).timeout(const Duration(seconds: 60));
        if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
          return res.bodyBytes;
        }
      } catch (_) {}
    }
    return null;
  }

  void _verifySha256(Uint8List bytes, String? expected) {
    if (expected == null || expected.isEmpty) return;
    final got = sha256.convert(bytes).toString();
    if (got.toLowerCase() != expected.toLowerCase()) {
      throw Exception('SHA-256 mismatch (expected $expected, got $got)');
    }
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

  Future<void> _downloadAndActivate(({String id, String name}) region) async {
    setState(() {
      _busy = true;
      _progress = 'Manifest…';
      _progressValue = null;
    });
    try {
      final docs = await getApplicationDocumentsDirectory();
      final regionDir = Directory(p.join(docs.path, 'regions', region.id));
      if (await regionDir.exists()) {
        await regionDir.delete(recursive: true);
      }
      await regionDir.create(recursive: true);

      final manifest = await _fetchManifest(region.id);
      final files = manifest?['files'] is Map
          ? Map<String, dynamic>.from(manifest!['files'] as Map)
          : <String, dynamic>{};
      final cdn = manifest?['cdn'] is Map
          ? Map<String, dynamic>.from(manifest!['cdn'] as Map)
          : <String, dynamic>{};
      final cdnBase = (cdn['baseUrl'] as String?)?.replaceAll(RegExp(r'/$'), '');
      final packGz = (cdn['packGz'] as String?) ?? '${region.id}.tar.gz';

      var sourceLabel = 'remote';
      var gotPack = false;

      // Prefer tar.gz pack (SHA-256 verified) — Flutter-friendly.
      if (files.containsKey(packGz) || packGz.endsWith('.tar.gz')) {
        setState(() => _progress = 'Pack $packGz…');
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
        final bytes = await _downloadBytes(urls);
        if (bytes != null) {
          _verifySha256(bytes, meta?['sha256'] as String?);
          await _extractTarGz(bytes, regionDir);
          gotPack = true;
        }
      }

      // Fallback: individual offline_graph.json (+ optional valhalla.json)
      if (!gotPack) {
        setState(() => _progress = 'offline_graph.json…');
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
        final graphBytes = await _downloadBytes(graphUrls);
        if (graphBytes != null) {
          _verifySha256(graphBytes, graphMeta?['sha256'] as String?);
          await File(p.join(regionDir.path, 'offline_graph.json'))
              .writeAsBytes(graphBytes);
          gotPack = true;
        }

        final valMeta = files['valhalla.json'] is Map
            ? Map<String, dynamic>.from(files['valhalla.json'] as Map)
            : null;
        final valUrls = <Uri>[
          if (cdnBase != null && cdnBase.isNotEmpty)
            Uri.parse('$cdnBase/valhalla.json'),
          Uri.parse(
            '${AppConfig.apiBaseUrl}/api/offline/packs/${region.id}/valhalla.json',
          ),
        ];
        final valBytes = await _downloadBytes(valUrls);
        if (valBytes != null) {
          _verifySha256(valBytes, valMeta?['sha256'] as String?);
          await File(p.join(regionDir.path, 'valhalla.json'))
              .writeAsBytes(valBytes);
        }
      }

      if (!gotPack) {
        sourceLabel = 'bundle';
        setState(() => _progress = 'Asset-Fallback…');
        final data = await rootBundle.load('assets/routing/offline_graph.json');
        await File(p.join(regionDir.path, 'offline_graph.json'))
            .writeAsBytes(data.buffer.asUint8List());
      }

      final engines = manifest?['engines'] is Map
          ? Map<String, dynamic>.from(manifest!['engines'] as Map)
          : null;
      final hint = engines?['valhalla_tiles'] == true
          ? 'valhalla'
          : 'offline_graph';

      await _savePrefs(
        regionPack: (manifest?['name'] as String?) ?? region.name,
        activatedPackPath: regionDir.path,
        engineHint: hint,
        packBbox: _packBbox(region.id, manifest),
      );
      await downloadBikeOverlayIntoPack(regionDir, region.id);
      await _ensureBasemapArchive(region.id, manifest);
      OfflineTilesStore.instance.clearCache();
      final status = await OfflineTilesStore.instance.valhallaLinkStatus();
      if (!mounted) return;
      setState(() {
        _regionPref = (manifest?['name'] as String?) ?? region.name;
        _activatedPath = regionDir.path;
        _engineHint = hint;
        _valhallaStatus = status;
        _progress = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            sourceLabel == 'bundle'
                ? '${region.name}: Bundle-Graph aktiv (kein Remote-Pack)'
                : status.contains('unlinked') || status.contains('graph')
                    ? '${region.name} aktiv ($hint) — $status'
                    : '${region.name} aktiv ($hint)',
          ),
        ),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Region-Pack: $e')),
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

  List<double>? _packBbox(String id, Map<String, dynamic>? manifest) {
    final raw = manifest?['bbox'];
    if (raw is List && raw.length >= 4) {
      final out = <double>[];
      for (final x in raw.take(4)) {
        if (x is! num) return overlayRegionById(id)?.bbox;
        out.add(x.toDouble());
      }
      return out;
    }
    return overlayRegionById(id)?.bbox;
  }

  String _fmtBytes(int n) {
    if (n >= 1024 * 1024 * 1024) {
      return '${(n / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
    if (n >= 1024 * 1024) {
      return '${(n / (1024 * 1024)).toStringAsFixed(0)} MB';
    }
    return '$n B';
  }

  /// Copy the matching CDN overview archive into documents. Never MapLibre OfflineRegion.
  Future<void> _ensureBasemapArchive(
    String regionId,
    Map<String, dynamic>? manifest,
  ) async {
    final bbox = _packBbox(regionId, manifest);
    final archiveId = basemapArchiveIdForBbox(bbox);
    if (await OfflinePmtilesStore.isReady(archiveId)) {
      if (!await OfflinePmtilesStore.assetsReady()) {
        if (mounted) {
          setState(() {
            _progressValue = null;
            _progress = 'Karten-Schrift (Glyphs/Sprites)…';
          });
        }
        await OfflinePmtilesStore.downloadAssets(
          onProgress: (done, total) {
            if (!mounted || total <= 0) return;
            setState(() {
              _progressValue = (done / total).clamp(0.0, 1.0);
              _progress = 'Karten-Schrift $done / $total';
            });
          },
        );
        await OfflinePmtilesStore.writeLocalStyle(archiveId);
      }
      final local = await OfflinePmtilesStore.localStyleUri(archiveId);
      if (local != null) {
        await _savePrefs(pmtilesUrl: local);
        if (mounted) setState(() => _urlCtrl.text = local);
      }
      return;
    }
    if (!mounted) return;
    setState(() {
      _progressValue = 0;
      _progress =
          'Basemap $archiveId (WLAN)…';
    });
    try {
      await OfflinePmtilesStore.downloadArchive(
        id: archiveId,
        onProgress: (got, total) {
          if (!mounted) return;
          final t = total != null && total > 0 ? _fmtBytes(total) : '?';
          setState(() {
            _progressValue =
                total != null && total > 0 ? (got / total).clamp(0.0, 1.0) : null;
            _progress = 'Basemap $archiveId: ${_fmtBytes(got)} / $t';
          });
        },
      );
      if (mounted) {
        setState(() {
          _progressValue = null;
          _progress = 'Karten-Schrift (Glyphs/Sprites)…';
        });
      }
      final local = await OfflinePmtilesStore.localStyleUri(archiveId);
      if (local != null) {
        await _savePrefs(pmtilesUrl: local);
        if (mounted) setState(() => _urlCtrl.text = local);
      }
    } catch (e) {
      debugPrint('PMTiles archive $archiveId: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Karte bleibt online (CDN). Archiv $archiveId: $e',
            ),
          ),
        );
      }
    }
  }

  /// True if URL looks like a MapLibre style JSON (not a raw .pmtiles file).
  static bool isStyleJsonUrl(String raw) => isMapLibreStyleJsonUrl(raw);

  String? _styleUrlError(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return null;
    if (t.toLowerCase().endsWith('.pmtiles') ||
        t.toLowerCase().contains('.pmtiles?')) {
      return 'Roh-.pmtiles wird nicht unterstützt — MapLibre-Style-JSON mit '
          'pmtiles://-Source nötig.';
    }
    if (!isStyleJsonUrl(t) &&
        !t.startsWith('http://') &&
        !t.startsWith('https://')) {
      return 'Ungültige URL';
    }
    if (!isStyleJsonUrl(t)) {
      return 'Erwarte Style-JSON-URL (*.json oder /styles/…), keine Tile-Datei.';
    }
    return null;
  }

  Future<void> _saveStyleUrl() async {
    final url = _urlCtrl.text.trim();
    final err = _styleUrlError(url);
    if (err != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
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
              ? 'Override gelöscht — Default-Style aktiv'
              : 'Style gespeichert. Karte wird neu geladen: $resolved',
        ),
      ),
    );
    Navigator.of(context).pop(true);
  }

  Future<void> _clearActivatedPack() async {
    await OfflineMapsPrefs.merge({
      'regionPack': null,
      'activatedPackPath': null,
      'engineHint': null,
      'packBbox': null,
    });
    OfflineTilesStore.instance.clearCache();
    final status = await OfflineTilesStore.instance.valhallaLinkStatus();
    if (!mounted) return;
    setState(() {
      _regionPref = null;
      _activatedPath = null;
      _engineHint = null;
      _valhallaStatus = status;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Region-Pack zurückgesetzt — Bundle-Graph als Fallback'),
      ),
    );
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  bool _isActive(({String id, String name}) r) {
    if (_regionPref == r.name) return true;
    return _activatedPath?.contains('/${r.id}') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final hasPack = _activatedPath != null;

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
                    'Offline-Karten',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Region laden — Graph plus Basemap-Archiv (DACH ~515 MB / '
                    'Frankreich-West ~293 MB). WLAN empfohlen; Glyphs bleiben remote.',
                    style: TextStyle(color: AppColors.muted, fontSize: 13),
                  ),
                  if (kDebugMode) ...[
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
                              ? AppColors.forestOnDark
                              : AppColors.muted,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                hasPack
                                    ? (_regionPref ?? 'Region aktiv')
                                    : 'Keine Region aktiv',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                hasPack
                                    ? 'Offline-Routing für diese Region bereit.'
                                    : 'Wähle unten eine DACH-Region zum Laden.',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.muted,
                                ),
                              ),
                              if (kDebugMode && _valhallaStatus != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Engine: $_valhallaStatus'
                                  '${_engineHint != null ? ' · $_engineHint' : ''}',
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
                    'Regionen',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  if (_catalogNote != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      _catalogNote!,
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  if (_progress != null) ...[
                    const SizedBox(height: 10),
                    Text(_progress!, style: const TextStyle(fontSize: 12)),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(value: _progressValue),
                  ],
                  const SizedBox(height: 10),
                  for (final r in _regions)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: AppColors.surfaceDark,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: _busy ? null : () => _downloadAndActivate(r),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _isActive(r)
                                      ? Icons.check_circle
                                      : Icons.download_outlined,
                                  color: _isActive(r)
                                      ? AppColors.forestOnDark
                                      : AppColors.muted,
                                  size: 22,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        r.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        _isActive(r)
                                            ? 'Aktiv — tippen zum Aktualisieren'
                                            : 'Tippen zum Laden',
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
                    ),
                  if (hasPack)
                    TextButton(
                      onPressed: _busy ? null : _clearActivatedPack,
                      child: const Text('Region entfernen'),
                    ),
                  const SizedBox(height: 8),
                  Theme(
                    data: Theme.of(context).copyWith(
                      dividerColor: Colors.transparent,
                    ),
                    child: ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      childrenPadding: EdgeInsets.zero,
                      title: const Text(
                        'Kartenstil (optional)',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: const Text(
                        'Nur nötig für eigenen MapLibre-Style',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                      children: [
                        TextField(
                          controller: _urlCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Style-JSON-URL',
                            hintText: 'https://…/styles/outdoors.json',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.forestOnDark,
                          ),
                          onPressed: _busy ? null : _saveStyleUrl,
                          child: const Text('Style speichern'),
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
