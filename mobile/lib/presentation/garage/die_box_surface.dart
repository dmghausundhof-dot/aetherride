import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/bike.dart';
import '../../domain/component.dart';
import '../../domain/garage/die_box.dart';
import '../../domain/garage/last_ride_hero.dart';
import '../../domain/garage/pressure_unit.dart';
import '../../domain/garage/werkstatt_setup.dart';
import '../../domain/maintenance/intervals.dart';
import '../../domain/setup.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_ext.dart';
import '../../providers/app_providers.dart';
import '../shared/bike_hero_banner.dart';

/// Die Box — four zones, one resident bike. Tab name stays Werkstatt.
class DieBoxSurface extends ConsumerStatefulWidget {
  const DieBoxSurface({
    super.key,
    required this.bike,
    required this.components,
    this.due = const [],
    this.compact = false,
    this.onOpenDetail,
    this.onInstallSlot,
    this.onEditComponent,
    this.sensorChild,
    this.shopChild,
  });

  final Bike bike;
  final List<BikeComponent> components;
  final List<MaintenanceAlert> due;
  final bool compact;
  final VoidCallback? onOpenDetail;
  final Future<void> Function(ComponentSlot slot)? onInstallSlot;
  final Future<void> Function(BikeComponent component)? onEditComponent;
  final Widget? sensorChild;
  final Widget? shopChild;

  @override
  ConsumerState<DieBoxSurface> createState() => _DieBoxSurfaceState();
}

