import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

/// Result of the offline-aware reroute sheet (N-02b).
enum RerouteSheetAction {
  rejoin,
  stay,
  skip,
}

/// Online off-route sheet: Rejoin · Stay · Skip section.
/// Caller: no graph and far off-route → toast. Graph or close splice → sheet.
Future<RerouteSheetAction?> showRerouteSheet(
  BuildContext context, {
  bool online = true,
}) {
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
      final l10n = AppLocalizations.of(ctx);
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
                l10n.rerouteTitle,
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                online ? l10n.rerouteHint : l10n.rerouteHintOffline,
                style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                      color: AppColors.meta(ctx),
                    ),
              ),
              const SizedBox(height: AppSpacing.l),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.chromeFill(ctx),
                  foregroundColor: AppColors.inkOnChrome(ctx),
                  minimumSize: const Size.fromHeight(52),
                ),
                onPressed: () =>
                    Navigator.of(ctx).pop(RerouteSheetAction.rejoin),
                icon: const Icon(Icons.alt_route),
                label: Text(
                  l10n.rerouteRejoin,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
              const SizedBox(height: AppSpacing.s),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: () => Navigator.of(ctx).pop(RerouteSheetAction.stay),
                child: Text(
                  l10n.rerouteStay,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: AppSpacing.s),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(RerouteSheetAction.skip),
                child: Text(
                  l10n.rerouteSkip,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
