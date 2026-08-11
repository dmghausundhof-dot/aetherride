import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/bike.dart';
import '../../domain/component.dart';
import '../../domain/garage/bike_schema_anchors.dart';
import '../../domain/garage/bike_schema_mapper.dart';

enum HotspotStatus { ok, missing, maintenance }

Color _statusColor(HotspotStatus s) => switch (s) {
      HotspotStatus.ok => const Color(statusColorOk),
      HotspotStatus.maintenance => const Color(statusColorMaintenance),
      HotspotStatus.missing => const Color(statusColorMissing),
    };

String _statusLabelDe(HotspotStatus s) => switch (s) {
      HotspotStatus.ok => 'gepflegt',
      HotspotStatus.maintenance => 'Wartung fällig',
      HotspotStatus.missing => 'Daten fehlen',
    };

/// Slot id used in hotspot JSON / anchors (snake_case web ids).
String _slotApiId(ComponentSlot slot) => slot.apiId;

/// G-SCH-05 — Flutter parity for web BikeSchema (same SVGs + anchors).
class BikeSchema extends StatelessWidget {
  const BikeSchema({
    super.key,
    required this.bike,
    required this.installedSlots,
    this.maintenanceSlots = const {},
    this.onSelectSlot,
    this.selectedSlot,
  });

  final Bike bike;
  final Set<ComponentSlot> installedSlots;
  final Set<ComponentSlot> maintenanceSlots;
  final ValueChanged<ComponentSlot>? onSelectSlot;
  final ComponentSlot? selectedSlot;

