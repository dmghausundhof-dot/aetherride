import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/shop_launcher.dart';
import '../../core/shopify_storefront.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../data/garage/bike_photo_sync.dart';
import '../../data/import/gpx_import.dart';
import '../../data/local/app_database.dart';
import '../../data/sensor/bike_ble_store.dart';
import '../../data/shop/garage_bike_shopify.dart';
import '../../domain/bike.dart';
import '../../domain/bike_assist.dart';
import '../../domain/catalog_bike.dart';
import '../../domain/compatibility/engine.dart';
import '../../domain/compatibility/rules.dart';
import '../../domain/component.dart';
import '../../domain/garage/die_box.dart';
import '../../domain/garage/werkstatt_setup.dart';
import '../../domain/maintenance/intervals.dart';
import '../../domain/saved_route.dart';
import '../../domain/setup.dart';
import '../../domain/setup/fingerprint.dart';
import '../../domain/setup/sag_guide.dart';
import '../../providers/app_providers.dart';
import '../../providers/ride_providers.dart';
import '../billing/upgrade_screen.dart';
import '../shared/empty_state.dart';
import '../shell/shell_tabs.dart';
import 'bike_overview.dart';
import 'ble_pair_sheet.dart';
import 'die_box_surface.dart';
import 'setup_sheet.dart';
import 'werkstatt_csc_bar_button.dart';

Future<void> _openShopForBike(
  WidgetRef ref,
  Bike bike, {
  String? slot,
}) async {
  ref.read(shopPendingBikeIdProvider.notifier).state = bike.id;
  var comps = const <BikeComponent>[];
  try {
    comps = await ref.read(componentRepositoryProvider).listInstalled(bike.id);
  } catch (_) {}
  final uri = ShopifyStorefront.partsFitUri(
    bike: bike,
    components: comps,
    slot: slot,
  );
  final ok = await openShopifyStorefront(uri);
  if (!ok) {
    ref.read(shellTabIndexProvider.notifier).state = ShellTabs.shop;
  }
}

class GarageScreen extends ConsumerStatefulWidget {
  const GarageScreen({super.key});

  @override
  ConsumerState<GarageScreen> createState() => _GarageScreenState();
}

class _GarageScreenState extends ConsumerState<GarageScreen> {
  @override
  Widget build(BuildContext context) {
    final openAdd = ref.watch(garageOpenAddPendingProvider);
    if (openAdd) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (!ref.read(garageOpenAddPendingProvider)) return;
        ref.read(garageOpenAddPendingProvider.notifier).state = false;
        unawaited(_openAddBike(context, ref));
      });
    }

    final pendingBikeId = ref.watch(garagePendingBikeIdProvider);
    if (pendingBikeId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final id = ref.read(garagePendingBikeIdProvider);
        if (id == null) return;
        ref.read(garagePendingBikeIdProvider.notifier).state = null;
        final list = ref.read(bikesProvider).valueOrNull;
        if (list == null) return;
        Bike? match;
        for (final b in list) {
          if (b.id == id) {
            match = b;
            break;
          }
        }
        if (match != null) {
          unawaited(_openDetail(context, ref, match));
        }
      });
    }

    final bikes = ref.watch(bikesProvider);
    final garageList = bikes.valueOrNull ?? const <Bike>[];
    final focused = garageList.isEmpty
        ? null
        : garageList.firstWhere((b) => b.isActive, orElse: () => garageList.first);

    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navWorkshop),
        actionsPadding: const EdgeInsets.only(right: AppSpacing.m),
        actions: [
          if (focused != null) WerkstattCscBarButton(bikeId: focused.id),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddBike(context, ref),
        backgroundColor: AppColors.forestOnDark,
        foregroundColor: AppColors.hofGround,
        icon: const Icon(Icons.add),
        label: Text(l10n.garageAddBike),
      ),
      body: bikes.when(
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: EmptyStateIllustration(
                title: l10n.garageEmptyTitle,
                message: l10n.garageEmptyMessage,
                actionLabel: l10n.garageAddBike,
                actionIcon: Icons.pedal_bike,
                icon: Icons.pedal_bike_outlined,
                onAction: () => _openAddBike(context, ref),
              ),
            );
          }
          final sorted = List<Bike>.from(list)
            ..sort((a, b) {
              if (a.isActive == b.isActive) return 0;
              return a.isActive ? -1 : 1;
            });
          return ListView(
            // Bottom 88px: Platz für den FAB, keine Rhythmus-Stufe.
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.l,
              AppSpacing.l,
              AppSpacing.l,
              88,
            ),
            children: [
              if (sorted.length > 1) ...[
                Text(
                  l10n.garageQuickSwitch,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.muted,
                      ),
                ),
                const SizedBox(height: AppSpacing.s),
                _BikeSwitcher(bikes: sorted),
                const SizedBox(height: AppSpacing.l),
              ],
              Builder(
                builder: (context) {
                  final active = sorted.firstWhere(
                    (b) => b.isActive,
                    orElse: () => sorted.first,
                  );
                  final compsAsync =
                      ref.watch(bikeComponentsProvider(active.id));
                  final comps =
                      compsAsync.valueOrNull ?? const <BikeComponent>[];
                  final due = listDueMaintenance(
                    bike: active,
                    components: comps,
                  );
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.l),
                    child: DieBoxSurface(
                      bike: active,
                      components: comps,
                      due: due,
                      compact: true,
                      onOpenDetail: () => _openDetail(context, ref, active),
                      onInstallSlot: (slot) => _installOnBike(
                        context,
                        ref,
                        active,
                        slot,
                      ),
                      onEditComponent: (c) => _installOnBike(
                        context,
                        ref,
                        active,
                        c.slot,
                        existing: c,
                      ),
                      shopChild: OutlinedButton.icon(
                        key: const Key('werkstatt-shop-parts'),
                        onPressed: () =>
                            unawaited(_openShopForBike(ref, active)),
                        icon: const Icon(Icons.storefront_outlined),
                        label: Text(l10n.werkstattShopParts),
                      ),
                      sensorChild: _BleSensorTile(
                        bikeId: active.id,
                        isEbike: active.hasElectricAssist,
                      ),
                    ),
                  );
                },
              ),
              // Hero-Bike nur in der Overview-Card — Tiles für alle anderen.
              ...() {
                final overviewBike = sorted.firstWhere(
                  (b) => b.isActive,
                  orElse: () => sorted.first,
                );
                final others =
                    sorted.where((b) => b.id != overviewBike.id).toList();
                if (others.isEmpty) return <Widget>[];
                return [
                  Text(
                    l10n.garageOtherBikes,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.muted,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.s),
                  ...List.generate(others.length, (i) {
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: i == others.length - 1 ? 0 : AppSpacing.s,
                      ),
                      child: _BikeTile(
                        bike: others[i],
                        onTap: () => _openDetail(context, ref, others[i]),
                      ),
                    );
                  }),
                ];
              }(),
              const SizedBox(height: AppSpacing.xl),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.errorPrefix('$e'))),
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
          title: const Text('Free: ein Rad'),
          content: const Text(
            'Im Free-Tarif ist ein Rad vorgesehen. Du kannst lokal trotzdem '
            'weitere anlegen — Sync-Limits gelten nach dem Anmelden.',
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
              child: const Text('Pro freischalten'),
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
    final initialCategory = ref.read(garageAddCategoryProvider) ??
        ref.read(userProfileStoreProvider).preferredSport;
    ref.read(garageAddCategoryProvider.notifier).state = null;
    final createdId = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final h = MediaQuery.sizeOf(ctx).height * 0.92;
        return SizedBox(
          height: h,
          child: _AddBikeSheet(initialCategory: initialCategory),
        );
      },
    );
    ref.invalidate(bikesProvider);
    if (createdId != null && createdId.isNotEmpty && context.mounted) {
      final list = await ref.read(garageRepositoryProvider).listBikes();
      Bike? created;
      for (final b in list) {
        if (b.id == createdId) {
          created = b;
          break;
        }
      }
      if (created == null) {
        for (final b in list) {
          if (b.isActive) {
            created = b;
            break;
          }
        }
      }
      created ??= list.isEmpty ? null : list.first;
      if (created != null && context.mounted) {
        await _openDetail(context, ref, created);
      }
    }
  }

  Future<void> _openDetail(
    BuildContext context,
    WidgetRef ref,
    Bike bike, {
    _DetailTab initialTab = _DetailTab.box,
  }) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => _BikeDetailSheet(
          bikeId: bike.id,
          initialTab: initialTab,
        ),
      ),
    );
    ref.invalidate(bikesProvider);
  }

  Future<void> _installOnBike(
    BuildContext context,
    WidgetRef ref,
    Bike bike,
    ComponentSlot slot, {
    BikeComponent? existing,
  }) async {
    final plan = planWerkstattSetup(
      bike: bike,
      components:
          await ref.read(componentRepositoryProvider).listInstalled(bike.id),
    );
    if (!context.mounted) return;
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _InstallComponentSheet(
        bikeId: bike.id,
        existing: existing,
        initialSlot: slot,
        allowedSlots: addableSlotsFor(plan),
      ),
    );
    ref.invalidate(bikesProvider);
    ref.invalidate(bikeComponentsProvider(bike.id));
  }
}

class _PartsGlance extends StatelessWidget {
  const _PartsGlance({
    required this.components,
    required this.onSeeAll,
    this.emphasisSlots = const [],
  });

  final List<BikeComponent> components;
  final VoidCallback onSeeAll;
  final List<ComponentSlot> emphasisSlots;

  static const _fallbackPriority = <ComponentSlot>[
    ComponentSlot.fork,
    ComponentSlot.rearShock,
    ComponentSlot.tireFront,
    ComponentSlot.tireRear,
    ComponentSlot.rearDerailleur,
    ComponentSlot.brakeFront,
    ComponentSlot.motor,
    ComponentSlot.battery,
  ];

