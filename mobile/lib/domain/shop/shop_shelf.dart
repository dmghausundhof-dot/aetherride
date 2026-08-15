/// Shop-Regale: Werkstatt-Teile vs. Merchandise vs. interner Garage-Hook.
/// Merch wird nicht über Garage-Fit gefiltert.
enum ShopShelf { parts, merch, garageHook, other }

const _merchTags = {
  'merch',
  'merchandise',
  'slot:merch',
  'product:merch',
};

const _garageHookTags = {
  'garage-bike',
  'garage_bike',
  'aetherride-garage',
  'garage-hook',
  'garage_hook',
};

const _partsSlots = {
  'brake_pads',
  'grips',
  'fluid',
  'chain',
  'tire',
  'cassette',
  'bar_tape',
  'rotor',
  'brake',
  'fork',
  'shock',
  'battery',
  'motor',
  'display',
};

final _merchTypeRe = RegExp(
  r'\b(t-?shirts?|tees?\b|hoodie|cap|kappe|hat\b|mütze|beanie|flasche|bottles?|trinkflasche|sticker|aufkleber|socken?|socks?|apparel|merch(?:andise)?|bekleidung|mug|tasse|tote|jersey|trikot|jacke|jacket|shirt)\b',
  caseSensitive: false,
);

final _partsTypeRe = RegExp(
  r'\b(tire|tyre|reifen|chain|kette|cassette|kassette|pad|belag|grip|griff|fluid|öl|oil|brake|bremse|rotor|fork|gabel|shock|dämpfer|derailleur|schaltung|bar.?tape|lenkerband)\b',
  caseSensitive: false,
);

final _fitTagRe = RegExp(
  r'^(?:category|cat|sport|discipline|fit|bike_type|wheel|wheel_size|laufrad|iso|shift_compat|drivetrain|groupset):',
  caseSensitive: false,
);

ShopShelf classifyShopProduct({
  List<String> tags = const [],
  String productType = '',
  String handle = '',
  String title = '',
  String slotKey = '',
}) {
  final h = handle.trim().toLowerCase();
  final type = productType.trim().toLowerCase();
  if (h.startsWith('ar-garage-') ||
      type == 'garage bike' ||
      type == 'garage-bike') {
    return ShopShelf.garageHook;
  }

  final slot = slotKey.trim().toLowerCase().replaceAll('-', '_');
  if (slot == 'merch') return ShopShelf.merch;

  final norm = [
    for (final t in tags) t.trim().toLowerCase(),
  ].where((t) => t.isNotEmpty).toList();
  if (norm.any(_garageHookTags.contains)) return ShopShelf.garageHook;
  if (norm.any(_merchTags.contains)) return ShopShelf.merch;

  if (slot.isNotEmpty && _partsSlots.contains(slot)) return ShopShelf.parts;
  for (final t in norm) {
    if (t.startsWith('slot:')) {
      final key = t.substring(5).replaceAll('-', '_');
      if (_partsSlots.contains(key)) return ShopShelf.parts;
    }
  }

  final blob = '$productType $title';
  if (_merchTypeRe.hasMatch(blob) && !_partsTypeRe.hasMatch(blob)) {
    return ShopShelf.merch;
  }
  if (norm.any(_fitTagRe.hasMatch) || _partsTypeRe.hasMatch(blob)) {
    return ShopShelf.parts;
  }
  return ShopShelf.other;
}

bool isMerchProduct({
  List<String> tags = const [],
  String productType = '',
  String handle = '',
  String title = '',
  String slotKey = '',
}) {
  return classifyShopProduct(
        tags: tags,
        productType: productType,
        handle: handle,
        title: title,
        slotKey: slotKey,
      ) ==
      ShopShelf.merch;
}
