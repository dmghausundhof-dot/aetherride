/// Garage → Teileshop Kompatibilität (Spiegel src/lib/shop/garageFit.ts).
///
/// Nur echte Felder: Kategorie, Laufradgröße, E-Bike vs. analog, Schaltung.
/// Keine erfundenen OEM-SKUs.
library;

import '../bike.dart';
import '../component.dart';

class GarageBikeProfile {
  const GarageBikeProfile({
    required this.id,
    required this.name,
    required this.category,
    required this.categoryLabel,
    required this.wheelSizes,
    required this.isEbike,
    required this.drivetrain,
    required this.families,
    this.brand,
    this.model,
  });

  final String id;
  final String name;
  final String? brand;
  final String? model;
  final BikeCategory category;
  final String categoryLabel;
  final List<String> wheelSizes;
  final bool isEbike;
  final List<String> drivetrain;
  final List<String> families;
}

class GarageFitConstraint {
  const GarageFitConstraint({
    this.families = const [],
    this.wheelSizes = const [],
    this.ebike = 'any',
    this.drivetrain = const [],
  });

  final List<String> families;
  final List<String> wheelSizes;
  /// any | only | no
  final String ebike;
  final List<String> drivetrain;

  bool get isEmpty =>
      families.isEmpty &&
      wheelSizes.isEmpty &&
      ebike == 'any' &&
      drivetrain.isEmpty;
}

class GarageFitResult {
  const GarageFitResult({
    required this.kind,
    required this.compatible,
    required this.matchedBikes,
    this.label,
  });

  /// match | universal | mismatch
  final String kind;
  final bool compatible;
  final List<GarageBikeProfile> matchedBikes;
  final String? label;
}

const _familyAliases = <String, String>{
  'mtb': 'mtb',
  'mountainbike': 'mtb',
  'mountain': 'mtb',
  'trail': 'mtb',
  'enduro': 'mtb',
  'downhill': 'mtb',
  'dh': 'mtb',
  'am': 'mtb',
  'allmountain': 'mtb',
  'mtb_trail': 'mtb',
  'mtb_am': 'mtb',
  'mtb_enduro': 'mtb',
  'emtb': 'mtb',
  'gravel': 'gravel',
  'road': 'road',
  'rennrad': 'road',
  'race': 'road',
  'urban': 'urban',
  'city': 'urban',
  'trekking': 'urban',
  'etrekking': 'urban',
  'commuter': 'urban',
};

const _drivetrainSlots = {
  ComponentSlot.cassette,
  ComponentSlot.chain,
  ComponentSlot.crankset,
  ComponentSlot.rearDerailleur,
  ComponentSlot.shifter,
  ComponentSlot.frontDerailleur,
};

bool isRideableGarageBike(BikeCategory category) =>
    category != BikeCategory.hiking;

List<String> familiesFromBike(BikeCategory category) {
  switch (category) {
    case BikeCategory.mtbTrail:
    case BikeCategory.mtbAm:
    case BikeCategory.mtbEnduro:
    case BikeCategory.dh:
    case BikeCategory.emtb:
      return const ['mtb'];
    case BikeCategory.gravel:
      return const ['gravel'];
    case BikeCategory.road:
      return const ['road'];
    case BikeCategory.urban:
    case BikeCategory.etrekking:
      return const ['urban'];
    case BikeCategory.hiking:
      return const [];
  }
}

String? normalizeWheel(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  final t = raw
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'''['"zoll]'''), '')
      .replaceAll(',', '.')
      .replaceAll(RegExp(r'\s+'), '');
  if (t == '29' || t == '29er' || t == '29x') return '29';
  if (t == '27_5' || t == '27.5' || t == '275' || t == '27.5er') return '27.5';
  if (t == '650b' || t == '650') return '650b';
  if (t == '700c' || t == '700' || t == '28-622') return '700c';
  return null;
}

String? wheelFromEnum(WheelSize? size) {
  if (size == null) return null;
  return switch (size) {
    WheelSize.w29 => '29',
    WheelSize.w275 => '27.5',
    WheelSize.c700 => '700c',
    WheelSize.b650 => '650b',
  };
}

String wheelLabel(String w) => switch (w) {
      '29' => '29"',
      '27.5' => '27.5"',
      '650b' => '650b',
      '700c' => '700c',
      _ => w,
    };