  @override
  Widget build(BuildContext context) {
    final bySlot = {for (final c in components) c.slot: c};
    final priority =
        emphasisSlots.isNotEmpty ? emphasisSlots : _fallbackPriority;
    final shown = <BikeComponent>[
      for (final s in priority)
        if (bySlot[s] != null) bySlot[s]!,
    ];
    if (shown.isEmpty) {
      shown.addAll(components.take(6));
    }
    return Material(
      color: AppColors.surfaceDark,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        onTap: onSeeAll,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.m),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Deine Teile',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  Text(
                    'alle ${components.length}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final c in shown.take(8))
                    Chip(
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      label: Text(
                        '${c.slot.label}: ${c.displayName}',
                        overflow: TextOverflow.ellipsis,
                      ),
                      labelStyle: const TextStyle(fontSize: 11.5),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BikeTile extends ConsumerWidget {
  const _BikeTile({required this.bike, required this.onTap});

  final Bike bike;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(userProfileStoreProvider);
    final photo = store.bikePhotos[bike.id];
    final hasPhoto =
        photo != null && (photo.startsWith('http') || File(photo).existsSync());

    return Material(
      color: AppColors.surfaceDark,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: bike.isActive ? AppColors.accent : AppColors.border,
              width: bike.isActive ? 2 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            children: [
              SizedBox(
                width: 96,
                height: 88,
                child: hasPhoto
                    ? (photo.startsWith('http')
                        ? Image.network(photo, fit: BoxFit.cover)
                        : Image.file(File(photo), fit: BoxFit.cover))
                    : Container(
                        color: AppColors.chipIdle,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.pedal_bike,
                          size: 36,
                          color: bike.isActive
                              ? AppColors.accent
                              : AppColors.muted,
                        ),
                      ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.m,
                    vertical: AppSpacing.s,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              bike.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (bike.isActive)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.s,
                                vertical: AppSpacing.xxs,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.18),
                                borderRadius:
                                    BorderRadius.circular(AppRadius.pill),
                              ),
                              child: Text(
                                AppLocalizations.of(context).garageActive,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.accent,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.s,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          bike.categoryLabel,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.accent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        [
                          if (bike.brand != null) bike.brand!,
                          if (bike.model != null) bike.model!,
                          '${bike.odometerKm.toStringAsFixed(0)} km',
                        ].join(' · '),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.s),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Consumer(
                      builder: (context, ref, _) {
                        final compsAsync =
                            ref.watch(bikeComponentsProvider(bike.id));
                        return compsAsync.when(
                          data: (comps) {
                            final due = listDueMaintenance(
                              bike: bike,
                              components: comps,
                            );
                            if (due.isEmpty) return const SizedBox.shrink();
                            final overdue =
                                due.any((a) => a.status == DueStatus.overdue);
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: overdue
                                      ? Colors.redAccent
                                      : Colors.orange,
                                ),
                              ),
                            );
                          },
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        );
                      },
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.muted),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddBikeSheet extends ConsumerStatefulWidget {
  const _AddBikeSheet({this.initialCategory});

  final BikeCategory? initialCategory;

  @override
  ConsumerState<_AddBikeSheet> createState() => _AddBikeSheetState();
}

enum _AddBikeMode { catalog, basic, importMode }

class _AddBikeSheetState extends ConsumerState<_AddBikeSheet> {
  final _name = TextEditingController();
  final _brand = TextEditingController();
  final _model = TextEditingController();
  final _importNote = TextEditingController();
  late BikeCategory _category;
  late BikeAssistMode _assistMode;
  WheelSize _wheel = WheelSize.c700;
  bool _busy = false;
  _AddBikeMode _mode = _AddBikeMode.catalog;
  bool _hasLight = false;
  bool _hasLock = false;
  bool _hasRack = false;
  bool _hasBags = false;
  final _travelFront = TextEditingController();
  final _travelRear = TextEditingController();

  List<CatalogManufacturer> _manufacturers = const [];
  String? _mfrId;
  String? _bikeId;
  String _frameSize = 'L';
  String? _catalogError;
  bool _catalogLoading = true;
  GpxTrack? _pickedGpx;
  String? _gpxFileLabel;
  final _findCtrl = TextEditingController();
  List<CatalogBikeHit> _findHits = const [];
  bool _findBusy = false;
  bool _showCatalogBrowse = false;

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory ?? BikeCategory.urban;
    _assistMode = BikeAssistUx.modeFor(category: _category);
    _wheel = _defaultWheel(_category);
    // Urban/Road → Basis; Trail-Sports → Katalog (Web-Parität).
    if (_category == BikeCategory.urban || _category == BikeCategory.road) {
      _mode = _AddBikeMode.basic;
    }
    _loadCatalog();
  }

  void _setAssistMode(BikeAssistMode mode) {
    setState(() {
      _assistMode = mode;
      _category = BikeAssistUx.coerceCategory(_category, mode);
      _wheel = _defaultWheel(_category);
    });
  }

  WheelSize _defaultWheel(BikeCategory c) => switch (c) {
        BikeCategory.urban ||
        BikeCategory.road ||
        BikeCategory.etrekking =>
          WheelSize.c700,
        BikeCategory.gravel => WheelSize.b650,
        _ => WheelSize.w29,
      };

  bool get _showTravel => switch (_category) {
        BikeCategory.mtbTrail ||
        BikeCategory.mtbAm ||
        BikeCategory.mtbEnduro ||
        BikeCategory.dh ||
        BikeCategory.emtb =>
          true,
        _ => false,
      };

  bool get _showCityAccessories =>
      _category == BikeCategory.urban || _category == BikeCategory.etrekking;

  bool get _showBags => _category == BikeCategory.gravel;

  @override
  void dispose() {
    _name.dispose();
    _brand.dispose();
    _model.dispose();
    _importNote.dispose();
    _findCtrl.dispose();
    _travelFront.dispose();
    _travelRear.dispose();
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
        _catalogLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _catalogLoading = false;
        _catalogError =
            'Katalog offline — du kannst dein Bike unter „Selbst“ oder „GPX“ anlegen.';
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

  void _applyHit(CatalogBikeHit hit) {
    CatalogManufacturer? mfr;
    for (final m in _manufacturers) {
      if (m.id == hit.manufacturerId) {
        mfr = m;
        break;
      }
    }
    setState(() {
      if (mfr != null) {
        _mfrId = mfr.id;
      } else {
        _mfrId = hit.manufacturerId;
      }
      _bikeId = hit.id;
      final bike = _catBike;
      _frameSize = bike != null && bike.frameSizeOptions.isNotEmpty
          ? bike.frameSizeOptions.first
          : 'L';
      _findHits = const [];
      _showCatalogBrowse = false;
      if (_name.text.trim().isEmpty) {
        _name.text = '${hit.manufacturerName} ${hit.name}';
      }
    });
  }

  Future<void> _runFind({String? imageBase64}) async {
    final q = _findCtrl.text.trim();
    if (q.length < 2 && (imageBase64 == null || imageBase64.isEmpty)) return;
    setState(() => _findBusy = true);
    try {
      final hits = await ref.read(catalogClientProvider).identify(
            q: q,
            imageBase64: imageBase64,
          );
      if (!mounted) return;
      setState(() => _findHits = hits);
      if (hits.length == 1) _applyHit(hits.first);
      if (hits.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kein Treffer — Liste nutzen oder anders suchen.'),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Suche gerade nicht möglich — Liste nutzen.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _findBusy = false);
    }
  }

  Future<void> _pickBikePhoto(ImageSource source) async {
    final x = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1024,
      imageQuality: 70,
    );
    if (x == null) return;
    final bytes = await x.readAsBytes();
    await _runFind(imageBase64: base64Encode(bytes));
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
        xml = decodeGpxBytes(bytes);
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
          const SnackBar(
              content: Text('Kein gültiger GPX-Track (min. 2 Punkte)')),
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
        final resolved = BikeAssistUx.resolveCatalogPersist(cat);
        bike = await garage.addBikeBasic(
          name: _name.text.trim().isEmpty
              ? '${mfr.name} ${cat.name}'
              : _name.text.trim(),
          category: resolved.category,
          isEbike: resolved.isEbike,
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
        // Modell-Lookups parallel (vorher seriell: 25–30 HTTP-Roundtrips —
        // „Bike anlegen dauert ewig"). Installs danach seriell in die DB.
        final slotEntries = <({ComponentSlot slot, String modelId})>[];
        for (final e in cat.oemComponents.entries) {
          final slot = ComponentSlotLabel.fromApiId(e.key);
          if (slot == null || slot == ComponentSlot.other) {
            oemMissed += 1;
            continue;
          }
          slotEntries.add((slot: slot, modelId: e.value));
        }
        final models = await Future.wait([
          for (final e in slotEntries)
            catalog.getModel(e.modelId).catchError((_) => null),
        ]);
        for (var i = 0; i < slotEntries.length; i++) {
          final e = slotEntries[i];
          final model = models[i];
          if (model == null) oemMissed += 1;
          final attrs = _attrsFromPayload(model?.payloadJson);
          await components.install(
            bikeId: bike.id,
            slot: e.slot,
            manufacturer: model?.manufacturer,
            model: model?.model ?? e.modelId,
            catalogModelId: e.modelId,
            attributes: attrs,
          );
          oemInstalled += 1;
        }

        await ref.read(setupRepositoryProvider).createVersion(
              bikeId: bike.id,
              label: 'Serien-Setup',
              values: BikeSetup.defaultValues(),
              createdBy: 'catalog',
            );
      } else if (_mode == _AddBikeMode.basic) {
        final persisted = BikeAssistUx.persistCategory(_category, _assistMode);
        bike = await garage.addBikeBasic(
          name: _name.text,
          category: persisted,
          isEbike: BikeAssistUx.persistIsEbike(_category, _assistMode),
          brand: _brand.text,
          model: _model.text,
          wheelSize: _wheel,
          travelFrontMm: _showTravel ? int.tryParse(_travelFront.text) : null,
          travelRearMm: _showTravel ? int.tryParse(_travelRear.text) : null,
          makeActive: true,
        );
        final components = ref.read(componentRepositoryProvider);
        Future<void> stub(ComponentSlot slot, String label) async {
          await components.install(
            bikeId: bike.id,
            slot: slot,
            model: label,
          );
        }
        if (_showCityAccessories) {
          if (_hasLight) await stub(ComponentSlot.light, 'Licht');
          if (_hasLock) await stub(ComponentSlot.lock, 'Schloss');
          if (_hasRack) await stub(ComponentSlot.rack, 'Gepäckträger');
        }
        if (_showBags && _hasBags) {
          await stub(ComponentSlot.bags, 'Taschen');
        }
      } else {
        final gpx = _pickedGpx;
        if (gpx != null) {
          final persisted =
              BikeAssistUx.persistCategory(_category, _assistMode);
          bike = await garage.addBikeBasic(
            name: _name.text.trim().isEmpty ? gpx.name : _name.text.trim(),
            category: persisted,
            isEbike: BikeAssistUx.persistIsEbike(_category, _assistMode),
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

      // G-SETUP: every new bike gets a baseline setup so Setup UI is never empty
      final existingSetups =
          await ref.read(setupRepositoryProvider).listForBike(bike.id);
      if (existingSetups.isEmpty) {
        final createdBy = switch (_mode) {
          _AddBikeMode.catalog => 'catalog',
          _AddBikeMode.basic => 'basic',
          _AddBikeMode.importMode => 'import',
        };
        await ref.read(setupRepositoryProvider).createVersion(
              bikeId: bike.id,
              label: 'Basis-Setup',
              values: BikeSetup.defaultValues(),
              createdBy: createdBy,
            );
      }

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
                  ? '${bike.name}: $oemInstalled Serienteile übernommen.'
                  : '${bike.name}: $oemInstalled Serienteile, $oemMissed übersprungen.',
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
      final comps =
          await ref.read(componentRepositoryProvider).listInstalled(bike.id);
      unawaited(notifyGarageBikeShopify(bike, components: comps));
      if (!mounted) return;
      Navigator.of(context).pop(bike.id);
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
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.accent : AppColors.chipIdle,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected ? AppColors.onAccent : AppColors.chipIdleText,
            ),
          ),
        ),
      ),
    );
  }

