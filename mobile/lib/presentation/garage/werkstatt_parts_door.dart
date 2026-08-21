import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/config.dart';
import '../../l10n/app_localizations.dart';
import '../shop/shop_screen.dart';
import 'garage_chrome.dart';
import '../shared/chrome_glyph.dart';

/// Ruhige Zeile in der Rad-Liste: Tür zum Laden, gebunden ans Rad.
/// Kein Banner, kein Grid, kein Preis.
class WerkstattPartsDoor extends ConsumerWidget {
  const WerkstattPartsDoor({
    super.key,
    required this.bikeId,
    this.bikeName,
    this.slot,
    this.lookupOnly = false,
  });

  final String bikeId;
  final String? bikeName;
  final String? slot;
  final bool lookupOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!AppConfig.shopEnabled) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final title = lookupOnly ? l10n.shopLookupInShop : l10n.werkstattPartsForBike;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: lookupOnly
            ? const Key('werkstatt-parts-lookup')
            : const Key('werkstatt-parts-row'),
        onTap: () => openShopGateway(
          context,
          ref,
          bikeId: bikeId,
          slot: slot,
        ),
        borderRadius: BorderRadius.circular(AppRadius.chip),
        child: Ink(
          decoration: garageCardDecoration(),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.m,
              vertical: AppSpacing.s,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: AppColors.chrome,
                          ),
                        ),
                        if (!lookupOnly &&
                            bikeName != null &&
                            bikeName!.isNotEmpty)
                          TextSpan(
                            text: ' · $bikeName',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: AppColors.muted,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const ChromeGlyph(
                  'share',
                  size: 16,
                  color: AppColors.muted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
