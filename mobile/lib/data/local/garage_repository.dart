import '../../domain/bike.dart';

/// Offline-First: UI liest nur lokal. Drift-Schema folgt in einem späteren Schnitt.
class GarageRepository {
  GarageRepository({List<Bike>? seed})
      : _bikes = List<Bike>.from(seed ?? _demoSeed);

  final List<Bike> _bikes;

  Future<List<Bike>> listBikes() async => List.unmodifiable(_bikes);

  Future<Bike?> getById(String id) async {
    for (final b in _bikes) {
      if (b.id == id) return b;
    }
    return null;
  }

  Future<void> upsert(Bike bike) async {
    final i = _bikes.indexWhere((b) => b.id == bike.id);
    if (i >= 0) {
      _bikes[i] = bike;
    } else {
      _bikes.add(bike);
    }
  }

  static const _demoSeed = [
    Bike(
      id: 'demo-emtb-1',
      name: 'Trail E-MTB',
      category: BikeCategory.emtb,
      brand: 'Demo',
      model: 'Aether 1',
      year: 2025,
      wheelSize: WheelSize.w29,
      odometerKm: 412,
    ),
  ];
}