  bool get _canSave {
    if (_busy) return false;
    return switch (_mode) {
      _AddBikeMode.catalog => _catBike != null,
      _AddBikeMode.basic => true,
      _AddBikeMode.importMode => true,
    };
  }

  Widget _sizeChips(CatalogBikeVariant cat) {
    if (cat.frameSizeOptions.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final s in cat.frameSizeOptions)
          ChoiceChip(
            label: Text(s),
            selected: _frameSize == s,
            onSelected: (_) => setState(() => _frameSize = s),
            color: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return AppColors.accent;
              }
              return AppColors.chipIdle;
            }),
            labelStyle: TextStyle(
              color:
                  _frameSize == s ? AppColors.onAccent : AppColors.chipIdleText,
              fontWeight: FontWeight.w600,
            ),
            side: BorderSide(
              color: _frameSize == s ? AppColors.accent : AppColors.border,
            ),
          ),
      ],
    );
  }

  Widget _selectedBikeCard(CatalogBikeVariant cat) {
    final mfr = _mfr?.name ?? '';
    final geo = cat.geometryForSize(_frameSize);
    final label = Bike(
      id: '',
      name: '',
      category: cat.category,
      isEbike: cat.isEbike,
    ).categoryLabel;
    final meta = [
      if (cat.year > 0) '${cat.year}',
      label,
      cat.wheelSizeFront.label,
      if (cat.travelFrontMm != null &&
          (cat.travelFrontMm! > 0 || (cat.travelRearMm ?? 0) > 0))
        '${cat.travelFrontMm}/${cat.travelRearMm} mm',
      if (cat.isEbike) 'E-Bike',
    ].join(' · ');
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: AppColors.chipIdle,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$mfr ${cat.name}'.trim(),
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            meta,
            style: const TextStyle(fontSize: 12.5, color: AppColors.muted),
          ),
          if (cat.oemComponents.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '${cat.oemComponents.length} Serienteile kommen mit',
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ],
          const SizedBox(height: AppSpacing.m),
          const Text(
            'Rahmengröße',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
          const SizedBox(height: AppSpacing.s),
          _sizeChips(cat),
          if (geo != null) ...[
            const SizedBox(height: AppSpacing.s),
            Text(
              'Reach ${geo.reachMm.toStringAsFixed(0)} mm · Stack ${geo.stackMm.toStringAsFixed(0)} mm',
              style: const TextStyle(fontSize: 12.5, color: AppColors.muted),
            ),
          ],
          const SizedBox(height: AppSpacing.m),
          TextField(
            controller: _name,
            decoration: const InputDecoration(
              labelText: 'Spitzname (optional)',
              hintText: 'z. B. Trail-Bike',
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _catalogBody(CatalogBikeVariant? cat) {
    if (_catalogLoading) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    if (_manufacturers.isEmpty) {
      return const [
        Text(
          'Katalog nicht geladen — wechsle auf „Selbst“ oder versuch es später.',
        ),
      ];
    }
    return [
      TextField(
        controller: _findCtrl,
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => unawaited(_runFind()),
        decoration: InputDecoration(
          hintText: 'Focus SAM, Canyon Grizl, Stevens …',
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIconConstraints: const BoxConstraints(
            minWidth: 0,
            minHeight: 0,
          ),
          suffixIcon: SizedBox(
            width: _findBusy ? 40 : 88,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_findBusy)
                  const Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else ...[
                  IconButton(
                    tooltip: 'Foto',
                    visualDensity: VisualDensity.compact,
                    onPressed: () =>
                        unawaited(_pickBikePhoto(ImageSource.camera)),
                    icon: const Icon(Icons.photo_camera_outlined, size: 20),
                  ),
                  IconButton(
                    tooltip: 'Galerie',
                    visualDensity: VisualDensity.compact,
                    onPressed: () =>
                        unawaited(_pickBikePhoto(ImageSource.gallery)),
                    icon: const Icon(Icons.photo_outlined, size: 20),
                  ),
                ],
              ],
            ),
          ),
          filled: true,
          fillColor: AppColors.chipIdle.withValues(alpha: 0.55),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            borderSide: BorderSide.none,
          ),
          isDense: true,
        ),
      ),
      if (_findHits.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.s),
        for (final h in _findHits.take(6))
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Material(
              color: AppColors.chipIdle,
              borderRadius: BorderRadius.circular(AppRadius.chip),
              child: ListTile(
                dense: true,
                title: Text(h.label,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700)),
                subtitle: h.isEbike
                    ? const Text('E-Bike', style: TextStyle(fontSize: 12))
                    : null,
                trailing: const Icon(Icons.chevron_right, size: 18),
                onTap: () => _applyHit(h),
              ),
            ),
          ),
      ],
      if (cat != null) ...[
        const SizedBox(height: AppSpacing.m),
        _selectedBikeCard(cat),
      ] else if (_findHits.isEmpty) ...[
        const SizedBox(height: AppSpacing.xl),
        const Text(
          'Suche nach Marke und Modell, mach ein Foto oder wähle aus der Liste.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.muted,
            fontSize: 13.5,
            height: 1.4,
          ),
        ),
      ],
      const SizedBox(height: AppSpacing.s),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton(
          onPressed: () =>
              setState(() => _showCatalogBrowse = !_showCatalogBrowse),
          child: Text(
            _showCatalogBrowse ? 'Liste ausblenden' : 'Aus Liste wählen',
          ),
        ),
      ),
      if (_showCatalogBrowse) ...[
        _searchableCatalogField<CatalogManufacturer>(
          key: ValueKey('mfr-ac-$_mfrId'),
          fieldLabel: 'Hersteller',
          currentText: _mfr?.name ?? '',
          options: _manufacturers,
          labelOf: (m) => m.name,
          onSelected: (m) {
            setState(() {
              _mfrId = m.id;
              _bikeId = m.bikes.isNotEmpty ? m.bikes.first.id : null;
              _frameSize = m.bikes.isNotEmpty &&
                      m.bikes.first.frameSizeOptions.isNotEmpty
                  ? m.bikes.first.frameSizeOptions.first
                  : 'L';
            });
          },
        ),
        const SizedBox(height: AppSpacing.s),
        _searchableCatalogField<CatalogBikeVariant>(
          key: ValueKey('bike-ac-$_mfrId-$_bikeId'),
          fieldLabel: 'Modell',
          currentText: cat == null ? '' : '${cat.name} (${cat.year})',
          options: _mfr?.bikes ?? const <CatalogBikeVariant>[],
          labelOf: (b) => '${b.name} (${b.year})',
          onSelected: (b) {
            setState(() {
              _bikeId = b.id;
              _frameSize = b.frameSizeOptions.isNotEmpty
                  ? b.frameSizeOptions.first
                  : 'L';
            });
          },
        ),
      ],
    ];
  }

  List<Widget> _basicBody() {
    return [
      TextField(
        controller: _name,
        decoration: const InputDecoration(
          labelText: 'Name',
          hintText: 'z. B. Alltagsrad',
        ),
        textInputAction: TextInputAction.next,
      ),
      const SizedBox(height: AppSpacing.m),
      _AssistModeSegmented(
        selected: _assistMode,
        onSelect: _setAssistMode,
      ),
      const SizedBox(height: AppSpacing.m),
      _CategoryGridPicker(
        selected: _category,
        assistMode: _assistMode,
        onSelect: (c) => setState(() {
          _category = c;
          _wheel = _defaultWheel(c);
        }),
      ),
      const SizedBox(height: AppSpacing.m),
      _WheelSizeChips(
        selected: _wheel,
        onSelect: (w) => setState(() => _wheel = w),
      ),
      if (_showTravel) ...[
        const SizedBox(height: AppSpacing.m),
        TextField(
          controller: _travelFront,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Federweg vorn (mm)',
            hintText: 'Nur wenn am Rad steht',
            isDense: true,
          ),
        ),
        const SizedBox(height: AppSpacing.s),
        TextField(
          controller: _travelRear,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Federweg hinten (mm)',
            isDense: true,
          ),
        ),
      ],
      if (_showCityAccessories) ...[
        const SizedBox(height: AppSpacing.m),
        Text(
          'Am Rad — nur anhaken wenn wirklich da',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.muted,
              ),
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          value: _hasLight,
          onChanged: (v) => setState(() => _hasLight = v ?? false),
          title: const Text('Licht'),
          activeColor: AppColors.forestOnDark,
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          value: _hasLock,
          onChanged: (v) => setState(() => _hasLock = v ?? false),
          title: const Text('Schloss'),
          activeColor: AppColors.forestOnDark,
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          value: _hasRack,
          onChanged: (v) => setState(() => _hasRack = v ?? false),
          title: const Text('Gepäckträger'),
          activeColor: AppColors.forestOnDark,
        ),
      ],
      if (_showBags) ...[
        const SizedBox(height: AppSpacing.s),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          value: _hasBags,
          onChanged: (v) => setState(() => _hasBags = v ?? false),
          title: const Text('Taschen am Rad'),
          activeColor: AppColors.forestOnDark,
        ),
      ],
      const SizedBox(height: AppSpacing.m),
      TextField(
        controller: _brand,
        decoration: const InputDecoration(
          labelText: 'Marke (optional)',
          isDense: true,
        ),
      ),
      const SizedBox(height: AppSpacing.s),
      TextField(
        controller: _model,
        decoration: const InputDecoration(
          labelText: 'Modell (optional)',
          isDense: true,
        ),
      ),
    ];
  }

  List<Widget> _gpxBody() {
    return [
      Material(
        color: AppColors.chipIdle,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(
            color: _pickedGpx == null ? AppColors.border : AppColors.accent,
            width: 1.2,
          ),
        ),
        child: InkWell(
          onTap: _busy ? null : _pickGpx,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.xl,
              horizontal: AppSpacing.m,
            ),
            child: Column(
              children: [
                Icon(
                  Icons.upload_file,
                  size: 32,
                  color:
                      _pickedGpx == null ? AppColors.muted : AppColors.accent,
                ),
                const SizedBox(height: AppSpacing.s),
                Text(
                  _gpxFileLabel == null ? 'GPX-Datei wählen' : _gpxFileLabel!,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (_pickedGpx != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${_pickedGpx!.distanceKm.toStringAsFixed(1)} km · '
                    '${_pickedGpx!.elevationM.round()} hm',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      const SizedBox(height: AppSpacing.m),
      TextField(
        controller: _name,
        decoration: const InputDecoration(
          labelText: 'Name (optional)',
          isDense: true,
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final cat = _catBike;
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.l,
              0,
              AppSpacing.s,
              AppSpacing.s,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Rad abstellen',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                IconButton(
                  tooltip: 'Schließen',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
            child: Row(
              children: [
                _modeChip(_AddBikeMode.catalog, 'Katalog'),
                const SizedBox(width: 8),
                _modeChip(_AddBikeMode.basic, 'Selbst'),
                const SizedBox(width: 8),
                _modeChip(_AddBikeMode.importMode, 'GPX'),
              ],
            ),
          ),
          if (_catalogError != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.l,
                AppSpacing.s,
                AppSpacing.l,
                0,
              ),
              child: Text(
                _catalogError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.l,
                AppSpacing.m,
                AppSpacing.l,
                AppSpacing.l + bottom,
              ),
              children: [
                if (_mode == _AddBikeMode.catalog) ..._catalogBody(cat),
                if (_mode == _AddBikeMode.basic) ..._basicBody(),
                if (_mode == _AddBikeMode.importMode) ..._gpxBody(),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.l,
                AppSpacing.s,
                AppSpacing.l,
                AppSpacing.m,
              ),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 48),
                  ),
                  onPressed: _canSave ? _save : null,
                  child: _busy
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          _mode == _AddBikeMode.importMode
                              ? 'Importieren'
                              : 'Rad anlegen',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Alle installierbaren Slots außer `other` (Sammelbecken) — bewusst
/// breiter als das App-weite `coreInstallSlots` (Shop-Filter/Legacy-
/// Subset ohne Vorderrad-Slots). Ohne Steuersatz/Nabe-vorn/Felge-vorn/
/// Reifen-vorn in der Auswahl können 4 der 15 Kompat-Regeln (Gabel↔
/// Steuersatz, Gabel↔Vorderradachse, Reifen/Felge vorn, Scheibe vorn↔Nabe)
/// nie auslösen — nicht die Engine ist blind, die UI bot die Slots nie an.
final List<ComponentSlot> _trackableSlots =
    ComponentSlot.values.where((s) => s != ComponentSlot.other).toList();

enum _DetailTab { box, teile, wartung, setup }

class _BikeDetailSheet extends ConsumerStatefulWidget {
  const _BikeDetailSheet({
    required this.bikeId,
    this.initialTab = _DetailTab.box,
  });

  final String bikeId;
  final _DetailTab initialTab;

  @override
  ConsumerState<_BikeDetailSheet> createState() => _BikeDetailSheetState();
}

class _BikeDetailSheetState extends ConsumerState<_BikeDetailSheet> {
  Bike? _bike;
  List<BikeComponent> _components = [];
  List<CompatibilityResult> _compat = [];
  bool _busy = false;
  // Segmente in einer ListView (kein TabBarView / kein BottomSheet —
  // verschachteltes Sheet war auf S25 leer).
  late _DetailTab _tab = widget.initialTab;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_load());
    });
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
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rad löschen?'),
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

  Future<void> _installComponent({
    BikeComponent? existing,
    ComponentSlot? initialSlot,
  }) async {
    final bike = _bike;
    final plan = bike == null
        ? null
        : planWerkstattSetup(bike: bike, components: _components);
    final installed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _InstallComponentSheet(
        bikeId: widget.bikeId,
        existing: existing,
        initialSlot: initialSlot,
        allowedSlots: plan == null ? null : addableSlotsFor(plan),
      ),
    );
    if (installed == true) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final bike = _bike;
    if (bike == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final due = listDueMaintenance(bike: bike, components: _components);
    final plan = planWerkstattSetup(bike: bike, components: _components);
    final bySlot = _groupCompatBySlot(_compat);
    final installedSlots = _components.map((c) => c.slot).toSet();
    final missingSlots = addableSlotsFor(plan)
        .where((s) => !installedSlots.contains(s))
        .toList();
    final okCount =
        _compat.where((r) => r.verdict == CompatVerdict.compatible).length;
    final warnCount = _compat
        .where((r) =>
            r.verdict == CompatVerdict.conditional ||
            r.verdict == CompatVerdict.insufficientData)
        .length;
    final badCount =
        _compat.where((r) => r.verdict == CompatVerdict.incompatible).length;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(bike.name),
        actionsPadding: const EdgeInsets.only(right: AppSpacing.m),
        actions: [
          WerkstattCscBarButton(bikeId: bike.id),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (v) {
              if (v == 'delete') unawaited(_delete());
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem(value: 'delete', child: Text('Rad löschen')),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.l,
          AppSpacing.s,
          AppSpacing.l,
          AppSpacing.xxl,
        ),
        children: [
          DieBoxSurface(
            bike: bike,
            components: _components,
            due: due,
            onInstallSlot: (slot) => _installComponent(initialSlot: slot),
            onEditComponent: (c) => _installComponent(existing: c),
            shopChild: OutlinedButton.icon(
              key: const Key('werkstatt-shop-parts-detail'),
              onPressed: () {
                Navigator.pop(context);
                unawaited(_openShopForBike(ref, bike));
              },
              icon: const Icon(Icons.storefront_outlined),
              label: Text(l10n.werkstattShopParts),
            ),
            sensorChild: _BleSensorTile(
              bikeId: bike.id,
              isEbike: bike.hasElectricAssist,
            ),
          ),
          const SizedBox(height: AppSpacing.l),
          BikeTechDetailsPanel(bike: bike),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: widget.initialTab != _DetailTab.box,
              tilePadding: EdgeInsets.zero,
              title: const Text(
                'Mehr am Rad',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: const Text(
                'Teile, Wartung, Setup-Versionen — hinter der Box',
                style: TextStyle(fontSize: 12, color: AppColors.muted),
              ),
              onExpansionChanged: (open) {
                if (open && _tab == _DetailTab.box) {
                  setState(() => _tab = _DetailTab.teile);
                }
              },
              children: [
          Row(
            children: [
              Expanded(
                child: _TabChip(
                  label: l10n.garageParts,
                  badge: _components.length,
                  active: _tab == _DetailTab.teile,
                  onTap: () => setState(() => _tab = _DetailTab.teile),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: _TabChip(
                  label: l10n.garageMaintenance,
                  badge: due.length,
                  active: _tab == _DetailTab.wartung,
                  onTap: () => setState(() => _tab = _DetailTab.wartung),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: _TabChip(
                  label: l10n.garageSetup,
                  active: _tab == _DetailTab.setup,
                  onTap: () => setState(() => _tab = _DetailTab.setup),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.l),
          if (_tab == _DetailTab.teile) ...[
            Row(
              children: [
                Text(
                  l10n.garageYourParts,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _installComponent,
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(l10n.garageInstall),
                ),
              ],
            ),
            if (_compat.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xxs),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _CompatBadge(
                    label: l10n.garageCompatFits(okCount),
                    color: const Color(0xFF4CAF50),
                  ),
                  _CompatBadge(
                    label: l10n.garageCompatCheck(warnCount),
                    color: Colors.orange,
                  ),
                  _CompatBadge(
                    label: l10n.garageCompatNoFit(badCount),
                    color: Colors.redAccent,
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.s),
            if (_components.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
                child: Text(
                  l10n.garagePartsEmpty,
                  style: const TextStyle(color: AppColors.muted, fontSize: 13),
                ),
              )
            else ...[
              for (final g in ComponentGroup.values)
                if (_components.any((c) => c.slot.group == g))
                  Theme(
                    data: Theme.of(context).copyWith(
                      dividerColor: Colors.transparent,
                    ),
                    child: ExpansionTile(
                      initiallyExpanded: plan.emphasisSlots.any(
                            (s) => s.group == g,
                          ) ||
                          g == ComponentGroup.wheels,
                      tilePadding: EdgeInsets.zero,
                      childrenPadding: EdgeInsets.zero,
                      title: Text(
                        '${g.label} · ${_components.where((c) => c.slot.group == g).length}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      children: [
                        for (final c in _components.where(
                          (c) => c.slot.group == g,
                        ))
                          _ComponentRow(
                            component: c,
                            findings: bySlot[c.slot] ?? const [],
                            onRemove: () async {
                              await ref
                                  .read(componentRepositoryProvider)
                                  .remove(c.id);
                              await _load();
                            },
                            onEdit: () => _installComponent(existing: c),
                            onTapFindings: (findings) =>
                                _openSlotFindings(context, c, findings),
                          ),
                      ],
                    ),
                  ),
              if (missingSlots.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.s),
                Text(
                  l10n.garageMissingSlots,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: AppSpacing.xs),
                for (final s in missingSlots)
                  _GhostSlotRow(
                    slot: s,
                    onTap: () => _installComponent(initialSlot: s),
                  ),
              ],
            ],
          ],
          if (_tab == _DetailTab.wartung) ...[
            if (due.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
                child: Text(
                  l10n.garageMaintEmpty,
                  style: const TextStyle(color: AppColors.muted, fontSize: 13),
                ),
              )
            else ...[
              Row(
                children: [
                  Text(
                    l10n.garageMaintenance,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () async {
                      final bike = _bike;
                      if (bike == null) return;
                      Navigator.pop(context);
                      await _openShopForBike(ref, bike);
                    },
                    child: const Text('Shop'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              for (final a in due.take(5))
                _MaintenanceBarRow(
                  alert: a,
                  onShop: () async {
                    final bike = _bike;
                    if (bike == null) return;
                    final slot = ShopifyStorefront.slotFromComponent(a.slot);
                    Navigator.pop(context);
                    await _openShopForBike(ref, bike, slot: slot);
                  },
                ),
            ],
          ],
          if (_tab == _DetailTab.setup) ...[
            Text(
              l10n.garageSetupTabTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              plan.hasSuspension
                  ? l10n.garageSetupTabHint
                  : l10n.garageSetupTabHintTires,
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
            const SizedBox(height: AppSpacing.s),
            _SagAndOdometerCard(
              bike: bike,
              components: _components,
              onUpdated: _load,
            ),
            const SizedBox(height: AppSpacing.l),
            SetupPanel(
              bike: bike,
              onChanged: () => unawaited(_load()),
            ),
          ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openSlotFindings(
    BuildContext context,
    BikeComponent component,
    List<CompatibilityResult> findings,
  ) {
    if (findings.length == 1) {
      _showEvidence(context, findings.first);
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.l,
            AppSpacing.xl,
            AppSpacing.xxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${component.slot.label} · ${component.displayName}',
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: AppSpacing.s),
              for (final r in findings)
                Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.s),
                  padding: const EdgeInsets.all(AppSpacing.m),
                  decoration: BoxDecoration(
                    color: AppColors.chipIdle,
                    borderRadius: BorderRadius.circular(AppRadius.chip),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(ctx);
                      _showEvidence(context, r);
                    },
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          margin: const EdgeInsets.only(top: AppSpacing.xs),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _verdictColor(r.verdict),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xxs),
                              Text(
                                r.explainDe,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.muted,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
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
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.l,
            AppSpacing.xl,
            AppSpacing.xxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Passgenauigkeit',
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: AppSpacing.s),
              Text(
                r.ruleCode,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(r.title,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: AppSpacing.s),
              Text('Status: ${verdictLabel(r.verdict)}'),
              Text(
                'Schwere: ${r.severity == RuleSeverity.safetyCritical ? 'sicherheitskritisch' : 'funktional'}',
                style: const TextStyle(color: AppColors.muted, fontSize: 13),
              ),
              const SizedBox(height: AppSpacing.m),
              Text(
                'Einfach erklärt',
                style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(r.explainDe),
              if (r.conditionText != null && r.conditionText!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.s),
                Text('Bedingung: ${r.conditionText}'),
              ],
              if (r.safetyWorkshopHint != null &&
                  r.safetyWorkshopHint!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.s),
                Text('Hinweis: ${r.safetyWorkshopHint}'),
              ],
              if (r.missingAttributes.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.m),
                Text(
                  'Noch fehlende Infos',
                  style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                for (final m in r.missingAttributes)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Text('· ${m.key}: ${m.howToObtain}'),
                  ),
              ],
              if (r.sourceUrl != null && r.sourceUrl!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.s),
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
  const _InstallComponentSheet({
    required this.bikeId,
    this.existing,
    this.initialSlot,
    this.allowedSlots,
  });

  final String bikeId;

  /// Gesetzt beim Bearbeiten eines bereits installierten Bauteils —
  /// Slot/Hersteller/Modell/Attribute werden vorausgefüllt. Speichern
  /// ersetzt es (`ComponentRepository.install` entfernt das alte Bauteil
  /// im selben Slot automatisch, kein Duplikat).
  final BikeComponent? existing;

  /// Gesetzt beim Antippen eines „Nicht erfasst"-Slots — startet das Sheet
  /// direkt auf diesem Slot statt auf der Default-Kassette.
  final ComponentSlot? initialSlot;

  /// Kind-relevante Slots — nie der volle 25er-Geisterkatalog.
  final List<ComponentSlot>? allowedSlots;

  @override
  ConsumerState<_InstallComponentSheet> createState() =>
      _InstallComponentSheetState();
}

class _InstallComponentSheetState
    extends ConsumerState<_InstallComponentSheet> {
  ComponentSlot _slot = ComponentSlot.cassette;
  final _manufacturer = TextEditingController();
  final _model = TextEditingController();
  final _attrKey = TextEditingController();
  final _attrVal = TextEditingController();
  final _catalogQ = TextEditingController();
  String? _catalogModelId;
  Map<String, dynamic> _catalogAttrs = {};
  // Kuratierte Attribut-Eingaben (Chips/Zahl statt Freitext) — überschreiben
  // Katalog-Werte, wenn der Nutzer sie bewusst anpasst.
  final Map<String, dynamic> _manualAttrs = {};
  List<CatalogCacheData> _hits = [];
  bool _searching = false;
  bool _busy = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _slot = existing.slot;
      _manufacturer.text = existing.manufacturer ?? '';
      _model.text = existing.model ?? '';
      _catalogModelId = existing.catalogModelId;
      _catalogAttrs = Map<String, dynamic>.from(existing.attributes)
        ..remove('_compat_placeholder');
    } else if (widget.initialSlot != null) {
      _slot = widget.initialSlot!;
    } else {
      final allowed = widget.allowedSlots;
      if (allowed != null && allowed.isNotEmpty) {
        _slot = allowed.first;
      }
    }
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
          final val =
              e['valueNum'] ?? e['valueEnum'] ?? e['value'] ?? e['valueStr'];
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
      _manualAttrs.clear();
    });
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    final attrs = Map<String, dynamic>.from(_catalogAttrs)
      ..addAll(_manualAttrs);
    if (_attrKey.text.trim().isNotEmpty && _attrVal.text.trim().isNotEmpty) {
      final raw = _attrVal.text.trim();
      attrs[_attrKey.text.trim()] = num.tryParse(raw) ?? raw;
    }
    // Default-Attribute für Kompat-Checks (Platzhalter, nicht Katalog-Wahrheit)
    var usedPlaceholders = false;
    if (_slot == ComponentSlot.frame && !attrs.containsKey('rear_spacing')) {
      usedPlaceholders = true;
      attrs['rear_spacing'] = '148x12';
      attrs['max_tire_width_mm'] = 2.6;
      attrs['bb_standard'] = 'BSA73';
      attrs['seatpost_diameter_mm'] = 31.6;
      attrs['max_seatpost_insertion_mm'] = 250;
      attrs['brake_mount_rear'] = 'post_mount';
    }
    if (_slot == ComponentSlot.rearHub &&
        !attrs.containsKey('freehub_standard')) {
      usedPlaceholders = true;
      attrs['freehub_standard'] = 'microspline';
      attrs['rear_spacing'] = '148x12';
      attrs['rotor_mount'] = '6bolt';
    }
    if (_slot == ComponentSlot.cassette &&
        !attrs.containsKey('freehub_standard')) {
      usedPlaceholders = true;
      attrs['freehub_standard'] = 'microspline';
    }
    if (usedPlaceholders) {
      attrs['_compat_placeholder'] = true;
    }
    await ref.read(componentRepositoryProvider).install(
          bikeId: widget.bikeId,
          slot: _slot,
          manufacturer: _manufacturer.text,
          model: _model.text,
          catalogModelId: _catalogModelId,
          attributes: attrs,
        );
    if (!mounted) return;
    if (usedPlaceholders) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Kompat-Platzhalter gesetzt (z. B. 148×12 / Microspline) — '
            'keine Katalog-Wahrheit. Attribute prüfen.',
          ),
        ),
      );
    }
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.l,
        AppSpacing.xl,
        AppSpacing.xl + bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _isEdit ? 'Teil bearbeiten' : 'Teil installieren',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: AppSpacing.m),
            Text('Slot', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: AppSpacing.s),
            _SlotGridPicker(
              selected: _slot,
              slots: widget.allowedSlots,
              onSelect: (v) {
                setState(() {
                  _slot = v;
                  _catalogModelId = null;
                  _catalogAttrs = {};
                  _manualAttrs.clear();
                });
                _searchCatalog();
              },
            ),
            const SizedBox(height: AppSpacing.s),
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
              const SizedBox(height: AppSpacing.xs),
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
                      leading: Icon(_slotIcon(_slot),
                          size: 18, color: AppColors.muted),
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
                padding: EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  'Keine Treffer — manuell ausfüllen (Basis). Cache kann leer sein.',
                  style: TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ),
            if (_catalogModelId != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Text(
                  'Cache-ID: $_catalogModelId',
                  style: const TextStyle(fontSize: 12, color: AppColors.accent),
                ),
              ),
            TextField(
              controller: _manufacturer,
              decoration: const InputDecoration(labelText: 'Hersteller'),
            ),
            const SizedBox(height: AppSpacing.s),
            TextField(
              controller: _model,
              decoration: const InputDecoration(labelText: 'Modell'),
            ),
            if (_relevantAttrKeys(_slot).isNotEmpty) ...[
              const SizedBox(height: AppSpacing.m),
              Text(
                'Kompat-Attribute · ${_slot.label}',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: AppSpacing.xxs),
              const Text(
                'Woher: Herstellerdatenblatt oder Aufdruck am Bauteil. '
                'Leer lassen, wenn unbekannt — dann „Daten fehlen" statt Rätselraten.',
                style: TextStyle(fontSize: 11, color: AppColors.muted),
              ),
              const SizedBox(height: AppSpacing.s),
              for (final f in _relevantAttrKeys(_slot))
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.m),
                  child: _knownAttrOptions.containsKey(f.key)
                      ? _AttrChipField(
                          label: f.label,
                          options: _knownAttrOptions[f.key]!,
                          value: (_manualAttrs[f.key] ?? _catalogAttrs[f.key])
                              ?.toString(),
                          onSelect: (v) =>
                              setState(() => _manualAttrs[f.key] = v),
                        )
                      : TextFormField(
                          key: ValueKey(
                            '${_slot.name}-${f.key}-${_catalogModelId ?? 'm'}',
                          ),
                          initialValue:
                              (_manualAttrs[f.key] ?? _catalogAttrs[f.key])
                                  ?.toString(),
                          decoration: InputDecoration(
                            labelText: f.label,
                            hintText: f.hint,
                            suffixText: f.key.endsWith('_mm') ? 'mm' : null,
                          ),
                          keyboardType: f.key.endsWith('_mm')
                              ? const TextInputType.numberWithOptions(
                                  decimal: true)
                              : TextInputType.text,
                          onChanged: (raw) {
                            final trimmed = raw.trim();
                            if (trimmed.isEmpty) {
                              _manualAttrs.remove(f.key);
                              return;
                            }
                            _manualAttrs[f.key] =
                                num.tryParse(trimmed) ?? trimmed;
                          },
                        ),
                ),
            ],
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              title: const Text(
                'Weiteres Attribut (fortgeschritten)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              children: [
                TextField(
                  controller: _attrKey,
                  decoration: const InputDecoration(
                    labelText: 'Attribut-Key',
                    hintText: 'z. B. hub_spacing_special',
                  ),
                ),
                const SizedBox(height: AppSpacing.s),
                TextField(
                  controller: _attrVal,
                  decoration: const InputDecoration(labelText: 'Attribut-Wert'),
                ),
                const SizedBox(height: AppSpacing.s),
              ],
            ),
            const SizedBox(height: AppSpacing.s),
            FilledButton(
              onPressed: _busy ? null : _save,
              child: Text(_isEdit ? 'Speichern' : 'Installieren'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompatBadge extends StatelessWidget {
  const _CompatBadge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppRadius.sheet),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _SagAndOdometerCard extends ConsumerWidget {
  const _SagAndOdometerCard({
    required this.bike,
    required this.onUpdated,
    this.components = const [],
  });

  final Bike bike;
  final List<BikeComponent> components;
  final Future<void> Function() onUpdated;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final store = ref.watch(userProfileStoreProvider);
    final weight = store.effectiveWeightKg;
    final plan = planWerkstattSetup(bike: bike, components: components);
    final setupAsync = ref.watch(currentSetupProvider(bike.id));
    final fp = SetupFingerprint.fromSetup(setupAsync.valueOrNull);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (fp.lines.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.s),
            child: Text(
              fp.lines.join(' · '),
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ),
        if (plan.hasSuspension) ...[
          Text(
            'Federungs-Richtwerte (Fahrer ${weight.toStringAsFixed(0)} kg)',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          Builder(
            builder: (context) {
              final fork = estimateAirPsi(
                riderWeightKg: weight,
                category: bike.category,
                end: 'fork',
                travelMm: bike.travelFrontMm?.toDouble(),
              );
              return Text(
                'Gabel: ${fork.psiTarget} psi '
                '(${fork.psiMin}–${fork.psiMax}) · SAG ${fork.sag.target.toStringAsFixed(0)}%',
                style: const TextStyle(fontSize: 13),
              );
            },
          ),
          if (plan.hasRearShock)
            Builder(
              builder: (context) {
                final shock = estimateAirPsi(
                  riderWeightKg: weight,
                  category: bike.category,
                  end: 'shock',
                  travelMm: bike.travelRearMm?.toDouble(),
                );
                return Text(
                  'Dämpfer: ${shock.psiTarget} psi '
                  '(${shock.psiMin}–${shock.psiMax}) · SAG ${shock.sag.target.toStringAsFixed(0)}%',
                  style: const TextStyle(fontSize: 13),
                );
              },
            ),
          const Text(
            'Richtwert zum Einstieg — am Bike messen, dann feinjustieren.',
            style: TextStyle(fontSize: 11, color: AppColors.muted),
          ),
          const SizedBox(height: AppSpacing.xs),
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
        ] else ...[
          Text(
            l10n.werkstattSetupTires,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          Text(
            l10n.garageSetupTabHintTires,
            style: const TextStyle(fontSize: 13, color: AppColors.muted),
          ),
          if (plan.wheelLabel != null)
            Text(
              l10n.werkstattSetupWheel(plan.wheelLabel!),
              style: const TextStyle(fontSize: 13),
            ),
        ],
        const SizedBox(height: AppSpacing.m),
        _NumberEditRow(
          label: 'Kilometerstand',
          value: bike.odometerKm,
          unit: 'km',
          decimals: 0,
          onSave: (v) async {
            await ref.read(garageRepositoryProvider).setOdometerAbsolute(
                  bikeId: bike.id,
                  odometerKm: v,
                  hours: bike.hours,
                );
            await ref.read(userProfileStoreProvider).addMaintenanceLog(
                  bikeId: bike.id,
                  activity: 'Kilometerstand aktualisiert',
                  odometerKm: v,
                  hours: bike.hours,
                  notes: 'Manuell: ${v.toStringAsFixed(0)} km',
                );
            ref.invalidate(bikesProvider);
            await onUpdated();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Stand: ${v.toStringAsFixed(0)} km')),
              );
            }
          },
        ),
        const SizedBox(height: AppSpacing.s),
        _NumberEditRow(
          label: 'Betriebsstunden',
          value: bike.hours,
          unit: 'h',
          decimals: 1,
          onSave: (v) async {
            await ref.read(garageRepositoryProvider).setOdometerAbsolute(
                  bikeId: bike.id,
                  odometerKm: bike.odometerKm,
                  hours: v,
                );
            await ref.read(userProfileStoreProvider).addMaintenanceLog(
                  bikeId: bike.id,
                  activity: 'Betriebsstunden aktualisiert',
                  odometerKm: bike.odometerKm,
                  hours: v,
                  notes: 'Manuell: ${v.toStringAsFixed(1)} h',
                );
            ref.invalidate(bikesProvider);
            await onUpdated();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Stunden: ${v.toStringAsFixed(1)} h')),
              );
            }
          },
        ),
        const SizedBox(height: AppSpacing.s),
        OutlinedButton.icon(
          onPressed: () async {
            final controller = TextEditingController();
            final result = await showDialog<double>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('km ohne GPS-Track hinzufügen'),
                content: TextField(
                  controller: controller,
                  autofocus: true,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Distanz (km)'),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Abbrechen'),
                  ),
                  FilledButton(
                    onPressed: () {
                      final v =
                          double.tryParse(controller.text.replaceAll(',', '.'));
                      Navigator.pop(ctx, v);
                    },
                    child: const Text('Hinzufügen'),
                  ),
                ],
              ),
            );
            if (result == null || result <= 0) return;
            await ref.read(garageRepositoryProvider).addOdometer(
                  bikeId: bike.id,
                  distanceKm: result,
                  hours: result / 18,
                );
            ref.invalidate(bikesProvider);
            await onUpdated();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('+${result.toStringAsFixed(1)} km importiert'),
                ),
              );
            }
          },
          icon: const Icon(Icons.add_road, size: 18),
          label: const Text('km importieren (ohne GPS-Ride)'),
        ),
        const SizedBox(height: AppSpacing.m),
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
              const Padding(
                padding: EdgeInsets.only(top: AppSpacing.xxs),
                child: Text(
                  'Noch keine Einträge — Odometer-Set erzeugt Logs.',
                  style: TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ),
            ];
          }
          return [
            for (final e in logs)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
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
}

