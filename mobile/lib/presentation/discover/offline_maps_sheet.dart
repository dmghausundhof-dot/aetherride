import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/config.dart';
import '../../core/theme/app_theme.dart';
import '../../data/routing/offline_tiles.dart';

/// Offline-Karten: PMTiles-URL + Region-Pack-Platzhalter.
class OfflineMapsSheet extends StatefulWidget {
  const OfflineMapsSheet({super.key});

  @override
  State<OfflineMapsSheet> createState() => _OfflineMapsSheetState();
}

class _OfflineMapsSheetState extends State<OfflineMapsSheet> {
  final _urlCtrl = TextEditingController();
  String? _regionPref;
  String? _valhallaStatus;
  bool _loading = true;

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

  Future<File> _prefsFile() async {
    final dir = await getApplicationSupportDirectory();
    return File(p.join(dir.path, 'offline_maps_prefs.json'));
  }

  Future<void> _load() async {
    final compileTime = AppConfig.pmtilesUrl;
    var override = '';
    String? region;
    try {
      final f = await _prefsFile();
      if (await f.exists()) {
        final m = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        override = (m['pmtilesUrl'] as String?) ?? '';
        region = m['regionPack'] as String?;
      }
    } catch (_) {}
    final status = await OfflineTilesStore.instance.valhallaLinkStatus();
    if (!mounted) return;
    setState(() {
      _urlCtrl.text = override.isNotEmpty ? override : compileTime;
      _regionPref = region;
      _valhallaStatus = status;
      _loading = false;
    });
  }

  Future<void> _savePrefs({String? pmtilesUrl, String? regionPack}) async {
    final f = await _prefsFile();
    Map<String, dynamic> m = {};
    try {
      if (await f.exists()) {
        final decoded = jsonDecode(await f.readAsString());
        if (decoded is Map) m = Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}
    if (pmtilesUrl != null) m['pmtilesUrl'] = pmtilesUrl;
    if (regionPack != null) m['regionPack'] = regionPack;
    await f.writeAsString(jsonEncode(m));
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
                    onPressed: () async {
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
                        ? 'Noch keine Region vorgemerkt.'
                        : 'Vorgemerkt: $_regionPref',
                    style: const TextStyle(color: AppColors.muted, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () async {
                      const region = 'Alpen-Demo (bald)';
                      await _savePrefs(regionPack: region);
                      setState(() => _regionPref = region);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Download folgt — Region vorgemerkt.',
                            ),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.download_outlined),
                    label: const Text('Region-Pack (bald)'),
                  ),
                ],
              ),
            ),
    );
  }
}