  @override
  Widget build(BuildContext context) {
    final isEbike = bike.category == BikeCategory.emtb ||
        bike.category == BikeCategory.etrekking;
    final hasRearShock = installedSlots.contains(ComponentSlot.rearShock) ||
        bike.category == BikeCategory.mtbAm ||
        bike.category == BikeCategory.mtbEnduro ||
        bike.category == BikeCategory.dh ||
        bike.category == BikeCategory.emtb ||
        (bike.travelRearMm != null && bike.travelRearMm! > 0);

    final plan = planBikeSchema(
      category: bike.category,
      isEbike: isEbike,
      hasRearShock: hasRearShock,
    );

    final key = plan.assetKey;
    final anchors = key != null
        ? schemaHotspots[key]!
        : hikingAnchors;
    final layers = key != null ? schemaLayers[key]! : const <String, SchemaLayer>{};

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(AppSpacing.s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: schemaViewBoxW / schemaViewBoxH,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final scaleX = constraints.maxWidth / schemaViewBoxW;
                final scaleY = constraints.maxHeight / schemaViewBoxH;
                // Uniform scale (meet)
                final scale = scaleX < scaleY ? scaleX : scaleY;
                final drawW = schemaViewBoxW * scale;
                final drawH = schemaViewBoxH * scale;
                final ox = (constraints.maxWidth - drawW) / 2;
                final oy = (constraints.maxHeight - drawH) / 2;

                Offset toLocal(double cx, double cy) =>
                    Offset(ox + cx * scale, oy + cy * scale);

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    if (key != null)
                      Positioned.fill(
                        child: SvgPicture.asset(
                          schemaAssetPath[key]!,
                          fit: BoxFit.contain,
                          semanticsLabel: '${bike.name} Schema',
                          placeholderBuilder: (context) => const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          errorBuilder: (context, error, stackTrace) =>
                              const Center(
                            child: Text(
                              'Schema nicht geladen',
                              style: TextStyle(color: AppColors.muted),
                            ),
                          ),
                        ),
                      )
                    else
                      Positioned.fill(
                        child: Container(
                          alignment: Alignment.center,
                          color: const Color(0xFF0A1210),
                          child: const Text(
                            'Wander-Ausrüstung',
                            style: TextStyle(color: Color(0xFFA8B5AE)),
                          ),
                        ),
                      ),
                    // Optional geometry layers
                    if (plan.showShock && layers['rear_shock'] != null)
                      CustomPaint(
                        size: Size(constraints.maxWidth, constraints.maxHeight),
                        painter: _LayerPainter(
                          layer: layers['rear_shock']!,
                          ox: ox,
                          oy: oy,
                          scale: scale,
                        ),
                      ),
                    if (plan.showEbike && layers['motor'] != null)
                      CustomPaint(
                        size: Size(constraints.maxWidth, constraints.maxHeight),
                        painter: _LayerPainter(
                          layer: layers['motor']!,
                          ox: ox,
                          oy: oy,
                          scale: scale,
                        ),
                      ),
                    if (plan.showEbike && layers['battery'] != null)
                      CustomPaint(
                        size: Size(constraints.maxWidth, constraints.maxHeight),
                        painter: _LayerPainter(
                          layer: layers['battery']!,
                          ox: ox,
                          oy: oy,
                          scale: scale,
                        ),
                      ),
                    for (final slot in plan.hotspotSlots)
                      if (anchors.containsKey(_slotApiId(slot)))
                        Builder(
                          builder: (context) {
                            final a = anchors[_slotApiId(slot)]!;
                            final center = toLocal(a.cx, a.cy);
                            final hitR =
                                (a.hitR < schemaHitRMin ? schemaHitRMin : a.hitR) *
                                    scale;
                            final status = !installedSlots.contains(slot)
                                ? HotspotStatus.missing
                                : maintenanceSlots.contains(slot)
                                    ? HotspotStatus.maintenance
                                    : HotspotStatus.ok;
                            final selected = selectedSlot == slot;
                            return Positioned(
                              left: center.dx - hitR,
                              top: center.dy - hitR,
                              width: hitR * 2,
                              height: hitR * 2,
                              child: Tooltip(
                                message:
                                    '${a.labelDe} — ${_statusLabelDe(status)}',
                                child: Semantics(
                                  button: true,
                                  label:
                                      '${a.labelDe} — ${_statusLabelDe(status)}',
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: onSelectSlot == null
                                        ? null
                                        : () => onSelectSlot!(slot),
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        if (selected)
                                          Container(
                                            width: hitR * 2,
                                            height: hitR * 2,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: AppColors.accent,
                                                width: 2.5,
                                              ),
                                            ),
                                          ),
                                        Container(
                                          width: schemaDotR * 2 * scale,
                                          height: schemaDotR * 2 * scale,
                                          decoration: BoxDecoration(
                                            color: _statusColor(status),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: const Color(0xFF0A1210),
                                              width: 1.5,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          const Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              _Legend(color: Color(statusColorOk), label: 'gepflegt'),
              _Legend(color: Color(statusColorMaintenance), label: 'Wartung'),
              _Legend(color: Color(statusColorMissing), label: 'fehlt'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.muted,
              ),
        ),
      ],
    );
  }
}

class _LayerPainter extends CustomPainter {
  _LayerPainter({
    required this.layer,
    required this.ox,
    required this.oy,
    required this.scale,
  });

  final SchemaLayer layer;
  final double ox;
  final double oy;
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    if (layer is SchemaLineLayer) {
      final l = layer as SchemaLineLayer;
      final paint = Paint()
        ..color = _parseColor(l.stroke)
        ..strokeWidth = l.strokeWidth * scale
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        Offset(ox + l.x1 * scale, oy + l.y1 * scale),
        Offset(ox + l.x2 * scale, oy + l.y2 * scale),
        paint,
      );
      return;
    }
    if (layer is SchemaRectLayer) {
      final r = layer as SchemaRectLayer;
      final paint = Paint()
        ..color = _parseColor(r.fill).withValues(alpha: 0.92)
        ..style = PaintingStyle.fill;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          ox + r.x * scale,
          oy + r.y * scale,
          r.width * scale,
          r.height * scale,
        ),
        Radius.circular(r.rx * scale),
      );
      canvas.drawRRect(rect, paint);
    }
  }

  Color _parseColor(String hex) {
    final h = hex.replaceFirst('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  @override
  bool shouldRepaint(covariant _LayerPainter oldDelegate) =>
      oldDelegate.layer != layer ||
      oldDelegate.scale != scale ||
      oldDelegate.ox != ox ||
      oldDelegate.oy != oy;
}
