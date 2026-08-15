import '../domain/component.dart';

/// Slot-Handles für Shopify-Tag-Filter (`slot:chain` → `slot-chain`).
/// Storefront-URLs: [ShopifyStorefront].
class ShopWebLinks {
  ShopWebLinks._();

  static String? partsSlotFromComponent(ComponentSlot slot) {
    return switch (slot) {
      ComponentSlot.chain => 'chain',
      ComponentSlot.cassette => 'cassette',
      ComponentSlot.grips => 'grips',
      ComponentSlot.tireFront || ComponentSlot.tireRear => 'tire',
      ComponentSlot.brakeFront || ComponentSlot.brakeRear => 'brake_pads',
      _ => null,
    };
  }
}
