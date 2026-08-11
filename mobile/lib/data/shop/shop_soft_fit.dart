import '../../domain/component.dart';

/// Soft-fit filter contract (S-PART / Research Compat Gates attrs-dimmap).
/// Mirrors web `src/lib/shop/softFit.ts` for in-app Garage→Shop filtering.

typedef SoftFitSize = String; // 'S' | 'L'
typedef MaguraShape = String; // '7' | '8'
typedef SoftFitVerdict = String; // 'passt' | 'pruefen' | 'universal'

class SoftFitTags {
  const SoftFitTags({
    this.slots = const [],
    this.maguraShape,
    this.padShape,
    this.calipers = const [],
    this.size,
    this.shiftCompat = const [],
    this.raw = const [],
  });

  final List<String> slots;
  final MaguraShape? maguraShape;
  final MaguraShape? padShape;
  final List<String> calipers;
  final SoftFitSize? size;
  final List<String> shiftCompat;
  final List<String> raw;

  factory SoftFitTags.fromJson(Map<String, dynamic>? m) {
    if (m == null) return const SoftFitTags();
    return SoftFitTags(
      slots: _strList(m['slots']),
      maguraShape: _shape(m['maguraShape'] ?? m['magura_shape']),
      padShape: _shape(m['padShape'] ?? m['pad_shape']),
      calipers: _strList(m['calipers']),
      size: _size(m['size']),
      shiftCompat: _strList(m['shiftCompat'] ?? m['shift_compat']),
      raw: _strList(m['raw'] ?? m['tags']),
    );
  }

  static List<String> _strList(Object? v) {
    if (v is! List) return const [];
    return [for (final e in v) '$e'.trim()].where((s) => s.isNotEmpty).toList();
  }

  static MaguraShape? _shape(Object? v) {
    final s = '$v'.trim();
    if (s == '7' || s == '8') return s;
    return null;
  }

  static SoftFitSize? _size(Object? v) {
    final s = '$v'.trim().toUpperCase();
    if (s == 'S' || s == 'L') return s;
    return null;
  }
}

class SoftFitContext {
  const SoftFitContext({
    required this.bikeId,
    required this.bikeName,
    this.maguraShape,
    this.calipers = const [],
    this.size,
    this.shiftCompat = const [],
    this.installedSlots = const [],
    this.missingSlots = const [],
  });

  final String bikeId;
  final String bikeName;
  final MaguraShape? maguraShape;
  final List<String> calipers;
  final SoftFitSize? size;
  final List<String> shiftCompat;
  final List<ComponentSlot> installedSlots;
  final List<ComponentSlot> missingSlots;
}

/// Attrs → Soft-Fit dimensions (Research Compat Gates / attrs-dimmap).
abstract final class AttrsDimMap {
  static SoftFitContext fromInstalled({
    required String bikeId,
    required String bikeName,
    required List<BikeComponent> installed,
  }) {
    MaguraShape? magura;
    SoftFitSize? size;
    final calipers = <String>{};
    final shift = <String>{};
    final active = installed.where((c) => c.isInstalled).toList();
    final installedSlots = active.map((c) => c.slot).toList();

    for (final c in active) {
      final attrs = c.attributes;
      final modelBlob =
          '${c.manufacturer ?? ''} ${c.model ?? ''} ${attrs.values.join(' ')}'
              .toLowerCase();

      // Direct attr keys (dimmap)
      magura ??= _shapeOf(attrs['magura_shape'] ?? attrs['pad_shape']);
      size ??= SoftFitTags._size(attrs['size'] ?? attrs['grip_size']);
      final cal = attrs['caliper'] ?? attrs['caliper_model'];
      if (cal != null) {
        final t = '$cal'.trim().toLowerCase();
        if (t.isNotEmpty) calipers.add(t);
      }
      final sc = attrs['shift_compat'] ?? attrs['drivetrain_compat'];
      if (sc is List) {
        for (final e in sc) {
          final t = '$e'.trim().toLowerCase();
          if (t.isNotEmpty) shift.add(t);
        }
      } else if (sc != null) {
        final t = '$sc'.trim().toLowerCase();
        if (t.isNotEmpty) shift.add(t);
      }

      // Heuristics from model names (same spirit as web softFit)
      if (c.slot == ComponentSlot.brakeFront ||
          c.slot == ComponentSlot.brakeRear) {
        magura ??= _maguraFromModel(modelBlob);
        final calTag = _caliperFromModel(modelBlob);
        if (calTag != null) calipers.add(calTag);
      }
      if (c.slot == ComponentSlot.grips) {
        size ??= SoftFitTags._size(attrs['size']);
      }
      if (c.slot == ComponentSlot.rearDerailleur ||
          c.slot == ComponentSlot.shifter ||
          c.slot == ComponentSlot.cassette ||
          c.slot == ComponentSlot.chain) {
        shift.addAll(_shiftFromModel(modelBlob, c.manufacturer));
      }
    }

    final missing = <ComponentSlot>[
      for (final s in coreInstallSlots)
        if (!installedSlots.contains(s)) s,
    ];

    return SoftFitContext(
      bikeId: bikeId,
      bikeName: bikeName,
      maguraShape: magura,
      calipers: [...calipers],
      size: size,
      shiftCompat: [...shift],
      installedSlots: installedSlots,
      missingSlots: missing,
    );
  }

