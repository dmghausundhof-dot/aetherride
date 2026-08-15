import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Result of the offline-aware reroute sheet (N-02b).
enum RerouteSheetAction {
  rejoin,
  stay,
  skip,
}

/// Online off-route sheet: Rejoin · Stay · Skip section.
/// Caller handles offline toast separately (no fake replan).
Future<RerouteSheetAction?> showRerouteSheet(BuildContext context) {
  return showModalBottomSheet<RerouteSheetAction>(
    context: context,
    isScrollControlled: false,
    showDragHandle: true,
    backgroundColor: Theme.of(context).cardColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppRadius.sheet),
      ),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.l,
            AppSpacing.s,
            AppSpacing.l,
            AppSpacing.l,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Abseits der Route.',
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Ruhig bleiben — du entscheidest.',
                style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                      color: AppColors.muted,
                    ),
              ),
              const SizedBox(height: AppSpacing.l),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.forestOnDark,
                  minimumSize: const Size.fromHeight(52),
                ),
                onPressed: () =>
                    Navigator.of(ctx).pop(RerouteSheetAction.rejoin),
                icon: const Icon(Icons.alt_route),
                label: const Text(
                  'Zurück zur Route',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
              const SizedBox(height: AppSpacing.s),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: () => Navigator.of(ctx).pop(RerouteSheetAction.stay),
                child: const Text(
                  'Bleiben',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: AppSpacing.s),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(RerouteSheetAction.skip),
                child: const Text(
                  'Abschnitt überspringen',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
