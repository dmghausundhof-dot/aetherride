import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config.dart';
import '../../core/shop_launcher.dart';
import '../../core/shopify_storefront.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/bike.dart';
import '../../domain/shop/garage_fit.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/app_providers.dart';
import '../../providers/ride_providers.dart';
import '../shell/shell_tabs.dart';

/// Shop-Tab: Gateway zum Shopify-Shop. Kein In-App-Katalog, kein Warenkorb.
class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  Bike? _rideBike(WidgetRef ref, List<Bike>? bikes) {
    if (bikes == null) return null;
    final rideable =
        bikes.where((b) => isRideableGarageBike(b.category)).toList();
    if (rideable.isEmpty) return null;
    final pending = ref.watch(shopPendingBikeIdProvider);
    if (pending != null) {
      for (final b in rideable) {
        if (b.id == pending) return b;
      }
    }
    for (final b in rideable) {
      if (b.isActive) return b;
    }
    return rideable.first;
  }

  Future<void> _open(
      BuildContext context, AppLocalizations l10n, Uri? uri) async {
    final ok = await openShopifyStorefront(uri);
    if (ok || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.shopOpenFailed)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final bike = _rideBike(ref, ref.watch(bikesProvider).valueOrNull);
    final connected = ShopifyStorefront.isConfigured;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navShop)),
      body: SafeArea(
        child: ListView(
          key: const Key('shop-gateway'),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.l,
            AppSpacing.l,
            AppSpacing.l,
            AppSpacing.xxxl,
          ),
          children: [
            Text(
              l10n.shopGatewayKicker,
              style: const TextStyle(
                color: AppColors.forestOnDark,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.shopGatewayTitle,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: AppSpacing.s),
            Text(
              l10n.shopGatewayHint,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 15,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (AppConfig.shopifyOnlineStoreLocked) ...[
              const SizedBox(height: AppSpacing.m),
              Text(
                l10n.shopPasswordWall,
                key: const Key('shop-password-wall'),
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 13,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            if (!connected) ...[
              Text(
                l10n.shopNotConnected,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.shopNotConnectedHint,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
            ] else
              FilledButton(
                key: const Key('shop-go'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.forestOnDark,
                  foregroundColor: const Color(0xFF0A1210),
                  minimumSize: const Size(0, 52),
                ),
                onPressed: () =>
                    _open(context, l10n, ShopifyStorefront.homeUri()),
                child: Text(
                  l10n.shopZumShop,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.xxl),
            if (bike == null)
              _ShopDoor(
                icon: Icons.pedal_bike_outlined,
                title: l10n.werkstattForYourBike,
                hint: l10n.shopForYourBikeEmpty,
                actionLabel: l10n.hofParkBike,
                onTap: () {
                  ref.read(garageOpenAddPendingProvider.notifier).state = true;
                  ref.read(shellTabIndexProvider.notifier).state =
                      ShellTabs.werkstatt;
                },
              )
            else
              _ShopDoor(
                key: const Key('shop-parts'),
                icon: Icons.pedal_bike_outlined,
                title: l10n.werkstattForYourBike,
                hint: l10n.shopForYourBikeHint(bike.name),
                onTap: connected
                    ? () => _open(
                          context,
                          l10n,
                          ShopifyStorefront.partsFitUri(bike: bike),
                        )
                    : null,
              ),
            const SizedBox(height: AppSpacing.m),
            _ShopDoor(
              key: const Key('shop-merch'),
              icon: Icons.checkroom_outlined,
              title: l10n.werkstattMerch,
              hint: l10n.shopMerchHint,
              onTap: connected
                  ? () => _open(context, l10n, ShopifyStorefront.merchUri())
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _ShopDoor extends StatelessWidget {
  const _ShopDoor({
    super.key,
    required this.icon,
    required this.title,
    required this.hint,
    this.actionLabel,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String hint;
  final String? actionLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: AppColors.forest.withValues(alpha: 0.10),
        highlightColor: AppColors.forest.withValues(alpha: 0.06),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.forestOnDark, size: 22),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      hint,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                    if (actionLabel != null) ...[
                      const SizedBox(height: AppSpacing.s),
                      Text(
                        actionLabel!,
                        style: const TextStyle(
                          color: AppColors.forestOnDark,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                actionLabel != null ? Icons.arrow_forward : Icons.north_east,
                size: 16,
                color: AppColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