bool wheelsCompatible(List<String> product, List<String> bike) {
  if (product.isEmpty || bike.isEmpty) return true;
  List<String> expand(String w) =>
      (w == '27.5' || w == '650b') ? const ['27.5', '650b'] : [w];
  final bikeSet = <String>{};
  for (final w in bike) {
    bikeSet.addAll(expand(w));
  }
  return product.any((p) => expand(p).any(bikeSet.contains));
}

List<String> inferDrivetrainTokens(String manufacturer, String model) {
  final blob = '${manufacturer.toLowerCase()} ${model.toLowerCase()}';
  final out = <String>[];
  if (RegExp(r'shimano|deore|xt|xtr|slx|ultegra|dura-ace|\b105\b|grx|cues')
      .hasMatch(blob)) {
    out.add('shimano');
  }
  if (RegExp(r'sram|eagle|gx|xx|x0|force|rival|\bred\b').hasMatch(blob)) {
    out.add('sram');
  }
  if (blob.contains('rohloff')) out.add('rohloff');
  if (RegExp(r'enviolo|nuvinci').hasMatch(blob)) out.add('enviolo');
  if (RegExp(r'campagnolo|chorus|record|ekar').hasMatch(blob)) {
    out.add('campagnolo');
  }
  return out;
}

GarageBikeProfile? profileFromBike(
  Bike bike, {
  List<BikeComponent> components = const [],
}) {
  if (!isRideableGarageBike(bike.category)) return null;
  final isEbike = bike.hasElectricAssist;
  final wheels = <String>{
    if (wheelFromEnum(bike.wheelSize) != null) wheelFromEnum(bike.wheelSize)!,
  };
  final drivetrain = <String>{};
  for (final c in components) {
    if (!c.isInstalled || !_drivetrainSlots.contains(c.slot)) continue;
    drivetrain.addAll(
      inferDrivetrainTokens(c.manufacturer ?? '', c.model ?? ''),
    );
  }
  return GarageBikeProfile(
    id: bike.id,
    name: bike.name,
    brand: bike.brand,
    model: bike.model,
    category: bike.category,
    categoryLabel: bike.categoryLabel,
    wheelSizes: wheels.toList(),
    isEbike: isEbike,
    drivetrain: drivetrain.toList(),
    families: familiesFromBike(bike.category),
  );
}

String? _parseFamilyToken(String raw) {
  final key = raw.trim().toLowerCase().replaceAll('-', '').replaceAll(' ', '');
  return _familyAliases[key];
}