/// Kompakte Zeile: Wert groß + Bearbeiten-Icon → Dialog mit Zahlenfeld.
/// Ersetzt die zuvor immer sichtbaren Roh-TextFields (kein versehentliches
/// Verstellen beim Scrollen, größere Tap-Fläche für den Edit-Button).
class _NumberEditRow extends StatelessWidget {
  const _NumberEditRow({
    required this.label,
    required this.value,
    required this.unit,
    required this.decimals,
    required this.onSave,
  });

  final String label;
  final double value;
  final String unit;
  final int decimals;
  final Future<void> Function(double) onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.m,
        vertical: AppSpacing.s,
      ),
      decoration: BoxDecoration(
        color: AppColors.chipIdle,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style:
                        const TextStyle(fontSize: 11, color: AppColors.muted)),
                Text(
                  '${value.toStringAsFixed(decimals)} $unit',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: () => _edit(context),
          ),
        ],
      ),
    );
  }

  Future<void> _edit(BuildContext context) async {
    final controller =
        TextEditingController(text: value.toStringAsFixed(decimals));
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$label setzen'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: label, suffixText: unit),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () {
              final v = double.tryParse(controller.text.replaceAll(',', '.'));
              Navigator.pop(ctx, v);
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
    if (result == null || result < 0) return;
    await onSave(result);
  }
}

