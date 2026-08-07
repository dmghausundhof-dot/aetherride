import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/config.dart';
import '../../core/theme/app_theme.dart';
import '../../data/routing/offline_maps_prefs.dart';
import '../../data/routing/offline_tiles.dart';

/// Fallback catalog when API has no list endpoint.
const _kFallbackRegions = [
  (id: 'schwarzwald-nord', name: 'Schwarzwald Nord'),
];

/// Offline-Karten: PMTiles-URL + Region-Packs (Manifest + SHA-256).
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

  @override
  void initState() {
    super.initState();
    _load();
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
  }) async {
    await OfflineMapsPrefs.merge({
      if (pmtilesUrl != null) 'pmtilesUrl': pmtilesUrl,
      if (regionPack != null) 'regionPack': regionPack,
      if (activatedPackPath != null) 'activatedPackPath': activatedPackPath,
      if (engineHint != null) 'engineHint': engineHint,
    });
  }

  Future<Map<String, dynamic>?> _fetchManifest(String id) async {
    final urls = [
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
      );
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
                : '${region.name} aktiv ($hint)',
          ),
        ),
      );
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
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
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
                  const SizedBox(height: 8),
                  Text(
                    'Compile-Zeit PMTiles: '
                    '${AppConfig.pmtilesUrl.isEmpty ? '(leer)' : AppConfig.pmtilesUrl}',
                    style: const TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                  if (_valhallaStatus != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Valhalla: $_valhallaStatus',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  if (_engineHint != null) ...[
                    Text(
                      'Pack-Engine: $_engineHint',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextField(
                    controller: _urlCtrl,
                    decoration: const InputDecoration(
                      labelText: 'PMTiles-URL',
                      hintText: 'https://…/region.pmtiles',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                    ),
                    onPressed: _busy
                        ? null
                        : () async {
                            await _savePrefs(pmtilesUrl: _urlCtrl.text.trim());
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('PMTiles-URL gespeichert'),
                                ),
                              );
                            }
                          },
                    child: const Text('URL speichern'),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Region-Pack',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _regionPref == null
                        ? 'Noch keine Region aktiv.'
                        : 'Aktiv: $_regionPref'
                            '${_activatedPath != null ? '\n$_activatedPath' : ''}',
                    style: const TextStyle(color: AppColors.muted, fontSize: 13),
                  ),
                  if (_progress != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _progress!,
                      style: const TextStyle(fontSize: 12),
                    ),
                    const LinearProgressIndicator(),
                  ],
                  const SizedBox(height: 8),
                  for (final r in _kFallbackRegions)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: OutlinedButton.icon(
                        onPressed:
                            _busy ? null : () => _downloadAndActivate(r),
                        icon: const Icon(Icons.download_outlined),
                        label: Text('${r.name} laden & aktivieren'),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
