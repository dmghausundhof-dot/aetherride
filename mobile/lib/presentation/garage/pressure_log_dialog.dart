import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/bike.dart';
import '../../domain/garage/pressure_unit.dart';
import '../../domain/setup.dart';
import '../../domain/setup/sag_guide.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/app_providers.dart';

Future<bool> logBikePressure({
  required BuildContext context,
  required WidgetRef ref,
  required Bike bike,
  List<BikeSetup> existingSetups = const [],
}) async {
  final store = ref.read(userProfileStoreProvider);
  final l10n = AppLocalizations.of(context);
  final pair = loggedTirePsi(existingSetups);
  final result = await showDialog<_PressureResult>(
    context: context,
    builder: (ctx) => _PressureLogDialog(
      bike: bike,
      riderWeightKg: store.effectiveWeightKg,
      initialPref: store.pressureUnitPref,
      existingFrontPsi: pair.front,
      existingRearPsi: pair.rear,
    ),
  );
  if (result == null) return false;
  store.pressureUnitPref = result.pref;
  await store.save();
  final usesBar = resolvePressureUsesBar(bike.category, result.pref);
  final enteredF = result.frontEntered;
  final enteredR = result.rearEntered;
  if (enteredF == null && enteredR == null) return false;
  final f = enteredF == null
      ? null
      : enteredPressureToPsi(enteredF, bike.category, result.pref);
  final r = enteredR == null
      ? null
      : enteredPressureToPsi(enteredR, bike.category, result.pref);
  final current = await ref.read(setupRepositoryProvider).getCurrent(bike.id);
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
        bikeId: bike.id,
        label: l10n.dieBoxPressureLogged,
        values: values,
        createdBy: 'user',
        parentSetupId: current?.id,
      );
  ref.invalidate(currentSetupProvider(bike.id));
  await store.addMaintenanceLog(
    bikeId: bike.id,
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
    odometerKm: bike.odometerKm,
  );
  return true;
}

class _PressureResult {
  const _PressureResult({
    required this.pref,
    this.frontEntered,
    this.rearEntered,
  });
  final PressureUnitPref pref;
  final double? frontEntered;
  final double? rearEntered;
}

class _PressureLogDialog extends StatefulWidget {
  const _PressureLogDialog({
    required this.bike,
    required this.riderWeightKg,
    required this.initialPref,
    this.existingFrontPsi,
    this.existingRearPsi,
  });

  final Bike bike;
  final double riderWeightKg;
  final PressureUnitPref initialPref;
  final double? existingFrontPsi;
  final double? existingRearPsi;

  @override
  State<_PressureLogDialog> createState() => _PressureLogDialogState();
}

class _PressureLogDialogState extends State<_PressureLogDialog> {
  late PressureUnitPref _pref;
  late final TextEditingController _front;
  late final TextEditingController _rear;

  @override
  void initState() {
    super.initState();
    _pref = widget.initialPref == PressureUnitPref.auto
        ? (pressureUsesBar(widget.bike.category)
            ? PressureUnitPref.bar
            : PressureUnitPref.psi)
        : widget.initialPref;
    _front = TextEditingController(
      text: _display(widget.existingFrontPsi),
    );
    _rear = TextEditingController(
      text: _display(widget.existingRearPsi),
    );
  }

  @override
  void dispose() {
    _front.dispose();
    _rear.dispose();
    super.dispose();
  }

  bool get _usesBar => _pref == PressureUnitPref.bar;

  String _display(double? psi) {
    if (psi == null) return '';
    return formatPressureValue(psi, usesBar: _usesBar);
  }

  void _setPref(PressureUnitPref next) {
    if (next == _pref) return;
    final f = double.tryParse(_front.text.replaceAll(',', '.'));
    final r = double.tryParse(_rear.text.replaceAll(',', '.'));
    final frontPsi = f == null
        ? widget.existingFrontPsi
        : enteredPressureToPsi(f, widget.bike.category, _pref);
    final rearPsi = r == null
        ? widget.existingRearPsi
        : enteredPressureToPsi(r, widget.bike.category, _pref);
    setState(() {
      _pref = next;
      _front.text = _display(frontPsi);
      _rear.text = _display(rearPsi);
    });
  }

  @override
  Widget build(BuildContext context) {
    final d = AppLocalizations.of(context);
    final unit = _usesBar ? 'bar' : 'psi';
    final start = estimateTireStart(
      category: widget.bike.category,
      riderWeightKg: widget.riderWeightKg,
      bikeWeightKg: widget.bike.owner.weightKg,
    );
    final frontHint = _usesBar ? psiToBar(start.front) : start.front;
    final rearHint = _usesBar ? psiToBar(start.rear) : start.rear;
    return AlertDialog(
      title: Text(d.dieBoxPressureTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              d.dieBoxPressureHint,
              style: const TextStyle(fontSize: 13, color: AppColors.muted),
            ),
            const SizedBox(height: AppSpacing.s),
            SegmentedButton<PressureUnitPref>(
              segments: [
                ButtonSegment(
                  value: PressureUnitPref.bar,
                  label: Text(d.garageUnitBar),
                ),
                ButtonSegment(
                  value: PressureUnitPref.psi,
                  label: Text(d.garageUnitPsi),
                ),
              ],
              selected: {_pref},
              onSelectionChanged: (s) => _setPref(s.first),
              showSelectedIcon: false,
            ),
            const SizedBox(height: AppSpacing.s),
            Text(
              _usesBar
                  ? '${frontHint.toStringAsFixed(1)} / ${rearHint.toStringAsFixed(1)} $unit'
                  : '${frontHint.round()} / ${rearHint.round()} $unit',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.m),
            TextField(
              controller: _front,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: '${d.dieBoxPressureFront} ($unit)',
                hintText: _usesBar
                    ? frontHint.toStringAsFixed(1)
                    : frontHint.round().toString(),
                isDense: true,
              ),
            ),
            const SizedBox(height: AppSpacing.s),
            TextField(
              controller: _rear,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: '${d.dieBoxPressureRear} ($unit)',
                hintText: _usesBar
                    ? rearHint.toStringAsFixed(1)
                    : rearHint.round().toString(),
                isDense: true,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(d.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            _PressureResult(
              pref: _pref,
              frontEntered: double.tryParse(_front.text.replaceAll(',', '.')),
              rearEntered: double.tryParse(_rear.text.replaceAll(',', '.')),
            ),
          ),
          child: Text(d.save),
        ),
      ],
    );
  }
}

List<SetupValue> _mergeValues(
  List<SetupValue> current,
  List<SetupValue> incoming,
) {
  final byKey = <String, SetupValue>{
    for (final v in current) v.adjusterKey: v,
  };
  for (final v in incoming) {
    byKey[v.adjusterKey] = v;
  }
  return byKey.values.toList();
}
