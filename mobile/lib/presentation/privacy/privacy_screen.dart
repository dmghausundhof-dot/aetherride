import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/app_theme.dart';
import '../../data/export/export_trimmed.dart';
import '../../data/export/json_export.dart';
import '../../domain/privacy/consents.dart';
import '../../providers/app_providers.dart';

/// Daten & Privatsphäre — Consents, Zonen, Export (F-ACC-003/005/006).
class PrivacyScreen extends ConsumerStatefulWidget {
  const PrivacyScreen({super.key});

  @override
  ConsumerState<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends ConsumerState<PrivacyScreen> {
  Map<String, bool> _consents = {};
  List<PrivacyZone> _zones = [];
  bool _busy = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final garage = ref.read(garageRepositoryProvider);
    final consents = await garage.listConsents();
    final zones = await garage.listPrivacyZones();
    final merged = defaultConsentGrants();
    merged.addAll(consents);
    if (mounted) {
      setState(() {
        _consents = merged;
        _zones = zones;
      });
    }
  }

  Future<void> _setConsent(ConsentPurpose purpose, bool granted) async {
    setState(() => _consents[purpose.apiId] = granted);
    await ref.read(garageRepositoryProvider).setConsent(
          purpose: purpose.apiId,
          granted: granted,
        );
  }

  Future<void> _addZone() async {
    final label = TextEditingController(text: 'Zuhause');
    final lat = TextEditingController(text: '47.448');
    final lng = TextEditingController(text: '12.148');
    final radius = TextEditingController(text: '200');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Privacy-Zone'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: label,
                decoration: const InputDecoration(labelText: 'Label'),
              ),
              TextField(
                controller: lat,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Lat'),
              ),
              TextField(
                controller: lng,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Lng'),
              ),
              TextField(
                controller: radius,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Radius (m)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final zone = PrivacyZone(
      id: const Uuid().v4(),
      label: label.text.trim().isEmpty ? 'Zone' : label.text.trim(),
      lat: double.tryParse(lat.text) ?? 47.448,
      lng: double.tryParse(lng.text) ?? 12.148,
      radiusM: double.tryParse(radius.text) ?? 200,
    );
    await ref.read(garageRepositoryProvider).upsertPrivacyZone(zone);
    await _load();
  }

  Future<String> _writeExport(String filename, String content) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, filename));
    await file.writeAsString(content);
    return file.path;
  }

  Future<String> _writeBytes(String filename, List<int> bytes) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, filename));
    await file.writeAsBytes(bytes);
    return file.path;
  }

  Future<void> _exportGpx() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final rides = await ref.read(rideRepositoryProvider).listRides(limit: 1);
      if (rides.isEmpty) {
        setState(() => _message = 'Kein Ride zum Exportieren.');
        return;
      }
      final bike = await ref.read(garageRepositoryProvider).getActiveBike();
      final zones = await ref.read(garageRepositoryProvider).listPrivacyZones();
      final gpx = exportGpxTrimmed(
        rides.first,
        zones: zones,
        bikeName: bike?.name,
      );
      final path = await _writeExport(
        'aetherride-${rides.first.id.substring(0, 8)}.gpx',
        gpx,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('GPX (privacy-trimmed) gespeichert: $path')),
        );
      }
    } catch (e) {
      setState(() => _message = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _exportFit() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final rides = await ref.read(rideRepositoryProvider).listRides(limit: 1);
      if (rides.isEmpty) {
        setState(() => _message = 'Kein Ride zum Exportieren.');
        return;
      }
      final zones = await ref.read(garageRepositoryProvider).listPrivacyZones();
      final bytes = exportFitTrimmed(rides.first, zones: zones);
      final path = await _writeBytes(
        'aetherride-${rides.first.id.substring(0, 8)}.fit',
        bytes,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('FIT gespeichert: $path')),
        );
      }
    } catch (e) {
      setState(() => _message = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _exportJson() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final bikes = await ref.read(garageRepositoryProvider).listBikes();
      final rides = await ref.read(rideRepositoryProvider).listRides(limit: 50);
      final consents = await ref.read(garageRepositoryProvider).listConsents();
      final zones = await ref.read(garageRepositoryProvider).listPrivacyZones();
      final trimmedRides = [
        for (final r in rides) rideWithTrimmedTrack(r, zones),
      ];
      final json = fullJsonExport(
        bikes: bikes,
        rides: trimmedRides,
        consents: consents,
      );
      final path = await _writeExport('aetherride-export.json', json);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('JSON gespeichert: $path')),
        );
      }
    } catch (e) {
      setState(() => _message = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daten & Privatsphäre')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Einwilligungen',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          for (final purpose in ConsentPurpose.values)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(consentLabels[purpose]!.title),
              subtitle: Text(
                consentLabels[purpose]!.description,
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
              value: _consents[purpose.apiId] ?? false,
              onChanged: _busy
                  ? null
                  : (v) => _setConsent(purpose, v),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'Privacy-Zonen',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _busy ? null : _addZone,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Zone'),
              ),
            ],
          ),
          if (_zones.isEmpty)
            const Text(
              'Keine Zonen — Start/Ziel-Umgebung kann getrimmt werden.',
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            ),
          for (final z in _zones)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(z.label),
              subtitle: Text(
                '${z.lat.toStringAsFixed(4)}, ${z.lng.toStringAsFixed(4)} · '
                '${z.radiusM.round()} m',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  await ref
                      .read(garageRepositoryProvider)
                      .removePrivacyZone(z.id);
                  await _load();
                },
              ),
            ),
          const SizedBox(height: 20),
          Text(
            'Export (Art. 20)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _busy ? null : _exportGpx,
            icon: const Icon(Icons.route),
            label: const Text('Letzter Ride als GPX'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _busy ? null : _exportFit,
            icon: const Icon(Icons.directions_bike),
            label: const Text('Letzter Ride als FIT'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _busy ? null : _exportJson,
            icon: const Icon(Icons.data_object),
            label: const Text('JSON-Vollexport'),
          ),
          if (_message != null) ...[
            const SizedBox(height: 12),
            Text(_message!, style: const TextStyle(color: AppColors.muted)),
          ],
        ],
      ),
    );
  }
}
