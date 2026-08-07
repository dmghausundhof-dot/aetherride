import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/config.dart';
import '../../core/theme/app_theme.dart';
import '../../data/routing/offline_maps_prefs.dart';
import '../../data/routing/offline_tiles.dart';

/// Hardcoded region catalog (demo).
const _kRegions = [
  (
    id: 'schwarzwald-nord',
    name: 'Schwarzwald Nord',
  ),
];

/// Offline-Karten: PMTiles-URL + Region-Packs.
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
  bool _loading = true;
  bool _busy = false;

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
    try {
      final m = await OfflineMapsPrefs.read();
      override = (m['pmtilesUrl'] as String?) ?? '';
      region = m['regionPack'] as String?;
      activated = m['activatedPackPath'] as String?;
    } catch (_) {}
    final status = await OfflineTilesStore.instance.valhallaLinkStatus();
    if (!mounted) return;
    setState(() {
      _urlCtrl.text = override.isNotEmpty ? override : compileTime;
      _regionPref = region;
      _activatedPath = activated;
      _valhallaStatus = status;
      _loading = false;
    });
  }

  Future<void> _savePrefs({
    String? pmtilesUrl,
    String? regionPack,
    String? activatedPackPath,
  }) async {
    await OfflineMapsPrefs.merge({
      if (pmtilesUrl != null) 'pmtilesUrl': pmtilesUrl,
      if (regionPack != null) 'regionPack': regionPack,
      if (activatedPackPath != null) 'activatedPackPath': activatedPackPath,
    });
  }

  Future<void> _downloadAndActivate(({String id, String name}) region) async {
    setState(() => _busy = true);
    try {
      final docs = await getApplicationDocumentsDirectory();
      final regionDir = Directory(p.join(docs.path, 'regions', region.id));
      await regionDir.create(recursive: true);
      final target = File(p.join(regionDir.path, 'offline_graph.json'));

      var gotRemote = false;
      final candidates = [
        Uri.parse(
          '${AppConfig.apiBaseUrl}/offline/${region.id}/offline_graph.json',
        ),
        Uri.parse(
          '${AppConfig.apiBaseUrl}/api/offline/packs/${region.id}/offline_graph.json',
        ),
      ];
      for (final url in candidates) {
        try {
          final res = await http.get(url).timeout(const Duration(seconds: 12));
          if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
            await target.writeAsBytes(res.bodyBytes);
            gotRemote = true;
            break;
          }
        } catch (_) {}
      }
      if (!gotRemote) {
        final data = await rootBundle.load('assets/routing/offline_graph.json');
        await target.writeAsBytes(data.buffer.asUint8List());
      }

      await _savePrefs(
        regionPack: region.name,
        activatedPackPath: regionDir.path,
      );
      OfflineTilesStore.instance.clearCache();
      if (!mounted) return;
      setState(() {
        _regionPref = region.name;
        _activatedPath = regionDir.path;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            gotRemote
                ? '${region.name} heruntergeladen & aktiv'
                : '${region.name} aus Bundle aktiviert',
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
      if (mounted) setState(() => _busy = false);
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
                  const SizedBox(height: 8),
                  for (final r in _kRegions)
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
