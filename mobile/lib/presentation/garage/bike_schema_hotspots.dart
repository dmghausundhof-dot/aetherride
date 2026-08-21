import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/bike.dart';
import '../../domain/component.dart';
import '../../domain/garage/bike_schema_anchors.dart';
import '../../domain/garage/bike_schema_mapper.dart';
import '../../domain/garage/schema_invites.dart';
import '../../domain/maintenance/intervals.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_ext.dart';
import 'rad_stand_frame.dart';

/// Tippbare Slot-Punkte auf der Silhouette (F-GAR-004).
class BikeSchemaHotspots extends StatelessWidget {
  const BikeSchemaHotspots({
    super.key,
    required this.bike,
    this.components = const [],
    this.due = const [],
    this.height = 168,
    this.onTapSlot,
  });

  final Bike bike;
  final List<BikeComponent> components;
  final List<MaintenanceAlert> due;
  final double height;
  final ValueChanged<ComponentSlot>? onTapSlot;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final plan = planBikeSchema(
      category: bike.category,
      isEbike: bike.hasElectricAssist,
      hasRearShock: (bike.travelRearMm ?? 0) > 0 ||
          components.any(
            (c) => c.isInstalled && c.slot == ComponentSlot.rearShock,
          ),
    );
    final assetKey = plan.assetKey;
    final asset = assetKey == null ? null : schemaAssetPath[assetKey];
    final anchors = assetKey == null ? null : schemaHotspots[assetKey];
    if (asset == null || anchors == null || anchors.isEmpty) {
      return const SizedBox.shrink();
    }

    final installed = {
      for (final c in components)
        if (c.isInstalled) c.slot,
    };
    final dueSlots = {for (final a in due) a.slot};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.garageSchemaHint,
          style: const TextStyle(fontSize: 12, color: AppColors.muted),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            _legendDot(
              const Color(statusColorOk),
              l10n.garageSchemaLegendOk,
            ),
            _legendDot(
              const Color(statusColorMissing),
              l10n.garageSchemaLegendOpen,
            ),
            _legendDot(
              const Color(statusColorMaintenance),
              l10n.garageSchemaLegendDue,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s),
        SizedBox(
          key: const Key('bike-schema-hotspots'),
          height: height,
          width: double.infinity,
          child: RadStandFrame(
            height: height,
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 18),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final w = constraints.maxWidth;
                  final h = constraints.maxHeight;
                  final scale =
                      math.min(w / schemaViewBoxW, h / schemaViewBoxH);
                  final dx = (w - schemaViewBoxW * scale) / 2;
                  final dy = (h - schemaViewBoxH * scale) / 2;
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: ColoredBox(
                      color: const Color(0xFFF4F1EA),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              child: SvgPicture.asset(
                                asset,
                                fit: BoxFit.contain,
                                excludeFromSemantics: true,
                              ),
                            ),
                          ),
                          for (final slot in plan.hotspotSlots)
                            if (anchors[slot.apiId] != null)
                              _dot(
                                context: context,
                                anchor: anchors[slot.apiId]!,
                                slot: slot,
                                scale: scale,
                                dx: dx,
                                dy: dy,
                                status: dueSlots.contains(slot)
                                    ? _HotspotStatus.maintenance
                                    : installed.contains(slot)
                                        ? _HotspotStatus.ok
                                        : _HotspotStatus.missing,
                                label: l10n.componentSlotLabel(slot),
                                onTap: onTapSlot,
                              ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        ...() {
          final invite = schemaInviteSlots(
            hotspotSlots: plan.hotspotSlots,
            installed: installed,
            due: dueSlots,
          );
          if (invite.isEmpty) return const <Widget>[];
          final hidden = schemaHiddenOpenCount(
            hotspotSlots: plan.hotspotSlots,
            installed: installed,
            due: dueSlots,
          );
          return [
            const SizedBox(height: AppSpacing.s),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final s in invite)
                  ActionChip(
                    visualDensity: VisualDensity.compact,
                    label: Text(
                      l10n.componentSlotLabel(s),
                      style: const TextStyle(fontSize: 11),
                    ),
                    onPressed: onTapSlot == null ? null : () => onTapSlot!(s),
                  ),
              ],
            ),
            if (hidden > 0) ...[
              const SizedBox(height: 4),
              Text(
                l10n.garageSchemaMoreOnDots,
                style: const TextStyle(fontSize: 11, color: AppColors.muted),
              ),
            ],
          ];
        }(),
      ],
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.muted),
        ),
      ],
    );
  }

  Widget _dot({
    required BuildContext context,
    required SchemaAnchor anchor,
    required ComponentSlot slot,
    required double scale,
    required double dx,
    required double dy,
    required _HotspotStatus status,
    required String label,
    required ValueChanged<ComponentSlot>? onTap,
  }) {
    final hit = math.max(44.0, anchor.hitR * 2 * scale);
    final cx = dx + anchor.cx * scale;
    final cy = dy + anchor.cy * scale;
    final quiet = schemaHotspotQuiet(
      slot,
      missing: status == _HotspotStatus.missing,
    );
    final color = quiet
        ? const Color(0xFFC4BDB0)
        : switch (status) {
            _HotspotStatus.ok => const Color(statusColorOk),
            _HotspotStatus.maintenance => const Color(statusColorMaintenance),
            _HotspotStatus.missing => const Color(statusColorMissing),
          };
    final size = quiet ? 7.0 : 12.0;
    return Positioned(
      left: cx - hit / 2,
      top: cy - hit / 2,
      width: hit,
      height: hit,
      child: Semantics(
        button: true,
        label: label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap == null ? null : () => onTap(slot),
            child: Center(
              child: Opacity(
                opacity: quiet ? 0.55 : 1,
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                    border: Border.all(
                      color: const Color(0xFF1E1E26),
                      width: 1,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _HotspotStatus { ok, missing, maintenance }
