import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/theme/app_theme.dart';
import '../../data/garage/bike_photo_sync.dart';
import '../../data/import/gpx_import.dart';
import '../../data/local/app_database.dart';
import '../../domain/bike.dart';
import '../../domain/catalog_bike.dart';
import '../../domain/compatibility/engine.dart';
import '../../domain/compatibility/rules.dart';
import '../../domain/component.dart';
import '../../domain/maintenance/intervals.dart';
import '../../domain/saved_route.dart';
import '../../domain/setup.dart';
import '../../domain/setup/fingerprint.dart';
import '../../domain/setup/sag_guide.dart';
import '../../providers/app_providers.dart';
import '../billing/upgrade_screen.dart';
import 'setup_sheet.dart';

class GarageScreen extends ConsumerWidget {
  const GarageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bikes = ref.watch(bikesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Garage')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddBike(context, ref),
        backgroundColor: AppColors.accent,
        icon: const Icon(Icons.add),
        label: const Text('Bike'),
      ),
      body: bikes.when(
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomPaint(
                      size: const Size(120, 72),
                      painter: _EmptyBikeSilhouettePainter(),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Deine Garage',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Lege dein erstes Bike an — Katalog, Basisdaten oder GPX-Import.\n'
                      'Kein Demo-Bike wird automatisch erzeugt.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.muted, height: 1.35),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => _openAddBike(context, ref),
                      icon: const Icon(Icons.add),
                      label: const Text('Erstes Bike anlegen'),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            children: [
              ...List.generate(list.length, (i) {
                return Padding(
                  padding: EdgeInsets.only(bottom: i == list.length - 1 ? 0 : 8),
                  child: _BikeTile(
                    bike: list[i],
                    onTap: () => _openDetail(context, ref, list[i]),
                  ),
                );
              }),
              const SizedBox(height: 20),
              Text(
                'Letzte Rides',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.muted,
                    ),
              ),
              const SizedBox(height: 8),
              Consumer(
                builder: (context, ref, _) {
                  final rides = ref.watch(recentRidesProvider);
                  return rides.when(
                    data: (items) {
                      if (items.isEmpty) {
                        return const Text(
                          'Noch keine gespeicherten Rides.',
                          style: TextStyle(color: AppColors.muted),
                        );
                      }
                      return Column(
                        children: [
                          for (final r in items.take(5))
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(r.name ?? 'Ride'),
                              subtitle: Text(
                                '${r.distanceKm.toStringAsFixed(1)} km · '
                                '${(r.movingTimeSec / 60).round()} min',
                              ),
                              trailing: r.feedback != null
                                  ? const Icon(Icons.check_circle_outline,
                                      size: 18)
                                  : null,
                            ),
                        ],
                      );
                    },
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text('$e'),
                  );
                },
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Fehler: $e')),
      ),
    );
  }

  Future<void> _openAddBike(BuildContext context, WidgetRef ref) async {
    final existing = await ref.read(garageRepositoryProvider).listBikes();
    final tier = ref.read(subscriptionTierProvider);
    ref.read(garageRepositoryProvider).subscriptionTier = tier;
    if (existing.isNotEmpty && tier != 'pro') {
      if (!context.mounted) return;
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Free: 1 Bike'),
          content: const Text(
            'Im Free-Tarif ist ein Bike vorgesehen. Du kannst lokal trotzdem '
            'weitere anlegen — Sync-Limits gelten server-seitig nach Login.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Abbrechen'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx, false);
                openUpgradeScreen(context);
              },
              child: const Text('Upgrade'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Trotzdem anlegen'),
            ),
          ],
        ),
      );
      if (proceed != true) return;
    }
    if (!context.mounted) return;
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _AddBikeSheet(),
    );
    if (created == true) {
      ref.invalidate(bikesProvider);
    }
  }

  Future<void> _openDetail(
    BuildContext context,
    WidgetRef ref,
    Bike bike,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _BikeDetailSheet(bikeId: bike.id),
    );
    ref.invalidate(bikesProvider);
  }
}

class _BikeTile extends StatelessWidget {
  const _BikeTile({required this.bike, required this.onTap});

  final Bike bike;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      leading: Icon(
        Icons.pedal_bike,
        color: bike.isActive ? AppColors.accent : null,
      ),
      title: Text(bike.name),
      subtitle: Text(
        [
          if (bike.brand != null) bike.brand!,
          if (bike.model != null) bike.model!,
          '${bike.odometerKm.toStringAsFixed(0)} km · '
          '${bike.hours.toStringAsFixed(0)} h',
          if (bike.isActive) 'aktiv',
        ].join(' · '),
      ),
      trailing: Text(
        bike.categoryLabel,
        style: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }
}

class _AddBikeSheet extends ConsumerStatefulWidget {
  const _AddBikeSheet();

  @override
  ConsumerState<_AddBikeSheet> createState() => _AddBikeSheetState();
}

enum _AddBikeMode { catalog, basic, importMode }