/// Ein Bauteil + Kompatibilitäts-Ampel in einer Zeile (statt zwei getrennten
/// Listen) — Tap öffnet die Befunde, Swipe entfernt das Bauteil.
class _ComponentRow extends StatelessWidget {
  const _ComponentRow({
    required this.component,
    required this.findings,
    required this.onRemove,
    required this.onEdit,
    required this.onTapFindings,
  });

  final BikeComponent component;
  final List<CompatibilityResult> findings;
  final Future<void> Function() onRemove;
  final VoidCallback onEdit;
  final void Function(List<CompatibilityResult>) onTapFindings;

  /// Geteilt zwischen Swipe (Dismissible) und dem immer sichtbaren
  /// Overflow-Menü — Swipe allein ist für Screenreader/motorisch
  /// eingeschränkte Nutzer schwer/nicht auffindbar (Regression ggü. dem
  /// vorherigen, immer sichtbaren Lösch-Icon).
  Future<bool> _confirmRemove(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Bauteil entfernen?'),
            content: Text(
              '${component.slot.label}: ${component.displayName} wird aus '
              'der Garage entfernt.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Abbrechen'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Entfernen'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final verdict = findings.isEmpty ? null : aggregateVerdict(findings);
    return Dismissible(
      key: ValueKey('comp-${component.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmRemove(context),
      onDismissed: (_) => onRemove(),
      background: Container(
        alignment: Alignment.centerRight,
        margin: const EdgeInsets.only(bottom: AppSpacing.xs),
        padding: const EdgeInsets.only(right: AppSpacing.l),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: findings.isEmpty ? null : () => onTapFindings(findings),
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.xs),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.m,
            vertical: AppSpacing.s,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.chipIdle,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Icon(_slotIcon(component.slot),
                    size: 16, color: AppColors.muted),
              ),
              const SizedBox(width: AppSpacing.s),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      component.slot.label,
                      style:
                          const TextStyle(fontSize: 11, color: AppColors.muted),
                    ),
                    Text(
                      component.displayName,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (verdict != null) ...[
                const SizedBox(width: AppSpacing.s),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _verdictColor(verdict),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  _verdictShort(verdict),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: _verdictColor(verdict),
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.chevron_right,
                    size: 16, color: AppColors.muted),
              ],
              SizedBox(
                width: 30,
                height: 30,
                child: PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  tooltip: 'Optionen',
                  icon: const Icon(Icons.more_vert,
                      size: 18, color: AppColors.muted),
                  onSelected: (v) async {
                    if (v == 'edit') {
                      onEdit();
                      return;
                    }
                    if (v != 'remove') return;
                    final ok = await _confirmRemove(context);
                    if (ok) await onRemove();
                  },
                  itemBuilder: (ctx) => const [
                    PopupMenuItem(value: 'edit', child: Text('Bearbeiten')),
                    PopupMenuItem(value: 'remove', child: Text('Entfernen')),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Segment-Chip für die Detail-Sheet-Tabs — gleiches Muster wie
/// `_modeChip` im Add-Bike-Sheet, mit optionalem Zähler-Badge, damit der
/// Nutzer die Zusammenfassung sieht, ohne den Tab wechseln zu müssen.
class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.active,
    required this.onTap,
    this.badge,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.chip),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? AppColors.accent : AppColors.chipIdle,
          borderRadius: BorderRadius.circular(AppRadius.chip),
          border:
              Border.all(color: active ? AppColors.accent : AppColors.border),
        ),
        child: Text(
          badge != null && badge! > 0 ? '$label ($badge)' : label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: active ? AppColors.onAccent : AppColors.chipIdleText,
          ),
        ),
      ),
    );
  }
}