  static MaguraShape? _shapeOf(Object? v) => SoftFitTags._shape(v);

  static MaguraShape? _maguraFromModel(String blob) {
    if (blob.contains('mt7') || blob.contains('mt5') || blob.contains('8.p')) {
      return '8';
    }
    if (blob.contains('mt4') || blob.contains('mt2') || blob.contains('7.p')) {
      return '7';
    }
    return null;
  }

  static String? _caliperFromModel(String blob) {
    for (final c in ['mt7', 'mt5', 'mt4', 'mt2', 'mt8', 'mttrail']) {
      if (blob.contains(c)) return c;
    }
    if (blob.contains('magura')) return 'mt*';
    return null;
  }

  static Iterable<String> _shiftFromModel(String blob, String? manufacturer) {
    final out = <String>{};
    if (blob.contains('sram') || (manufacturer ?? '').toLowerCase().contains('sram')) {
      out.add('sram');
      if (blob.contains('eagle') || blob.contains('transmission')) {
        out.add('sram_eagle');
      }
    }
    if (blob.contains('shimano') ||
        (manufacturer ?? '').toLowerCase().contains('shimano')) {
      out.add('shimano');
      if (blob.contains('microspline')) out.add('microspline');
      if (blob.contains('hg ')) out.add('hg');
    }
    return out;
  }
}

SoftFitTags parseSoftFitTags(List<String> tags) {
  final slots = <String>{};
  final calipers = <String>{};
  final shiftCompat = <String>{};
  MaguraShape? maguraShape;
  MaguraShape? padShape;
  SoftFitSize? size;

  for (final raw in tags) {
    final tag = raw.trim();
    final slotMatch = RegExp(r'^slot:(.+)$', caseSensitive: false).firstMatch(tag);
    if (slotMatch != null) {
      final key = normalizePartsSlot(slotMatch.group(1)!.trim().toLowerCase());
      if (key != 'all') slots.add(key);
      continue;
    }
    final magura =
        RegExp(r'^magura_shape:([78])$', caseSensitive: false).firstMatch(tag);
    if (magura != null) {
      maguraShape = magura.group(1);
      continue;
    }
    final pad =
        RegExp(r'^pad:shape-([78])$', caseSensitive: false).firstMatch(tag);
    if (pad != null) {
      padShape = pad.group(1);
      continue;
    }
    final cal =
        RegExp(r'^caliper:(.+)$', caseSensitive: false).firstMatch(tag);
    if (cal != null) {
      calipers.add(cal.group(1)!.trim().toLowerCase());
      continue;
    }
    final sz = RegExp(r'^size:([sl])$', caseSensitive: false).firstMatch(tag);
    if (sz != null) {
      size = sz.group(1)!.toUpperCase();
      continue;
    }
    final sh =
        RegExp(r'^shift_compat:(.+)$', caseSensitive: false).firstMatch(tag);
    if (sh != null) {
      shiftCompat.add(sh.group(1)!.trim().toLowerCase());
    }
  }

  return SoftFitTags(
    slots: [...slots],
    maguraShape: maguraShape,
    padShape: padShape,
    calipers: [...calipers],
    size: size,
    shiftCompat: [...shiftCompat],
    raw: tags,
  );
}