class _AddBikeSheetState extends ConsumerState<_AddBikeSheet> {
  final _name = TextEditingController();
  final _brand = TextEditingController();
  final _model = TextEditingController();
  final _importNote = TextEditingController();
  BikeCategory _category = BikeCategory.mtbAm;
  WheelSize _wheel = WheelSize.w29;
  bool _busy = false;
  _AddBikeMode _mode = _AddBikeMode.catalog;

  List<CatalogManufacturer> _manufacturers = const [];
  String? _mfrId;
  String? _bikeId;
  String _frameSize = 'L';
  String? _catalogError;
  bool _catalogLoading = true;
  GpxTrack? _pickedGpx;
  String? _gpxFileLabel;

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  @override
  void dispose() {
    _name.dispose();
    _brand.dispose();
    _model.dispose();
    _importNote.dispose();
    super.dispose();
  }

  Future<void> _loadCatalog() async {
    setState(() {
      _catalogLoading = true;
      _catalogError = null;
    });
    try {
      final list = await ref.read(catalogClientProvider).fetchBikes();
      if (!mounted) return;
      setState(() {
        _manufacturers = list;
        _mfrId = list.isNotEmpty ? list.first.id : null;
        final bikes = list.isNotEmpty ? list.first.bikes : const <CatalogBikeVariant>[];
        _bikeId = bikes.isNotEmpty ? bikes.first.id : null;
        _frameSize = bikes.isNotEmpty && bikes.first.frameSizeOptions.isNotEmpty
            ? bikes.first.frameSizeOptions.first
            : 'L';
        _catalogLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _catalogLoading = false;
        _catalogError = 'Katalog nicht erreichbar — Basis/Import nutzen.';
        if (_mode == _AddBikeMode.catalog) _mode = _AddBikeMode.basic;
      });
    }
  }

  CatalogManufacturer? get _mfr {
    final id = _mfrId;
    if (id == null) return null;
    for (final m in _manufacturers) {
      if (m.id == id) return m;
    }
    return null;
  }

  CatalogBikeVariant? get _catBike {
    final m = _mfr;
    final id = _bikeId;
    if (m == null || id == null) return null;
    for (final b in m.bikes) {
      if (b.id == id) return b;
    }
    return null;
  }

  Map<String, dynamic> _attrsFromPayload(String? payloadJson) {
    if (payloadJson == null || payloadJson.isEmpty) return {};
    try {
      final decoded = jsonDecode(payloadJson);
      if (decoded is! Map) return {};
      final m = Map<String, dynamic>.from(decoded);
      final attrs = m['attributes'];
      if (attrs is Map) return Map<String, dynamic>.from(attrs);
      if (attrs is List) {
        final out = <String, dynamic>{};
        for (final e in attrs) {
          if (e is! Map) continue;
          final key = e['key'] as String?;
          if (key == null) continue;
          final val =
              e['valueNum'] ?? e['valueEnum'] ?? e['value'] ?? e['valueStr'];
          if (val != null) out[key] = val;
        }
        return out;
      }
    } catch (_) {}
    return {};
  }

