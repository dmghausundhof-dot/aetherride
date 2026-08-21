import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/shop/shop_product.dart';
import '../../l10n/app_localizations.dart';
import '../garage/rad_stand_frame.dart';

String shopPriceLabel(ShopProduct product) {
  return NumberFormat.simpleCurrency(
    locale: 'de_DE',
    name: product.currencyCode,
  ).format(product.priceEur);
}

/// Produktakte im Laden — kein Warenkorb, Checkout bleibt Shopify.
class ShopProductSheet extends StatelessWidget {
  const ShopProductSheet({
    super.key,
    required this.product,
    required this.openLabel,
    required this.checkoutHint,
    this.fitLabel,
    this.webLabel,
    this.dealerLabel,
    this.onOpenShop,
    this.onOpenWeb,
    this.onOpenDealer,
  });

  final ShopProduct product;
  final String openLabel;
  final String checkoutHint;
  final String? fitLabel;
  final String? webLabel;
  final String? dealerLabel;
  final VoidCallback? onOpenShop;
  final VoidCallback? onOpenWeb;
  final VoidCallback? onOpenDealer;

  @override
  Widget build(BuildContext context) {
    final desc = product.description.trim();
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.l,
            AppSpacing.s,
            AppSpacing.l,
            AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.l),
              if (product.imageUrl != null && product.imageUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  child: AspectRatio(
                    aspectRatio: 16 / 10,
                    child: Image.network(
                      product.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const RadShopStandFallback(
                        markSize: 48,
                      ),
                    ),
                  ),
                )
              else
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  child: const SizedBox(
                    height: 120,
                    width: double.infinity,
                    child: RadShopStandFallback(markSize: 48),
                  ),
                ),
              const SizedBox(height: AppSpacing.l),
              if (product.manufacturer.isNotEmpty)
                Text(
                  product.manufacturer.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              Text(
                product.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
              if (fitLabel != null) ...[
                const SizedBox(height: AppSpacing.s),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.sage.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      fitLabel!,
                      style: const TextStyle(
                        color: AppColors.sageOnDark,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.s),
              Text(
                shopPriceLabel(product),
                style: const TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                ),
              ),
              if (desc.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.m),
                Text(
                  desc,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.m),
              Text(
                checkoutHint,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 13,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.l),
              if (onOpenShop != null)
                FilledButton(
                  key: const Key('shop-sheet-open'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.onAccent,
                    minimumSize: const Size(0, 52),
                  ),
                  onPressed: onOpenShop,
                  child: Text(
                    openLabel,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              if (onOpenDealer != null && dealerLabel != null) ...[
                const SizedBox(height: AppSpacing.s),
                TextButton(
                  key: const Key('shop-sheet-dealer'),
                  onPressed: onOpenDealer,
                  child: Text(
                    dealerLabel!,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
              if (onOpenWeb != null && webLabel != null) ...[
                const SizedBox(height: AppSpacing.s),
                TextButton(
                  key: const Key('shop-sheet-web'),
                  onPressed: onOpenWeb,
                  child: Text(
                    webLabel!,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showShopProductSheet({
  required BuildContext context,
  required ShopProduct product,
  required AppLocalizations l10n,
  String? fitLabel,
  VoidCallback? onOpenShop,
  VoidCallback? onOpenWeb,
  VoidCallback? onOpenDealer,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceDark,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppRadius.sheet),
      ),
    ),
    builder: (ctx) => ShopProductSheet(
      key: const Key('shop-product-sheet'),
      product: product,
      fitLabel: fitLabel,
      openLabel: l10n.shopOpenProduct,
      webLabel: l10n.shopOpenInBrowser,
      dealerLabel: l10n.shopZumHaendler,
      checkoutHint: l10n.shopSheetCheckout,
      onOpenShop: onOpenShop == null
          ? null
          : () {
              Navigator.pop(ctx);
              onOpenShop();
            },
      onOpenWeb: onOpenWeb == null
          ? null
          : () {
              Navigator.pop(ctx);
              onOpenWeb();
            },
      onOpenDealer: onOpenDealer == null
          ? null
          : () {
              Navigator.pop(ctx);
              onOpenDealer();
            },
    ),
  );
}
