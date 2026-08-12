// Domain-Spiegel von src/types/garage.ts (Spec F-GAR / DM-02…DM-07).

enum BikeCategory {
  mtbTrail,
  mtbAm,
  mtbEnduro,
  dh,
  gravel,
  road,
  urban,
  emtb,
  etrekking,
  hiking,
}

enum WheelSize { w275, w29, c700, b650 }

extension WheelSizeLabel on WheelSize {
  String get label => switch (this) {
        WheelSize.w275 => '27.5"',
        WheelSize.w29 => '29"',
        WheelSize.c700 => '700c',
        WheelSize.b650 => '650b',
      };
}

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
