import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/flowline_mark.dart';
import '../../domain/bike.dart';
import '../../domain/sport/discipline_ux.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_ext.dart';
import '../../native/location_core_channel.dart';
import '../../providers/app_providers.dart';
import '../../providers/ride_providers.dart';

/// Einmaliges Onboarding → erster echter GPS-Track oder Garage.
/// Multi-Sport: alle Disziplinen gleichwertig (kein MTB-first Framing).
class OnboardingFlow extends ConsumerStatefulWidget {
  const OnboardingFlow({super.key});

  @override
  ConsumerState<OnboardingFlow> createState() => OnboardingFlowState();
}

class OnboardingFlowState extends ConsumerState<OnboardingFlow> {
  int _step = 1;
  BikeCategory _sport = BikeCategory.urban;
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
      final l10n = AppLocalizations.of(context);
      setState(() => _status = l10n.onboardGpsStatus);
      final location = ref.read(locationCoreProvider);
      final result = await location.ensurePermissionDetailed();
      if (!mounted) return;
      if (result != LocationPermissionResult.granted) {
        setState(() {
          _busy = false;
          _status = switch (result) {
            LocationPermissionResult.servicesDisabled =>
              l10n.onboardServicesOff,
            LocationPermissionResult.deniedForever => l10n.onboardDeniedForever,
            _ => l10n.onboardNeedGps,
          };
        });
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

    ref.read(shellTabIndexProvider.notifier).state = 0;
  }

  /// System-back: vorheriger Schritt; auf Schritt 1 bleibt das Overlay.
  bool handleSystemBack() {
    if (!mounted) return true;
    if (_busy) return true;
    if (_step > 1) {
      setState(() => _step -= 1);
    }
    return true;
  }

  IconData _iconFor(String name) => switch (name) {
        'terrain' => Icons.terrain,
        'landscape' => Icons.landscape,
        'route' => Icons.route,
        'speed' => Icons.speed,
        'location_city' => Icons.location_city,
        'electric_bike' => Icons.electric_bike,
        'electric_moped' => Icons.electric_moped,
        'forest' => Icons.forest,
        _ => Icons.pedal_bike,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.border,
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
                              const FlowLineWordmark(
                                fontSize: 13,
                                showMark: true,
                                markSize: 18,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _step == 1
                                    ? l10n.onboardHowYouRide
                                    : _step == 2
                                        ? l10n.onboardYourWeight
                                        : l10n.onboardFirstRide,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _step == 1
                                    ? l10n.appTagline
                                    : _step == 2
                                        ? l10n.onboardWeightHint
                                        : l10n.onboardGpsHint,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: l10n.skip,
                          onPressed:
                              _busy ? null : () => unawaited(_finish('skip')),
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
                        childAspectRatio: 1.45,
                        children: [
                          for (final s in OnboardingSportOption.all)
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
                                        : AppColors.charcoal
                                            .withValues(alpha: 0.4),
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
                                    Icon(
                                      _iconFor(s.icon),
                                      size: 20,
                                      color: _sport == s.id
                                          ? AppColors.accent
                                          : AppColors.muted,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      l10n.onboardingSportLabel(s.id),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      l10n.onboardingSportBlurb(s.id),
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
                        l10n.onboardWeightLabel(_weight.round()),
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
                        l10n.onboardDiscipline(l10n.bikeCategoryShort(_sport)),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                    ] else ...[
                      Text(
                        l10n.onboardSensorsHint,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.muted,
                        ),
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
                          backgroundColor: AppColors.chrome,
                          minimumSize: const Size.fromHeight(48),
                        ),
                        onPressed: () => setState(() => _step = 2),
                        child: Text(l10n.next),
                      )
                    else if (_step == 2)
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.chrome,
                          minimumSize: const Size.fromHeight(48),
                        ),
                        onPressed: () => setState(() => _step = 3),
                        child: Text(l10n.onboardNextRide),
                      )
                    else ...[
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.chrome,
                          minimumSize: const Size.fromHeight(52),
                        ),
                        onPressed:
                            _busy ? null : () => unawaited(_finish('ride')),
                        child: _busy
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(l10n.startRide),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed:
                            _busy ? null : () => unawaited(_finish('garage')),
                        child: Text(l10n.onboardParkBikeFirst),
                      ),
                    ],
                    TextButton(
                      onPressed:
                          _busy ? null : () => unawaited(_finish('skip')),
                      child: Text(l10n.onboardLater),
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