GarageFitConstraint parseGarageFitConstraint({
  List<String> tags = const [],
  String title = '',
  String productType = '',
  String slotKey = '',
  String description = '',
}) {
  final families = <String>{};
  final wheels = <String>{};
  final drive = <String>{};
  String? ebike;

  for (final raw in tags) {
    final tag = raw.trim();
    final fam = RegExp(
      r'^(?:category|cat|sport|discipline|fit|bike_type):(.+)$',
      caseSensitive: false,
    ).firstMatch(tag);
    if (fam != null) {
      final parsed = _parseFamilyToken(fam.group(1)!);
      if (parsed != null) families.add(parsed);
      continue;
    }
    final wheel = RegExp(
      r'^(?:wheel|wheel_size|laufrad|iso):(.+)$',
      caseSensitive: false,
    ).firstMatch(tag);
    if (wheel != null) {
      final w = normalizeWheel(wheel.group(1));
      if (w != null) wheels.add(w);
      continue;
    }
    final lower = tag.toLowerCase();
    if (lower == 'analog' || lower == 'muskel' || lower == 'acoustic') {
      ebike = 'no';
      continue;
    }
    final e = RegExp(r'^(?:ebike|e-bike|e_bike)(?::(.+))?$').firstMatch(lower);
    if (e != null) {
      final val = (e.group(1) ?? 'yes').toLowerCase();
      if (val == 'no' || val == 'false' || val == 'analog') {
        ebike = 'no';
      } else if (val == 'only' || val == 'exclusive') {
        ebike = 'only';
      } else {
        ebike ??= 'any';
      }
      continue;
    }
    final dt = RegExp(
      r'^(?:drivetrain|groupset|shift_compat):(.+)$',
      caseSensitive: false,
    ).firstMatch(tag);
    if (dt != null) {
      final token = dt.group(1)!.trim().toLowerCase();
      if (token.isNotEmpty) drive.add(token);
    }
  }

  final blob = '$title $productType $description ${tags.join(' ')}'.toLowerCase();
  if (families.isEmpty) {
    if (RegExp(r'\bgravel\b').hasMatch(blob)) families.add('gravel');
    if (RegExp(r'\brennrad\b|\broad(?:bike|ie)?\b|\bcyclocross\b|\bcx\b')
        .hasMatch(blob)) {
      families.add('road');
    }
    if (RegExp(
      r'\b(?:e-?)?mtb\b|\bmountain\s*bike\b|\benduro\b|\bdownhill\b|\btrail\s*bike\b',
    ).hasMatch(blob)) {
      families.add('mtb');
    }
    if (RegExp(r'\bcity\b|\burban\b|\btrekking\b|\bcommuter\b|\btouring\b')
        .hasMatch(blob)) {
      families.add('urban');
    }
  }
  if (wheels.isEmpty) {
    if (RegExp(r'29\s*[x×]\s*\d', caseSensitive: false).hasMatch(blob) ||
        RegExp(r'\b29er\b', caseSensitive: false).hasMatch(blob)) {
      wheels.add('29');
    }
    if (RegExp(r'27[.,]5\s*[x×]', caseSensitive: false).hasMatch(blob)) {
      wheels.add('27.5');
    }
    if (RegExp(r'\b650b\b', caseSensitive: false).hasMatch(blob) ||
        RegExp(r'\b\d{2}-584\b').hasMatch(blob)) {
      wheels.add('650b');
    }
    if (RegExp(r'\b700c\b', caseSensitive: false).hasMatch(blob) ||
        RegExp(r'\b\d{2}-622\b').hasMatch(blob)) {
      wheels.add('700c');
    }
  }

  final type = '$slotKey $productType'.toLowerCase();
  if (ebike == null) {
    if (RegExp(r'\b(akku|battery|motor|display|antriebseinheit)\b')
            .hasMatch(type) ||
        slotKey == 'battery' ||
        slotKey == 'motor' ||
        slotKey == 'display') {
      ebike = 'only';
    } else if (RegExp(r'nur\s+(?:für\s+)?e-?bikes?|e-?bike\s*only')
        .hasMatch(blob)) {
      ebike = 'only';
    }
  }
  if (drive.isEmpty) {
    drive.addAll(inferDrivetrainTokens(title, productType));
  }

  return GarageFitConstraint(
    families: families.toList(),
    wheelSizes: wheels.toList(),
    ebike: ebike ?? 'any',
    drivetrain: drive.toList(),
  );
}

bool bikeMatchesConstraint(
  GarageBikeProfile bike,
  GarageFitConstraint constraint,
) {
  if (constraint.ebike == 'only' && !bike.isEbike) return false;
  if (constraint.ebike == 'no' && bike.isEbike) return false;
  if (constraint.families.isNotEmpty) {
    if (bike.families.isEmpty) return false;
    if (!constraint.families.any(bike.families.contains)) return false;
  }
  if (!wheelsCompatible(constraint.wheelSizes, bike.wheelSizes)) return false;
  if (constraint.drivetrain.isNotEmpty && bike.drivetrain.isNotEmpty) {
    if (!constraint.drivetrain.any(bike.drivetrain.contains)) return false;
  }
  return true;
}

String _displayName(GarageBikeProfile bike) {
  if (bike.brand != null &&
      bike.brand!.isNotEmpty &&
      bike.model != null &&
      bike.model!.isNotEmpty) {
    return '${bike.brand} ${bike.model}';
  }
  return bike.name;
}

String? formatGarageFitLabel(List<GarageBikeProfile> bikes) {
  if (bikes.isEmpty) return null;
  if (bikes.length == 1) {
    final b = bikes.first;
    final parts = <String>[_displayName(b)];
    if (b.wheelSizes.isNotEmpty) parts.add(wheelLabel(b.wheelSizes.first));
    if (b.categoryLabel.isNotEmpty) parts.add(b.categoryLabel);
    return 'passt zu ${parts.join(' · ')}';
  }
  if (bikes.length == 2) {
    return 'passt zu ${_displayName(bikes[0])} und ${_displayName(bikes[1])}';
  }
  return 'passt zu ${_displayName(bikes.first)} und ${bikes.length - 1} weiteren';
}

