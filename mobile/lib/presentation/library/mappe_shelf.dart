import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Rahmen für Stimmen, Sammlungen, Gruppen — ein Regal, kein nackter Fold.
class MappeShelf extends StatelessWidget {
  const MappeShelf({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}