/// Platzhalter-Zeile für einen Kern-Slot ohne installiertes Bauteil —
/// macht sichtbar, was für vollständige Kompat-Checks noch fehlt, statt
/// stillschweigend zu verschweigen, dass z. B. kein Dämpfer erfasst ist.
class _GhostSlotRow extends StatelessWidget {
  const _GhostSlotRow({required this.slot, required this.onTap});

  final ComponentSlot slot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.xs),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.m,
          vertical: AppSpacing.s,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              alignment: Alignment.center,
              child: Icon(_slotIcon(slot), size: 16, color: AppColors.border),
            ),
            const SizedBox(width: AppSpacing.s),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    slot.label,
                    style:
                        const TextStyle(fontSize: 11, color: AppColors.muted),
                  ),
                  const Text(
                    'Nicht erfasst',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.muted,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.add_circle_outline,
                size: 18, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}

/// Fällige Wartung als Fortschrittsbalken statt ListTile-Fließtext.
class _MaintenanceBarRow extends StatelessWidget {
  const _MaintenanceBarRow({required this.alert, required this.onShop});

  final MaintenanceAlert alert;
  final VoidCallback onShop;

  @override
  Widget build(BuildContext context) {
    final color =
        alert.status == DueStatus.overdue ? Colors.redAccent : Colors.orange;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                alert.status == DueStatus.overdue
                    ? Icons.warning_amber
                    : Icons.schedule,
                size: 16,
                color: color,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  alert.label,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                alert.remainingLabel,
                style: const TextStyle(fontSize: 11, color: AppColors.muted),
              ),
              IconButton(
                icon: const Icon(Icons.storefront_outlined, size: 18),
                onPressed: onShop,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: alert.progressPct / 100,
              minHeight: 6,
              backgroundColor: AppColors.chipIdle,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}

/// Kennzahl-Chip (km / Std. / Wartung, Bike-Anzahl …) — glanceable statt Fließtext.
class _StatChip extends StatelessWidget {
  const _StatChip({required this.value, required this.label, this.color});