GarageFitResult matchGarageFit(
  GarageFitConstraint constraint,
  List<GarageBikeProfile> bikes, {
  String? selectedBikeId,
}) {
  final pool = (selectedBikeId != null &&
          selectedBikeId.isNotEmpty &&
          selectedBikeId != 'all')
      ? bikes.where((b) => b.id == selectedBikeId).toList()
      : bikes;
  final usable = pool.where((b) => b.families.isNotEmpty).toList();
  if (usable.isEmpty) {
    return const GarageFitResult(
      kind: 'universal',
      compatible: true,
      matchedBikes: [],
    );
  }
  if (constraint.isEmpty) {
    return GarageFitResult(
      kind: 'universal',
      compatible: true,
      matchedBikes: usable,
    );
  }
  final matched =
      usable.where((b) => bikeMatchesConstraint(b, constraint)).toList();
  if (matched.isEmpty) {
    return const GarageFitResult(
      kind: 'mismatch',
      compatible: false,
      matchedBikes: [],
    );
  }
  return GarageFitResult(
    kind: 'match',
    compatible: true,
    matchedBikes: matched,
    label: formatGarageFitLabel(matched),
  );
}

String? maguraShapeFromModel(String model) {
  final m = model.toUpperCase();
  if (m.contains('8.P')) return '8';
  if (m.contains('7.P')) return '7';
  if (RegExp(r'MT\s*TRAIL|MTTRAIL').hasMatch(m)) return '8';
  if (RegExp(r'MT\s*5\b|\bMT5\b').hasMatch(m)) return '8';
  if (RegExp(r'MT\s*7\b|\bMT7\b').hasMatch(m)) return '8';
  if (RegExp(r'MT\s*[2468]\b|\bMT[2468]\b').hasMatch(m)) return '7';
  return null;
}

String? maguraShapeFromComponents(List<BikeComponent> components) {
  for (final c in components) {
    if (!c.isInstalled) continue;
    if (c.slot != ComponentSlot.brakeFront &&
        c.slot != ComponentSlot.brakeRear) {
      continue;
    }
    final shape = maguraShapeFromModel(c.model ?? '');
    if (shape != null) return shape;
  }
  return null;
}

bool productSoftFitOk({
  required List<String> tags,
  String? maguraShape,
  List<String> calipers = const [],
  String? size,
  List<String> shiftCompat = const [],
}) {
  String? productShape;
  final productCals = <String>[];
  String? productSize;
  final productShift = <String>[];
  for (final raw in tags) {
    final magura = RegExp(r'^magura_shape:([78])$', caseSensitive: false)
        .firstMatch(raw.trim());
    if (magura != null) productShape = magura.group(1);
    final pad = RegExp(r'^pad:shape-([78])$', caseSensitive: false)
        .firstMatch(raw.trim());
    if (pad != null) productShape ??= pad.group(1);
    final cal =
        RegExp(r'^caliper:(.+)$', caseSensitive: false).firstMatch(raw.trim());
    if (cal != null) productCals.add(cal.group(1)!.trim().toLowerCase());
    final sz =
        RegExp(r'^size:([sl])$', caseSensitive: false).firstMatch(raw.trim());
    if (sz != null) productSize = sz.group(1)!.toUpperCase();
    final sh = RegExp(r'^shift_compat:(.+)$', caseSensitive: false)
        .firstMatch(raw.trim());
    if (sh != null) productShift.add(sh.group(1)!.trim().toLowerCase());
  }
  if (productShape != null && maguraShape != null && productShape != maguraShape) {
    return false;
  }
  if (productCals.isNotEmpty && calipers.isNotEmpty) {
    final ok = productCals.any((pc) {
      if (pc == 'mt*' || pc == '*') return true;
      if (calipers.contains(pc)) return true;
      if (pc.endsWith('*')) {
        final prefix = pc.substring(0, pc.length - 1);
        return calipers.any((b) => b.startsWith(prefix));
      }
      return false;
    });
    if (!ok) return false;
  }
  if (productSize != null && size != null && productSize != size) return false;
  if (productShift.isNotEmpty && shiftCompat.isNotEmpty) {
    if (!productShift.any(shiftCompat.contains)) return false;
  }
  return true;
}
