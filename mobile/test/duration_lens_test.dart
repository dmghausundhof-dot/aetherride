import 'package:aetherride_mobile/domain/bike.dart';
import 'package:aetherride_mobile/domain/routing/duration_lens.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DurationLens.defaultMinutesForSport', () {
    test('default 60 for city/gravel/mtb/unclear', () {
      expect(DurationLens.defaultMinutesForSport(null), 60);
      expect(DurationLens.defaultMinutesForSport(BikeCategory.urban), 60);
      expect(DurationLens.defaultMinutesForSport(BikeCategory.gravel), 60);
      expect(DurationLens.defaultMinutesForSport(BikeCategory.mtbAm), 60);
      expect(DurationLens.defaultMinutesForSport(BikeCategory.road), 60);
    });

    test('touring-like E-Trekking → 2–3 h (150)', () {
      expect(
        DurationLens.defaultMinutesForSport(BikeCategory.etrekking),
        150,
      );
    });
  });

  group('DurationLens.inBand ~60 → 45–75', () {
    test('accepts band edges and mid', () {
      expect(DurationLens.inBand(45, 60), isTrue);
      expect(DurationLens.inBand(50, 60), isTrue);
      expect(DurationLens.inBand(58, 60), isTrue);
      expect(DurationLens.inBand(65, 60), isTrue);
      expect(DurationLens.inBand(75, 60), isTrue);
    });

    test('rejects outside band', () {
      expect(DurationLens.inBand(44, 60), isFalse);
      expect(DurationLens.inBand(76, 60), isFalse);
      expect(DurationLens.inBand(150, 60), isFalse);
      expect(DurationLens.inBand(0, 60), isFalse);
    });

    test('egal (0) accepts all positive', () {
      expect(DurationLens.inBand(30, 0), isTrue);
      expect(DurationLens.inBand(300, 0), isTrue);
    });
  });

  test('chip labels', () {
    expect(DurationLens.chipLabel(60), '~60');
    expect(DurationLens.chipLabel(150), '2–3 h');
    expect(DurationLens.chipLabel(0), 'egal');
  });
}
