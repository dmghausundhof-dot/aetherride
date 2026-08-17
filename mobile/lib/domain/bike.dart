// Domain-Spiegel von src/types/garage.ts (Spec F-GAR / DM-02…DM-07).

enum BikeCategory {
  mtbTrail,
  mtbAm,
  mtbEnduro,
  dh,
  gravel,
  road,
  urban,
  cargo,
  folding,
  kids,
  emtb,
  etrekking,
  hiking,
}

extension BikeCategoryKind on BikeCategory {
  /// Licht, Schloss, Träger — Alltag, nicht Trail.
  bool get showsCityAccessories => switch (this) {
        BikeCategory.urban ||
        BikeCategory.etrekking ||
        BikeCategory.cargo ||
        BikeCategory.folding ||
        BikeCategory.kids =>
          true,
        _ => false,
      };
}

enum WheelSize { w275, w29, c700, b650 }

extension WheelSizeLabel on WheelSize {
  String get label => switch (this) {
        WheelSize.w275 => '27.5"',
        WheelSize.w29 => '29"',
        WheelSize.c700 => '700c',
        WheelSize.b650 => '650b',
      };

  /// Typical rolling circumference for CSC speed. Shared by garage and HUD.
  double get circumferenceM => switch (this) {
        WheelSize.w275 => 2.070,
        WheelSize.w29 => 2.105,
        WheelSize.c700 => 2.130,
        WheelSize.b650 => 1.935,
      };
}

/// Default ~29×2.25 gravel-ish when the bike has no wheel size yet.
double wheelCircumferenceM(WheelSize? size) => size?.circumferenceM ?? 2.105;

enum CompatibilityVerdict {
  compatible,
  conditional,
  incompatible,
  insufficientData,
}

class Bike {
  const Bike({
    required this.id,
    required this.name,
    required this.category,
    this.brand,
    this.model,
    this.year,
    this.wheelSize,
    this.catalogBikeId,
    this.frameSize,
    this.travelFrontMm,
    this.travelRearMm,
    this.odometerKm = 0,
    this.hours = 0,
    this.isActive = false,
    this.isEbike = false,
  });

  final String id;
  final String name;
  final BikeCategory category;
  final String? brand;
  final String? model;
  final int? year;
  final WheelSize? wheelSize;
  final String? catalogBikeId;
  final String? frameSize;
  final int? travelFrontMm;
  final int? travelRearMm;
  final double odometerKm;
  final double hours;
  final bool isActive;

  /// Explizites Assist-Flag (Web-Parität). Legacy: auch über Kategorie.
  final bool isEbike;

  /// true bei Flag oder kanonischer E-Kategorie (`emtb` / `etrekking`).
  bool get hasElectricAssist =>
      isEbike ||
      category == BikeCategory.emtb ||
      category == BikeCategory.etrekking;

  /// Nutzer-Labels (Multi-Sport). E-Untertypen via [isEbike].
  /// Siehe auch [BikeCategoryUx.shortLabel].
  String get categoryLabel {
    if (hasElectricAssist) {
      return switch (category) {
        BikeCategory.emtb ||
        BikeCategory.mtbTrail ||
        BikeCategory.mtbAm ||
        BikeCategory.mtbEnduro ||
        BikeCategory.dh =>
          'E-MTB',
        BikeCategory.etrekking => 'E-Trekking',
        BikeCategory.gravel => 'E-Gravel',
        BikeCategory.urban => 'E-City',
        BikeCategory.cargo => 'E-Lastenrad',
        BikeCategory.folding => 'E-Faltrad',
        BikeCategory.kids => 'E-Kinderrad',
        BikeCategory.road => 'E-Road',
        BikeCategory.hiking => 'Zu Fuß',
      };
    }
    return switch (category) {
      BikeCategory.mtbTrail => 'MTB Trail',
      BikeCategory.mtbAm => 'MTB',
      BikeCategory.mtbEnduro => 'Enduro',
      BikeCategory.dh => 'Downhill',
      BikeCategory.gravel => 'Gravel',
      BikeCategory.road => 'Rennrad',
      BikeCategory.urban => 'City',
      BikeCategory.cargo => 'Lastenrad',
      BikeCategory.folding => 'Faltrad',
      BikeCategory.kids => 'Kinderrad',
      BikeCategory.emtb => 'E-MTB',
      BikeCategory.etrekking => 'E-Trekking',
      BikeCategory.hiking => 'Zu Fuß',
    };
  }

  Bike copyWith({
    String? name,
    BikeCategory? category,
    String? brand,
    String? model,
    int? year,
    WheelSize? wheelSize,
    String? catalogBikeId,
    String? frameSize,
    int? travelFrontMm,
    int? travelRearMm,
    double? odometerKm,
    double? hours,
    bool? isActive,
    bool? isEbike,
  }) {
    return Bike(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      year: year ?? this.year,
      wheelSize: wheelSize ?? this.wheelSize,
      catalogBikeId: catalogBikeId ?? this.catalogBikeId,
      frameSize: frameSize ?? this.frameSize,
      travelFrontMm: travelFrontMm ?? this.travelFrontMm,
      travelRearMm: travelRearMm ?? this.travelRearMm,
      odometerKm: odometerKm ?? this.odometerKm,
      hours: hours ?? this.hours,
      isActive: isActive ?? this.isActive,
      isEbike: isEbike ?? this.isEbike,
    );
  }
}

/// Name beim Anlegen ohne Spitzname: Kategorie (Gravel, City, MTB),
/// kein Fake „Mein Bike“.
String fallbackBikeName(BikeCategory category, {bool isEbike = false}) {
  return Bike(
    id: '',
    name: '',
    category: category,
    isEbike: isEbike,
  ).categoryLabel;
}

/// Gesetzter Name bleibt. Leer/Whitespace wird zur Kategorie.
String resolvedBikeName(
  String name,
  BikeCategory category, {
  bool isEbike = false,
}) {
  final trimmed = name.trim();
  return trimmed.isEmpty
      ? fallbackBikeName(category, isEbike: isEbike)
      : trimmed;
}