  Future<void> _pickGpx() async {
    final f = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['gpx', 'xml'],
    );
    if (f == null) return;
    String? xml;
    try {
      if (f.path != null) {
        xml = await File(f.path!).readAsString();
      } else {
        final bytes = await f.readAsBytes();
        xml = String.fromCharCodes(bytes);
      }
    } catch (_) {}
    if (xml == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Datei konnte nicht gelesen werden')),
        );
      }
      return;
    }
    final parsed = parseGpx(
      xml,
      fallbackName:
          f.name.replaceAll(RegExp(r'\.gpx$', caseSensitive: false), ''),
    );
    if (parsed == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kein gültiger GPX-Track (min. 2 Punkte)')),
        );
      }
      return;
    }
    setState(() {
      _pickedGpx = parsed;
      _gpxFileLabel = f.name;
      if (_name.text.trim().isEmpty) _name.text = parsed.name;
    });
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      final garage = ref.read(garageRepositoryProvider);
      final existing = await garage.listBikes();
      final tier = ref.read(subscriptionTierProvider);
      final Bike bike;
      var oemInstalled = 0;
      var oemMissed = 0;

      if (_mode == _AddBikeMode.catalog) {
        final mfr = _mfr;
        final cat = _catBike;
        if (mfr == null || cat == null) {
          throw StateError('Bitte Hersteller und Modell wählen');
        }
        bike = await garage.addBikeBasic(
          name: _name.text.trim().isEmpty
              ? '${mfr.name} ${cat.name}'
              : _name.text.trim(),
          category: cat.isEbike && cat.category != BikeCategory.emtb
              ? BikeCategory.emtb
              : cat.category,
          brand: mfr.name,
          model: cat.name,
          year: cat.year > 0 ? cat.year : null,
          wheelSize: cat.wheelSizeFront,
          catalogBikeId: cat.id,
          frameSize: _frameSize,
          travelFrontMm: cat.travelFrontMm,
          travelRearMm: cat.travelRearMm,
          makeActive: true,
        );

        final catalog = ref.read(catalogClientProvider);
        final components = ref.read(componentRepositoryProvider);
        for (final e in cat.oemComponents.entries) {
          final slot = ComponentSlotLabel.fromApiId(e.key);
          if (slot == null || slot == ComponentSlot.other) {
            oemMissed += 1;
            continue;
          }
          final model = await catalog.getModel(e.value);
          if (model == null) oemMissed += 1;
          final attrs = _attrsFromPayload(model?.payloadJson);
          await components.install(
            bikeId: bike.id,
            slot: slot,
            manufacturer: model?.manufacturer,
            model: model?.model ?? e.value,
            catalogModelId: e.value,
            attributes: attrs,
          );
          oemInstalled += 1;
        }

        await ref.read(setupRepositoryProvider).createVersion(
              bikeId: bike.id,
              label: 'OEM Basis-Setup',
              values: BikeSetup.defaultValues(),
              createdBy: 'catalog',
            );
      } else if (_mode == _AddBikeMode.basic) {
        bike = await garage.addBikeBasic(
          name: _name.text,
          category: _category,
          brand: _brand.text,
          model: _model.text,
          wheelSize: _wheel,
          makeActive: true,
        );
      } else {
        final gpx = _pickedGpx;
        if (gpx != null) {
          bike = await garage.addBikeBasic(
            name: _name.text.trim().isEmpty ? gpx.name : _name.text.trim(),
            category: _category,
            makeActive: true,
          );
          await ref.read(routeRepositoryProvider).saveEntry(
                SavedRouteEntry(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: gpx.name,
                  distanceKm: gpx.distanceKm,
                  elevationM: gpx.elevationM,
                  durationMin: gpx.durationMinEstimate,
                  source: 'gpx_import',
                  coordinates: gpx.points,
                  waypoints: const [],
                  savedAt: DateTime.now().toUtc(),
                ),
              );
          await garage.profileStore?.addMaintenanceLog(
            bikeId: bike.id,
            activity: 'gpx_import',
            notes: _importNote.text.trim().isEmpty
                ? 'GPX „${gpx.name}“ · ${gpx.distanceKm.toStringAsFixed(1)} km'
                : _importNote.text.trim(),
          );
          ref.invalidate(savedRoutesProvider);
        } else {
          bike = await garage.addBikeFromImport(
            name: _name.text.trim().isEmpty ? 'Import-Bike' : _name.text.trim(),
            note: _importNote.text.trim().isEmpty
                ? 'Import ohne GPX — Komponenten später ergänzen'
                : _importNote.text.trim(),
          );
        }
      }

      if (!mounted) return;
      if (existing.isNotEmpty && tier != 'pro') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Free: weiteres Bike lokal angelegt (Multi-Bike ist Pro).',
            ),
          ),
        );
      } else if (_mode == _AddBikeMode.catalog) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              oemMissed == 0
                  ? '${bike.name}: $oemInstalled OEM-Komponenten.'
                  : '${bike.name}: $oemInstalled OEM, $oemMissed Slots/Modelle übersprungen.',
            ),
          ),
        );
      } else if (_mode == _AddBikeMode.importMode && _pickedGpx != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${bike.name}: GPX gespeichert (${_pickedGpx!.distanceKm.toStringAsFixed(1)} km).',
            ),
          ),
        );
      }
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Anlegen fehlgeschlagen: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _modeChip(_AddBikeMode mode, String label) {
    final selected = _mode == mode;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _mode = mode),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.accent : AppColors.sunSurface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : null,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final cat = _catBike;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Bike anlegen',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _modeChip(_AddBikeMode.catalog, 'Katalog'),
                const SizedBox(width: 8),
                _modeChip(_AddBikeMode.basic, 'Basis'),
                const SizedBox(width: 8),
                _modeChip(_AddBikeMode.importMode, 'Import'),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              switch (_mode) {
                _AddBikeMode.catalog =>
                  'OEM-Ausstattung wird vollständig vorbefüllt.',
                _AddBikeMode.basic =>
                  'Kategorie + Laufrad — Komponenten später ergänzen.',
                _AddBikeMode.importMode =>
                  'GPX wählen → Bike + gespeicherte Route. Ohne Datei nur Notiz-Platzhalter.',
              },
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (_catalogError != null) ...[
              const SizedBox(height: 8),
              Text(
                _catalogError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'Optional',
              ),
              textInputAction: TextInputAction.next,
            ),
            if (_mode == _AddBikeMode.catalog) ...[
              const SizedBox(height: 8),
              if (_catalogLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_manufacturers.isEmpty)
                const Text('Kein OEM-Katalog geladen.')
              else ...[
                DropdownButtonFormField<String>(
                  key: ValueKey('mfr-$_mfrId'),
                  initialValue: _mfrId,
                  decoration: const InputDecoration(labelText: 'Hersteller'),
                  items: [
                    for (final m in _manufacturers)
                      DropdownMenuItem(value: m.id, child: Text(m.name)),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    final m = _manufacturers.firstWhere((x) => x.id == v);
                    setState(() {
                      _mfrId = v;
                      _bikeId =
                          m.bikes.isNotEmpty ? m.bikes.first.id : null;
                      _frameSize = m.bikes.isNotEmpty &&
                              m.bikes.first.frameSizeOptions.isNotEmpty
                          ? m.bikes.first.frameSizeOptions.first
                          : 'L';
                    });
                  },
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  key: ValueKey('bike-$_bikeId'),
                  initialValue: _bikeId,
                  decoration: const InputDecoration(labelText: 'Modell / Jahr'),
                  items: [
                    for (final b in _mfr?.bikes ?? const <CatalogBikeVariant>[])
                      DropdownMenuItem(
                        value: b.id,
                        child: Text(
                          '${b.name} (${b.year}) · ${Bike(id: '', name: '', category: b.category).categoryLabel}',
                        ),
                      ),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    final b = _mfr?.bikes.firstWhere((x) => x.id == v);
                    setState(() {
                      _bikeId = v;
                      _frameSize = b != null && b.frameSizeOptions.isNotEmpty
                          ? b.frameSizeOptions.first
                          : 'L';
                    });
                  },
                ),
                if ((cat?.frameSizeOptions ?? const []).isNotEmpty) ...[
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    key: ValueKey('size-$_frameSize-$_bikeId'),
                    initialValue: cat!.frameSizeOptions.contains(_frameSize)
                        ? _frameSize
                        : cat.frameSizeOptions.first,
                    decoration:
                        const InputDecoration(labelText: 'Rahmengröße'),
                    items: [
                      for (final s in cat.frameSizeOptions)
                        DropdownMenuItem(value: s, child: Text(s)),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _frameSize = v);
                    },
                  ),
                ],
                if (cat != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.sunSurface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      [
                        if (cat.travelFrontMm != null)
                          '${cat.travelFrontMm}/${cat.travelRearMm} mm',
                        switch (cat.wheelSizeFront) {
                          WheelSize.w29 => '29"',
                          WheelSize.w275 => '27.5"',
                          WheelSize.c700 => '700c',
                          WheelSize.b650 => '650b',
                        },
                        if (cat.isEbike) 'E-Bike',
                        '${cat.oemComponents.length} OEM-Komponenten',
                      ].join(' · '),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ],
            ],
            if (_mode == _AddBikeMode.basic) ...[
              const SizedBox(height: 8),
              DropdownButtonFormField<BikeCategory>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Kategorie'),
                items: [
                  for (final c in BikeCategory.values)
                    DropdownMenuItem(
                      value: c,
                      child: Text(
                        Bike(id: '', name: '', category: c).categoryLabel,
                      ),
                    ),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _category = v);
                },
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<WheelSize>(
                initialValue: _wheel,
                decoration: const InputDecoration(labelText: 'Laufradgröße'),
                items: const [
                  DropdownMenuItem(value: WheelSize.w29, child: Text('29"')),
                  DropdownMenuItem(value: WheelSize.w275, child: Text('27.5"')),
                  DropdownMenuItem(value: WheelSize.c700, child: Text('700c')),
                  DropdownMenuItem(value: WheelSize.b650, child: Text('650b')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _wheel = v);
                },
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _brand,
                decoration:
                    const InputDecoration(labelText: 'Marke (optional)'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _model,
                decoration:
                    const InputDecoration(labelText: 'Modell (optional)'),
              ),
            ],
            if (_mode == _AddBikeMode.importMode) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _busy ? null : _pickGpx,
                icon: const Icon(Icons.upload_file),
                label: Text(
                  _gpxFileLabel == null
                      ? 'GPX-Datei wählen'
                      : 'GPX: $_gpxFileLabel',
                ),
              ),
              if (_pickedGpx != null) ...[
                const SizedBox(height: 8),
                Text(
                  '${_pickedGpx!.distanceKm.toStringAsFixed(1)} km · '
                  '${_pickedGpx!.elevationM.round()} hm · '
                  '${_pickedGpx!.points.length} Punkte',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 8),
              TextField(
                controller: _importNote,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notiz (optional)',
                  hintText: 'z. B. Quelle oder fehlende Komponenten',
                ),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
              onPressed: _busy ? null : _save,
              child: _busy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Speichern'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BikeDetailSheet extends ConsumerStatefulWidget {
  const _BikeDetailSheet({required this.bikeId});

  final String bikeId;

  @override
  ConsumerState<_BikeDetailSheet> createState() => _BikeDetailSheetState();
}