class _DieBoxSurfaceState extends ConsumerState<DieBoxSurface> {
  List<BikeSetup> _setups = const [];
  List<Map<String, dynamic>> _logs = const [];
  bool _cscPaired = false;
  bool _busy = false;
  String? _lastRideLine;
  final Set<String> _snoozed = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reloadMeta());
  }

  @override
  void didUpdateWidget(covariant DieBoxSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bike.id != widget.bike.id) {
      _reloadMeta();
    }
  }

  Future<void> _reloadMeta() async {
    final setups =
        await ref.read(setupRepositoryProvider).listForBike(widget.bike.id);
    final logs = ref
        .read(userProfileStoreProvider)
        .maintenanceLogs
        .where((e) => e['bikeId'] == widget.bike.id)
        .toList();
    final ble =
        await ref.read(bikeBleStoreProvider).deviceForBike(widget.bike.id);
    final last = await ref
        .read(rideRepositoryProvider)
        .lastEndedForBike(widget.bike.id);
    if (!mounted) return;
    setState(() {
      _setups = setups;
      _logs = logs;
      _cscPaired = ble != null;
      _lastRideLine = lastRideHeroLine(last);
    });
  }

  DieBoxPlan get _plan => planDieBox(
        bike: widget.bike,
        components: widget.components,
        currentSetup: _setups.where((s) => s.isCurrent).firstOrNull,
        setups: _setups,
        due: widget.due,
        logs: _logs,
        cscPaired: _cscPaired,
      );

  Future<void> _runToday(DieBoxTodayItem item) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      switch (item.id) {
        case DieBoxItemId.setActive:
          await ref
              .read(garageRepositoryProvider)
              .setActiveBike(widget.bike.id);
          ref.invalidate(bikesProvider);
        case DieBoxItemId.lightsMissing:
        case DieBoxItemId.lockMissing:
        case DieBoxItemId.rackMissing:
        case DieBoxItemId.bagsMissing:
        case DieBoxItemId.brakesUnknown:
          final slot = item.slot;
          if (slot != null) await widget.onInstallSlot?.call(slot);
        case DieBoxItemId.pressureUnknown:
          await _logPressure();
        case DieBoxItemId.sagUnknown:
          await _logSag();
        case DieBoxItemId.travelUnknown:
          await _logTravel();
        case DieBoxItemId.chainTeach:
          final l10n = AppLocalizations.of(context);
          await ref.read(userProfileStoreProvider).addMaintenanceLog(
                bikeId: widget.bike.id,
                activity: l10n.dieBoxChainLogged,
                notes: l10n.dieBoxChainNotes,
                odometerKm: widget.bike.odometerKm,
              );
        case DieBoxItemId.dueCare:
          await ref.read(userProfileStoreProvider).addMaintenanceLog(
                bikeId: widget.bike.id,
                activity: item.title,
                notes: item.hint,
                odometerKm: widget.bike.odometerKm,
              );
        case DieBoxItemId.pairCsc:
          if (widget.compact) widget.onOpenDetail?.call();
        case DieBoxItemId.parkTrail:
          await _switchParkTrail();
      }
      await _reloadMeta();
      ref.invalidate(bikesProvider);
      ref.invalidate(bikeComponentsProvider(widget.bike.id));
      ref.invalidate(currentSetupProvider(widget.bike.id));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _logPressure() async {
    final l10n = AppLocalizations.of(context);
    final usesBar = pressureUsesBar(widget.bike.category);
    final unit = pressureUnitLabel(widget.bike.category);
    final front = TextEditingController();
    final rear = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final d = AppLocalizations.of(ctx);
        return AlertDialog(
          title: Text(d.dieBoxPressureTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                d.dieBoxPressureHint,
                style: const TextStyle(fontSize: 13, color: AppColors.muted),
              ),
              const SizedBox(height: AppSpacing.m),
              TextField(
                controller: front,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: '${d.dieBoxPressureFront} ($unit)',
                  isDense: true,
                ),
              ),
              const SizedBox(height: AppSpacing.s),
              TextField(
                controller: rear,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: '${d.dieBoxPressureRear} ($unit)',
                  isDense: true,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(d.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(d.save),
            ),
          ],
        );
      },
    );
    if (ok != true) return;
    final enteredF = double.tryParse(front.text.replaceAll(',', '.'));
    final enteredR = double.tryParse(rear.text.replaceAll(',', '.'));
    if (enteredF == null && enteredR == null) return;
    final f = enteredF == null
        ? null
        : enteredPressureToPsi(enteredF, widget.bike.category);
    final r = enteredR == null
        ? null
        : enteredPressureToPsi(enteredR, widget.bike.category);
    final current =
        await ref.read(setupRepositoryProvider).getCurrent(widget.bike.id);
    final values = _mergeValues(
      current?.values ?? const [],
      [
        if (f != null)
          SetupValue(
            adjusterKey: 'tire_front.pressure_psi',
            valueNum: f,
            unit: 'psi',
          ),
        if (r != null)
          SetupValue(
            adjusterKey: 'tire_rear.pressure_psi',
            valueNum: r,
            unit: 'psi',
          ),
      ],
    );
    await ref.read(setupRepositoryProvider).createVersion(
          bikeId: widget.bike.id,
          label: l10n.dieBoxPressureLogged,
          values: values,
          createdBy: 'user',
          parentSetupId: current?.id,
        );
    await ref.read(userProfileStoreProvider).addMaintenanceLog(
          bikeId: widget.bike.id,
          activity: l10n.dieBoxPressureLogged,
          notes: [
            if (enteredF != null)
              usesBar
                  ? l10n.garageLogBarFront(enteredF.toStringAsFixed(1))
                  : l10n.garageLogPsiFront(enteredF.toStringAsFixed(0)),
            if (enteredR != null)
              usesBar
                  ? l10n.garageLogBarRear(enteredR.toStringAsFixed(1))
                  : l10n.garageLogPsiRear(enteredR.toStringAsFixed(0)),
          ].join(' · '),
        );
  }

  Future<void> _logSag() async {
    final l10n = AppLocalizations.of(context);
    final fork = TextEditingController();
    final shock = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final d = AppLocalizations.of(ctx);
        return AlertDialog(
          title: Text(d.dieBoxSagTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                d.dieBoxSagHint,
                style: const TextStyle(fontSize: 13, color: AppColors.muted),
              ),
              const SizedBox(height: AppSpacing.m),
              TextField(
                controller: fork,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: d.dieBoxSagFork,
                  isDense: true,
                ),
              ),
              const SizedBox(height: AppSpacing.s),
              TextField(
                controller: shock,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: d.dieBoxSagShock,
                  isDense: true,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(d.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(d.save),
            ),
          ],
        );
      },
    );
    if (ok != true) return;
    final f = double.tryParse(fork.text.replaceAll(',', '.'));
    final s = double.tryParse(shock.text.replaceAll(',', '.'));
    if (f == null && s == null) return;
    final current =
        await ref.read(setupRepositoryProvider).getCurrent(widget.bike.id);
    final values = _mergeValues(
      current?.values ?? const [],
      [
        if (f != null)
          SetupValue(adjusterKey: 'fork.sag_pct', valueNum: f, unit: '%'),
        if (s != null)
          SetupValue(adjusterKey: 'shock.sag_pct', valueNum: s, unit: '%'),
      ],
    );
    await ref.read(setupRepositoryProvider).createVersion(
          bikeId: widget.bike.id,
          label: l10n.dieBoxSagLogged,
          values: values,
          createdBy: 'user',
          parentSetupId: current?.id,
        );
  }

  Future<void> _logTravel() async {
    final front = TextEditingController(
      text: widget.bike.travelFrontMm?.toString() ?? '',
    );
    final rear = TextEditingController(
      text: widget.bike.travelRearMm?.toString() ?? '',
    );
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final d = AppLocalizations.of(ctx);
        return AlertDialog(
          title: Text(d.dieBoxTravelTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                d.dieBoxTravelHint,
                style: const TextStyle(fontSize: 13, color: AppColors.muted),
              ),
              const SizedBox(height: AppSpacing.m),
              TextField(
                controller: front,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: d.dieBoxTravelFront,
                  isDense: true,
                ),
              ),
              const SizedBox(height: AppSpacing.s),
              TextField(
                controller: rear,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: d.dieBoxTravelRear,
                  isDense: true,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(d.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(d.dieBoxTravelSave),
            ),
          ],
        );
      },
    );
    if (ok != true) return;
    final f = int.tryParse(front.text.trim());
    final r = int.tryParse(rear.text.trim());
    if (f == null && r == null) return;
    await ref.read(garageRepositoryProvider).upsert(
          widget.bike.copyWith(
            travelFrontMm: f ?? widget.bike.travelFrontMm,
            travelRearMm: r ?? widget.bike.travelRearMm,
          ),
        );
  }

  Future<void> _switchParkTrail() async {
    final plan = _plan;
    final park = plan.parkSetup;
    final trail = plan.trailSetup;
    if (park == null || trail == null) return;
    final currentIsPark = park.isCurrent;
    final next = currentIsPark ? trail : park;
    await ref.read(setupRepositoryProvider).setCurrent(widget.bike.id, next.id);
  }

  List<SetupValue> _mergeValues(
    List<SetupValue> base,
    List<SetupValue> overlay,
  ) {
    final map = {for (final v in base) v.adjusterKey: v};
    for (final v in overlay) {
      map[v.adjusterKey] = v;
    }
    return map.values.toList();
  }

  String _itemKey(DieBoxTodayItem item) {
    if (item.id == DieBoxItemId.dueCare) {
      return 'due:${item.due?.label ?? item.title}';
    }
    return item.id.name;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final plan = _plan;
    final today = [
      for (final item in plan.today)
        if (!_snoozed.contains(_itemKey(item))) l10n.localizeDieBoxItem(item),
    ];
    final primary = today.isEmpty ? null : today.first;
    final rest = today.length <= 1 ? const <DieBoxTodayItem>[] : today.sublist(1);

    return Column(
      key: const Key('die-box-surface'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BikeHeroBanner(
          key: widget.compact ? const Key('werkstatt-bike-hero') : null,
          bike: widget.bike,
          onTap: widget.onOpenDetail,
          photoHeight: widget.compact ? 140 : 160,
          lastRideLine: _lastRideLine,
        ),
        const SizedBox(height: AppSpacing.s),
        _BereitCard(plan: plan, bike: widget.bike),
        if (primary != null) ...[
          const SizedBox(height: AppSpacing.s),
          FilledButton(
            key: const Key('die-box-primary'),
            onPressed: _busy ? null : () => unawaited(_runToday(primary)),
            child: Text(primary.cta),
          ),
        ] else if (plan.isReady) ...[
          const SizedBox(height: AppSpacing.s),
          Text(
            plan.setup.kind == WerkstattKind.urban
                ? l10n.dieBoxNothingDueMonday
                : l10n.dieBoxNothingDue,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.forestOnDark,
            ),
          ),
        ],
        if (rest.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.l),
          _ZoneTitle(label: l10n.dieBoxZoneToday),
          const SizedBox(height: AppSpacing.s),
          _HeuteZone(
            items: rest,
            busy: _busy,
            laterLabel: l10n.dieBoxLater,
            onTap: _runToday,
            onLater: (item) => setState(() => _snoozed.add(_itemKey(item))),
          ),
        ],
        const SizedBox(height: AppSpacing.l),
        _ZoneTitle(label: l10n.dieBoxZoneOnBike),
        const SizedBox(height: AppSpacing.s),
        _AmRadZone(
          plan: plan,
          onTap: widget.onEditComponent,
          onAdd: widget.onInstallSlot == null
              ? null
              : () {
                  final next = plan.addableSlots.where(
                    (s) => !plan.onBike.any((c) => c.slot == s),
                  );
                  final slot =
                      next.isEmpty ? plan.addableSlots.firstOrNull : next.first;
                  if (slot != null) unawaited(widget.onInstallSlot!(slot));
                },
        ),
        const SizedBox(height: AppSpacing.l),
        if (widget.sensorChild != null) ...[
          _ZoneTitle(label: l10n.dieBoxZoneSensor),
          const SizedBox(height: AppSpacing.s),
          widget.sensorChild!,
        ],
        if (plan.setup.hasElectricAssist) ...[
          const SizedBox(height: AppSpacing.s),
          const _BatteryHonestyCard(),
        ],
        if (widget.shopChild != null) ...[
          const SizedBox(height: AppSpacing.m),
          widget.shopChild!,
        ],
      ],
    );
  }
}

