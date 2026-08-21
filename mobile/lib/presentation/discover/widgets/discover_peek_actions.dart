import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

/// Peek-Aktionen nach Tourwahl: Navigieren · Merken · Akte.
class DiscoverPeekActions extends StatelessWidget {
  const DiscoverPeekActions({
    super.key,
    required this.onNavigate,
    required this.onSave,
    required this.onAkte,
    this.navigateLabel,
  });

  final VoidCallback onNavigate;
  final VoidCallback onSave;
  final VoidCallback onAkte;
  final String? navigateLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: FilledButton(
            key: const Key('discover-peek-navigate'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.chrome,
              foregroundColor: AppColors.onAccent,
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
            onPressed: onNavigate,
            child: Text(
              navigateLabel ?? l10n.goRide,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: OutlinedButton(
            key: const Key('discover-peek-save'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
            onPressed: onSave,
            child: Text(
              l10n.discoverPeekSave,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: OutlinedButton(
            key: const Key('discover-peek-akte'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
            onPressed: onAkte,
            child: Text(
              l10n.discoverPeekAkte,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }
}
