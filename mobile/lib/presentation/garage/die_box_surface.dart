import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/bike.dart';
import '../../domain/bike_owner.dart';
import '../../domain/component.dart';
import '../../domain/garage/die_box.dart';
import '../../domain/garage/rad_mark.dart';
import '../../domain/garage/bike_value_strip_plan.dart';
import 'bike_value_strip.dart';
import 'bike_stand_editor.dart';
import 'garage_chrome.dart';
import 'rad_glyph.dart';
import '../../domain/garage/pressure_unit.dart';
import '../../domain/garage/werkstatt_setup.dart';
import 'pressure_log_dialog.dart';
import 'service_care_card.dart';
import '../../domain/maintenance/intervals.dart';
import '../../domain/setup.dart';
import '../../domain/setup/sag_guide.dart';
import '../../domain/ride.dart';
import '../../domain/ride/ride_telemetry.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_ext.dart';
import '../../providers/app_providers.dart';
import '../../domain/ble/bike_ble_kind.dart';
import '../post_ride/post_ride_screen.dart';
import '../ride/ride_elev_sparkline.dart';
import '../shared/bike_hero_banner.dart';

/// Die Box — four zones, one resident bike. Tab title is the bike name.
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
    this.onPairSensor,
    this.showOnBike = true,
    this.showHeuteRest = false,
    this.onChanged,
    this.onOpenMaintenance,
    this.footer,
  });

  final Bike bike;
  final List<BikeComponent> components;
  final List<MaintenanceAlert> due;
  final bool compact;

  /// Teile-Liste in der Box. Im Rad-Detail aus — dort lebt sie im Tab.
  final bool showOnBike;

  /// Weitere Heute-Karten unter dem einen Knopf. Standard aus — eine Aktion.
  final bool showHeuteRest;
  final VoidCallback? onOpenDetail;
  final Future<void> Function(ComponentSlot slot)? onInstallSlot;
  final Future<void> Function(BikeComponent component)? onEditComponent;
  final Widget? sensorChild;
  final Future<void> Function()? onPairSensor;
  final VoidCallback? onChanged;
  final VoidCallback? onOpenMaintenance;

  /// Tabs sitzen in derselben Karte wie Hero und Werte — nicht darunter.
  final Widget? footer;

  @override
  ConsumerState<DieBoxSurface> createState() => _DieBoxSurfaceState();
}

