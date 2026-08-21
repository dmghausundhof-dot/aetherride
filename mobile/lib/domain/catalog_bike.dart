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
      BikeCategory.cargo => 'cargo',
      BikeCategory.folding => 'folding',
      BikeCategory.kids => 'kids',
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
    'cargo' || 'lastenrad' => BikeCategory.cargo,
    'folding' || 'faltrad' || 'fold' => BikeCategory.folding,
    'kids' || 'kinderrad' || 'children' => BikeCategory.kids,
    'emtb' => BikeCategory.emtb,
    'etrekking' => BikeCategory.etrekking,
    'hiking' => BikeCategory.hiking,
    _ => BikeCategory.values.firstWhere(
        (c) => c.name.toLowerCase() == n.replaceAll('_', ''),
        orElse: () => BikeCategory.urban,
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

class CatalogIdentifyResult {
  const CatalogIdentifyResult({
    this.matches = const [],
    this.vision = false,
    this.reason,
    this.visionParts = const [],
    this.queries = const [],
  });

  final List<CatalogBikeHit> matches;
  final bool vision;
  final String? reason;

  /// Am Foto genannte Teile — ohne SKU, nur Slot + sichtbarer Name.
  final List<CatalogVisionPart> visionParts;

  /// Was Grok als Marke/Modell gelesen hat — auch ohne Katalogtreffer.
  final List<String> queries;

  bool get hasHits => matches.isNotEmpty;

  /// Text oder Teile vom Foto — Flow darf weiterlaufen, auch ohne Treffer.
  bool get hasVisionRead => readSummary.isNotEmpty;

  /// Treffer, gelesener Text oder Teile — Abbruch nur wenn wirklich nichts da ist.
  bool get canContinue =>
      hasHits || hasVisionRead || visionParts.isNotEmpty;

  /// Kurztext zum Gegenprüfen, z. B. „Canyon Spectral · Fox 36 Grip2“.
  String get readSummary =>
      grokReadSummary(queries: queries, parts: visionParts);

  factory CatalogIdentifyResult.fromJson(Map<String, dynamic> m) {
    final raw = m['matches'];
    final q = m['queries'];
    return CatalogIdentifyResult(
      matches: [
        if (raw is List)
          for (final e in raw)
            if (e is Map)
              CatalogBikeHit.fromJson(Map<String, dynamic>.from(e)),
      ],
      vision: m['vision'] == true || m['source'] == 'vision+catalog',
      reason: (m['reason'] as String?)?.trim(),
      visionParts: CatalogVisionPart.listFromJson(m['parts']),
      queries: [
        if (q is List)
          for (final e in q)
            if (e is String && e.trim().isNotEmpty) e.trim(),
      ],
    );
  }
}

/// Roh-Text aus Queries + Teilnamen, ohne Duplikate, nichts erfinden.
String grokReadSummary({
  List<String> queries = const [],
  List<CatalogVisionPart> parts = const [],
}) {
  final bits = <String>[];
  void add(String? raw) {
    final t = (raw ?? '').trim();
    if (t.isEmpty) return;
    if (bits.any((b) => b.toLowerCase() == t.toLowerCase())) return;
    bits.add(t);
  }

  for (final q in queries) {
    add(q);
  }
  for (final p in parts) {
    add(
      [
        if ((p.manufacturer ?? '').trim().isNotEmpty) p.manufacturer!.trim(),
        if ((p.model ?? '').trim().isNotEmpty) p.model!.trim(),
      ].join(' '),
    );
  }
  return bits.join(' · ');
}

/// Sichtbares Teil vom Foto — kein Katalog-SKU.
class CatalogVisionPart {
  const CatalogVisionPart({
    required this.slotApiId,
    this.manufacturer,
    this.model,
  });

  final String slotApiId;
  final String? manufacturer;
  final String? model;

  static List<CatalogVisionPart> listFromJson(Object? raw) {
    if (raw is! List) return [];
    final out = <CatalogVisionPart>[];
    for (final e in raw) {
      if (e is! Map) continue;
      final m = Map<String, dynamic>.from(e);
      final slot = '${m['slot'] ?? ''}'.trim();
      if (slot.isEmpty) continue;
      final manufacturer = (m['manufacturer'] as String?)?.trim();
      final model = (m['model'] as String?)?.trim();
      if ((manufacturer == null || manufacturer.isEmpty) &&
          (model == null || model.isEmpty)) {
        continue;
      }
      out.add(CatalogVisionPart(
        slotApiId: slot,
        manufacturer: manufacturer,
        model: model,
      ));
    }
    return out;
  }
}

String preferCatalogManufacturerId(String a, [String? b]) {
  if (b == null || b.isEmpty) return a.startsWith('mfr-') ? a : a;
  if (a.startsWith('mfr-') && !b.startsWith('mfr-')) return a;
  if (b.startsWith('mfr-') && !a.startsWith('mfr-')) return b;
  return a;
}

/// Postgres hat Marken doppelt (`canyon` + `mfr-canyon`). Ein Eintrag pro Name.
List<CatalogManufacturer> mergeCatalogManufacturers(
  List<CatalogManufacturer> raw,
) {
  final byName = <String, CatalogManufacturer>{};
  for (final m in raw) {
    final key = m.name.trim().toLowerCase();
    if (key.isEmpty) continue;
    final existing = byName[key];
    if (existing == null) {
      byName[key] = CatalogManufacturer(
        id: preferCatalogManufacturerId(m.id),
        name: m.name.trim(),
        bikes: List<CatalogBikeVariant>.from(m.bikes),
      );
      continue;
    }
    final bikes = [...existing.bikes];
    final seen = {for (final b in bikes) b.id};
    for (final b in m.bikes) {
      if (b.id.isEmpty || seen.contains(b.id)) continue;
      bikes.add(b);
      seen.add(b.id);
    }
    byName[key] = CatalogManufacturer(
      id: preferCatalogManufacturerId(existing.id, m.id),
      name: existing.name,
      bikes: bikes,
    );
  }
  final out = byName.values.toList()
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  return out;
}

({CatalogManufacturer mfr, CatalogBikeVariant bike})? findCatalogBikeInList(
  List<CatalogManufacturer> manufacturers, {
  String? bikeId,
  String? manufacturerId,
  String? manufacturerName,
}) {
  if (bikeId != null && bikeId.isNotEmpty) {
    for (final m in manufacturers) {
      for (final b in m.bikes) {
        if (b.id == bikeId) return (mfr: m, bike: b);
      }
    }
  }
  CatalogManufacturer? mfr;
  if (manufacturerId != null && manufacturerId.isNotEmpty) {
    for (final m in manufacturers) {
      if (m.id == manufacturerId) {
        mfr = m;
        break;
      }
    }
  }
  if (mfr == null && manufacturerName != null && manufacturerName.isNotEmpty) {
    final n = manufacturerName.trim().toLowerCase();
    for (final m in manufacturers) {
      if (m.name.trim().toLowerCase() == n) {
        mfr = m;
        break;
      }
    }
  }
  if (mfr == null || mfr.bikes.isEmpty) return null;
  return (mfr: mfr, bike: mfr.bikes.first);
}
