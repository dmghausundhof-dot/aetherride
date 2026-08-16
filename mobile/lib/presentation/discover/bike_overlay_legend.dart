import 'package:flutter/material.dart';

import '../../domain/routing/bike_overlay_class.dart';

class BikeOverlayLegend extends StatelessWidget {
  const BikeOverlayLegend({
    super.key,
    required this.family,
    required this.visible,
    required this.extraOn,
    required this.onToggleVisible,
    required this.onToggleClass,
    this.hasOverlayData = true,
  });

  final BikeOverlayFamily family;
  final bool visible;
  final Set<BikeOverlayClass> extraOn;
  final VoidCallback onToggleVisible;
  final ValueChanged<BikeOverlayClass> onToggleClass;
  final bool hasOverlayData;

  @override
  Widget build(BuildContext context) {
    if (!hasOverlayData) {
      return Material(
        color: Colors.black.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 168),
            child: const Text(
              'Wege kommen mit dem Stadt-Pack und dem Radnetz-Schalter — nicht auf diesem Überblick.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 10,
                height: 1.3,
              ),
            ),
          ),
        ),
      );
    }
    final primary = overlayClassesForFamily(family).toSet();
    final rows = <({BikeOverlayClass cls, String label, Color color})>[
      (cls: BikeOverlayClass.mtb, label: 'S0', color: _hex(BikeOverlayColors.s0)),
      (cls: BikeOverlayClass.mtb, label: 'S1', color: _hex(BikeOverlayColors.s1)),
      (cls: BikeOverlayClass.mtb, label: 'S2', color: _hex(BikeOverlayColors.s2)),
      (cls: BikeOverlayClass.mtb, label: 'S3', color: _hex(BikeOverlayColors.s3)),
      (
        cls: BikeOverlayClass.mtbUnrated,
        label: 'unbewertet',
        color: _hex(BikeOverlayColors.unrated),
      ),
      (
        cls: BikeOverlayClass.gravel,
        label: 'Gravel',
        color: _hex(BikeOverlayColors.gravel),
      ),
      (
        cls: BikeOverlayClass.road,
        label: 'Radweg / Asphalt',
        color: _hex(BikeOverlayColors.road),
      ),
      (
        cls: BikeOverlayClass.urban,
        label: 'City',
        color: _hex(BikeOverlayColors.urban),
      ),
    ];

    return Material(
      color: Colors.black.withValues(alpha: 0.72),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 168),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: onToggleVisible,
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Wege · OSM',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    Text(
                      visible ? 'an' : 'aus',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              for (final row in rows)
                InkWell(
                  onTap: () => onToggleClass(row.cls),
                  child: Opacity(
                    opacity: visible &&
                            (primary.contains(row.cls) || extraOn.contains(row.cls))
                        ? 1
                        : 0.38,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Container(
                            width: 14,
                            height: 3,
                            decoration: BoxDecoration(
                              color: row.color,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            row.label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 4),
              const Text(
                'S0–S3 nur bei OSM-Tag. Sonst unbewertet.',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 9,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Color _hex(String css) {
  final h = css.replaceFirst('#', '');
  return Color(int.parse('FF$h', radix: 16));
}