  final String value;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
        decoration: BoxDecoration(
          color: AppColors.chipIdle,
          borderRadius: BorderRadius.circular(AppRadius.chip),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: color ?? AppColors.chipIdleText,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Segmented Muskel / E-Bike — steuert die sichtbaren Untertypen.
class _AssistModeSegmented extends StatelessWidget {
  const _AssistModeSegmented({
    required this.selected,
    required this.onSelect,
  });

  final BikeAssistMode selected;
  final ValueChanged<BikeAssistMode> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final mode in BikeAssistMode.values) ...[
          if (mode != BikeAssistMode.values.first)
            const SizedBox(width: AppSpacing.s),
          Expanded(
            child: InkWell(
              onTap: () => onSelect(mode),
              borderRadius: BorderRadius.circular(AppRadius.chip),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
                decoration: BoxDecoration(
                  color:
                      selected == mode ? AppColors.accent : AppColors.chipIdle,
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                  border: Border.all(
                    color:
                        selected == mode ? AppColors.accent : AppColors.border,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      mode == BikeAssistMode.ebike
                          ? Icons.electric_bike
                          : Icons.pedal_bike,
                      size: 18,
                      color: selected == mode
                          ? AppColors.onAccent
                          : AppColors.muted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      mode == BikeAssistMode.ebike ? 'E-Bike' : 'Muskel',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: selected == mode
                            ? AppColors.onAccent
                            : AppColors.chipIdleText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Icon-Grid statt Text-Dropdown für die Kategoriewahl beim Anlegen.
class _CategoryGridPicker extends StatelessWidget {
  const _CategoryGridPicker({
    required this.selected,
    required this.onSelect,
    this.assistMode = BikeAssistMode.muscle,
  });

  final BikeCategory selected;
  final ValueChanged<BikeCategory> onSelect;
  final BikeAssistMode assistMode;

  @override
  Widget build(BuildContext context) {
    final cats = assistMode == BikeAssistMode.ebike
        ? BikeAssistUx.ebikeCategories
        : BikeAssistUx.muscleCategories;
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.s,
      crossAxisSpacing: AppSpacing.s,
      childAspectRatio: 1.15,
      children: [
        for (final c in cats)
          _CategoryTile(
            category: c,
            label: BikeAssistUx.subtypeLabel(c, assistMode),
            selected: c == selected,
            onTap: () => onSelect(c),
          ),
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.selected,
    required this.onTap,
    required this.label,
  });

  final BikeCategory category;
  final bool selected;
  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.chip),
      child: Container(
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accent.withValues(alpha: 0.14)
              : AppColors.chipIdle,
          borderRadius: BorderRadius.circular(AppRadius.chip),
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.border,
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _categoryIcon(category),
              size: 22,
              color: selected ? AppColors.accent : AppColors.muted,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: selected ? AppColors.chipIdleText : AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Laufradgröße als Choice-Chips statt Dropdown (nur 4 Optionen).
/// Durchsuchbares Textfeld mit Options-Overlay statt Dropdown — für Felder
/// mit potenziell vielen/beliebigen Katalog-Einträgen (Hersteller, Modell),
/// bei denen ein Icon-Grid nicht passt (keine feste, kleine Optionsmenge).
Widget _searchableCatalogField<T extends Object>({
  required Key key,
  required String fieldLabel,
  required String currentText,
  required List<T> options,
  required String Function(T) labelOf,
  required ValueChanged<T> onSelected,
}) {
  return Autocomplete<T>(
    key: key,
    initialValue: TextEditingValue(text: currentText),
    displayStringForOption: labelOf,
    optionsBuilder: (v) {
      if (v.text.trim().isEmpty) return options;
      final q = v.text.trim().toLowerCase();
      return options.where((o) => labelOf(o).toLowerCase().contains(q));
    },
    onSelected: onSelected,
    fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
      return TextField(
        controller: controller,
        focusNode: focusNode,
        decoration: InputDecoration(
          labelText: fieldLabel,
          prefixIcon: const Icon(Icons.search, size: 20),
        ),
      );
    },
    optionsViewBuilder: (context, onSelectedCb, opts) {
      return Align(
        alignment: Alignment.topLeft,
        child: Material(
          color: AppColors.chipIdle,
          surfaceTintColor: Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.chip),
          elevation: 4,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220),
            child: ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: opts.length,
              itemBuilder: (context, i) {
                final o = opts.elementAt(i);
                return ListTile(
                  dense: true,
                  textColor: AppColors.chipIdleText,
                  iconColor: AppColors.muted,
                  title: Text(
                    labelOf(o),
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.chipIdleText,
                    ),
                  ),
                  onTap: () => onSelectedCb(o),
                );
              },
            ),
          ),
        ),
      );
    },
  );
}

class _WheelSizeChips extends StatelessWidget {
  const _WheelSizeChips({required this.selected, required this.onSelect});

  final WheelSize selected;
  final ValueChanged<WheelSize> onSelect;

  static const _labels = {
    WheelSize.w29: '29"',
    WheelSize.w275: '27.5"',
    WheelSize.c700: '700c',
    WheelSize.b650: '650b',
  };

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.s,
      runSpacing: AppSpacing.s,
      children: [
        for (final e in _labels.entries)
          ChoiceChip(
            label: Text(e.value),
            selected: selected == e.key,
            onSelected: (_) => onSelect(e.key),
            color: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return AppColors.accent;
              }
              return AppColors.chipIdle;
            }),
            labelStyle: TextStyle(
              color: selected == e.key
                  ? AppColors.onAccent
                  : AppColors.chipIdleText,
              fontWeight: FontWeight.w600,
            ),
            side: BorderSide(
              color: selected == e.key ? AppColors.accent : AppColors.border,
            ),
          ),
      ],
    );
  }
}

/// Ordnet Kompat-Befunde beiden beteiligten Slots zu (Regel-Def-Lookup über
/// ruleCode), damit sie an jedem betroffenen Bauteil in einer Zeile
/// erscheinen — kein Textabgleich über den Regeltitel nötig.
Map<ComponentSlot, List<CompatibilityResult>> _groupCompatBySlot(
  List<CompatibilityResult> results,
) {
  final map = <ComponentSlot, List<CompatibilityResult>>{};
  for (final r in results) {
    CompatibilityRuleDef? rule;
    for (final rl in compatibilityRules) {
      if (rl.code == r.ruleCode) {
        rule = rl;
        break;
      }
    }
    if (rule == null) continue;
    map.putIfAbsent(rule.slotA, () => []).add(r);
    if (rule.slotB != rule.slotA) {
      map.putIfAbsent(rule.slotB, () => []).add(r);
    }
  }
  return map;
}

Color _verdictColor(CompatVerdict v) => switch (v) {
      CompatVerdict.compatible => const Color(0xFF4CAF50),
      CompatVerdict.conditional => Colors.orange,
      CompatVerdict.incompatible => Colors.redAccent,
      CompatVerdict.insufficientData => AppColors.muted,
    };

String _verdictShort(CompatVerdict v) => switch (v) {
      CompatVerdict.compatible => 'Passt',
      CompatVerdict.conditional => 'Prüfen',
      CompatVerdict.incompatible => 'Passt nicht',
      CompatVerdict.insufficientData => 'Unklar',
    };

IconData _slotIcon(ComponentSlot slot) => switch (slot) {
      ComponentSlot.frame => Icons.architecture,
      ComponentSlot.fork => Icons.height,
      ComponentSlot.rearShock => Icons.compress,
      ComponentSlot.headset => Icons.adjust,
      ComponentSlot.stem => Icons.horizontal_rule,
      ComponentSlot.handlebar => Icons.swap_horiz,
      ComponentSlot.grips => Icons.back_hand_outlined,
      ComponentSlot.seatpost => Icons.chair_alt_outlined,
      ComponentSlot.saddle => Icons.event_seat_outlined,
      ComponentSlot.frontHub || ComponentSlot.rearHub => Icons.trip_origin,
      ComponentSlot.frontRim ||
      ComponentSlot.rearRim =>
        Icons.panorama_fish_eye,
      ComponentSlot.tireFront || ComponentSlot.tireRear => Icons.tire_repair,
      ComponentSlot.cassette => Icons.settings,
      ComponentSlot.chain => Icons.link,
      ComponentSlot.crankset => Icons.rotate_right,
      ComponentSlot.bottomBracket => Icons.circle_outlined,
      ComponentSlot.frontDerailleur ||
      ComponentSlot.rearDerailleur =>
        Icons.tune,
      ComponentSlot.shifter => Icons.touch_app_outlined,
      ComponentSlot.brakeFront ||
      ComponentSlot.brakeRear =>
        Icons.stop_circle_outlined,
      ComponentSlot.rotorFront ||
      ComponentSlot.rotorRear =>
        Icons.album_outlined,
      ComponentSlot.motor => Icons.electric_bolt,
      ComponentSlot.battery => Icons.battery_full,
      ComponentSlot.display => Icons.speed,
      ComponentSlot.light => Icons.lightbulb_outline,
      ComponentSlot.lock => Icons.lock_outline,
      ComponentSlot.rack => Icons.luggage_outlined,
      ComponentSlot.bags => Icons.shopping_bag_outlined,
      ComponentSlot.other => Icons.more_horiz,
    };

IconData _categoryIcon(BikeCategory c) => switch (c) {
      BikeCategory.mtbTrail => Icons.terrain,
      BikeCategory.mtbAm => Icons.landscape,
      BikeCategory.mtbEnduro => Icons.bolt,
      BikeCategory.dh => Icons.south,
      BikeCategory.gravel => Icons.route,
      BikeCategory.road => Icons.directions_bike,
      BikeCategory.urban => Icons.location_city,
      BikeCategory.emtb => Icons.electric_bike,
      BikeCategory.etrekking => Icons.ev_station,
      BikeCategory.hiking => Icons.hiking,
    };

/// Horizontaler Schnellwechsel für Mehrfach-Bike-Nutzer (Pro) — ergänzt die
/// vertikale Liste (Vollübersicht/Verwaltung) um einen schnellen Weg, das
/// aktive Bike zu wechseln, ohne die Detail-Sheet öffnen zu müssen.
class _BikeSwitcher extends StatelessWidget {
  const _BikeSwitcher({required this.bikes});

  final List<Bike> bikes;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: bikes.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.s),
        itemBuilder: (context, i) => _BikeSwitcherPill(bike: bikes[i]),
      ),
    );
  }
}

class _BikeSwitcherPill extends ConsumerWidget {
  const _BikeSwitcherPill({required this.bike});

