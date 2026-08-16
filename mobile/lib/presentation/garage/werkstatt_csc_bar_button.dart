import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/sensor/bike_ble_store.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/app_providers.dart';
import 'ble_pair_sheet.dart';

/// Discreet Werkstatt-bar control for the bike CSC. Never a hero CTA.
class WerkstattCscBarButton extends ConsumerStatefulWidget {
  const WerkstattCscBarButton({
    super.key,
    required this.bikeId,
    this.isEbike = false,
  });

  final String bikeId;
  final bool isEbike;

  @override
  ConsumerState<WerkstattCscBarButton> createState() =>
      _WerkstattCscBarButtonState();
}

class _WerkstattCscBarButtonState extends ConsumerState<WerkstattCscBarButton> {
  BikeBleBinding _binding = const BikeBleBinding();
  bool _busy = false;
  StreamSubscription<dynamic>? _liveSub;

  @override
  void initState() {
    super.initState();
    unawaited(_reload());
    _liveSub = ref.read(bleCoreProvider).liveData.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant WerkstattCscBarButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bikeId != widget.bikeId) unawaited(_reload());
  }

  @override
  void dispose() {
    unawaited(_liveSub?.cancel());
    super.dispose();
  }

  Future<void> _reload() async {
    final b =
        await ref.read(bikeBleStoreProvider).bindingForBike(widget.bikeId);
    if (mounted) setState(() => _binding = b);
  }

  bool get _live {
    final ble = ref.read(bleCoreProvider);
    if (!ble.hasBikeLiveMetrics) return false;
    return ble.isRemoteLive(_binding.wheel?.deviceId) ||
        ble.isRemoteLive(_binding.drive?.deviceId);
  }

  Future<void> _pair() async {
    if (_busy) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.maybeOf(context);
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
        final name = ble.connectedDeviceName ??
            _binding.wheel?.name ??
            _binding.drive?.name;
        messenger?.showSnackBar(
          SnackBar(
            content: Text(
              name != null && name.isNotEmpty
                  ? AppLocalizations.of(context).garageBlePairedNamed(name)
                  : AppLocalizations.of(context).garageBlePaired,
            ),
          ),
        );
      }
    } catch (_) {
      messenger?.showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).blePairFailed)),
      );
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
    );
    await _applyManage(choice);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final live = _live;
    final saved = !_binding.isEmpty;
    final names = [
      _binding.drive?.name,
      _binding.wheel?.name,
    ].whereType<String>().where((n) => n.trim().isNotEmpty).toList();
    final tooltip = live
        ? (names.isEmpty ? l10n.bleSemanticsLive : names.join(' · '))
        : saved
            ? l10n.bleTooltipSaved
            : l10n.bleTooltipPair;
    return Semantics(
      button: true,
      label: live
          ? l10n.bleSemanticsLive
          : saved
              ? l10n.bleSemanticsPaired
              : l10n.bleSemanticsPair,
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          key: const Key('werkstatt-csc-bar'),
          onTap: _busy ? null : () => unawaited(_onTap()),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: _busy
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        Icons.bluetooth,
                        size: 22,
                        color: live
                            ? AppColors.chrome
                            : AppColors.muted,
                      ),
                      if (live)
                        Positioned(
                          right: -1,
                          top: -1,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.chrome,
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
