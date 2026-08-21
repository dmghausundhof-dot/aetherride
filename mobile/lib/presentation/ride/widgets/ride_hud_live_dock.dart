import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/nav_hud_tokens.dart';
import '../../../domain/active_route.dart';
import '../../../domain/hud_lean_calibration.dart';
import '../../../l10n/l10n_ext.dart';
import 'ride_hud_island.dart';

/// One compact live readout in the Daten dock.
class HudDockMetric {
  const HudDockMetric(this.label, this.value);

  final String label;
  final String value;
}

/// Charcoal island shared by Daten / Fahrwerk — or a bare body inside the
/// layer bar so the map stays the primary surface.
class RideHudLiveDock extends StatelessWidget {
  const RideHudLiveDock({
    super.key,
    required this.child,
    this.embedded = false,
  });

  final Widget child;
  final bool embedded;

  static const dockKey = Key('ride-hud-live-dock');
  static const dataKey = Key('ride-hud-data-dock');
  static const chassisKey = Key('ride-hud-chassis-dock');
  static const calibrateKey = Key('ride-lean-calibrate');
  static const resetCalKey = Key('ride-lean-reset-cal');
  static const gaugeKey = Key('ride-lean-gauge');
  static const maxDataChips = 6;

  @override
  Widget build(BuildContext context) {
    if (embedded) {
      return KeyedSubtree(key: dockKey, child: child);
    }
    return RideHudIsland(
      key: dockKey,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.m,
        AppSpacing.s,
        AppSpacing.m,
        AppSpacing.s,
      ),
      child: child,
    );
  }
}

/// Compact live metrics — two-row chips, map stays behind.
class RideHudDataDock extends StatelessWidget {
  const RideHudDataDock({
    super.key,
    required this.metrics,
    this.embedded = false,
  });