  final Bike bike;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(userProfileStoreProvider);
    final photo = store.bikePhotos[bike.id];
    final hasPhoto =
        photo != null && (isRemotePhotoRef(photo) || File(photo).existsSync());
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: bike.isActive
            ? null
            : () async {
                await ref.read(garageRepositoryProvider).setActiveBike(bike.id);
                ref.invalidate(bikesProvider);
              },
        child: Container(
          padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
          decoration: BoxDecoration(
            color: bike.isActive
                ? AppColors.forestOnDark.withValues(alpha: 0.14)
                : AppColors.chipIdle,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: bike.isActive ? AppColors.forestOnDark : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: AppColors.forest.withValues(alpha: 0.25),
                backgroundImage: !hasPhoto
                    ? null
                    : (isRemotePhotoRef(photo)
                        ? NetworkImage(photo) as ImageProvider
                        : FileImage(File(photo))),
                child: hasPhoto
                    ? null
                    : const Icon(Icons.pedal_bike,
                        size: 13, color: AppColors.muted),
              ),
              const SizedBox(width: 8),
              Text(
                bike.name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color:
                      bike.isActive ? AppColors.chipIdleText : AppColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Icon-Grid statt 15-Punkte-Dropdown für die Slot-Wahl beim Installieren.
class _SlotGridPicker extends StatelessWidget {
  const _SlotGridPicker({
    required this.selected,
    required this.onSelect,
    this.slots,
  });

  final ComponentSlot selected;
  final ValueChanged<ComponentSlot> onSelect;
  final List<ComponentSlot>? slots;

  @override
  Widget build(BuildContext context) {
    final list = slots ?? _trackableSlots;
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.s,
      crossAxisSpacing: AppSpacing.s,
      childAspectRatio: 0.95,
      children: [
        for (final s in list)
          _SlotTile(
            slot: s,
            selected: s == selected,
            onTap: () => onSelect(s),
          ),
      ],
    );
  }
}

class _SlotTile extends StatelessWidget {
  const _SlotTile({
    required this.slot,
    required this.selected,
    required this.onTap,
  });

  final ComponentSlot slot;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.chip),
      child: Container(
        decoration: BoxDecoration(
          color: selected
              ? AppColors.forestOnDark.withValues(alpha: 0.14)
              : AppColors.chipIdle,
          borderRadius: BorderRadius.circular(AppRadius.chip),
          border: Border.all(
            color: selected ? AppColors.forestOnDark : AppColors.border,
          ),
        ),
        padding:
            const EdgeInsets.symmetric(vertical: AppSpacing.xs, horizontal: 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _slotIcon(slot),
              size: 18,
              color: selected ? AppColors.forestOnDark : AppColors.muted,
            ),
            const SizedBox(height: 3),
            Text(
              slot.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9,
                height: 1.05,
                fontWeight: FontWeight.w700,
                color: selected ? AppColors.chipIdleText : AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Enum-artige Attribut-Wahl als Chips (z. B. Freilauf-Standard) statt
/// Freitext — kein Vertippen bei Werten, die die Kompat-Engine wörtlich
/// vergleicht (`equals`-Prädikat in `compatibility/engine.dart`).
class _AttrChipField extends StatelessWidget {
  const _AttrChipField({
    required this.label,
    required this.options,
    required this.value,
    required this.onSelect,
  });

  final String label;
  final List<String> options;
  final String? value;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.muted,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: AppSpacing.s,
          runSpacing: AppSpacing.xs,
          children: [
            for (final o in options)
              ChoiceChip(
                label: Text(o),
                selected: value == o,
                onSelected: (_) => onSelect(o),
                selectedColor: AppColors.accent,
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: value == o ? Colors.white : AppColors.chipIdleText,
                ),
                backgroundColor: AppColors.chipIdle,
                side: BorderSide(
                  color: value == o ? AppColors.accent : AppColors.border,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Attribut-Spec für die kuratierte Eingabe: Key aus den Kompat-Regeln
/// abgeleitet (nie eigenständig gepflegt, kann also nicht von der Engine
/// abdriften), Label + Hinweistext von Hand kuratiert.
typedef _AttrFieldSpec = ({String key, String label, String? hint});

/// Sammelt für einen Slot alle Attribut-Keys, die irgendeine Kompat-Regel
/// für diesen Slot benötigt (als slotA *oder* slotB) — direkt aus
/// `compatibilityRules`, damit die Eingabemaske nie von der Engine abweicht.
List<_AttrFieldSpec> _relevantAttrKeys(ComponentSlot slot) {
  final seen = <String>{};
  final out = <_AttrFieldSpec>[];
  for (final rule in compatibilityRules) {
    if (rule.slotA == slot) {
      for (final k in rule.requiresA) {
        if (seen.add(k)) {
          out.add((key: k, label: _attrLabel(k), hint: rule.howToObtain[k]));
        }
      }
    }
    if (rule.slotB == slot) {
      for (final k in rule.requiresB) {
        if (seen.add(k)) {
          out.add((key: k, label: _attrLabel(k), hint: rule.howToObtain[k]));
        }
      }
    }
  }
  return out;
}

const Map<String, String> _attrLabels = {
  'freehub_standard': 'Freilauf-Standard',
  'rear_spacing': 'Hinterbau-Einbaubreite',
  'eye_to_eye_mm': 'Einbaulänge (Auge-zu-Auge)',
  'stroke_mm': 'Hub',
  'mount_type': 'Montage-Typ',
  'shock_eye_to_eye_mm': 'Rahmenvorgabe: Einbaulänge',
  'shock_stroke_mm': 'Rahmenvorgabe: Hub',
  'shock_mount_type': 'Rahmenvorgabe: Montage-Typ',
  'steerer_type': 'Gabelschaft',
  'brake_mount': 'Bremssattel-Aufnahme',
  'brake_mount_rear': 'Rahmen: Bremsaufnahme hinten',
  'rotor_mount': 'Scheiben-Aufnahme',
  'tire_width_mm': 'Reifenbreite',
  'internal_rim_width_mm': 'Felgen-Maulweite (innen)',
  'max_tire_width_mm': 'Rahmen: max. Reifenfreigang',
  'handlebar_clamp_mm': 'Klemmdurchmesser',
  'stem_clamp_mm': 'Vorbau-Klemmung',
  'seatpost_diameter_mm': 'Durchmesser',
  'min_insertion_mm': 'Min. Einstecktiefe',
  'max_seatpost_insertion_mm': 'Rahmen: max. Einstecktiefe',
  'crank_axle': 'Kurbelwelle',
  'bb_standard': 'Innenlager-Standard',
  'motor_interface': 'Motor-Interface',
  'axle_front': 'Achse',
};

String _attrLabel(String key) => _attrLabels[key] ?? key;

/// Bekannte Wertebereiche für Attribut-Keys, die in den Kompat-Regeln als
/// Standard-Enum vorkommen. Nicht vollständig — alles außerhalb bleibt ein
/// (numerisches oder freies) Textfeld, kein Rätselraten mit Fantasiewerten.
const Map<String, List<String>> _knownAttrOptions = {
  'freehub_standard': ['microspline', 'xd', 'xdr', 'hg'],
  'rear_spacing': ['148x12', '142x12', '135x9', '157x12'],
  'mount_type': ['trunnion', 'eyelet'],
  'shock_mount_type': ['trunnion', 'eyelet'],
  'steerer_type': ['tapered_1_5', '1_1_8'],
  'brake_mount': ['post_mount', 'flat_mount', 'is'],
  'brake_mount_rear': ['post_mount', 'flat_mount', 'is'],
  'rotor_mount': ['center_lock', '6bolt'],
  'bb_standard': ['BSA73', 'T47', 'PF92', 'BB30'],
  'crank_axle': ['DUB', '24mm', '30mm', 'ISIS'],
  'motor_interface': [
    'bosch_smart_system',
    'bosch_gen4',
    'shimano_steps',
    'yamaha_pw',
    'specialized_sl',
    'bosch_cx',
  ],
  'axle_front': ['15x100', '15x110_boost', '9x100_qr', '20x110'],
};

/// Garage: CSC-/Radsensor an aktives Bike koppeln (speichert in [BikeBleStore]).
class _BleSensorTile extends ConsumerStatefulWidget {
  const _BleSensorTile({
    required this.bikeId,
    this.isEbike = false,
  });

  final String bikeId;
  final bool isEbike;

  @override
  ConsumerState<_BleSensorTile> createState() => _BleSensorTileState();
}

class _BleSensorTileState extends ConsumerState<_BleSensorTile> {
  BikeBleDevice? _saved;
  bool _busy = false;
  String? _status;

  @override
  void initState() {
    super.initState();
    unawaited(_reload());
  }

  Future<void> _reload() async {
    final d = await ref.read(bikeBleStoreProvider).deviceForBike(widget.bikeId);
    if (mounted) setState(() => _saved = d);
  }

  Future<void> _pair() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _status = 'Suche Geräte …';
    });
    try {
      final ok = await showBlePairSheet(
        context,
        bikeId: widget.bikeId,
        isEbike: widget.isEbike,
      );
      await _reload();
      if (!mounted) return;
      if (ok) {
        final ble = ref.read(bleCoreProvider);
        setState(() {
          _status = ble.connectedDeviceName != null
              ? 'Gekoppelt: ${ble.connectedDeviceName}'
              : 'Gerät gekoppelt';
        });
      } else {
        setState(() => _status = null);
      }
    } catch (e) {
      if (mounted) setState(() => _status = 'Kopplung fehlgeschlagen');
      debugPrint('garage ble pair: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _unlink() async {
    await ref.read(bikeBleStoreProvider).removeForBike(widget.bikeId);
    try {
      await ref.read(bleCoreProvider).disconnectCsc();
    } catch (_) {}
    await _reload();
    if (mounted) setState(() => _status = 'Sensor entfernt');
  }

  @override
  Widget build(BuildContext context) {
    final name = _saved?.name?.trim();
    final line = _saved == null
        ? 'Bluetooth nicht verbunden'
        : (name != null && name.isNotEmpty ? name : 'Gerät gekoppelt');
    final hint = widget.isEbike
        ? 'Bosch, Shimano STEPS oder CSC. Display einschalten.'
        : 'Sensor am Rad, nicht am Fahrer.';

    return InkWell(
      onTap: _busy ? null : () => unawaited(_pair()),
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
        child: Row(
          children: [
            Icon(
              Icons.bluetooth,
              size: 18,
              color: _saved != null ? AppColors.forestOnDark : AppColors.muted,
            ),
            const SizedBox(width: AppSpacing.s),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    line,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_saved == null)
                    Text(
                      hint,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                      ),
                    ),
                  if (_status != null)
                    Text(
                      _status!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                      ),
                    ),
                ],
              ),
            ),
            if (_busy)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else if (_saved != null)
              TextButton(
                onPressed: () => unawaited(_unlink()),
                child: const Text('Entfernen'),
              ),
          ],
        ),
      ),
    );
  }
}