class _BikeDetailSheetState extends ConsumerState<_BikeDetailSheet> {
  Bike? _bike;
  List<BikeComponent> _components = [];
  List<CompatibilityResult> _compat = [];
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final bike =
        await ref.read(garageRepositoryProvider).getById(widget.bikeId);
    final comps = await ref
        .read(componentRepositoryProvider)
        .listInstalled(widget.bikeId);
    final results = checkBikeCompatibility(comps);
    if (mounted) {
      setState(() {
        _bike = bike;
        _components = comps;
        _compat = results;
      });
    }
  }

  Future<void> _setActive() async {
    setState(() => _busy = true);
    await ref.read(garageRepositoryProvider).setActiveBike(widget.bikeId);
    await _load();
    setState(() => _busy = false);
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bike löschen?'),
        content: const Text(
          'Komponenten und Setups dieses Bikes entfallen lokal.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(garageRepositoryProvider).deleteBike(widget.bikeId);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _installComponent() async {
    final installed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _InstallComponentSheet(bikeId: widget.bikeId),
    );
    if (installed == true) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final bike = _bike;
    if (bike == null) {
      return const SizedBox(
        height: 160,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final aggregate = aggregateVerdict(_compat);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      builder: (context, scroll) {
        return ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            Text(
              bike.name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              [
                bike.categoryLabel,
                if (bike.brand != null) bike.brand!,
                if (bike.model != null) bike.model!,
                if (bike.year != null) '${bike.year}',
              ].join(' · '),
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 8),
            Text(
              '${bike.odometerKm.toStringAsFixed(0)} km · '
              '${bike.hours.toStringAsFixed(1)} h'
              '${bike.isActive ? ' · aktiv' : ''}'
              ' · Kompat: ${verdictLabel(aggregate)}',
            ),
            const SizedBox(height: 8),
            _BikePhotoAndSag(bike: bike),
            const SizedBox(height: 8),
            Builder(
              builder: (context) {
                final setupAsync =
                    ref.watch(currentSetupProvider(widget.bikeId));
                return setupAsync.when(
                  data: (setup) {
                    if (setup == null) {
                      return const Text(
                        'Kein aktuelles Setup',
                        style: TextStyle(color: AppColors.muted, fontSize: 13),
                      );
                    }
                    final rebound = setup.valueFor('fork.rebound');
                    return Text(
                      'Setup v${setup.version}: ${setup.label}'
                      '${rebound != null ? ' · Gabel Zug ${rebound.toStringAsFixed(0)}' : ''}',
                      style: const TextStyle(fontSize: 13),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                );
              },
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () async {
                await showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => SetupSheet(bike: bike),
                );
                ref.invalidate(currentSetupProvider(widget.bikeId));
                await _load();
              },
              icon: const Icon(Icons.tune),
              label: const Text('Setups & Bracketing'),
            ),
            Builder(
              builder: (context) {
                final due = listDueMaintenance(
                  bike: bike,
                  components: _components,
                );
                if (due.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Text(
                      'Wartung',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    for (final a in due.take(5))
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        leading: Icon(
                          a.status == DueStatus.overdue
                              ? Icons.warning_amber
                              : Icons.schedule,
                          color: a.status == DueStatus.overdue
                              ? Colors.redAccent
                              : Colors.orange,
                          size: 20,
                        ),
                        title: Text(a.label, style: const TextStyle(fontSize: 13)),
                        subtitle: Text(
                          '${a.remainingLabel} · ${a.progressPct}% · Tip: Shop',
                          style: const TextStyle(fontSize: 11),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.storefront_outlined, size: 20),
                          onPressed: () {
                            Navigator.pop(context);
                            ref.read(shellTabIndexProvider.notifier).state = 4;
                          },
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            if (!bike.isActive)
              FilledButton(
                style:
                    FilledButton.styleFrom(backgroundColor: AppColors.accent),
                onPressed: _busy ? null : _setActive,
                child: const Text('Als aktiv setzen'),
              ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _busy ? null : _delete,
              child: const Text('Löschen'),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Text(
                  'Komponenten',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _installComponent,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Installieren'),
                ),
              ],
            ),
            if (_components.isEmpty)
              const Text(
                'Noch keine Teile — Attribute setzen für Kompat-Urteile.',
                style: TextStyle(color: AppColors.muted, fontSize: 13),
              ),
            for (final c in _components)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(c.slot.label),
                subtitle: Text(c.displayName),
                trailing: IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () async {
                    await ref
                        .read(componentRepositoryProvider)
                        .remove(c.id);
                    await _load();
                  },
                ),
              ),
            if (_compat.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Kompatibilität',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              for (final r in _compat.take(8))
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  onTap: () => _showEvidence(context, r),
                  title: Text(r.title, style: const TextStyle(fontSize: 13)),
                  subtitle: Text(
                    r.explainDe,
                    style: const TextStyle(fontSize: 11),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    verdictLabel(r.verdict),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: switch (r.verdict) {
                        CompatVerdict.compatible => Colors.green,
                        CompatVerdict.conditional => Colors.orange,
                        CompatVerdict.incompatible => Colors.redAccent,
                        CompatVerdict.insufficientData => AppColors.muted,
                      },
                    ),
                  ),
                ),
            ],
          ],
        );
      },
    );
  }

  void _showEvidence(BuildContext context, CompatibilityResult r) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Evidence',
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                r.ruleCode,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(height: 4),
              Text(r.title, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text('Verdict: ${verdictLabel(r.verdict)}'),
              Text(
                'Schwere: ${r.severity == RuleSeverity.safetyCritical ? 'sicherheitskritisch' : 'funktional'}',
                style: const TextStyle(color: AppColors.muted, fontSize: 13),
              ),
              const SizedBox(height: 12),
              Text(
                'Begründung',
                style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              Text(r.explainDe),
              if (r.conditionText != null && r.conditionText!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Bedingung: ${r.conditionText}'),
              ],
              if (r.safetyWorkshopHint != null &&
                  r.safetyWorkshopHint!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Hinweis: ${r.safetyWorkshopHint}'),
              ],
              if (r.missingAttributes.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Fehlende Attribute',
                  style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                for (final m in r.missingAttributes)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('· ${m.key}: ${m.howToObtain}'),
                  ),
              ],
              if (r.sourceUrl != null && r.sourceUrl!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Quelle: ${r.sourceUrl}',
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _InstallComponentSheet extends ConsumerStatefulWidget {
  const _InstallComponentSheet({required this.bikeId});

  final String bikeId;

  @override
  ConsumerState<_InstallComponentSheet> createState() =>
      _InstallComponentSheetState();
}

class _InstallComponentSheetState
    extends ConsumerState<_InstallComponentSheet> {
  ComponentSlot _slot = ComponentSlot.cassette;
  final _manufacturer = TextEditingController();
  final _model = TextEditingController();
  final _attrKey = TextEditingController(text: 'freehub_standard');
  final _attrVal = TextEditingController(text: 'microspline');
  final _catalogQ = TextEditingController();
  String? _catalogModelId;
  Map<String, dynamic> _catalogAttrs = {};
  List<CatalogCacheData> _hits = [];
  bool _searching = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _searchCatalog());
  }

  @override
  void dispose() {
    _manufacturer.dispose();
    _model.dispose();
    _attrKey.dispose();
    _attrVal.dispose();
    _catalogQ.dispose();
    super.dispose();
  }

  Map<String, dynamic> _attrsFromPayload(String payloadJson) {
    try {
      final decoded = jsonDecode(payloadJson);
      if (decoded is! Map) return {};
      final raw = decoded['attributes'];
      if (raw is Map) {
        return Map<String, dynamic>.from(raw);
      }
      if (raw is List) {
        final out = <String, dynamic>{};
        for (final e in raw) {
          if (e is! Map) continue;
          final key = e['key'] as String?;
          if (key == null) continue;
          final val = e['valueNum'] ?? e['valueEnum'] ?? e['value'] ?? e['valueStr'];
          if (val != null) out[key] = val;
        }
        return out;
      }
    } catch (_) {}
    return {};
  }

  Future<void> _searchCatalog() async {
    setState(() => _searching = true);
    final hits = await ref.read(catalogClientProvider).search(
          slot: _slot.apiId,
          q: _catalogQ.text.trim().isEmpty ? null : _catalogQ.text.trim(),
          limit: 30,
        );
    if (mounted) {
      setState(() {
        _hits = hits;
        _searching = false;
      });
    }
  }

  void _pickCatalog(CatalogCacheData item) {
    final attrs = _attrsFromPayload(item.payloadJson);
    setState(() {
      _catalogModelId = item.id;
      _manufacturer.text = item.manufacturer;
      _model.text = item.model;
      _catalogAttrs = attrs;
      if (attrs.isNotEmpty) {
        final first = attrs.entries.first;
        _attrKey.text = first.key;
        _attrVal.text = '${first.value}';
      }
    });
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    final attrs = Map<String, dynamic>.from(_catalogAttrs);
    if (_attrKey.text.trim().isNotEmpty && _attrVal.text.trim().isNotEmpty) {
      final raw = _attrVal.text.trim();
      attrs[_attrKey.text.trim()] = num.tryParse(raw) ?? raw;
    }
    // Default-Attribute für Kompat-Checks (Platzhalter, nicht Katalog-Wahrheit)
    if (_slot == ComponentSlot.frame && !attrs.containsKey('rear_spacing')) {
      attrs['rear_spacing'] = '148x12';
      attrs['max_tire_width_mm'] = 2.6;
      attrs['bb_standard'] = 'BSA73';
      attrs['seatpost_diameter_mm'] = 31.6;
      attrs['max_seatpost_insertion_mm'] = 250;
      attrs['brake_mount_rear'] = 'post_mount';
    }
    if (_slot == ComponentSlot.rearHub &&
        !attrs.containsKey('freehub_standard')) {
      attrs['freehub_standard'] = 'microspline';
      attrs['rear_spacing'] = '148x12';
      attrs['rotor_mount'] = '6bolt';
    }
    if (_slot == ComponentSlot.cassette &&
        !attrs.containsKey('freehub_standard')) {
      attrs['freehub_standard'] = 'microspline';
    }
    await ref.read(componentRepositoryProvider).install(
          bikeId: widget.bikeId,
          slot: _slot,
          manufacturer: _manufacturer.text,
          model: _model.text,
          catalogModelId: _catalogModelId,
          attributes: attrs,
        );
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Teil installieren',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ComponentSlot>(
              initialValue: _slot,
              decoration: const InputDecoration(labelText: 'Slot'),
              items: [
                for (final s in coreInstallSlots)
                  DropdownMenuItem(value: s, child: Text(s.label)),
              ],
              onChanged: (v) {
                if (v != null) {
                  setState(() {
                    _slot = v;
                    _catalogModelId = null;
                    _catalogAttrs = {};
                  });
                  _searchCatalog();
                }
              },
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _catalogQ,
              decoration: InputDecoration(
                labelText: 'Teile suchen (API/Cache)',
                hintText: 'Hersteller / Modell — optional',
                helperText: 'Ohne Treffer: Basisdaten manuell',
                suffixIcon: IconButton(
                  icon: _searching
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search),
                  onPressed: _searching ? null : _searchCatalog,
                ),
              ),
              onSubmitted: (_) => _searchCatalog(),
            ),
            if (_hits.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Treffer',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              SizedBox(
                height: 140,
                child: ListView.builder(
                  itemCount: _hits.length,
                  itemBuilder: (context, i) {
                    final h = _hits[i];
                    final selected = h.id == _catalogModelId;
                    return ListTile(
                      dense: true,
                      selected: selected,
                      title: Text(
                        '${h.manufacturer} ${h.model}',
                        style: const TextStyle(fontSize: 13),
                      ),
                      subtitle: Text(
                        h.id,
                        style: const TextStyle(fontSize: 11),
                      ),
                      onTap: () => _pickCatalog(h),
                    );
                  },
                ),
              ),
            ] else if (!_searching)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  'Keine Treffer — manuell ausfüllen (Basis). Cache kann leer sein.',
                  style: TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ),
            if (_catalogModelId != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'Cache-ID: $_catalogModelId',
                  style: const TextStyle(fontSize: 12, color: AppColors.accent),
                ),
              ),
            TextField(
              controller: _manufacturer,
              decoration: const InputDecoration(labelText: 'Hersteller'),
            ),
            TextField(
              controller: _model,
              decoration: const InputDecoration(labelText: 'Modell'),
            ),
            TextField(
              controller: _attrKey,
              decoration: const InputDecoration(
                labelText: 'Attribut-Key (optional)',
                hintText: 'freehub_standard',
              ),
            ),
            TextField(
              controller: _attrVal,
              decoration: const InputDecoration(
                labelText: 'Attribut-Wert',
                hintText: 'microspline',
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
              onPressed: _busy ? null : _save,
              child: const Text('Installieren'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BikePhotoAndSag extends ConsumerWidget {
  const _BikePhotoAndSag({required this.bike});
  final Bike bike;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(userProfileStoreProvider);
    final photo = store.bikePhotos[bike.id];
    final weight = store.effectiveWeightKg;
    final fork = estimateAirPsi(
      riderWeightKg: weight,
      category: bike.category,
      end: 'fork',
    );
    final shock = estimateAirPsi(
      riderWeightKg: weight,
      category: bike.category,
      end: 'shock',
    );
    final setupAsync = ref.watch(currentSetupProvider(bike.id));
    final fp = SetupFingerprint.fromSetup(setupAsync.valueOrNull);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 72,
                height: 72,
                color: AppColors.forest.withValues(alpha: 0.12),
                child: _bikePhotoWidget(photo),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Silhouette / Foto',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  Text(
                    fp.lines.join(' · '),
                    style: const TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      final picker = ImagePicker();
                      final x = await picker.pickImage(
                        source: ImageSource.gallery,
                        maxWidth: 1600,
                        imageQuality: 85,
                      );
                      if (x == null) return;
                      final dir = await getApplicationSupportDirectory();
                      final dest = File(
                        p.join(dir.path, 'bike_photos', '${bike.id}.jpg'),
                      );
                      await dest.parent.create(recursive: true);
                      await File(x.path).copy(dest.path);
                      await store.setBikePhoto(bike.id, dest.path);
                      final url = await uploadBikePhotoToStorage(
                        bikeId: bike.id,
                        file: dest,
                      );
                      if (url != null) {
                        await store.setBikePhoto(bike.id, url);
                      }
                      // Rebuild this ConsumerWidget subtree via invalidate.
                      ref.invalidate(currentSetupProvider(bike.id));
                    },
                    icon: const Icon(Icons.photo_camera_outlined, size: 18),
                    label: const Text('Foto'),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Sag-Guide (Fahrer ${weight.toStringAsFixed(0)} kg)',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        Text(
          'Gabel: ${fork.psiTarget} psi '
          '(${fork.psiMin}–${fork.psiMax}) · SAG ${fork.sag.target.toStringAsFixed(0)}%',
          style: const TextStyle(fontSize: 13),
        ),
        Text(
          'Dämpfer: ${shock.psiTarget} psi '
          '(${shock.psiMin}–${shock.psiMax}) · SAG ${shock.sag.target.toStringAsFixed(0)}%',
          style: const TextStyle(fontSize: 13),
        ),
        Text(
          fork.note,
          style: const TextStyle(fontSize: 11, color: AppColors.muted),
        ),
        const SizedBox(height: 4),
        TextButton(
          onPressed: () {
            showDialog<void>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('SAG messen'),
                content: Text(sagMeasureSteps('fork').join('\n\n')),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          },
          child: const Text('Messschritte anzeigen'),
        ),
        TextField(
          decoration: InputDecoration(
            labelText:
                'Odometer absolut setzen (jetzt ${bike.odometerKm.toStringAsFixed(0)} km)',
            hintText: bike.odometerKm.toStringAsFixed(0),
            isDense: true,
            border: const OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          onSubmitted: (raw) async {
            final km = double.tryParse(raw.replaceAll(',', '.'));
            if (km == null || km < 0) return;
            await ref.read(garageRepositoryProvider).setOdometerAbsolute(
                  bikeId: bike.id,
                  odometerKm: km,
                  hours: bike.hours,
                );
            await ref.read(userProfileStoreProvider).addMaintenanceLog(
                  bikeId: bike.id,
                  activity: 'Kilometerstand aktualisiert',
                  odometerKm: km,
                  hours: bike.hours,
                  notes: 'Manuell / Import: ${km.toStringAsFixed(0)} km',
                );
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Stand: ${km.toStringAsFixed(0)} km · ${bike.hours.toStringAsFixed(1)} h',
                  ),
                ),
              );
              ref.invalidate(bikesProvider);
            }
          },
        ),
        const SizedBox(height: 8),
        TextField(
          decoration: InputDecoration(
            labelText:
                'Stunden absolut setzen (jetzt ${bike.hours.toStringAsFixed(1)} h)',
            hintText: bike.hours.toStringAsFixed(1),
            isDense: true,
            border: const OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          onSubmitted: (raw) async {
            final h = double.tryParse(raw.replaceAll(',', '.'));
            if (h == null || h < 0) return;
            await ref.read(garageRepositoryProvider).setOdometerAbsolute(
                  bikeId: bike.id,
                  odometerKm: bike.odometerKm,
                  hours: h,
                );
            await ref.read(userProfileStoreProvider).addMaintenanceLog(
                  bikeId: bike.id,
                  activity: 'Betriebsstunden aktualisiert',
                  odometerKm: bike.odometerKm,
                  hours: h,
                  notes: 'Manuell: ${h.toStringAsFixed(1)} h',
                );
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Stunden: ${h.toStringAsFixed(1)} h')),
              );
              ref.invalidate(bikesProvider);
            }
          },
        ),
        const SizedBox(height: 6),
        TextField(
          decoration: const InputDecoration(
            labelText: 'Oder km addieren',
            isDense: true,
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          onSubmitted: (raw) async {
            final km = double.tryParse(raw.replaceAll(',', '.'));
            if (km == null || km <= 0) return;
            await ref.read(garageRepositoryProvider).addOdometer(
                  bikeId: bike.id,
                  distanceKm: km,
                  hours: km / 18,
                );
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('+$km km importiert')),
              );
              ref.invalidate(bikesProvider);
            }
          },
        ),
        const SizedBox(height: 10),
        Text(
          'Wartungslog',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        ...() {
          final logs = store.maintenanceLogs
              .where((e) => e['bikeId'] == bike.id)
              .take(5)
              .toList();
          if (logs.isEmpty) {
            return [
              const Text(
                'Noch keine Einträge — Odometer-Set erzeugt Logs.',
                style: TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ];
          }
          return [
            for (final e in logs)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${e['date'] ?? '—'} · ${e['activity'] ?? ''}'
                  '${e['odometerKm'] != null ? ' · ${(e['odometerKm'] as num).toStringAsFixed(0)} km' : ''}',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
          ];
        }(),
      ],
    );
  }

  Widget _bikePhotoWidget(String? photo) {
    if (photo == null) {
      return const Icon(Icons.pedal_bike, size: 36);
    }
    if (isRemotePhotoRef(photo)) {
      return Image.network(
        photo,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.pedal_bike, size: 36),
      );
    }
    if (File(photo).existsSync()) {
      return Image.file(File(photo), fit: BoxFit.cover);
    }
    return const Icon(Icons.pedal_bike, size: 36);
  }
}

class _EmptyBikeSilhouettePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = AppColors.trail.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final w = size.width;
    final h = size.height;
    // Simple MTB silhouette: wheels + frame + bars
    canvas.drawCircle(Offset(w * 0.22, h * 0.72), h * 0.22, stroke);
    canvas.drawCircle(Offset(w * 0.78, h * 0.72), h * 0.22, stroke);
    final frame = Path()
      ..moveTo(w * 0.22, h * 0.72)
      ..lineTo(w * 0.42, h * 0.38)
      ..lineTo(w * 0.68, h * 0.38)
      ..lineTo(w * 0.78, h * 0.72)
      ..moveTo(w * 0.42, h * 0.38)
      ..lineTo(w * 0.5, h * 0.72)
      ..moveTo(w * 0.68, h * 0.38)
      ..lineTo(w * 0.5, h * 0.72)
      ..moveTo(w * 0.42, h * 0.38)
      ..lineTo(w * 0.36, h * 0.22)
      ..lineTo(w * 0.28, h * 0.22);
    canvas.drawPath(frame, stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

