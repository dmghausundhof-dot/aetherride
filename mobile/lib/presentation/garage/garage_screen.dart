import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_ext.dart';
import '../../data/local/app_database.dart';
import '../../data/garage/stand_photo_file.dart';
import '../../data/sensor/bike_ble_store.dart';
import '../../domain/ble.dart';
import '../../domain/ble/bike_ble_kind.dart';
import '../../domain/ble/ble_link_status.dart';
import '../../domain/ble/garage_ble_live.dart';
import '../../domain/hud_bike_peek.dart';
import '../../domain/bike.dart';
import '../../domain/compatibility/engine.dart';
import '../../domain/compatibility/rules.dart';
import '../../domain/component.dart';
import '../../domain/garage/die_box.dart';
import '../../domain/garage/bike_schema_mapper.dart';
import '../../domain/garage/pressure_unit.dart';
import '../../domain/garage/werkstatt_setup.dart';
import '../../domain/maintenance/intervals.dart';
import '../../domain/setup/fingerprint.dart';
import '../../domain/setup/sag_guide.dart';
import '../../providers/app_providers.dart';
import '../../providers/ride_providers.dart';
import '../billing/upgrade_screen.dart';
import '../shared/empty_state.dart';
import 'add_bike_sheet.dart';
import 'bike_identity_card.dart';
import 'bike_overview.dart';
import 'bike_receipts_panel.dart';
import 'garage_chrome.dart';
import 'ble_pair_sheet.dart';
import 'die_box_surface.dart';
import 'family_rider_strip.dart';
import 'rad_stand_frame.dart';
import 'bike_schema_hotspots.dart';
import 'pressure_log_dialog.dart';
import 'service_care_card.dart';
import 'setup_sheet.dart';
import 'werkstatt_csc_bar_button.dart';
import 'werkstatt_parts_door.dart';

class GarageScreen extends ConsumerStatefulWidget {
  const GarageScreen({super.key});

  @override
  ConsumerState<GarageScreen> createState() => _GarageScreenState();
}

class _GarageScreenState extends ConsumerState<GarageScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_cropLegacyStandPhotos());
    });
  }

  Future<void> _cropLegacyStandPhotos() async {
    final changed = await ensureStandCroppedBikePhotos(
      store: ref.read(userProfileStoreProvider),
    );
    if (changed && mounted) setState(() {});
  }

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
        : garageList.firstWhere((b) => b.isActive,
            orElse: () => garageList.first);

    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(focused?.name ?? l10n.navWorkshop),
        actionsPadding: const EdgeInsets.only(right: AppSpacing.m),
        actions: [
          if (focused != null)
            WerkstattCscBarButton(
              bikeId: focused.id,
              isEbike: focused.isEbike,
              wheelSize: focused.wheelSize,
            ),
          if (garageList.isNotEmpty)
            IconButton(
              tooltip: l10n.garageAddAnother,
              onPressed: () => _openAddBike(context, ref),
              icon: const Icon(Icons.add),
            ),
        ],
      ),
      body: bikes.when(
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: EmptyStateIllustration(
                title: l10n.garageEmptyTitle,
                message: l10n.garageEmptyMessage,
                actionLabel: l10n.garageAddBike,
                actionIcon: Icons.add,
                illustration: const RadEmptyStandMark(height: 140),
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
            padding: const EdgeInsets.all(AppSpacing.l),
            children: [
              if (sorted.length > 1) ...[
                GarageSectionTitle(label: l10n.garageQuickSwitch),
                const SizedBox(height: AppSpacing.s),
                _BikeSwitcher(
                  bikes: sorted,
                  onOpenActive: () {
                    final active = sorted.firstWhere(
                      (b) => b.isActive,
                      orElse: () => sorted.first,
                    );
                    _openDetail(context, ref, active);
                  },
                ),
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
                  final logs =
                      ref.watch(userProfileStoreProvider).maintenanceLogs;
                  final due = listDueMaintenance(
                    bike: active,
                    components: comps,
                    logs: logs,
                  );
                  return DieBoxSurface(
                    bike: active,
                    components: comps,
                    due: due,
                    compact: true,
                    showOnBike: false,
                    showHeuteRest: false,
                    onOpenDetail: () => _openDetail(context, ref, active),
                    onChanged: () => ref.invalidate(bikesProvider),
                    onOpenMaintenance: () => _openDetail(
                      context,
                      ref,
                      active,
                      initialTab: _DetailTab.wartung,
                    ),
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
                    onPairSensor: () => showBlePairSheet(
                      context,
                      bikeId: active.id,
                      isEbike: active.hasElectricAssist,
                    ),
                  );
                },
              ),
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
        builder: (ctx) {
          final l10n = AppLocalizations.of(ctx);
          return AlertDialog(
            title: Text(l10n.garageFreeOneBikeTitle),
            content: Text(l10n.garageFreeOneBikeBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(ctx, false);
                  openUpgradeScreen(context);
                },
                child: Text(l10n.garageUnlockPro),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l10n.garageAddAnyway),
              ),
            ],
          );
        },
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
      builder: (ctx) => AddBikeSheet(initialCategory: initialCategory),
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
      if (created != null && context.mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.garageCreatedAtStand(created.name))),
        );
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
      useSafeArea: true,
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

/// Alle installierbaren Slots außer `other` (Sammelbecken) — bewusst
/// breiter als das App-weite `coreInstallSlots` (Shop-Filter/Legacy-
/// Subset ohne Vorderrad-Slots). Ohne Steuersatz/Nabe-vorn/Felge-vorn/
/// Reifen-vorn in der Auswahl können 4 der 15 Kompat-Regeln (Gabel↔
/// Steuersatz, Gabel↔Vorderradachse, Reifen/Felge vorn, Scheibe vorn↔Nabe)
/// nie auslösen — nicht die Engine ist blind, die UI bot die Slots nie an.
final List<ComponentSlot> _trackableSlots =
    ComponentSlot.values.where((s) => s != ComponentSlot.other).toList();

