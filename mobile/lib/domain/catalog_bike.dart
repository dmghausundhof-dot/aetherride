import 'bike.dart';

/// OEM-Katalog-Eintrag von GET /api/catalog/bikes.
class CatalogManufacturer {
  const CatalogManufacturer({
    required this.id,
    required this.name,
    required this.bikes,
  });

  final String id;
  final String name;
  final List<CatalogBikeVariant> bikes;

  factory CatalogManufacturer.fromJson(Map<String, dynamic> m) {
    final raw = m['bikes'];
    return CatalogManufacturer(
      id: (m['id'] as String?) ?? '',
      name: (m['name'] as String?) ?? '',
      bikes: [
        if (raw is List)
          for (final e in raw)
            if (e is Map)
              CatalogBikeVariant.fromJson(Map<String, dynamic>.from(e)),
      ],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'bikes': [for (final b in bikes) b.toJson()],
      };
}

class FrameSizeGeometry {
  const FrameSizeGeometry({
    required this.size,
    required this.reachMm,
    required this.stackMm,
    this.wheelbaseMm,
    this.chainstayMm,
    this.headAngleDeg,
    this.seatAngleEffectiveDeg,
    this.setting,
    this.sourceUrl,
  });

  final String size;
  final double reachMm;
  final double stackMm;
  final double? wheelbaseMm;
  final double? chainstayMm;
  final double? headAngleDeg;
  final double? seatAngleEffectiveDeg;
  final String? setting;
  final String? sourceUrl;

