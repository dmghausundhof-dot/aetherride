import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/sensor/bike_ble_store.dart';
import '../../domain/bike.dart';
import '../../domain/ble/ble_link_status.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/app_providers.dart';
import 'ble_pair_sheet.dart';

/// Discreet Werkstatt-bar control for the bike CSC. Never a hero CTA.
class WerkstattCscBarButton extends ConsumerStatefulWidget {
  const WerkstattCscBarButton({
    super.key,
    required this.bikeId,
    this.isEbike = false,
    this.wheelSize,
  });

  final String bikeId;
  final bool isEbike;
  final WheelSize? wheelSize;

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
    return ble.isBindingLive(
      wheelId: _binding.wheel?.deviceId,
      driveId: _binding.drive?.deviceId,
      driveKind: _binding.drive?.kind,
    );
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
        ble.wheelCircumferenceM = wheelCircumferenceM(widget.wheelSize);
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
    final ble = ref.read(bleCoreProvider);
    if (choice == 'unlinkWheel' || choice == 'unlinkAll') {
      if (choice == 'unlinkAll') {
        await store.removeForBike(widget.bikeId);
        try {
          await ble.disconnectBikeKeepWatch();
        } catch (_) {}
      } else {
        await store.removeWheel(widget.bikeId);
        try {
          await ble.disconnectCsc();
        } catch (_) {}
      }
      try {
        await ble.forgetLastBikeId();
      } catch (_) {}
      await store.removeLastCscIdFile();
    } else if (choice == 'unlinkDrive') {
      await store.removeDrive(widget.bikeId);
      try {
        await ble.disconnectDriveKeepWheel();
      } catch (_) {}
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
      wheelName: bleWheelDisplayName(storedName: _binding.wheel?.name),
      driveName: bleDriveDisplayName(
        storedName: _binding.drive?.name,
        deviceId: _binding.drive?.deviceId,
      ),
    );
    await _applyManage(choice);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final live = _live;
    final saved = !_binding.isEmpty;
    final names = [
      if (_binding.drive != null)
        bleDriveDisplayName(
          storedName: _binding.drive?.name,
          deviceId: _binding.drive?.deviceId,
        ),
      if (_binding.wheel != null)
        bleWheelDisplayName(storedName: _binding.wheel?.name),
    ];
    final label = names.isEmpty ? null : names.join(' · ');
    final tooltip = live
        ? (label == null ? l10n.bleSemanticsLive : l10n.bleLinkLiveNamed(label))
        : saved
            ? (label == null
                ? l10n.bleTooltipSaved
                : l10n.bleLinkSavedNamed(label))
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
                        color: live ? AppColors.chrome : AppColors.muted,
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