String normalizePartsSlot(String? slot) {
  if (slot == null || slot.isEmpty || slot == 'all') return 'all';
  if (slot == 'brake_pads_front' ||
      slot == 'brake_pads_rear' ||
      slot == 'brake_front' ||
      slot == 'brake_rear') {
    return 'brake_pads';
  }
  if (slot == 'tire_front' || slot == 'tire_rear') return 'tire';
  const aliases = {
    'belaege': 'brake_pads',
    'pads': 'brake_pads',
    'griffe': 'grips',
    'brake_fluid': 'fluid',
    'oel': 'fluid',
    'kette': 'chain',
    'kassette': 'cassette',
    'reifen': 'tire',
    'lenkerband': 'bar_tape',
    'gravel': 'gravel',
    'road': 'road',
    'urban': 'urban',
  };
  return aliases[slot] ?? slot;
}

bool? _caliperMatches(List<String> productCals, List<String> bikeCals) {
  if (productCals.isEmpty || bikeCals.isEmpty) return null;
  for (final pc in productCals) {
    if (pc == 'mt*' || pc == '*') return true;
    if (bikeCals.contains(pc)) return true;
    if (pc.endsWith('*')) {
      final prefix = pc.substring(0, pc.length - 1);
      if (bikeCals.any((b) => b.startsWith(prefix))) return true;
    }
  }
  return false;
}

SoftFitVerdict softFitVerdict(SoftFitTags tags, SoftFitContext? ctx) {
  if (ctx == null) return 'universal';
  final productShape = tags.maguraShape ?? tags.padShape;
  var constrained = false;
  var ok = true;

  if (productShape != null && ctx.maguraShape != null) {
    constrained = true;
    if (productShape != ctx.maguraShape) ok = false;
  }
  final cal = _caliperMatches(tags.calipers, ctx.calipers);
  if (cal != null) {
    constrained = true;
    if (!cal) ok = false;
  }
  if (tags.size != null && ctx.size != null) {
    constrained = true;
    if (tags.size != ctx.size) ok = false;
  }
  if (tags.shiftCompat.isNotEmpty && ctx.shiftCompat.isNotEmpty) {
    constrained = true;
    final hit = tags.shiftCompat.any(ctx.shiftCompat.contains);
    if (!hit) ok = false;
  }
  if (!constrained) return 'universal';
  return ok ? 'passt' : 'pruefen';
}

bool productMatchesSlotFilter(SoftFitTags tags, String chip, String slotFilter) {
  final slot = normalizePartsSlot(slotFilter);
  if (slot == 'all') return true;
  if (tags.slots.contains(slot)) return true;
  if (normalizePartsSlot(chip) == slot) return true;
  final blob = tags.raw.join(' ').toLowerCase();
  if (slot == 'brake_pads' &&
      RegExp(r'belag|pad|7\.p|8\.p|magura_shape|pad:shape').hasMatch(blob)) {
    return true;
  }
  if (slot == 'grips' && RegExp(r'grip|ergon|gp1|size:[sl]').hasMatch(blob)) {
    return true;
  }
  // Seed bikes use discipline chips — allow when no softFit slots declared.
  if (tags.slots.isEmpty && (chip == slot || chip == 'universal')) return true;
  if (tags.slots.isNotEmpty) return false;
  return false;
}

bool productMatchesSoftFitFilter(
  SoftFitTags tags,
  SoftFitContext? ctx,
  String fitMode,
) {
  if (fitMode != 'bike' || ctx == null) return true;
  return softFitVerdict(tags, ctx) != 'pruefen';
}

String softFitChipLabel(SoftFitVerdict verdict, String? slotLabel) {
  if (verdict == 'passt') {
    return slotLabel != null ? 'passt · $slotLabel' : 'passt';
  }
  if (verdict == 'pruefen') return 'prüfen';
  return slotLabel ?? 'universal';
}
