import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/bike.dart';
import '../../domain/setup.dart';
import '../../domain/setup/bracketing.dart';
import '../../domain/setup/templates.dart';
import '../../providers/app_providers.dart';

/// Setup-Liste, Templates, manuelle Version, Bracketing-MVP.
class SetupSheet extends ConsumerStatefulWidget {
  const SetupSheet({super.key, required this.bike});

  final Bike bike;

  @override
  ConsumerState<SetupSheet> createState() => _SetupSheetState();
}

class _SetupSheetState extends ConsumerState<SetupSheet> {
  List<BikeSetup> _setups = [];
  bool _busy = false;
  double _riderWeight = 75;
  String? _bracketMsg;

  @override
  void initState() {
    super.initState();
    _load();
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

  Future<void> _applyTemplate(SetupTemplate tpl) async {
    setState(() => _busy = true);
    await ref.read(setupRepositoryProvider).createVersion(
          bikeId: widget.bike.id,
          label: '${tpl.label} (Vorlage)',
          values: tpl.toValues(_riderWeight, widget.bike.category),
          conditions: tpl.conditions,
          createdBy: 'template',
        );
    ref.invalidate(currentSetupProvider(widget.bike.id));
    await _load();
    if (mounted) {
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vorlage übernommen — ${tpl.disclaimer}')),
      );
    }
  }

  Future<void> _setCurrent(BikeSetup s) async {
    await ref.read(setupRepositoryProvider).setCurrent(widget.bike.id, s.id);
    ref.invalidate(currentSetupProvider(widget.bike.id));
    await _load();
  }

  Future<void> _manualVersion() async {
    final current = await ref
        .read(setupRepositoryProvider)
        .getCurrent(widget.bike.id);
    final base = Map<String, double>.from(
      current?.adjusterMap ??
          {for (final v in BikeSetup.defaultValues()) v.adjusterKey: v.valueNum},
    );
    final rebound = base['fork.rebound'] ?? 8;
    final ctrl = TextEditingController(text: rebound.toStringAsFixed(0));
    final labelCtrl = TextEditingController(text: 'Manuell v${(_setups.length + 1)}');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Neue Setup-Version'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelCtrl,
              decoration: const InputDecoration(labelText: 'Label'),
            ),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Gabel Zugstufe (Klicks)',
              ),
            ),
          ],
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
    final next = double.tryParse(ctrl.text) ?? rebound;
    base['fork.rebound'] = next.clamp(0, 14);
    final values = [
      for (final e in base.entries)
        SetupValue(
          adjusterKey: e.key,
          valueNum: e.value,
          unit: e.key.contains('pressure') ? 'psi' : 'clicks',
        ),
    ];
    await ref.read(setupRepositoryProvider).createVersion(
          bikeId: widget.bike.id,
          label: labelCtrl.text.trim().isEmpty ? 'Manuell' : labelCtrl.text.trim(),
          values: values,
          parentSetupId: current?.id,
        );
    ref.invalidate(currentSetupProvider(widget.bike.id));
    await _load();
  }

  Future<void> _startBracketing() async {
    final current =
        await ref.read(setupRepositoryProvider).getCurrent(widget.bike.id);
    final rebound = current?.valueFor('fork.rebound') ?? 8;
    final series = createBlindPair(
      adjusterKey: 'fork.rebound',
      currentValue: rebound,
    );
    final a = series.rangeFrom.clamp(0, 14);
    final b = series.rangeTo.clamp(0, 14);

    // Zwei Blind-Varianten als Setup-Versionen anlegen (Labels A/B ohne Werte)
    await ref.read(setupRepositoryProvider).createVersion(
          bikeId: widget.bike.id,
          label: 'Bracketing A (blind)',
          values: [
            for (final v in (current?.values ?? BikeSetup.defaultValues()))
              v.adjusterKey == 'fork.rebound'
                  ? SetupValue(
                      adjusterKey: v.adjusterKey,
                      valueNum: a.toDouble(),
                      unit: v.unit,
                    )
                  : v,
          ],
          createdBy: 'user',
          parentSetupId: current?.id,
        );
    await ref.read(setupRepositoryProvider).createVersion(
          bikeId: widget.bike.id,
          label: 'Bracketing B (blind)',
          values: [
            for (final v in (current?.values ?? BikeSetup.defaultValues()))
              v.adjusterKey == 'fork.rebound'
                  ? SetupValue(
                      adjusterKey: v.adjusterKey,
                      valueNum: b.toDouble(),
                      unit: v.unit,
                    )
                  : v,
          ],
          createdBy: 'user',
          parentSetupId: current?.id,
        );

    // Auswertung: bevorzugt echte Ride-Metriken, sonst synthetischer Fallback
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
        adjusterKey: 'fork.rebound',
        rangeFrom: a.toDouble(),
        rangeTo: b.toDouble(),
        step: (b - a).abs() < 1e-6 ? 2.0 : (b - a).abs().toDouble(),
        runs: runs,
      ),
    );

    ref.invalidate(currentSetupProvider(widget.bike.id));
    await _load();
    if (mounted) {
      setState(() {
        _bracketMsg = fromRides
            ? 'Blind A/B angelegt · Auswertung aus ${rides.where((r) => r.bikeId == widget.bike.id && r.feedback != null).length} Rides: ${eval.summary}'
            : 'Blind A/B angelegt · noch zu wenig Ride-Feedback — Demo-Auswertung: ${eval.summary}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tpls = templatesFor(widget.bike.category);
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
            Text(
              'Setups · ${widget.bike.name}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Fahrergewicht (kg) für OEM-Tabellen',
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
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    minimumSize: const Size(0, 44),
                  ),
                  onPressed: _busy ? null : _manualVersion,
                  child: const Text('Neue Version'),
                ),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
                  onPressed: _busy ? null : _startBracketing,
                  child: const Text('Bracketing'),
                ),
              ],
            ),
            if (_bracketMsg != null) ...[
              const SizedBox(height: 8),
              Text(
                _bracketMsg!,
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              'Gespeicherte Versionen',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            if (_setups.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Noch keine Setups — Vorlage anwenden.',
                  style: TextStyle(color: AppColors.muted),
                ),
              ),
            for (final s in _setups)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  '${s.isCurrent ? '● ' : ''}${s.label} · v${s.version}',
                ),
                subtitle: Text(
                  [
                    s.conditions,
                    s.createdBy,
                    if (s.valueFor('fork.rebound') != null)
                      'Zug ${s.valueFor('fork.rebound')!.toStringAsFixed(0)}',
                  ].join(' · '),
                ),
                trailing: s.isCurrent
                    ? const Text('aktuell', style: TextStyle(fontSize: 12))
                    : TextButton(
                        onPressed: () => _setCurrent(s),
                        child: const Text('Aktiv'),
                      ),
              ),
            const SizedBox(height: 16),
            Text(
              'Vorlagen (Ausgangspunkt)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const Text(
              'Keine persönliche Empfehlung — OEM/Editorial-Startpunkt.',
              style: TextStyle(fontSize: 12, color: AppColors.muted),
            ),
            const SizedBox(height: 8),
            for (final tpl in tpls)
              Card(
                child: ListTile(
                  title: Text(tpl.label),
                  subtitle: Text(
                    '${tpl.kind} · ${tpl.sourceLabel}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: TextButton(
                    onPressed: _busy ? null : () => _applyTemplate(tpl),
                    child: const Text('Anwenden'),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