class _DieBoxSurfaceState extends ConsumerState<DieBoxSurface> {
  List<BikeSetup> _setups = const [];
  List<Map<String, dynamic>> _logs = const [];
  bool _cscPaired = false;
  bool _driveNeedsWheel = false;
  bool _busy = false;
  RideRecord? _lastRide;
  final Set<String> _snoozed = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reloadMeta());
  }

  @override
  void didUpdateWidget(covariant DieBoxSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bike.id != widget.bike.id ||
        oldWidget.bike.odometerKm != widget.bike.odometerKm ||
        oldWidget.bike.hours != widget.bike.hours ||
        oldWidget.bike.owner.nextServiceAt !=
            widget.bike.owner.nextServiceAt) {
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
        await ref.read(bikeBleStoreProvider).bindingForBike(widget.bike.id);
    final last =
        await ref.read(rideRepositoryProvider).lastEndedForBike(widget.bike.id);
    if (!mounted) return;
    setState(() {
      _setups = setups;
      _logs = logs;
      _cscPaired = ble.wheel != null;
      _driveNeedsWheel = bleDriveNeedsWheelSensor(
        bikeBleKindFromStorage(ble.drive?.kind),
      );
      _lastRide = last;
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
        driveNeedsWheelSensor: _driveNeedsWheel,
        receiptCount:
            ref.watch(userProfileStoreProvider).receiptsForBike(widget.bike.id).length,
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
          await logBikePressure(
            context: context,
            ref: ref,
            bike: widget.bike,
            existingSetups: _setups,
          );
        case DieBoxItemId.serviceAppointment:
          await showServiceCareEditor(context, ref, widget.bike);
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
                hours: widget.bike.hours,
              );
        case DieBoxItemId.dueCare:
          await ref.read(userProfileStoreProvider).addMaintenanceLog(
                bikeId: widget.bike.id,
                activity: item.due?.label ?? item.title,
                notes: item.due?.sourceLabel ?? item.hint,
                odometerKm: widget.bike.odometerKm,
                hours: widget.bike.hours,
              );
        case DieBoxItemId.pairCsc:
          await widget.onPairSensor?.call();
        case DieBoxItemId.parkTrail:
          await _switchParkTrail();
      }
      await _reloadMeta();
      widget.onChanged?.call();
      ref.invalidate(bikesProvider);
      ref.invalidate(bikeComponentsProvider(widget.bike.id));
      ref.invalidate(currentSetupProvider(widget.bike.id));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _logSag() async {
    final l10n = AppLocalizations.of(context);
    final weight = ref.read(userProfileStoreProvider).effectiveWeightKg;
    final hasShock = _plan.setup.hasRearShock;
    final forkEst = estimateAirPsi(
      riderWeightKg: weight,
      bikeWeightKg: widget.bike.owner.weightKg,
      category: widget.bike.category,
      end: 'fork',
      travelMm: widget.bike.travelFrontMm?.toDouble(),
    );
    final shockEst = hasShock
        ? estimateAirPsi(
            riderWeightKg: weight,
            bikeWeightKg: widget.bike.owner.weightKg,
            category: widget.bike.category,
            end: 'shock',
            travelMm: widget.bike.travelRearMm?.toDouble(),
          )
        : null;
    final fork = TextEditingController();
    final shock = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final d = AppLocalizations.of(ctx);
        return AlertDialog(
          title: Text(d.dieBoxSagTitle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasShock ? d.dieBoxSagHint : d.garageSagGuideHint,
                  style: const TextStyle(fontSize: 13, color: AppColors.muted),
                ),
                const SizedBox(height: AppSpacing.s),
                Text(
                  d.garageSagGuideFork(
                    '${forkEst.psiTarget}',
                    '${forkEst.psiMin}',
                    '${forkEst.psiMax}',
                    '${forkEst.sag.target}${forkEst.sagMm != null ? ' · ${forkEst.sagMm} mm' : ''}',
                  ),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                if (shockEst != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    d.garageSagGuideShock(
                      '${shockEst.psiTarget}',
                      '${shockEst.psiMin}',
                      '${shockEst.psiMax}',
                      '${shockEst.sag.target}${shockEst.sagMm != null ? ' · ${shockEst.sagMm} mm' : ''}',
                    ),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.s),
                Text(
                  d.sagMeasureStepsFor('fork').take(3).join('\n'),
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
                const SizedBox(height: AppSpacing.m),
                TextField(
                  controller: fork,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: d.dieBoxSagFork,
                    hintText: '${forkEst.sag.target}',
                    isDense: true,
                  ),
                ),
                if (hasShock) ...[
                  const SizedBox(height: AppSpacing.s),
                  TextField(
                    controller: shock,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: d.dieBoxSagShock,
                      hintText: '${shockEst!.sag.target}',
                      isDense: true,
                    ),
                  ),
                ],
              ],
            ),
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

  Future<void> _openStand({required bool focusHours}) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final saved = await showBikeStandEditor(
        context: context,
        km: widget.bike.odometerKm,
        hours: widget.bike.hours,
        focusHours: focusHours,
      );
      if (saved == null) return;
      if (!mounted) return;
      final sameKm = (saved.km - widget.bike.odometerKm).abs() < 0.01;
      final sameHours = (saved.hours - widget.bike.hours).abs() < 0.01;
      if (sameKm && sameHours) return;
      await ref.read(garageRepositoryProvider).setOdometerAbsolute(
            bikeId: widget.bike.id,
            odometerKm: saved.km,
            hours: saved.hours,
          );
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      await ref.read(userProfileStoreProvider).addMaintenanceLog(
            bikeId: widget.bike.id,
            activity: sameKm ? 'hours_updated' : 'odo_updated',
            odometerKm: saved.km,
            hours: saved.hours,
            notes:
                '${l10n.garageLogManualKm(saved.km.toStringAsFixed(0))} · ${l10n.garageLogManualHours(saved.hours.toStringAsFixed(1))}',
          );
      await _reloadMeta();
      widget.onChanged?.call();
      ref.invalidate(bikesProvider);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openPressure() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await logBikePressure(
        context: context,
        ref: ref,
        bike: widget.bike,
        existingSetups: _setups,
      );
      await _reloadMeta();
      widget.onChanged?.call();
      ref.invalidate(bikesProvider);
      ref.invalidate(currentSetupProvider(widget.bike.id));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
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
    ref.listen(currentSetupProvider(widget.bike.id), (prev, next) {
      if (next.hasValue) unawaited(_reloadMeta());
    });
    final plan = _plan;
    final today = [
      for (final item in plan.today)
        if (!_snoozed.contains(_itemKey(item))) l10n.localizeDieBoxItem(item),
    ];
    final lastRideLine = l10n.lastRideHeroLineFor(_lastRide);
    final primary = today.isEmpty ? null : today.first;
    final rest =
        today.length <= 1 ? const <DieBoxTodayItem>[] : today.sublist(1);

    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: Column(
        key: const Key('die-box-surface'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: garageCardDecoration(active: widget.bike.isActive),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                BikeHeroBanner(
                  key: widget.compact
                      ? const Key('werkstatt-bike-hero')
                      : null,
                  bike: widget.bike,
                  onTap: widget.onOpenDetail,
                  photoHeight: widget.compact ? 132 : 148,
                  showCaption: false,
                  embedded: true,
                  usePhotoFill: true,
                  onPhotoFilled: () {
                    unawaited(_reloadMeta());
                    widget.onChanged?.call();
                    ref.invalidate(bikesProvider);
                  },
                ),
                if (_lastRide != null) ...[
                  if (lastRideLine != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.m,
                        AppSpacing.s,
                        AppSpacing.m,
                        0,
                      ),
                      child: Text(
                        lastRideLine,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.m,
                      AppSpacing.s,
                      AppSpacing.m,
                      0,
                    ),
                    child: _GarageLastRidePeek(ride: _lastRide!),
                  ),
                ],
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.m,
                    AppSpacing.s,
                    AppSpacing.m,
                    0,
                  ),
                  child: Builder(
                    builder: (context) {
                      final l10n = AppLocalizations.of(context);
                      final top = widget.due.isEmpty ? null : widget.due.first;
                      final service = planStripService(
                        appointmentLabel:
                            widget.bike.owner.hasServiceAppointment
                                ? BikeOwner.formatDate(
                                    widget.bike.owner.nextServiceAt!,
                                  )
                                : null,
                        intervalStatus: top == null
                            ? null
                            : top.status == DueStatus.overdue
                                ? StripIntervalStatus.overdue
                                : StripIntervalStatus.dueSoon,
                        intervalRemaining: top == null
                            ? null
                            : l10n.maintRemainingFor(top.remainingLabel),
                        appointmentCaption: l10n.garageStatService,
                        careCaption: l10n.garageStatCare,
                        dueNow: l10n.garageStatDueNow,
                        dash: l10n.garageStatDash,
                      );
                      return BikeValueStrip(
                        embedded: true,
                        km: widget.bike.odometerKm,
                        hours: widget.bike.hours,
                        pressure: formatLoggedTirePressure(
                          _setups,
                          usesBar: resolvePressureUsesBar(
                            widget.bike.category,
                            ref
                                .watch(userProfileStoreProvider)
                                .pressureUnitPref,
                          ),
                        ),
                        serviceLabel: service.value,
                        serviceCaption: service.caption,
                        onKm: _busy
                            ? null
                            : () => unawaited(_openStand(focusHours: false)),
                        onHours: _busy
                            ? null
                            : () => unawaited(_openStand(focusHours: true)),
                        onPressure:
                            _busy ? null : () => unawaited(_openPressure()),
                        onService: _busy
                            ? null
                            : () async {
                                if (widget.onOpenMaintenance != null) {
                                  widget.onOpenMaintenance!();
                                  return;
                                }
                                await showServiceCareEditor(
                                  context,
                                  ref,
                                  widget.bike,
                                );
                                await _reloadMeta();
                                widget.onChanged?.call();
                                ref.invalidate(bikesProvider);
                              },
                      );
                    },
                  ),
                ),
                _BereitCard(
                  plan: plan,
                  bike: widget.bike,
                  embedded: true,
                ),
                if (primary != null)
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.m,
                      0,
                      AppSpacing.m,
                      widget.footer == null ? AppSpacing.m : AppSpacing.s,
                    ),
                    child: FilledButton(
                      key: const Key('die-box-primary'),
                      onPressed:
                          _busy ? null : () => unawaited(_runToday(primary)),
                      child: Text(primary.cta),
                    ),
                  )
                else if (plan.isReady)
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.m,
                      0,
                      AppSpacing.m,
                      widget.footer == null ? AppSpacing.m : AppSpacing.s,
                    ),
                    child: Text(
                      plan.setup.kind == WerkstattKind.urban
                          ? l10n.dieBoxNothingDueMonday
                          : l10n.dieBoxNothingDue,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.chrome,
                      ),
                    ),
                  ),
                if (widget.footer != null && widget.sensorChild != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.m,
                      0,
                      AppSpacing.m,
                      AppSpacing.s,
                    ),
                    child: widget.sensorChild,
                  ),
                if (widget.footer != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.m,
                      0,
                      AppSpacing.m,
                      AppSpacing.m,
                    ),
                    child: widget.footer,
                  ),
              ],
            ),
          ),
          if (widget.showHeuteRest && rest.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.l),
            GarageSectionTitle(label: l10n.dieBoxZoneToday, mark: 'care'),
            const SizedBox(height: AppSpacing.s),
            _HeuteZone(
              items: rest,
              busy: _busy,
              laterLabel: l10n.dieBoxLater,
              onTap: _runToday,
              onLater: (item) => setState(() => _snoozed.add(_itemKey(item))),
            ),
          ],
          if (widget.showOnBike) ...[
            const SizedBox(height: AppSpacing.l),
            GarageSectionTitle(label: l10n.dieBoxZoneOnBike, mark: 'parts'),
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
                      final slot = next.isEmpty
                          ? plan.addableSlots.firstOrNull
                          : next.first;
                      if (slot != null) unawaited(widget.onInstallSlot!(slot));
                    },
            ),
          ],
          if (widget.sensorChild != null && widget.footer == null) ...[
            const SizedBox(height: AppSpacing.l),
            GarageSectionTitle(label: l10n.dieBoxZoneSensor, mark: 'battery'),
            const SizedBox(height: AppSpacing.s),
            widget.sensorChild!,
          ],
        ],
      ),
    );
  }
}

