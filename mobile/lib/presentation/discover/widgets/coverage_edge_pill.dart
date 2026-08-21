import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Pack name on the map chrome — readable against hillshade, unlike map text.
class CoverageEdgePill extends StatelessWidget {
  const CoverageEdgePill({
    super.key,
    required this.label,
    this.outside = false,
    this.overview = false,
    this.needsNet = false,
    this.onTap,
  });

  final String label;
  final bool outside;
  final bool overview;
  final bool needsNet;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final fill = outside ? const Color(0xE61F1F1F) : const Color(0xF2F4F1EC);
    final ink = outside ? const Color(0xFFFFB080) : const Color(0xFF3D2914);
    final icon = outside || needsNet
        ? Icons.wifi_off
        : overview
            ? Icons.layers_outlined
            : Icons.map_outlined;
    final iconColor = outside
        ? const Color(0xFFFF6A00)
        : needsNet
            ? AppColors.sage
            : overview
                ? AppColors.sage
                : AppColors.sageOnDark;
    return Material(
      color: fill,
      elevation: 3,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        key: const Key('discover-coverage-edge-pill'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: iconColor,
              ),
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 220),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: ink,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
