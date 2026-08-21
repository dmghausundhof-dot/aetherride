import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme/app_theme.dart';
import 'mappe_glyph.dart';

class MappeEmptyBlock extends StatelessWidget {
  const MappeEmptyBlock({
    super.key,
    required this.title,
    required this.hint,
    this.compact = false,
    this.actions,
  });

  final String title;
  final String hint;
  final bool compact;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        compact ? 12 : 16,
        compact ? 8 : 12,
        compact ? 12 : 16,
        compact ? 12 : 16,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          SvgPicture.asset(
            'assets/tours/empty-mappe.svg',
            width: compact ? 180 : 240,
            excludeFromSemantics: true,
          ),
          SizedBox(height: compact ? 8 : 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const MappeGlyph('mappe', size: 18),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            hint,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.muted),
          ),
          if (actions != null && actions!.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: actions!,
            ),
          ],
        ],
      ),
    );
  }
}
