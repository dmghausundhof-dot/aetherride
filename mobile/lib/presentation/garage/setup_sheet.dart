import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/bike.dart';
import '../../domain/component.dart';
import '../../domain/garage/werkstatt_setup.dart';
import '../../domain/setup.dart';
import '../../domain/setup/bracketing.dart';
import '../../domain/setup/templates.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_ext.dart';
import '../../providers/app_providers.dart';
import 'garage_chrome.dart';

/// Setup-Versionen, Vorlagen und A/B-Vergleich — einbettbar im Garage-Tab.
///
/// Kein zweites Sheet mehr nötig: Inhalte leben im Setup-Tab.
class SetupPanel extends ConsumerStatefulWidget {
  const SetupPanel({
    super.key,
    required this.bike,
    this.onChanged,
  });

  final Bike bike;
  final VoidCallback? onChanged;

  @override
  ConsumerState<SetupPanel> createState() => _SetupPanelState();
}

class _SetupPanelState extends ConsumerState<SetupPanel> {
  List<BikeSetup> _setups = [];
  bool _busy = false;
  double _riderWeight = 75;
  String? _compareMsg;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant SetupPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bike.id != widget.bike.id) {
      _compareMsg = null;
      _load();
    }
  }

  WerkstattSetupPlan get _plan {
    final comps =
        ref.read(bikeComponentsProvider(widget.bike.id)).valueOrNull ??
            const <BikeComponent>[];
    return planWerkstattSetup(bike: widget.bike, components: comps);
  }

  Future<void> _load() async {
    final store = ref.read(userProfileStoreProvider);
    await store.load();
    final list =
        await ref.read(setupRepositoryProvider).listForBike(widget.bike.id);
    if (mounted) {
      setState(() {
        _setups = list;
        _riderWeight = store.effectiveWeightKg;
      });
    }
  }

  void _notify() {
    ref.invalidate(currentSetupProvider(widget.bike.id));
    widget.onChanged?.call();
  }

  Future<void> _bindCreated(BikeSetup setup) async {
    final store = ref.read(userProfileStoreProvider);
    await store.assignSetupToActiveRider(setup.id);
    if (store.activeFamilyRiderId == null) {
      await store.rememberOwnSetup(widget.bike.id, setup.id);
    }
  }

  Future<void> _applyTemplate(SetupTemplate tpl) async {
    final l10n = AppLocalizations.of(context);
    final label = l10n.setupTemplateLabelFor(tpl.id, fallback: tpl.label);
    final disclaimer = l10n.setupTemplateDisclaimerFor(
      tpl.id,
      fallback: tpl.disclaimer,
    );
    setState(() => _busy = true);
    await ref.read(setupRepositoryProvider).createVersion(
          bikeId: widget.bike.id,
          label: l10n.setupTemplateAppliedLabel(label),
          values: tpl.toValues(_riderWeight, widget.bike.category),
          conditions: tpl.conditions,
          createdBy: 'template',
        ).then(_bindCreated);
    await _load();
    _notify();
    if (mounted) {
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.setupTemplateAppliedSnack(disclaimer))),
      );
    }
  }

  Future<void> _setCurrent(BikeSetup s) async {
    await ref.read(setupRepositoryProvider).setCurrent(widget.bike.id, s.id);
    final store = ref.read(userProfileStoreProvider);
    if (store.activeFamilyRiderId == null) {
      await store.rememberOwnSetup(widget.bike.id, s.id);
    }
    await _load();
    _notify();
  }

  Future<void> _manualVersion() async {
    final l10n = AppLocalizations.of(context);
    final plan = _plan;
    final key = plan.primaryAdjusterKey;
    final current = await ref
        .read(setupRepositoryProvider)
        .getCurrent(widget.bike.id);
    final fallback = defaultSetupValuesFor(plan);
    final base = Map<String, double>.from(
      current?.adjusterMap ??
          {for (final v in fallback) v.adjusterKey: v.valueNum},
    );
    final seed = base[key] ?? (plan.showsFahrwerk ? 8.0 : 36.0);
    final ctrl = TextEditingController(text: seed.toStringAsFixed(0));
    final labelCtrl = TextEditingController(
      text: l10n.setupNewVersionDefaultName(_setups.length + 1),
    );
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.setupNewVersionTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.setupNewVersionHint,
              style: const TextStyle(fontSize: 13, color: AppColors.muted),
            ),
            const SizedBox(height: AppSpacing.s),
            TextField(
              controller: labelCtrl,
              decoration: InputDecoration(labelText: l10n.setupVersionNameLabel),
            ),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: plan.showsFahrwerk
                    ? l10n.setupForkReboundLabel
                    : l10n.setupTirePressureLabel,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.setupCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.setupSave),
          ),
        ],
      ),
    );
    if (!mounted || ok != true) return;
    final next = double.tryParse(ctrl.text) ?? seed;
    base[key] = plan.showsFahrwerk ? next.clamp(0, 14) : next.clamp(15, 130);
    final values = [
      for (final e in base.entries)
        SetupValue(
          adjusterKey: e.key,
          valueNum: e.value,
          unit: e.key.contains('pressure') ? 'psi' : 'clicks',
        ),
    ];
    final name = labelCtrl.text.trim();
    await ref.read(setupRepositoryProvider).createVersion(
          bikeId: widget.bike.id,
          label: name.isEmpty ? l10n.setupManualFallback : name,
          values: values,
          parentSetupId: current?.id,
        ).then(_bindCreated);
    await _load();
    _notify();
  }

  Future<void> _startCompare() async {
    final l10n = AppLocalizations.of(context);
    final plan = _plan;
    final key = plan.primaryAdjusterKey;
    setState(() => _busy = true);
    final current =
        await ref.read(setupRepositoryProvider).getCurrent(widget.bike.id);
    final fallback = defaultSetupValuesFor(plan);
    final fromCurrent = current?.valueFor(key);
    final fromFallback = fallback
        .where((v) => v.adjusterKey == key)
        .map((v) => v.valueNum);
    final seed = fromCurrent ??
        (fromFallback.isEmpty
            ? (plan.showsFahrwerk ? 8.0 : 36.0)
            : fromFallback.first);
    final series = createBlindPair(
      adjusterKey: key,
      currentValue: seed,
    );
    final a = plan.showsFahrwerk
        ? series.rangeFrom.clamp(0, 14)
        : series.rangeFrom.clamp(15, 130);
    final b = plan.showsFahrwerk
        ? series.rangeTo.clamp(0, 14)
        : series.rangeTo.clamp(15, 130);
    final baseValues = current?.values ?? fallback;

    await ref.read(setupRepositoryProvider).createVersion(
          bikeId: widget.bike.id,
          label: l10n.setupCompareVariantA,
          values: [
            for (final v in baseValues)
              v.adjusterKey == key
                  ? SetupValue(
                      adjusterKey: v.adjusterKey,
                      valueNum: a.toDouble(),
                      unit: v.unit,
                    )
                  : v,
          ],
          createdBy: 'user',
          parentSetupId: current?.id,
        ).then(_bindCreated);
    await ref.read(setupRepositoryProvider).createVersion(
          bikeId: widget.bike.id,
          label: l10n.setupCompareVariantB,
          values: [
            for (final v in baseValues)
              v.adjusterKey == key
                  ? SetupValue(
                      adjusterKey: v.adjusterKey,
                      valueNum: b.toDouble(),
                      unit: v.unit,
                    )
                  : v,
          ],
          createdBy: 'user',
          parentSetupId: current?.id,
        ).then(_bindCreated);

    final rides = await ref.read(rideRepositoryProvider).listRides(limit: 40);
    var runs = runsFromRides(
      rides: rides,
      configA: a.toDouble(),
      configB: b.toDouble(),
      bikeId: widget.bike.id,
    );
    final fromRides = runs.length >= 2;
    if (runs.length < 4) {
      runs = [...runs, ...syntheticBracketRuns(a.toDouble(), b.toDouble())];
    }

    final eval = evaluateBracketingSeries(
      BracketingSeries(
        adjusterKey: key,
        rangeFrom: a.toDouble(),
        rangeTo: b.toDouble(),
        step: (b - a).abs() < 1e-6 ? 2.0 : (b - a).abs().toDouble(),
        runs: runs,
      ),
    );

    await _load();
    _notify();
    if (mounted) {
      final rideFeedback = rides
          .where((r) => r.bikeId == widget.bike.id && r.feedback != null)
          .length;
      setState(() {
        _busy = false;
        _compareMsg = fromRides
            ? l10n.setupCompareResultFromRides(rideFeedback, eval.summary)
            : l10n.setupCompareResultDemo(eval.summary);
      });
    }
  }

  String _formatDate(DateTime dt, String locale) {
    return DateFormat.yMMMd(locale).format(dt.toLocal());
  }

  String _createdByLabel(AppLocalizations l10n, String createdBy) {
    return switch (createdBy) {
      'template' => l10n.setupSourceTemplate,
      'system' || 'baseline' => l10n.setupSourceBaseline,
      _ => l10n.setupSourceManual,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    ref.watch(bikeComponentsProvider(widget.bike.id));
    ref.listen(currentSetupProvider(widget.bike.id), (prev, next) {
      if (next.hasValue) unawaited(_load());
    });
    final plan = _plan;
    final tpls = templatesFor(widget.bike.category);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GarageSectionTitle(label: l10n.setupVersionsTitle, mark: 'setup'),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          l10n.setupVersionsHint,
          style: const TextStyle(fontSize: 12.5, color: AppColors.muted),
        ),
        const SizedBox(height: AppSpacing.s),
        Text(
          l10n.setupRiderWeightLabel,
          style: Theme.of(context).textTheme.labelMedium,
        ),
        Slider(
          value: _riderWeight,
          min: 55,
          max: 110,
          divisions: 55,
          label: _riderWeight.round().toString(),
          onChanged: (v) => setState(() => _riderWeight = v),
        ),
        // Theme minimumSize: Size.fromHeight(48) = infinite width —
        // override or BoxConstraints Infinity crash (S25 Setup).
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.chrome,
                minimumSize: const Size(0, 44),
              ),
              onPressed: _busy ? null : _manualVersion,
              icon: const Icon(Icons.add, size: 18),
              label: Text(l10n.setupNewVersionCta),
            ),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
              onPressed: _busy ? null : _startCompare,
              icon: const Icon(Icons.compare_arrows, size: 18),
              label: Text(l10n.setupCompareCta),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          plan.showsFahrwerk
              ? l10n.setupCompareHint
              : l10n.setupCompareHintTires,
          style: const TextStyle(fontSize: 12, color: AppColors.muted),
        ),
        if (_compareMsg != null) ...[
          const SizedBox(height: AppSpacing.s),
          Container(
            padding: const EdgeInsets.all(AppSpacing.m),
            decoration: BoxDecoration(
              color: AppColors.chipIdle,
              borderRadius: BorderRadius.circular(AppRadius.chip),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              _compareMsg!,
              style: const TextStyle(fontSize: 12.5, color: AppColors.muted),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.l),
        GarageSectionTitle(label: l10n.setupSavedVersions),
        if (_setups.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
            child: GarageInviteCard(
              title: l10n.setupEmpty,
              hint: l10n.setupVersionsHint,
              icon: Icons.tune,
              onTap: _busy ? null : _manualVersion,
            ),
          )
        else
          for (final s in _setups)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.s),
              child: Material(
                color: s.isCurrent
                    ? AppColors.accent.withValues(alpha: 0.12)
                    : AppColors.chipIdle,
                borderRadius: BorderRadius.circular(AppRadius.chip),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                  onTap: s.isCurrent ? null : () => _setCurrent(s),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.m),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      s.label,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  if (s.isCurrent)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.s,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.accent,
                                        borderRadius: BorderRadius.circular(
                                          AppRadius.pill,
                                        ),
                                      ),
                                      child: Text(
                                        l10n.setupActiveBadge,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.onAccent,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.xxs),
                              Text(
                                [
                                  l10n.setupVersionMeta(s.version),
                                  _formatDate(s.createdAt, locale),
                                  _createdByLabel(l10n, s.createdBy),
                                  if (plan.showsFahrwerk &&
                                      s.valueFor('fork.rebound') != null)
                                    l10n.setupForkReboundValue(
                                      s.valueFor('fork.rebound')!
                                          .toStringAsFixed(0),
                                    )
                                  else if (s.valueFor(
                                        'tire_front.pressure_psi',
                                      ) !=
                                      null)
                                    l10n.setupTirePressureValue(
                                      s
                                          .valueFor('tire_front.pressure_psi')!
                                          .toStringAsFixed(0),
                                    ),
                                ].join(' · '),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!s.isCurrent)
                          TextButton(
                            onPressed: () => _setCurrent(s),
                            child: Text(l10n.setupUseVersion),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        const SizedBox(height: AppSpacing.l),
        Text(
          l10n.setupTemplatesTitle,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          l10n.setupTemplatesHint,
          style: const TextStyle(fontSize: 12, color: AppColors.muted),
        ),
        const SizedBox(height: AppSpacing.s),
        if (tpls.isEmpty)
          Text(
            l10n.setupEmpty,
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
          )
        else
          for (final tpl in tpls)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.s),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.m),
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
                        Text(
                          l10n.setupTemplateLabelFor(
                            tpl.id,
                            fallback: tpl.label,
                          ),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tpl.sourceLabel,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _busy ? null : () => _applyTemplate(tpl),
                    child: Text(l10n.setupApplyTemplate),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// @Deprecated Prefer [SetupPanel] embedded in the Setup tab.
@Deprecated('Use SetupPanel in the garage Setup tab')
class SetupSheet extends StatelessWidget {
  const SetupSheet({super.key, required this.bike});

  final Bike bike;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scroll) {
        return ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            SetupPanel(bike: bike),
          ],
        );
      },
    );
  }
}