class _BereitCard extends StatelessWidget {
  const _BereitCard({
    required this.plan,
    required this.bike,
    this.embedded = false,
  });
  final DieBoxPlan plan;
  final Bike bike;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tone = switch (plan.readiness) {
      DieBoxReadiness.ready => AppColors.chrome,
      DieBoxReadiness.almost => AppColors.sageOnDark,
      DieBoxReadiness.unknown => AppColors.muted,
    };
    return Container(
      key: const Key('die-box-bereit'),
      decoration: embedded ? null : garageCardDecoration(active: bike.isActive),
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              RadGlyph(radMarkForReadiness(plan.readiness), size: 16),
              const SizedBox(width: 6),
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
          if (plan.chips.any((c) => c.known && !c.fact)) ...[
            const SizedBox(height: AppSpacing.s),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final c in plan.chips)
                  if (c.known && !c.fact)
                    GarageFactChip(
                      label: l10n.dieBoxChipLabel(c.label),
                      leading: RadGlyph(radMarkForChip(c.label), size: 12),
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
              color: Colors.transparent,
              child: InkWell(
                onTap: busy ? null : () => unawaited(onTap(item)),
                borderRadius: BorderRadius.circular(AppRadius.card),
                child: Ink(
                  decoration: garageCardDecoration(),
                  child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.m,
                    vertical: AppSpacing.s,
                  ),
                  child: Row(
                    children: [
                      RadGlyph(radMarkForItem(item.id), size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              item.hint,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.muted,
                                height: 1.25,
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
                              color: AppColors.chrome,
                            ),
                          ),
                          const SizedBox(height: 2),
                          GestureDetector(
                            onTap: busy ? null : () => onLater(item),
                            child: Text(
                              laterLabel,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.muted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
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
      return GarageInviteCard(
        title: l10n.dieBoxAddSomething,
        hint: l10n.dieBoxOnBikeEmpty,
        onTap: onAdd,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final c in plan.onBike)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap == null ? null : () => unawaited(onTap!(c)),
                borderRadius: BorderRadius.circular(AppRadius.card),
                child: Ink(
                  decoration: garageCardDecoration(),
                  child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.m,
                    vertical: AppSpacing.s,
                  ),
                  child: Row(
                    children: [
                      RadGlyph(radMarkForSlot(c.slot), size: 16),
                      const SizedBox(width: 8),
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

class _GarageLastRidePeek extends StatelessWidget {
  const _GarageLastRidePeek({required this.ride});

  final RideRecord ride;

  @override
  Widget build(BuildContext context) {
    final tel = buildRideTelemetry(ride.track);
    if (!tel.hasElev) return const SizedBox.shrink();
    return RideTerrainPeek(
      telemetry: tel,
      caption: terrainCaption(tel),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => PostRideScreen(rideId: ride.id),
          ),
        );
      },
    );
  }
}
