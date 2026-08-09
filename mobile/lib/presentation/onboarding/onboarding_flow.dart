import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/bike.dart';
import '../../native/location_core_channel.dart';
import '../../providers/app_providers.dart';
import '../../providers/ride_providers.dart';

class _SportOption {
  const _SportOption({
    required this.id,
    required this.label,
    required this.blurb,
  });
  final BikeCategory id;
  final String label;
  final String blurb;
}

const _sports = <_SportOption>[
  _SportOption(id: BikeCategory.mtbAm, label: 'MTB', blurb: 'Trails & All-Mountain'),
  _SportOption(
    id: BikeCategory.mtbEnduro,
    label: 'Enduro',
    blurb: 'Steil & technisch',
  ),
  _SportOption(id: BikeCategory.gravel, label: 'Gravel', blurb: 'Schotter & Distanz'),
  _SportOption(id: BikeCategory.emtb, label: 'E-MTB', blurb: 'Trail mit Assist'),
  _SportOption(id: BikeCategory.road, label: 'Rennrad', blurb: 'Asphalt'),
  _SportOption(id: BikeCategory.urban, label: 'City', blurb: 'Alltag & Pendeln'),
];

/// Einmaliges Onboarding → erster echter Freeride (GPS) oder Garage.
class OnboardingFlow extends ConsumerStatefulWidget {
  const OnboardingFlow({super.key});

  @override
  ConsumerState<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends ConsumerState<OnboardingFlow> {
  int _step = 1;
  BikeCategory _sport = BikeCategory.mtbAm;
  double _weight = 78;
  bool _busy = false;
  String? _status;

  Future<void> _finish(String next) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _status = null;
    });
    final store = ref.read(userProfileStoreProvider);
    await store.markOnboardingDone(sport: _sport, weightKg: _weight);
    ref.read(onboardingDoneProvider.notifier).state = true;
    ref.invalidate(riderProfileProvider);

    if (!mounted) return;

    if (next == 'ride') {
      setState(() => _status = 'Standort für GPS-Track…');
      final location = ref.read(locationCoreProvider);
      final result = await location.ensurePermissionDetailed();
      if (!mounted) return;
      if (result != LocationPermissionResult.granted) {
        setState(() {
          _busy = false;
          _status = switch (result) {
            LocationPermissionResult.servicesDisabled =>
              'Ortungsdienste einschalten, dann erneut versuchen.',
            LocationPermissionResult.deniedForever =>
              'Standort in den App-Einstellungen erlauben.',
            _ => 'Standort erlauben — ohne GPS kein Track.',
          };
        });
        // Onboarding bleibt abgeschlossen; User kann Ride-Tab manuell öffnen.
        if (result == LocationPermissionResult.deniedForever) {
          await location.openAppSettings();
        } else if (result == LocationPermissionResult.servicesDisabled) {
          await location.openLocationSettings();
        }
        return;
      }
      ref.read(rideAutostartProvider.notifier).state = true;
      ref.read(shellTabIndexProvider.notifier).state = 2;
      return;
    }

    if (next == 'garage') {
      ref.read(garageAddCategoryProvider.notifier).state = _sport;
      ref.read(garageOpenAddPendingProvider.notifier).state = true;
      ref.read(shellTabIndexProvider.notifier).state = 1;
      return;
    }

    // skip — Home bleibt
    ref.read(shellTabIndexProvider.notifier).state = 0;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.72),
      child: SafeArea(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Container(
              margin: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
              decoration: BoxDecoration(
                color: const Color(0xFF14201C),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.trail.withValues(alpha: 0.35),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Willkommen',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.6,
                                  color: AppColors.accent.withValues(alpha: 0.95),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _step == 1
                                    ? 'Was fährst du?'
                                    : _step == 2
                                        ? 'Dein Gewicht'
                                        : 'Erster Ride',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _step == 1
                                    ? 'Damit Routen und Setup zu dir passen.'
                                    : _step == 2
                                        ? 'Für SAG & Reichweite — nur lokal, jederzeit änderbar.'
                                        : 'GPS-Track starten — ohne Demo, ohne Fake-Daten. Bike optional.',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Überspringen',
                          onPressed: _busy ? null : () => unawaited(_finish('skip')),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_step == 1)
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 1.55,
                        children: [
                          for (final s in _sports)
                            InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () => setState(() => _sport = s.id),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: _sport == s.id
                                        ? AppColors.accent
                                        : AppColors.forest.withValues(alpha: 0.4),
                                    width: _sport == s.id ? 2 : 1,
                                  ),
                                  color: _sport == s.id
                                      ? AppColors.accent.withValues(alpha: 0.12)
                                      : const Color(0xFF1A2822),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      s.label,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      s.blurb,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      )
                    else if (_step == 2) ...[
                      Text(
                        'Fahrergewicht: ${_weight.round()} kg',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Slider(
                        value: _weight,
                        min: 40,
                        max: 140,
                        divisions: 100,
                        label: '${_weight.round()} kg',
                        activeColor: AppColors.accent,
                        onChanged: (v) => setState(() => _weight = v),
                      ),
                      Text(
                        'Sport: ${_sports.firstWhere((s) => s.id == _sport).label}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                    ] else ...[
                      const Text(
                        'Standort erlaubt den echten GPS-Track. '
                        'Bluetooth-Sensoren (CSC) sind optional.',
                        style: TextStyle(fontSize: 13, color: AppColors.muted),
                      ),
                      if (_status != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          _status!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                    ],
                    const SizedBox(height: 18),
                    if (_step == 1)
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          minimumSize: const Size.fromHeight(48),
                        ),
                        onPressed: () => setState(() => _step = 2),
                        child: const Text('Weiter'),
                      )
                    else if (_step == 2)
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          minimumSize: const Size.fromHeight(48),
                        ),
                        onPressed: () => setState(() => _step = 3),
                        child: const Text('Weiter zum Ride'),
                      )
                    else ...[
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          minimumSize: const Size.fromHeight(52),
                        ),
                        onPressed:
                            _busy ? null : () => unawaited(_finish('ride')),
                        child: _busy
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Ersten Ride starten'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed:
                            _busy ? null : () => unawaited(_finish('garage')),
                        child: const Text('Zuerst Bike anlegen'),
                      ),
                    ],
                    TextButton(
                      onPressed: _busy ? null : () => unawaited(_finish('skip')),
                      child: const Text('Später einrichten'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
