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

/// Charcoal island shared by Daten / Fahrwerk — sits in the HUD stack,
/// never replaces the map.
class RideHudLiveDock extends StatelessWidget {
  const RideHudLiveDock({super.key, required this.child});

  final Widget child;

  static const dockKey = Key('ride-hud-live-dock');
  static const dataKey = Key('ride-hud-data-dock');
  static const chassisKey = Key('ride-hud-chassis-dock');
  static const calibrateKey = Key('ride-lean-calibrate');
  static const resetCalKey = Key('ride-lean-reset-cal');
  static const gaugeKey = Key('ride-lean-gauge');

  @override
  Widget build(BuildContext context) {
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
  const RideHudDataDock({super.key, required this.metrics});

  final List<HudDockMetric> metrics;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10nOrNull;
    return RideHudLiveDock(
      child: KeyedSubtree(
        key: RideHudLiveDock.dataKey,
        child: metrics.isEmpty
            ? Text(
                l10n?.rideWaitingSensors ?? 'Warte auf Sensorik…',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.meta(context),
                ),
              )
            : Wrap(
                spacing: AppSpacing.s,
                runSpacing: AppSpacing.s,
                children: [
                  for (final m in metrics) _metricChip(context, m),
                ],
              ),
      ),
    );
  }

  Widget _metricChip(BuildContext context, HudDockMetric metric) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 72),
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

/// Compact Fahrwerk dock: lean gauge + G/Flow + mount-zero calibrate.
class RideHudChassisDock extends StatelessWidget {
  const RideHudChassisDock({
    super.key,
    required this.mount,
    required this.onMarkMounted,
    this.leanDeg,
    this.gPeak,
    this.flow,
    this.calibrated = false,
    this.onCalibrate,
    this.onResetCal,
  });

  final MountCheck mount;
  final VoidCallback onMarkMounted;
  final double? leanDeg;
  final double? gPeak;
  final double? flow;
  final bool calibrated;
  final VoidCallback? onCalibrate;
  final VoidCallback? onResetCal;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10nOrNull;
    if (mount != MountCheck.mounted) {
      return RideHudLiveDock(
        child: KeyedSubtree(
          key: RideHudLiveDock.chassisKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n?.rideChassisOff ?? 'Fahrwerksanalyse aus',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n?.rideChassisHint ??
                    'Handy am Lenker befestigen und als montiert markieren.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.25,
                  color: AppColors.meta(context),
                ),
              ),
              const SizedBox(height: AppSpacing.s),
              FilledButton(
                onPressed: onMarkMounted,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 40),
                  visualDensity: VisualDensity.compact,
                ),
                child: Text(l10n?.rideMarkMounted ?? 'Als montiert markieren'),
              ),
            ],
          ),
        ),
      );
    }

    final waiting = leanDeg == null && gPeak == null && flow == null;
    return RideHudLiveDock(
      child: KeyedSubtree(
        key: RideHudLiveDock.chassisKey,
        child: waiting
            ? Text(
                l10n?.rideWaitingSensors ?? 'Warte auf Sensorik…',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.meta(context),
                ),
              )
            : Row(
                children: [
                  RideLeanGauge(leanDeg: leanDeg ?? 0),
                  const SizedBox(width: AppSpacing.m),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _stat(
                                context,
                                value: leanDeg == null
                                    ? NavHudTokens.emptyStat
                                    : HudLeanCalibration.formatDeg(leanDeg!),
                                label: l10n?.rideLean ?? 'Neig.',
                              ),
                            ),
                            Expanded(
                              child: _stat(
                                context,
                                value: gPeak == null
                                    ? NavHudTokens.emptyStat
                                    : gPeak!.toStringAsFixed(2),
                                label: l10n?.rideGPeak ?? 'G-Peak',
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
                          ],
                        ),
                        const SizedBox(height: AppSpacing.s),
                        Row(
                          children: [
                            Expanded(
                              child: Tooltip(
                                message: l10n?.rideCalibrateLeanHint ??
                                    'Lenker gerade halten — setzt die aktuelle Neigung auf 0°.',
                                child: OutlinedButton.icon(
                                  key: RideHudLiveDock.calibrateKey,
                                  onPressed:
                                      leanDeg == null ? null : onCalibrate,
                                  icon: const Icon(
                                    Icons.horizontal_rule,
                                    size: 16,
                                  ),
                                  label: Text(
                                    l10n?.rideCalibrateLean ?? 'Kalibrieren',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size(0, 36),
                                    visualDensity: VisualDensity.compact,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.s,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (calibrated && onResetCal != null) ...[
                              const SizedBox(width: AppSpacing.s),
                              IconButton(
                                key: RideHudLiveDock.resetCalKey,
                                tooltip:
                                    l10n?.rideResetLeanCal ?? 'Nullung zurück',
                                onPressed: onResetCal,
                                visualDensity: VisualDensity.compact,
                                icon: const Icon(Icons.restart_alt, size: 20),
                              ),
                            ],
                          ],
                        ),
                        if (calibrated)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              l10n?.rideLeanCalibrated ?? 'genullt',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.meta(context),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _stat(BuildContext context, {required String value, required String label}) {
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

/// Glanceable lean: horizon + tilted bike bar, signed degrees.
class RideLeanGauge extends StatelessWidget {
  const RideLeanGauge({super.key, required this.leanDeg});

  final double leanDeg;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.chromeFill(context);
    final tick = AppColors.meta(context);
    return SizedBox(
      key: RideHudLiveDock.gaugeKey,
      width: 64,
      height: 64,
      child: CustomPaint(
        painter: _LeanGaugePainter(
          leanDeg: leanDeg,
          accent: accent,
          tick: tick,
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
      ..color = accent
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(-r + 10, 0), Offset(r - 10, 0), bar);
    final diamond = Path()
      ..moveTo(0, -7)
      ..lineTo(5, 0)
      ..lineTo(0, 7)
      ..lineTo(-5, 0)
      ..close();
    canvas.drawPath(diamond, Paint()..color = accent);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LeanGaugePainter old) =>
      old.leanDeg != leanDeg || old.accent != accent || old.tick != tick;
}
