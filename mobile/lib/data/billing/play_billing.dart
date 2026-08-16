import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// Google Play subscription product id for FlowLine Pro (monthly).
const kPlayProMonthlyId = 'aetherride_pro_monthly';

class PurchaseUpdate {
  const PurchaseUpdate({
    required this.purchaseToken,
    required this.productId,
  });

  final String purchaseToken;
  final String productId;
}

/// Thin wrapper around `in_app_purchase` for Pro monthly **subscription**.
///
/// Play subscriptions use [InAppPurchase.buyNonConsumable] in the Flutter
/// plugin (there is no separate buySubscription API on the main interface).
class PlayBilling {
  PlayBilling({InAppPurchase? iap}) : _iap = iap ?? InAppPurchase.instance;

  final InAppPurchase _iap;
  StreamSubscription<List<PurchaseDetails>>? _sub;
  final _controller = StreamController<PurchaseUpdate>.broadcast();
  final _errors = StreamController<String>.broadcast();

  Stream<PurchaseUpdate> get updates => _controller.stream;
  Stream<String> get errors => _errors.stream;

  Future<bool> get isAvailable => _iap.isAvailable();

  Future<void> start() async {
    if (_sub != null) return;
    _sub = _iap.purchaseStream.listen(
      _onPurchases,
      onError: (Object e) {
        debugPrint('PlayBilling: $e');
        if (!_errors.isClosed) _errors.add('$e');
      },
    );
  }

  void _onPurchases(List<PurchaseDetails> purchases) {
    for (final p in purchases) {
      if (p.status == PurchaseStatus.pending) continue;
      if (p.status == PurchaseStatus.error) {
        final msg = p.error?.message ?? 'Play-Kauf fehlgeschlagen';
        debugPrint('PlayBilling error: ${p.error}');
        if (!_errors.isClosed) _errors.add(msg);
        continue;
      }
      if (p.status == PurchaseStatus.purchased ||
          p.status == PurchaseStatus.restored) {
        final token = p.verificationData.serverVerificationData;
        if (token.isNotEmpty && !_controller.isClosed) {
          _controller.add(
            PurchaseUpdate(
              purchaseToken: token,
              productId: p.productID,
            ),
          );
        }
        if (p.pendingCompletePurchase) {
          unawaited(_iap.completePurchase(p));
        }
      }
    }
  }

  /// Starts the Play Billing flow for the Pro monthly **subscription** SKU.
  Future<void> buyProMonthly() async {
    final available = await _iap.isAvailable();
    if (!available) {
      throw Exception('Play Billing nicht verfügbar');
    }
    final response = await _iap.queryProductDetails({kPlayProMonthlyId});
    if (response.error != null) {
      throw Exception(response.error!.message);
    }
    if (response.productDetails.isEmpty) {
      throw Exception(
        'Abo-Produkt $kPlayProMonthlyId nicht gefunden. '
        'In Play Console als Subscription anlegen (Internal Testing + License Tester).',
      );
    }
    final product = response.productDetails.first;
    final param = PurchaseParam(productDetails: product);
    // Subscription SKUs are purchased via buyNonConsumable in this plugin.
    final ok = await _iap.buyNonConsumable(purchaseParam: param);
    if (!ok) throw Exception('Kauf konnte nicht gestartet werden');
  }

  Future<void> restorePurchases() async {
    final available = await _iap.isAvailable();
    if (!available) {
      throw Exception('Play Billing nicht verfügbar');
    }
    await _iap.restorePurchases();
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
    await _controller.close();
    await _errors.close();
  }
}