class _ZoneTitle extends StatelessWidget {
  const _ZoneTitle({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppColors.muted,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
          ),
    );
  }
}

class _BereitCard extends StatelessWidget {
  const _BereitCard({required this.plan, required this.bike});
  final DieBoxPlan plan;
  final Bike bike;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tone = switch (plan.readiness) {
      DieBoxReadiness.ready => AppColors.forestOnDark,
      DieBoxReadiness.almost => const Color(0xFFE8EEEA),
      DieBoxReadiness.unknown => AppColors.muted,
    };
    return Container(
      key: const Key('die-box-bereit'),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: bike.isActive ? AppColors.forestOnDark : AppColors.border,
          width: bike.isActive ? 1.5 : 1,
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                l10n.dieBoxReadiness(plan.readiness),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: tone,
                ),
              ),
              const SizedBox(width: AppSpacing.s),
              Expanded(
                child: Text(
                  l10n.bikeCategoryLabel(bike),
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s),
          Text(
            l10n.dieBoxSentenceFor(bike, plan),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
          if (plan.chips.any((c) => c.known)) ...[
            const SizedBox(height: AppSpacing.s),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final c in plan.chips)
                  if (c.known)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.chipIdle,
                        borderRadius: BorderRadius.circular(AppRadius.chip),
                        border: Border.all(
                          color: AppColors.forestOnDark.withValues(alpha: 0.45),
                        ),
                      ),
                      child: Text(
                        l10n.dieBoxChipLabel(c.label),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.chipIdleText,
                        ),
                      ),
                    ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _HeuteZone extends StatelessWidget {
  const _HeuteZone({
    required this.items,
    required this.busy,
    required this.laterLabel,
    required this.onTap,
    required this.onLater,
  });

  final List<DieBoxTodayItem> items;
  final bool busy;
  final String laterLabel;
  final Future<void> Function(DieBoxTodayItem) onTap;
  final ValueChanged<DieBoxTodayItem> onLater;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Text(
        AppLocalizations.of(context).dieBoxNothingDue,
        style: const TextStyle(fontSize: 13, color: AppColors.muted),
      );
    }
    return Column(
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.s),
            child: Material(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(AppRadius.card),
              child: InkWell(
                onTap: busy ? null : () => unawaited(onTap(item)),
                borderRadius: BorderRadius.circular(AppRadius.card),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.m),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.hint,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.muted,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            item.cta,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.forestOnDark,
                            ),
                          ),
                          TextButton(
                            onPressed: busy ? null : () => onLater(item),
                            child: Text(laterLabel),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _AmRadZone extends StatelessWidget {
  const _AmRadZone({
    required this.plan,
    this.onTap,
    this.onAdd,
  });

  final DieBoxPlan plan;
  final Future<void> Function(BikeComponent)? onTap;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (plan.onBike.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.dieBoxEmptyHint,
            style: const TextStyle(fontSize: 13, color: AppColors.muted),
          ),
          if (onAdd != null)
            TextButton(
              onPressed: onAdd,
              child: Text(l10n.dieBoxAddSomething),
            ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final c in plan.onBike)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Material(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(AppRadius.card),
              child: InkWell(
                onTap: onTap == null ? null : () => unawaited(onTap!(c)),
                borderRadius: BorderRadius.circular(AppRadius.card),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.m,
                    vertical: AppSpacing.s,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${l10n.componentSlotLabel(c.slot)} · ${c.displayName}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: AppColors.muted,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        if (onAdd != null)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: onAdd,
              child: Text(l10n.dieBoxAddMore),
            ),
          ),
      ],
    );
  }
}

class _BatteryHonestyCard extends StatelessWidget {
  const _BatteryHonestyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        AppLocalizations.of(context).dieBoxBatteryHint,
        style:
            const TextStyle(fontSize: 13, height: 1.35, color: AppColors.muted),
      ),
    );
  }
}
