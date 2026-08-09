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
    );
  }
}

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