  factory FrameSizeGeometry.fromJson(Map<String, dynamic> m) {
    return FrameSizeGeometry(
      size: (m['size'] as String?) ?? '',
      reachMm: (m['reachMm'] as num?)?.toDouble() ??
          (m['reach_mm'] as num?)?.toDouble() ??
          0,
      stackMm: (m['stackMm'] as num?)?.toDouble() ??
          (m['stack_mm'] as num?)?.toDouble() ??
          0,
      wheelbaseMm: (m['wheelbaseMm'] as num?)?.toDouble() ??
          (m['wheelbase_mm'] as num?)?.toDouble(),
      chainstayMm: (m['chainstayMm'] as num?)?.toDouble() ??
          (m['chainstay_mm'] as num?)?.toDouble(),
      headAngleDeg: (m['headAngleDeg'] as num?)?.toDouble() ??
          (m['head_angle_deg'] as num?)?.toDouble(),
      seatAngleEffectiveDeg: (m['seatAngleEffectiveDeg'] as num?)?.toDouble() ??
          (m['seat_angle_effective_deg'] as num?)?.toDouble(),
      setting: m['setting'] as String?,
      sourceUrl: m['sourceUrl'] as String? ?? m['source_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'size': size,
        'reachMm': reachMm,
        'stackMm': stackMm,
        if (wheelbaseMm != null) 'wheelbaseMm': wheelbaseMm,
        if (chainstayMm != null) 'chainstayMm': chainstayMm,
        if (headAngleDeg != null) 'headAngleDeg': headAngleDeg,
        if (seatAngleEffectiveDeg != null)
          'seatAngleEffectiveDeg': seatAngleEffectiveDeg,
        if (setting != null) 'setting': setting,
        if (sourceUrl != null) 'sourceUrl': sourceUrl,
      };
}

class CatalogBikeVariant {
  const CatalogBikeVariant({
    required this.id,
    required this.name,
    required this.year,
    required this.category,
    required this.frameSizeOptions,
    required this.wheelSizeFront,
    required this.wheelSizeRear,
    required this.isEbike,
    required this.oemComponents,
    this.travelFrontMm,
    this.travelRearMm,
    this.weightKgApprox,
    this.sourceUrl,
    this.geometryBySize = const [],
  });

  final String id;
  final String name;
  final int year;
  final BikeCategory category;
  final List<String> frameSizeOptions;
  final WheelSize wheelSizeFront;
  final WheelSize wheelSizeRear;
  final bool isEbike;
  final Map<String, String> oemComponents;
  final int? travelFrontMm;
  final int? travelRearMm;
  final double? weightKgApprox;
  final String? sourceUrl;
  final List<FrameSizeGeometry> geometryBySize;

  FrameSizeGeometry? geometryForSize(String? size) {
    if (size == null || size.isEmpty) return null;
    for (final row in geometryBySize) {
      if (row.size == size) return row;
    }
    return null;
  }

  factory CatalogBikeVariant.fromJson(Map<String, dynamic> m) {
    final oemRaw = m['oemComponents'] ?? m['oem_components'];
    final oem = <String, String>{};
    if (oemRaw is Map) {
      for (final e in oemRaw.entries) {
        final v = e.value;
        if (v is String && v.isNotEmpty) oem['${e.key}'] = v;
      }
    } else if (oemRaw is List) {
      for (final e in oemRaw) {
        if (e is! Map) continue;
        final row = Map<String, dynamic>.from(e);
        final slot = row['slot'] as String?;
        final id = (row['component_model_id'] as String?) ??
            (row['componentModelId'] as String?) ??
            (row['modelId'] as String?);
        if (slot != null && id != null) oem[slot] = id;
      }
    }

    final sizes = m['frameSizeOptions'] ?? m['frame_size_options'];
    final geoRaw = m['geometryBySize'] ?? m['geometry_by_size'];
    return CatalogBikeVariant(
      id: (m['id'] as String?) ?? '',
      name: (m['name'] as String?) ?? '',
      year: (m['year'] as num?)?.toInt() ?? 0,
      category: bikeCategoryFromApi((m['category'] as String?) ?? 'mtb_am'),
      frameSizeOptions: [
        if (sizes is List)
          for (final s in sizes)
            if (s is String) s,
      ],
      wheelSizeFront: wheelSizeFromApi(
        (m['wheelSizeFront'] as String?) ?? (m['wheel_size_front'] as String?),
      ),
      wheelSizeRear: wheelSizeFromApi(
        (m['wheelSizeRear'] as String?) ?? (m['wheel_size_rear'] as String?),
      ),
      isEbike: m['isEbike'] == true || m['is_ebike'] == true,
      oemComponents: oem,
      travelFrontMm: (m['travelFrontMm'] as num?)?.toInt() ??
          (m['travel_front_mm'] as num?)?.toInt(),
      travelRearMm: (m['travelRearMm'] as num?)?.toInt() ??
          (m['travel_rear_mm'] as num?)?.toInt(),
      weightKgApprox: (m['weightKgApprox'] as num?)?.toDouble() ??
          (m['weight_kg_approx'] as num?)?.toDouble(),
      sourceUrl: m['sourceUrl'] as String? ?? m['source_url'] as String?,
      geometryBySize: [
        if (geoRaw is List)
          for (final e in geoRaw)
            if (e is Map)
              FrameSizeGeometry.fromJson(Map<String, dynamic>.from(e)),
      ],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'year': year,
        'category': _categoryApiId(category),
        'frameSizeOptions': frameSizeOptions,
        'wheelSizeFront': _wheelApiId(wheelSizeFront),
        'wheelSizeRear': _wheelApiId(wheelSizeRear),
        'isEbike': isEbike,
        'oemComponents': oemComponents,
        if (travelFrontMm != null) 'travelFrontMm': travelFrontMm,
        if (travelRearMm != null) 'travelRearMm': travelRearMm,
        if (weightKgApprox != null) 'weightKgApprox': weightKgApprox,
        if (sourceUrl != null) 'sourceUrl': sourceUrl,
        if (geometryBySize.isNotEmpty)
          'geometryBySize': [for (final g in geometryBySize) g.toJson()],
      };
}

String _categoryApiId(BikeCategory c) => switch (c) {
      BikeCategory.mtbTrail => 'mtb_trail',
      BikeCategory.mtbAm => 'mtb_am',
      BikeCategory.mtbEnduro => 'mtb_enduro',
      BikeCategory.dh => 'dh',
      BikeCategory.gravel => 'gravel',
      BikeCategory.road => 'road',
      BikeCategory.urban => 'urban',
      BikeCategory.emtb => 'emtb',
      BikeCategory.etrekking => 'etrekking',
      BikeCategory.hiking => 'hiking',
    };

String _wheelApiId(WheelSize w) => switch (w) {
      WheelSize.w275 => '27.5',
      WheelSize.w29 => '29',
      WheelSize.c700 => '700c',
      WheelSize.b650 => '650b',
    };

BikeCategory bikeCategoryFromApi(String raw) {
  final n = raw.trim().toLowerCase().replaceAll('-', '_');
  return switch (n) {
    'mtb_trail' || 'mtbtrail' => BikeCategory.mtbTrail,
    'mtb_am' || 'mtbam' => BikeCategory.mtbAm,
    'mtb_enduro' || 'mtbenduro' => BikeCategory.mtbEnduro,
    'dh' => BikeCategory.dh,
    'gravel' => BikeCategory.gravel,
    'road' => BikeCategory.road,
    'urban' => BikeCategory.urban,
    'emtb' => BikeCategory.emtb,
    'etrekking' => BikeCategory.etrekking,
    'hiking' => BikeCategory.hiking,
    _ => BikeCategory.values.firstWhere(
        (c) => c.name.toLowerCase() == n.replaceAll('_', ''),
        orElse: () => BikeCategory.mtbAm,
      ),
  };
}

WheelSize wheelSizeFromApi(String? raw) {
  final n = (raw ?? '29').trim().toLowerCase();
  return switch (n) {
    '27.5' || '275' || 'w275' => WheelSize.w275,
    '700c' || 'c700' => WheelSize.c700,
    '650b' || 'b650' => WheelSize.b650,
    _ => WheelSize.w29,
  };
}

/// Treffer von POST /api/catalog/identify (Text oder Foto).
class CatalogBikeHit {
  const CatalogBikeHit({
    required this.id,
    required this.manufacturerId,
    required this.manufacturerName,
    required this.name,
    required this.year,
    required this.category,
    required this.isEbike,
    required this.score,
  });

  final String id;
  final String manufacturerId;
  final String manufacturerName;
  final String name;
  final int year;
  final BikeCategory category;
  final bool isEbike;
  final double score;

  factory CatalogBikeHit.fromJson(Map<String, dynamic> m) {
    return CatalogBikeHit(
      id: (m['id'] as String?) ?? '',
      manufacturerId: (m['manufacturerId'] as String?) ?? '',
      manufacturerName: (m['manufacturerName'] as String?) ?? '',
      name: (m['name'] as String?) ?? '',
      year: (m['year'] as num?)?.toInt() ?? 0,
      category: bikeCategoryFromApi((m['category'] as String?) ?? 'mtb_am'),
      isEbike: m['isEbike'] == true,
      score: (m['score'] as num?)?.toDouble() ?? 0,
    );
  }

  String get label =>
      '$manufacturerName $name${year > 0 ? ' ($year)' : ''}';
}
