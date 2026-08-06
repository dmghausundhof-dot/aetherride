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
    this.odometerKm = 0,
  });

  final String id;
  final String name;
  final BikeCategory category;
  final String? brand;
  final String? model;
  final int? year;
  final WheelSize? wheelSize;
  final double odometerKm;

  Bike copyWith({
    String? name,
    BikeCategory? category,
    String? brand,
    String? model,
    int? year,
    WheelSize? wheelSize,
    double? odometerKm,
  }) {
    return Bike(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      year: year ?? this.year,
      wheelSize: wheelSize ?? this.wheelSize,
      odometerKm: odometerKm ?? this.odometerKm,
    );
  }
}