enum _DetailTab { box, overview, teile, wartung, setup }

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
  // Segmente in einer ListView (kein TabBarView / kein BottomSheet —
  // verschachteltes Sheet war auf S25 leer).
  late _DetailTab _tab = widget.initialTab == _DetailTab.box
      ? _DetailTab.overview
      : widget.initialTab;

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

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx);
        return AlertDialog(
          title: Text(l10n.garageDeleteBikeTitle),
          content: Text(l10n.garageDeleteBikeBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.delete),
            ),
          ],
        );
      },
    );
    if (ok != true) return;
    await ref.read(garageRepositoryProvider).deleteBike(widget.bikeId);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _editIdentity() async {
    final bike = _bike;
    if (bike == null) return;
    final saved = await showBikeIdentitySheet(context, ref, bike);
    if (saved) await _load();
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
      useSafeArea: true,
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
    final logs = ref.watch(userProfileStoreProvider).maintenanceLogs;
    final due = listDueMaintenance(
      bike: bike,
      components: _components,
      logs: logs,
    );
    final upcoming = listDueMaintenance(
      bike: bike,
      components: _components,
      logs: logs,
      includeUpcoming: true,
    );
    final plan = planWerkstattSetup(bike: bike, components: _components);
    final listed = planDieBox(bike: bike, components: _components).onBike;
    final bySlot = _groupCompatBySlot(_compat);
    final installedSlots = _components.map((c) => c.slot).toSet();
    final schemaPlan = planBikeSchema(
      category: bike.category,
      isEbike: bike.hasElectricAssist,
      hasRearShock: (bike.travelRearMm ?? 0) > 0 ||
          _components.any(
            (c) => c.isInstalled && c.slot == ComponentSlot.rearShock,
          ),
    );
    final missingSlots = ghostSlotsFor(
      addable: addableSlotsFor(plan),
      installed: installedSlots,
      schemaSlots: schemaPlan.hotspotSlots,
    );
    final okCount =
        _compat.where((r) => r.verdict == CompatVerdict.compatible).length;
    final warnCount =
        _compat.where((r) => r.verdict == CompatVerdict.conditional).length;
    final badCount =
        _compat.where((r) => r.verdict == CompatVerdict.incompatible).length;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      key: const Key('bike-detail'),
      appBar: AppBar(
        title: Text(bike.name),
        actionsPadding: const EdgeInsets.only(right: AppSpacing.m),
        actions: [
          WerkstattCscBarButton(
            bikeId: bike.id,
            isEbike: bike.isEbike,
            wheelSize: bike.wheelSize,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (v) {
              if (v == 'delete') unawaited(_delete());
              if (v == 'edit') unawaited(_editIdentity());
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'edit',
                child: Text(l10n.garageEditBike),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Text(l10n.garageDeleteBike),
              ),
            ],
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.l,
              AppSpacing.s,
              AppSpacing.l,
              0,
            ),
            sliver: SliverToBoxAdapter(
              child: DieBoxSurface(
                bike: bike,
                components: _components,
                due: due,
                compact: true,
                showOnBike: false,
                showHeuteRest: false,
                onChanged: () => unawaited(_load()),
                onOpenMaintenance: () =>
                    setState(() => _tab = _DetailTab.wartung),
                onInstallSlot: (slot) => _installComponent(initialSlot: slot),
                onEditComponent: (c) => _installComponent(existing: c),
                onPairSensor: () => showBlePairSheet(
                  context,
                  bikeId: bike.id,
                  isEbike: bike.hasElectricAssist,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: FamilyRiderStrip(
              bikeId: bike.id,
              onChanged: () => unawaited(_load()),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _PinnedGarageTabs(
              height: 52,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.l,
                  4,
                  AppSpacing.l,
                  4,
                ),
                child: _FadeHScroll(
                  children: [
                    _TabChip(
                      key: const Key('garage-tab-overview'),
                      label: l10n.garageTabOverview,
                      active: _tab == _DetailTab.overview,
                      onTap: () => setState(() => _tab = _DetailTab.overview),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    _TabChip(
                      key: const Key('garage-tab-teile'),
                      label: l10n.garageParts,
                      badge: listed.length,
                      active: _tab == _DetailTab.teile,
                      onTap: () => setState(() => _tab = _DetailTab.teile),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    _TabChip(
                      key: const Key('garage-tab-wartung'),
                      label: l10n.garageMaintenance,
                      badge: due.length,
                      active: _tab == _DetailTab.wartung,
                      onTap: () => setState(() => _tab = _DetailTab.wartung),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    _TabChip(
                      key: const Key('garage-tab-setup'),
                      label: l10n.garageSetup,
                      active: _tab == _DetailTab.setup,
                      onTap: () => setState(() => _tab = _DetailTab.setup),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.l,
              AppSpacing.s,
              AppSpacing.l,
              AppSpacing.xxl + MediaQuery.paddingOf(context).bottom,
            ),
            sliver: SliverToBoxAdapter(
              child: KeyedSubtree(
                key: const Key('garage-more-on-bike'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_tab == _DetailTab.overview) ...[
                      _BleSensorTile(
                        bikeId: bike.id,
                        isEbike: bike.hasElectricAssist,
                        wheelSize: bike.wheelSize,
                      ),
                      const SizedBox(height: AppSpacing.m),
                      BikeIdentityCard(
                        bike: bike,
                        onEdit: () => unawaited(_editIdentity()),
                        onChanged: () => unawaited(_load()),
                      ),
                      const SizedBox(height: AppSpacing.m),
                      BikeTechDetailsPanel(
                        bike: bike,
                        initiallyExpanded: false,
                      ),
                    ],
                    if (_tab == _DetailTab.teile) ...[
                      BikeSchemaHotspots(
                        bike: bike,
                        components: _components,
                        due: due,
                        onTapSlot: (slot) =>
                            _installComponent(initialSlot: slot),
                      ),
                      const SizedBox(height: AppSpacing.m),
                      WerkstattPartsDoor(
                        bikeId: bike.id,
                        lookupOnly: true,
                      ),
                      const SizedBox(height: AppSpacing.m),
                      Row(
                        children: [
                          Expanded(
                            child: GarageSectionTitle(
                              label: l10n.garageYourParts,
                              mark: 'parts',
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _installComponent,
                            icon: const Icon(Icons.add, size: 18),
                            label: Text(l10n.garageInstall),
                          ),
                        ],
                      ),
                      if (okCount + warnCount + badCount > 0) ...[
                        const SizedBox(height: AppSpacing.xxs),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            if (okCount > 0)
                              GarageFactChip(
                                label: l10n.garageCompatFits(okCount),
                                color: AppColors.sageOnDark,
                              ),
                            if (warnCount > 0)
                              GarageFactChip(
                                label: l10n.garageCompatCheck(warnCount),
                                color: AppColors.warning,
                              ),
                            if (badCount > 0)
                              GarageFactChip(
                                label: l10n.garageCompatNoFit(badCount),
                                color: AppColors.error,
                              ),
                          ],
                        ),
                      ],
                      const SizedBox(height: AppSpacing.s),
                      if (listed.isEmpty)
                        GarageInviteCard(
                          title: l10n.garagePartsEmptyTitle,
                          hint: l10n.garagePartsEmptyHint,
                          icon: Icons.add,
                          onTap: _installComponent,
                        )
                      else ...[
                        for (final g in ComponentGroup.values)
                          if (listed.any((c) => c.slot.group == g))
                            Theme(
                              data: Theme.of(context).copyWith(
                                dividerColor: Colors.transparent,
                              ),
                              child: ExpansionTile(
                                initiallyExpanded: plan.emphasisSlots.any(
                                      (s) => s.group == g,
                                    ) ||
                                    g == ComponentGroup.wheels ||
                                    listed.any(
                                      (c) =>
                                          c.slot.group == g &&
                                          (bySlot[c.slot]?.isNotEmpty ?? false),
                                    ),
                                tilePadding: EdgeInsets.zero,
                                childrenPadding: EdgeInsets.zero,
                                title: Text(
                                  l10n.garageGroupCount(
                                    l10n.componentGroupLabel(g),
                                    listed
                                        .where((c) => c.slot.group == g)
                                        .length,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                children: [
                                  for (final c in listed.where(
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
                                      onEdit: () =>
                                          _installComponent(existing: c),
                                      onTapFindings: (findings) =>
                                          _openSlotFindings(
                                              context, c, findings),
                                    ),
                                ],
                              ),
                            ),
                      ],
                      if (listed.isNotEmpty && missingSlots.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.s),
                        GarageSectionTitle(
                          label: l10n.garageMissingInvite,
                          mark: 'add',
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        for (final s in missingSlots)
                          GarageGhostRow(
                            title: l10n.componentSlotLabel(s),
                            hint: l10n.garageGhostInvite,
                            onTap: () => _installComponent(initialSlot: s),
                          ),
                      ],
                    ],
                    if (_tab == _DetailTab.wartung) ...[
                      ServiceCareCard(
                        bike: bike,
                        onChanged: () => unawaited(_load()),
                      ),
                      const SizedBox(height: AppSpacing.l),
                      BikeReceiptsPanel(
                        bike: bike,
                        components: listed,
                        onChanged: () => unawaited(_load()),
                      ),
                      const SizedBox(height: AppSpacing.l),
                      WerkstattPartsDoor(
                        bikeId: bike.id,
                        slot: due.isEmpty ? null : due.first.slot.apiId,
                        lookupOnly: true,
                      ),
                      const SizedBox(height: AppSpacing.m),
                      GarageSectionTitle(
                        label: l10n.garageMaintenance,
                        mark: 'care',
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        l10n.garageMaintThresholdHint,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.muted),
                      ),
                      const SizedBox(height: AppSpacing.s),
                      if (upcoming.isEmpty)
                        GarageInviteCard(
                          title: bike.odometerKm < 50 && bike.hours < 2
                              ? l10n.garageMaintEmptyLowKm
                              : maintenanceEmptyIsHonestOk(
                                  bike: bike,
                                  logs: logs,
                                )
                                  ? l10n.garageMaintEmpty
                                  : l10n.garageMaintEmptyNoInspection,
                          hint: l10n.garageMaintThresholdHint,
                          icon: Icons.schedule,
                        )
                      else
                        for (final a in upcoming.take(8))
                          _MaintenanceBarRow(
                            alert: a,
                            onDone: () async {
                              await ref
                                  .read(userProfileStoreProvider)
                                  .addMaintenanceLog(
                                    bikeId: bike.id,
                                    activity: a.label,
                                    notes: a.sourceLabel,
                                    odometerKm: bike.odometerKm,
                                    hours: bike.hours,
                                  );
                              await _load();
                            },
                          ),
                    ],
                    if (_tab == _DetailTab.setup) ...[
                      GarageSectionTitle(
                        label: l10n.garageSetupTabTitle,
                        mark: 'setup',
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        plan.showsFahrwerk
                            ? l10n.garageSetupTabHint
                            : l10n.garageSetupTabHintTires,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.muted),
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
      _showEvidence(context, findings.first, slot: component.slot);
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx);
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            0,
            AppSpacing.xl,
            AppSpacing.xxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const GarageSheetHandle(),
              GarageSheetTitle(
                title:
                    '${l10n.componentSlotLabel(component.slot)} · ${component.displayName}',
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
                      _showEvidence(context, r, slot: component.slot);
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
                                r.ruleCode,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.accent,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xxs),
                              Text(
                                l10n.compatTitleFor(r),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xxs),
                              Text(
                                l10n.compatExplain(r),
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

  void _showEvidence(
    BuildContext context,
    CompatibilityResult r, {
    ComponentSlot? slot,
  }) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            0,
            AppSpacing.xl,
            AppSpacing.xxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const GarageSheetHandle(),
              GarageSheetTitle(title: l10n.garageFitTitle),
              const SizedBox(height: AppSpacing.s),
              Text(
                r.ruleCode,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(l10n.compatTitleFor(r),
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: AppSpacing.s),
              Text(l10n.garageFitStatus(l10n.compatVerdictShort(r.verdict))),
              Text(
                l10n.garageFitSeverity(
                  r.severity == RuleSeverity.safetyCritical
                      ? l10n.garageFitSeveritySafety
                      : l10n.garageFitSeverityFunctional,
                ),
                style: const TextStyle(color: AppColors.muted, fontSize: 13),
              ),
              const SizedBox(height: AppSpacing.m),
              Text(
                l10n.garageFitExplained,
                style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(l10n.compatExplain(r)),
              if (r.conditionText != null && r.conditionText!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.s),
                Text(l10n.garageFitCondition(l10n.compatConditionFor(r))),
              ],
              if (r.safetyWorkshopHint != null &&
                  r.safetyWorkshopHint!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.s),
                Text(
                  l10n.garageFitHint(
                    l10n.compatWorkshopFor(r.safetyWorkshopHint) ??
                        r.safetyWorkshopHint!,
                  ),
                ),
              ],
              if (r.missingAttributes.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.m),
                Text(
                  l10n.garageFitMissing,
                  style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                for (final m in r.missingAttributes)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Text('· ${m.key}: ${l10n.compatHowTo(m.key)}'),
                  ),
              ],
              if (r.sourceUrl != null && r.sourceUrl!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.s),
                Text(
                  l10n.garageFitSource(r.sourceUrl!),
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
              if (r.verdict == CompatVerdict.incompatible) ...[
                const SizedBox(height: AppSpacing.l),
                WerkstattPartsDoor(
                  bikeId: widget.bikeId,
                  slot: slot?.apiId,
                  lookupOnly: true,
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
    // Default-Attribute weggelassen: Fake-Maße dürfen nicht als „passt“ gelten.
    await ref.read(componentRepositoryProvider).install(
          bikeId: widget.bikeId,
          slot: _slot,
          manufacturer: _manufacturer.text,
          model: _model.text,
          catalogModelId: _catalogModelId,
          attributes: attrs,
        );
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bottom = MediaQuery.viewInsetsOf(context).bottom +
        MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        0,
        AppSpacing.xl,
        AppSpacing.xl + bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const GarageSheetHandle(),
            GarageSheetTitle(
              title: _isEdit ? l10n.garageEditPart : l10n.garageInstallPart,
            ),
            const SizedBox(height: AppSpacing.m),
            Text(l10n.garageSlotHeading,
                style: Theme.of(context).textTheme.labelLarge),
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
              controller: _manufacturer,
              decoration: InputDecoration(labelText: l10n.garageManufacturer),
            ),
            const SizedBox(height: AppSpacing.s),
            TextField(
              controller: _model,
              decoration: InputDecoration(labelText: l10n.garageBrandModel),
            ),
            if (_catalogModelId != null) ...[
              const SizedBox(height: AppSpacing.s),
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.sageOnDark.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    l10n.garageCatalogPicked,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.sageOnDark,
                    ),
                  ),
                ),
              ),
            ],
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              title: Text(
                l10n.garageCatalogOptional,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              children: [
                TextField(
                  controller: _catalogQ,
                  decoration: InputDecoration(
                    labelText: l10n.garageSearchParts,
                    hintText: l10n.garageSearchPartsHint,
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
                if (_hits.isNotEmpty)
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
                          leading: Icon(
                            _slotIcon(_slot),
                            size: 18,
                            color: AppColors.muted,
                          ),
                          title: Text(
                            '${h.manufacturer} ${h.model}',
                            style: const TextStyle(fontSize: 13),
                          ),
                          subtitle: selected
                              ? Text(
                                  l10n.garageCatalogPicked,
                                  style: const TextStyle(fontSize: 11),
                                )
                              : null,
                          onTap: () => _pickCatalog(h),
                        );
                      },
                    ),
                  )
                else if (!_searching)
                  Padding(
                    padding: const EdgeInsets.only(
                      top: AppSpacing.xs,
                      bottom: AppSpacing.s,
                    ),
                    child: Text(
                      l10n.garageNoHitsShort,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                      ),
                    ),
                  ),
              ],
            ),
            if (_relevantAttrKeys(_slot, l10n).isNotEmpty) ...[
              const SizedBox(height: AppSpacing.m),
              Text(
                l10n.garageCompatAttrs(l10n.componentSlotLabel(_slot)),
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                l10n.garageCompatAttrsHint,
                style: const TextStyle(fontSize: 11, color: AppColors.muted),
              ),
              const SizedBox(height: AppSpacing.s),
              for (final f in _relevantAttrKeys(_slot, l10n))
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
              title: Text(
                l10n.garageExtraAttr,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              children: [
                TextField(
                  controller: _attrKey,
                  decoration: InputDecoration(
                    labelText: l10n.garageAttrKey,
                    hintText: 'z. B. hub_spacing_special',
                  ),
                ),
                const SizedBox(height: AppSpacing.s),
                TextField(
                  controller: _attrVal,
                  decoration: InputDecoration(labelText: l10n.garageAttrValue),
                ),
                const SizedBox(height: AppSpacing.s),
              ],
            ),
            const SizedBox(height: AppSpacing.s),
            FilledButton(
              onPressed: _busy ? null : _save,
              child: Text(_isEdit ? l10n.save : l10n.garageInstallPart),
            ),
          ],
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
    final plan = planWerkstattSetup(bike: bike, components: components);
    final setupAsync = ref.watch(currentSetupProvider(bike.id));
    final usesBar =
        resolvePressureUsesBar(bike.category, store.pressureUnitPref);
    final fp = SetupFingerprint.fromSetup(
      setupAsync.valueOrNull,
      usesBar: usesBar,
    );
    final weight = store.effectiveWeightKg;
    final forkEst = plan.showsFahrwerk
        ? estimateAirPsi(
            riderWeightKg: weight,
            bikeWeightKg: bike.owner.weightKg,
            category: bike.category,
            end: 'fork',
            travelMm: bike.travelFrontMm?.toDouble(),
          )
        : null;

    return Container(
      decoration: garageCardDecoration(),
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Column(
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
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () async {
                await logBikePressure(
                  context: context,
                  ref: ref,
                  bike: bike,
                  existingSetups: [
                    if (setupAsync.valueOrNull != null) setupAsync.valueOrNull!,
                  ],
                );
                await onUpdated();
              },
              child: Text(l10n.garagePressureChange),
            ),
          ),
          if (plan.showsFahrwerk) ...[
            Text(
              l10n.werkstattSetupSuspension,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            Text(
              l10n.garageSagGuideHint,
              style: const TextStyle(fontSize: 11, color: AppColors.muted),
            ),
            Text(
              l10n.garageSagWeightHint(
                weight.toStringAsFixed(0),
                forkEst == null
                    ? ''
                    : l10n.garageSagWeightFork('${forkEst.psiTarget}'),
              ),
              style: const TextStyle(fontSize: 11, color: AppColors.muted),
            ),
            const SizedBox(height: AppSpacing.xs),
            TextButton(
              onPressed: () {
                showDialog<void>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(l10n.garageMeasureSag),
                    content: Text(
                      l10n.sagMeasureStepsFor('fork').join('\n\n'),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(l10n.ok),
                      ),
                    ],
                  ),
                );
              },
              child: Text(l10n.garageShowMeasureSteps),
            ),
          ] else ...[
            Text(
              l10n.werkstattSetupTires,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            if (plan.wheelLabel != null)
              Text(
                l10n.werkstattSetupWheel(plan.wheelLabel!),
                style: const TextStyle(fontSize: 13),
              ),
          ],
          const SizedBox(height: AppSpacing.m),
          _NumberEditRow(
            label: l10n.garageOdometer,
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
                    activity: 'odo_updated',
                    odometerKm: v,
                    hours: bike.hours,
                    notes: l10n.garageLogManualKm(v.toStringAsFixed(0)),
                  );
              ref.invalidate(bikesProvider);
              await onUpdated();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(l10n.garageOdoStand(v.toStringAsFixed(0)))),
                );
              }
            },
          ),
          const SizedBox(height: AppSpacing.s),
          _NumberEditRow(
            label: l10n.garageOperatingHours,
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
                    activity: 'hours_updated',
                    odometerKm: bike.odometerKm,
                    hours: v,
                    notes: l10n.garageLogManualHours(v.toStringAsFixed(1)),
                  );
              ref.invalidate(bikesProvider);
              await onUpdated();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content:
                          Text(l10n.garageHoursStand(v.toStringAsFixed(1)))),
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
                  title: Text(l10n.garageAddKmNoGps),
                  content: TextField(
                    controller: controller,
                    autofocus: true,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration:
                        InputDecoration(labelText: l10n.garageDistanceKm),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(l10n.cancel),
                    ),
                    FilledButton(
                      onPressed: () {
                        final v = double.tryParse(
                            controller.text.replaceAll(',', '.'));
                        Navigator.pop(ctx, v);
                      },
                      child: Text(l10n.add),
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
                    content: Text(
                      l10n.garageKmImported(result.toStringAsFixed(1)),
                    ),
                  ),
                );
              }
            },
            icon: const Icon(Icons.add_road, size: 18),
            label: Text(l10n.garageImportKm),
          ),
          const SizedBox(height: AppSpacing.m),
          Text(
            l10n.garageMaintLog,
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
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xxs),
                  child: Text(
                    l10n.garageMaintLogEmpty,
                    style:
                        const TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                ),
              ];
            }
            return [
              for (final e in logs)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(
                    '${e['date'] ?? '—'} · ${l10n.garageLogActivityLabel('${e['activity'] ?? ''}')}'
                    '${e['odometerKm'] != null ? ' · ${(e['odometerKm'] as num).toStringAsFixed(0)} km' : ''}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
            ];
          }(),
        ],
      ),
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
    return Material(
      color: AppColors.chipIdle,
      borderRadius: BorderRadius.circular(AppRadius.chip),
      child: InkWell(
        onTap: () => _edit(context),
        borderRadius: BorderRadius.circular(AppRadius.chip),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.m,
              vertical: AppSpacing.s,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.chip),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.muted,
                        ),
                      ),
                      Text(
                        '${value.toStringAsFixed(decimals)} $unit',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.edit_outlined,
                    size: 20, color: AppColors.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _edit(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final controller =
        TextEditingController(text: value.toStringAsFixed(decimals));
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.garageSetNamed(label)),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: label, suffixText: unit),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              final v = double.tryParse(controller.text.replaceAll(',', '.'));
              Navigator.pop(ctx, v);
            },
            child: Text(l10n.save),
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
    final l10n = AppLocalizations.of(context);
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.garageRemovePartTitle),
            content: Text(
              l10n.garageRemovePartBody(
                l10n.componentSlotLabel(component.slot),
                component.displayName,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l10n.remove),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
          color: AppColors.error.withValues(alpha: 0.85),
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
            borderRadius: BorderRadius.circular(AppRadius.chip),
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
                      l10n.componentSlotLabel(component.slot),
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
                  l10n.compatVerdictShort(verdict),
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
                  tooltip: l10n.garageOptions,
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
                  itemBuilder: (ctx) => [
                    PopupMenuItem(value: 'edit', child: Text(l10n.edit)),
                    PopupMenuItem(value: 'remove', child: Text(l10n.remove)),
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

class _FadeHScroll extends StatefulWidget {
  const _FadeHScroll({required this.children});

  final List<Widget> children;

  @override
  State<_FadeHScroll> createState() => _FadeHScrollState();
}

class _FadeHScrollState extends State<_FadeHScroll> {
  final _controller = ScrollController();
  bool _start = false;
  bool _end = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_update);
    WidgetsBinding.instance.addPostFrameCallback((_) => _update());
  }

  @override
  void didUpdateWidget(covariant _FadeHScroll oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _update());
  }

  @override
  void dispose() {
    _controller.removeListener(_update);
    _controller.dispose();
    super.dispose();
  }

  void _update() {
    if (!_controller.hasClients) return;
    final p = _controller.position;
    final overflow = p.maxScrollExtent > 2;
    final start = overflow && p.pixels > 2;
    final end = overflow && p.pixels < p.maxScrollExtent - 2;
    if (start != _start || end != _end) {
      setState(() {
        _start = start;
        _end = end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final fade = Theme.of(context).scaffoldBackgroundColor;
    return Stack(
      children: [
        ListView(
          key: const Key('garage-tab-scroller'),
          controller: _controller,
          scrollDirection: Axis.horizontal,
          children: widget.children,
        ),
        if (_start)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 28,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [fade, fade.withValues(alpha: 0)],
                  ),
                ),
              ),
            ),
          ),
        if (_end)
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: 28,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [fade.withValues(alpha: 0), fade],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _PinnedGarageTabs extends SliverPersistentHeaderDelegate {
  _PinnedGarageTabs({required this.child, required this.height});

  final Widget child;
  final double height;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _PinnedGarageTabs oldDelegate) {
    return oldDelegate.child != child || oldDelegate.height != height;
  }
}

