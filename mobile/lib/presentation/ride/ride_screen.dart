import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/ble.dart';
import '../../domain/sensor.dart';
import '../../providers/app_providers.dart';

class RideScreen extends ConsumerStatefulWidget {
  const RideScreen({super.key});

  @override
  ConsumerState<RideScreen> createState() => _RideScreenState();
}

class _RideScreenState extends ConsumerState<RideScreen> {
  bool _active = false;
  FusedMetrics? _metrics;
  BoschLiveData? _ldi;
  StreamSubscription<SensorBlock>? _sensorSub;
  StreamSubscription<BoschLiveData>? _bleSub;

  Future<void> _toggle() async {
    final sensor = ref.read(sensorCoreProvider);
    final ble = ref.read(bleCoreProvider);

    if (_active) {
      await _sensorSub?.cancel();
      await _bleSub?.cancel();
      await sensor.stop();
      await ble.disconnect();
      setState(() => _active = false);
      return;
    }

    await sensor.start();
    await ble.connect();
    _sensorSub = sensor.blocks.listen((b) {
      if (mounted) setState(() => _metrics = b.fused);
    });
    _bleSub = ble.liveData.listen((d) {
      if (mounted) setState(() => _ldi = d);
    });
    setState(() => _active = true);
  }

  @override
  void dispose() {
    _sensorSub?.cancel();
    _bleSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ride')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _active ? 'Aufnahme läuft' : 'Bereit',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'sensor_core + ble_core: Stub bis native Plugins gebunden sind.',
            ),
            const SizedBox(height: 24),
            if (_metrics != null) ...[
              _MetricRow('G-Peak', _metrics!.gForcePeak.toStringAsFixed(2)),
              _MetricRow('Lean °', _metrics!.leanAngleDeg.toStringAsFixed(1)),
              _MetricRow('Flow', _metrics!.flowContribution.toStringAsFixed(2)),
            ],
            if (_ldi != null) ...[
              const Divider(height: 32),
              _MetricRow('Speed', '${_ldi!.speedKmh.toStringAsFixed(1)} km/h'),
              _MetricRow('SOC', '${_ldi!.batterySocPercent.toStringAsFixed(0)} %'),
              _MetricRow('Power', '${_ldi!.riderPowerW.toStringAsFixed(0)} W'),
              _MetricRow('Cadence', '${_ldi!.cadenceRpm.toStringAsFixed(0)} rpm'),
            ],
            const Spacer(),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _active ? Colors.redAccent : AppColors.accent,
                minimumSize: const Size.fromHeight(56),
              ),
              onPressed: _toggle,
              child: Text(_active ? 'Stop' : 'Start'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyLarge),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
          ),
        ],
      ),
    );
  }
}