  final List<HudDockMetric> metrics;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10nOrNull;
    final shown = metrics.length <= RideHudLiveDock.maxDataChips
        ? metrics
        : metrics.sublist(0, RideHudLiveDock.maxDataChips);
    return RideHudLiveDock(
      embedded: embedded,
      child: KeyedSubtree(
        key: RideHudLiveDock.dataKey,
        child: shown.isEmpty
            ? Text(
                l10n?.rideWaitingSensors ?? 'Warte auf Sensorik…',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.meta(context),
                ),
              )
            : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (var i = 0; i < shown.length; i++) ...[
                      if (i > 0) const SizedBox(width: AppSpacing.s),
                      _metricChip(context, shown[i]),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _metricChip(BuildContext context, HudDockMetric metric) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 64),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            metric.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 1.1,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            metric.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppColors.meta(context),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact Fahrwerk: lean gauge + G/Flow + mount-zero in one row.
class RideHudChassisDock extends StatelessWidget {
  const RideHudChassisDock({
    super.key,
    required this.mount,
    required this.onMarkMounted,
    this.leanDeg,
    this.gPeak,
    this.flow,
    this.calibrated = false,
    this.calibrateEnabled = true,
    this.onCalibrate,
    this.onResetCal,
    this.embedded = false,
  });

  final MountCheck mount;
  final VoidCallback onMarkMounted;
  final double? leanDeg;
  final double? gPeak;
  final double? flow;
  final bool calibrated;
  final bool calibrateEnabled;
  final VoidCallback? onCalibrate;
  final VoidCallback? onResetCal;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10nOrNull;
    final live = HudLeanCalibration.hasLiveSample(
      leanDeg: leanDeg,
      gPeak: gPeak,
      flow: flow,
    );
    final calHint = calibrateEnabled
        ? (l10n?.rideCalibrateLeanHint ??
            'Lenker gerade halten — setzt die aktuelle Neigung auf 0°.')
        : (l10n?.rideCalibrateLeanHold ?? 'Kurz anhalten zum Kalibrieren');
    final calLabel = l10n?.rideCalibrateLean ?? 'Kalibrieren';

    if (!live) {
      final prime = mount != MountCheck.mounted;
      return RideHudLiveDock(
        embedded: embedded,
        child: KeyedSubtree(
          key: RideHudLiveDock.chassisKey,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  prime
                      ? calHint
                      : (l10n?.rideWaitingSensors ?? 'Warte auf Sensorik…'),
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.25,
                    color: AppColors.meta(context),
                  ),
                ),
              ),
              if (prime) ...[
                const SizedBox(width: AppSpacing.s),
                _calibrateButton(
                  label: calLabel,
                  hint: calHint,
                  onPressed: () {
                    onMarkMounted();
                    onCalibrate?.call();
                  },
                ),
              ],
            ],
          ),
        ),
      );
    }

    return RideHudLiveDock(
      embedded: embedded,
      child: KeyedSubtree(
        key: RideHudLiveDock.chassisKey,
        child: Row(
          children: [
            RideLeanGauge(leanDeg: leanDeg ?? 0),
            const SizedBox(width: AppSpacing.s),
            Expanded(
              child: _stat(
                context,
                value: gPeak == null
                    ? NavHudTokens.emptyStat
                    : gPeak!.toStringAsFixed(2),
                label: l10n?.rideGPeak ?? 'g-Spitze',
              ),
            ),
            Expanded(
              child: _stat(
                context,
                value: flow == null
                    ? NavHudTokens.emptyStat
                    : flow!.toStringAsFixed(2),
                label: l10n?.rideFlow ?? 'Flow',
              ),
            ),
            Flexible(
              child: _calibrateButton(
                label: calLabel,
                hint: calHint,
                onPressed: !calibrateEnabled || leanDeg == null
                    ? null
                    : () {
                        onMarkMounted();
                        onCalibrate?.call();
                      },
              ),
            ),
            if (calibrated && onResetCal != null)
              IconButton(
                key: RideHudLiveDock.resetCalKey,
                tooltip: l10n?.rideResetLeanCal ?? 'Nullung zurück',
                onPressed: onResetCal,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.restart_alt, size: 20),
              ),
          ],
        ),
      ),
    );
  }

  Widget _calibrateButton({
    required String label,
    required String hint,
    required VoidCallback? onPressed,
  }) {
    return Tooltip(
      message: hint,
      child: OutlinedButton(
        key: RideHudLiveDock.calibrateKey,
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 36),
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }

  Widget _stat(
    BuildContext context, {
    required String value,
    required String label,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          maxLines: 1,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            height: 1.1,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: AppColors.meta(context),
          ),
        ),
      ],
    );
  }
}

/// Glanceable lean: horizon + tilted bar, signed degrees on the face.
class RideLeanGauge extends StatelessWidget {
  const RideLeanGauge({super.key, required this.leanDeg});

  final double leanDeg;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.chromeFill(context);
    final tick = AppColors.meta(context);
    final ink = AppColors.sheetInk(context);
    final label = HudLeanCalibration.formatDeg(leanDeg);
    return Semantics(
      label: label,
      child: SizedBox(
        key: RideHudLiveDock.gaugeKey,
        width: 56,
        height: 56,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: const Size(56, 56),
              painter: _LeanGaugePainter(
                leanDeg: HudLeanCalibration.gaugeVisualDeg(leanDeg),
                accent: accent,
                tick: tick,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                height: 1,
                color: ink,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeanGaugePainter extends CustomPainter {
  const _LeanGaugePainter({
    required this.leanDeg,
    required this.accent,
    required this.tick,
  });

  final double leanDeg;
  final Color accent;
  final Color tick;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.shortestSide / 2;
    final ring = Paint()
      ..color = tick.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawCircle(c, r - 1, ring);

    final horizon = Paint()
      ..color = tick.withValues(alpha: 0.55)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(c.dx - r + 8, c.dy),
      Offset(c.dx + r - 8, c.dy),
      horizon,
    );

    final rad = leanDeg * math.pi / 180;
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(rad);
    final bar = Paint()
      ..color = accent.withValues(alpha: 0.85)
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(-r + 10, 0), Offset(r - 10, 0), bar);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LeanGaugePainter old) =>
      old.leanDeg != leanDeg || old.accent != accent || old.tick != tick;
}