/// Segment-Chip für die Detail-Sheet-Tabs — gleiches Muster wie
/// `_modeChip` im Add-Bike-Sheet, mit optionalem Zähler-Badge, damit der
/// Nutzer die Zusammenfassung sieht, ohne den Tab wechseln zu müssen.
class _TabChip extends StatelessWidget {
  const _TabChip({
    super.key,
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
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Ink(
          decoration: BoxDecoration(
            color: active ? AppColors.accent : AppColors.chipIdle,
            borderRadius: BorderRadius.circular(AppRadius.chip),
            border:
                Border.all(color: active ? AppColors.accent : AppColors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Center(
              child: Text(
                badge != null && badge! > 0 ? '$label ($badge)' : label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: active ? AppColors.onAccent : AppColors.chipIdleText,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Fällige Wartung als Fortschrittsbalken statt ListTile-Fließtext.
class _MaintenanceBarRow extends StatelessWidget {
  const _MaintenanceBarRow({required this.alert, required this.onDone});

  final MaintenanceAlert alert;
  final Future<void> Function() onDone;

  @override
  Widget build(BuildContext context) {
    final color = switch (alert.status) {
      DueStatus.overdue => AppColors.error,
      DueStatus.dueSoon => AppColors.warning,
      DueStatus.ok => AppColors.muted,
    };
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
                  context.l10nOrNull?.maintIntervalLabel(alert.label) ??
                      alert.label,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
              TextButton(
                onPressed: () => unawaited(onDone()),
                child: Text(AppLocalizations.of(context).done),
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
          const SizedBox(height: 3),
          Text(
            [
              context.l10nOrNull?.maintRemainingFor(alert.remainingLabel) ??
                  alert.remainingLabel,
              if (alert.sourceLabel != null) alert.sourceLabel!,
              if (alert.sourceSpan != null) alert.sourceSpan!,
            ].join(' · '),
            style: const TextStyle(fontSize: 10.5, color: AppColors.muted),
          ),
        ],
      ),
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
      CompatVerdict.compatible => AppColors.sageOnDark,
      CompatVerdict.conditional => AppColors.warning,
      CompatVerdict.incompatible => AppColors.error,
      CompatVerdict.insufficientData => AppColors.muted,
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

/// Horizontaler Schnellwechsel — ein Muster für mehrere Räder, kein zweites Listen-Verb.
class _BikeSwitcher extends StatefulWidget {
  const _BikeSwitcher({required this.bikes, this.onOpenActive});

  final List<Bike> bikes;
  final VoidCallback? onOpenActive;

  @override
  State<_BikeSwitcher> createState() => _BikeSwitcherState();
}

class _BikeSwitcherState extends State<_BikeSwitcher> {
  final _controller = ScrollController();
  bool _start = false;
  bool _end = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_update);
    WidgetsBinding.instance.addPostFrameCallback((_) => _update());
  }

  @override
  void didUpdateWidget(covariant _BikeSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _update());
  }

  @override
  void dispose() {
    _controller.removeListener(_update);
    _controller.dispose();
    super.dispose();
  }

  void _update() {
    if (!_controller.hasClients) return;
    final p = _controller.position;
    final overflow = p.maxScrollExtent > 2;
    final start = overflow && p.pixels > 2;
    final end = overflow && p.pixels < p.maxScrollExtent - 2;
    if (start != _start || end != _end) {
      setState(() {
        _start = start;
        _end = end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final fade = Theme.of(context).scaffoldBackgroundColor;
    return SizedBox(
      height: 40,
      child: Stack(
        children: [
          ListView.separated(
            controller: _controller,
            scrollDirection: Axis.horizontal,
            itemCount: widget.bikes.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.s),
            itemBuilder: (context, i) =>
                _BikeSwitcherPill(
                  bike: widget.bikes[i],
                  onOpenActive: widget.onOpenActive,
                ),
          ),
          if (_start)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 24,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [fade, fade.withValues(alpha: 0)],
                    ),
                  ),
                ),
              ),
            ),
          if (_end)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: 24,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [fade.withValues(alpha: 0), fade],
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

class _BikeSwitcherPill extends ConsumerWidget {
  const _BikeSwitcherPill({required this.bike, this.onOpenActive});

  final Bike bike;
  final VoidCallback? onOpenActive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(userProfileStoreProvider);
    final photo = store.bikePhotos[bike.id];
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: bike.isActive
            ? onOpenActive
            : () async {
                await ref.read(garageRepositoryProvider).setActiveBike(bike.id);
                ref.invalidate(bikesProvider);
              },
        child: Container(
          padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
          decoration: BoxDecoration(
            color: bike.isActive
                ? AppColors.chrome.withValues(alpha: 0.14)
                : AppColors.chipIdle,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: bike.isActive ? AppColors.chrome : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadMiniStand(
                bike: bike,
                photo: photo,
                width: 28,
                height: 28,
                selected: bike.isActive,
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
    final l10n = AppLocalizations.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.chip),
      child: Container(
        decoration: BoxDecoration(
          color: selected
              ? AppColors.chrome.withValues(alpha: 0.14)
              : AppColors.chipIdle,
          borderRadius: BorderRadius.circular(AppRadius.chip),
          border: Border.all(
            color: selected ? AppColors.chrome : AppColors.border,
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
              color: selected ? AppColors.chrome : AppColors.muted,
            ),
            const SizedBox(height: 3),
            Text(
              l10n.componentSlotLabel(slot),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                height: 1.1,
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
                  color:
                      value == o ? AppColors.onAccent : AppColors.chipIdleText,
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
List<_AttrFieldSpec> _relevantAttrKeys(
  ComponentSlot slot, [
  AppLocalizations? l10n,
]) {
  final seen = <String>{};
  final out = <_AttrFieldSpec>[];
  for (final rule in compatibilityRules) {
    if (rule.slotA == slot) {
      for (final k in rule.requiresA) {
        if (seen.add(k)) {
          out.add((
            key: k,
            label: l10n?.compatAttrLabel(k) ?? _attrLabel(k),
            hint: l10n?.compatHowTo(k) ?? rule.howToObtain[k],
          ));
        }
      }
    }
    if (rule.slotB == slot) {
      for (final k in rule.requiresB) {
        if (seen.add(k)) {
          out.add((
            key: k,
            label: l10n?.compatAttrLabel(k) ?? _attrLabel(k),
            hint: l10n?.compatHowTo(k) ?? rule.howToObtain[k],
          ));
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
    this.wheelSize,
  });

  final String bikeId;
  final bool isEbike;
  final WheelSize? wheelSize;

  @override
  ConsumerState<_BleSensorTile> createState() => _BleSensorTileState();
}

class _BleSensorTileState extends ConsumerState<_BleSensorTile> {
  BikeBleBinding _binding = const BikeBleBinding();
  bool _busy = false;
  String? _status;
  BoschLiveData? _data;
  bool _hasCrank = false;
  StreamSubscription<BoschLiveData>? _liveSub;
  bool _waking = false;

  @override
  void initState() {
    super.initState();
    unawaited(_reload(wake: true));
    _liveSub = ref.read(bleCoreProvider).liveData.listen((d) {
      if (!mounted) return;
      setState(() {
        _data = d;
        _hasCrank = HudBikePeek.crankLive(
          bikeConnected: ref.read(bleCoreProvider).hasWheelLive,
          previouslySeen: _hasCrank,
          cadenceRpm: d.cadenceRpm,
        );
      });
    });
  }

  @override
  void didUpdateWidget(covariant _BleSensorTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bikeId != widget.bikeId) {
      _hasCrank = false;
      _data = null;
      unawaited(_reload(wake: true));
    } else if (oldWidget.wheelSize != widget.wheelSize) {
      ref.read(bleCoreProvider).wheelCircumferenceM =
          wheelCircumferenceM(widget.wheelSize);
    }
  }

  @override
  void dispose() {
    unawaited(_liveSub?.cancel());
    super.dispose();
  }

  Future<void> _reload({bool wake = false}) async {
    final b =
        await ref.read(bikeBleStoreProvider).bindingForBike(widget.bikeId);
    if (mounted) setState(() => _binding = b);
    if (wake) unawaited(_wakeSaved());
  }

  bool get _live {
    final ble = ref.read(bleCoreProvider);
    return ble.isBindingLive(
      wheelId: _binding.wheel?.deviceId,
      driveId: _binding.drive?.deviceId,
      driveKind: _binding.drive?.kind,
    );
  }

  Future<void> _wakeSaved() async {
    if (_waking || _binding.isEmpty) return;
    final ble = ref.read(bleCoreProvider);
    if (ble.isBikeScanning) return;
    final plan = garageBleWakePlan(_binding);
    final wheelId = plan.wheelId;
    final needWheel = wheelId != null && !ble.isRemoteLive(wheelId);
    final driveId = _binding.drive?.deviceId;
    final needLdi = plan.startLdi &&
        driveId != null &&
        driveId.isNotEmpty &&
        !ble.isRemoteLive(driveId);
    if (!needWheel && !needLdi) return;
    _waking = true;
    ble.wheelCircumferenceM = wheelCircumferenceM(widget.wheelSize);
    try {
      if (needWheel && wheelId != null) {
        await ble.connect(
          deviceId: wheelId,
          scanIfMissing: false,
          tryLdi: false,
          kindHint: plan.wheelKind,
        );
      }
      if (needLdi && mounted && driveId != null) {
        await ble.attachSavedDrive(
          deviceId: driveId,
          kindHint: bikeBleKindFromStorage(_binding.drive?.kind),
        );
      }
    } catch (e) {
      debugPrint('garage ble wake: $e');
    } finally {
      _waking = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _pair() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _status = AppLocalizations.of(context).garageBleScanning;
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
        ble.wheelCircumferenceM = wheelCircumferenceM(widget.wheelSize);
        final name = ble.connectedDeviceName ??
            _binding.wheel?.name ??
            _binding.drive?.name;
        setState(() {
          _status = name != null && name.isNotEmpty
              ? AppLocalizations.of(context).garageBlePairedNamed(name)
              : AppLocalizations.of(context).garageBlePaired;
        });
      } else {
        setState(() => _status = null);
      }
    } catch (e) {
      if (mounted) {
        setState(
            () => _status = AppLocalizations.of(context).garageBlePairFailed);
      }
      debugPrint('garage ble pair: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _applyManage(String? choice) async {
    if (choice == null) return;
    if (choice == 'pair') {
      await _pair();
      return;
    }
    final store = ref.read(bikeBleStoreProvider);
    if (choice == 'unlinkWheel' || choice == 'unlinkAll') {
      if (choice == 'unlinkAll') {
        await store.removeForBike(widget.bikeId);
      } else {
        await store.removeWheel(widget.bikeId);
      }
      try {
        await ref.read(bleCoreProvider).disconnectCsc();
      } catch (_) {}
    } else if (choice == 'unlinkDrive') {
      await store.removeDrive(widget.bikeId);
    }
    await _reload();
    if (mounted) {
      setState(() {
        _status = AppLocalizations.of(context).garageBleRemoved;
        _data = null;
        _hasCrank = false;
      });
    }
  }

  Future<void> _onTap() async {
    if (_busy) return;
    if (_binding.isEmpty) {
      await _pair();
      return;
    }
    final choice = await showBikeBleManageSheet(
      context,
      hasWheel: _binding.wheel != null,
      hasDrive: _binding.drive != null,
      wheelName: bleWheelDisplayName(storedName: _binding.wheel?.name),
      driveName: bleDriveDisplayName(
        storedName: _binding.drive?.name,
        deviceId: _binding.drive?.deviceId,
      ),
    );
    if (!mounted) return;
    await _applyManage(choice);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final names = [
      if (_binding.drive != null)
        bleDriveDisplayName(
          storedName: _binding.drive?.name,
          deviceId: _binding.drive?.deviceId,
        ),
      if (_binding.wheel != null)
        bleWheelDisplayName(storedName: _binding.wheel?.name),
    ];
    final live = _live;
    final data = _data;
    final chips = data == null
        ? const <String>[]
        : garageBleLiveChipsFromData(
            live: live,
            hasCrank: _hasCrank,
            data: data,
          );
    final spin = garageBleShowSpinHint(live: live, chips: chips);
    final line = _binding.isEmpty
        ? l10n.bleLinkEmpty
        : (names.isEmpty
            ? l10n.garageBlePaired
            : live
                ? l10n.bleLinkLiveNamed(names.join(' · '))
                : l10n.bleLinkSavedNamed(names.join(' · ')));
    final honestyKind = garageBleRiderHint(
      isEbike: widget.isEbike,
      bindingEmpty: _binding.isEmpty,
      live: live,
      hasWheel: _binding.wheel != null,
      driveKind: bikeBleKindFromStorage(_binding.drive?.kind),
      spin: spin,
      batterySocPercent: data?.batterySocPercent,
    );
    final hintText = l10n.garageBleRiderHintFor(honestyKind);
    final hint = hintText.isEmpty ? null : hintText;

    return Semantics(
      button: true,
      label: [
        line,
        if (chips.isNotEmpty) chips.join(', '),
        if (hint != null) hint,
      ].join('. '),
      child: InkWell(
        onTap: _busy ? null : () => unawaited(_onTap()),
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
          child: Row(
            children: [
              Icon(
                Icons.bluetooth,
                size: 18,
                color: live ? AppColors.chrome : AppColors.muted,
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
                    if (chips.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        chips.join(' · '),
                        key: const Key('garage-ble-live'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                    ],
                    if (hint != null)
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
              else if (!_binding.isEmpty)
                TextButton(
                  onPressed: () async {
                    final choice = await showBikeBleManageSheet(
                      context,
                      hasWheel: _binding.wheel != null,
                      hasDrive: _binding.drive != null,
                      wheelName: bleWheelDisplayName(
                        storedName: _binding.wheel?.name,
                      ),
                      driveName: bleDriveDisplayName(
                        storedName: _binding.drive?.name,
                        deviceId: _binding.drive?.deviceId,
                      ),
                    );
                    if (!mounted) return;
                    await _applyManage(choice);
                  },
                  child: Text(l10n.remove),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
