import 'package:aetherride_mobile/domain/bike.dart';
import 'package:aetherride_mobile/domain/sport/discipline_ux.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Multi-sport UX', () {
    test('all onboarding sports present', () {
      final ids = OnboardingSportOption.all.map((e) => e.id).toSet();
      expect(ids, contains(BikeCategory.mtbAm));
      expect(ids, contains(BikeCategory.gravel));
      expect(ids, contains(BikeCategory.road));
      expect(ids, contains(BikeCategory.urban));
      expect(ids, contains(BikeCategory.emtb));
      expect(ids, contains(BikeCategory.etrekking));
      expect(OnboardingSportOption.all.length, greaterThanOrEqualTo(6));
      expect(OnboardingSportOption.primary.length, 4);
    });

    test('families cover core bike types', () {
      expect(BikeCategory.road.family, SportFamily.road);
      expect(BikeCategory.urban.family, SportFamily.urban);
      expect(BikeCategory.cargo.family, SportFamily.urban);
      expect(BikeCategory.folding.family, SportFamily.urban);
      expect(BikeCategory.kids.family, SportFamily.urban);
      expect(BikeCategory.gravel.family, SportFamily.gravel);
      expect(BikeCategory.mtbAm.family, SportFamily.mtb);
      expect(BikeCategory.emtb.family, SportFamily.ebike);
    });

    test('chassis layer only for suspension-relevant sports', () {
      expect(BikeCategory.mtbAm.showsChassisLayer, isTrue);
      expect(BikeCategory.road.showsChassisLayer, isFalse);
      expect(BikeCategory.urban.showsChassisLayer, isFalse);
      expect(
        MultiSportCopy.chassisLayerLabel(BikeCategory.road),
        'Sensorik',
      );
      expect(
        MultiSportCopy.chassisLayerLabel(BikeCategory.mtbEnduro),
        'Fahrwerk',
      );
    });

    test('nav labels are German multi-sport', () {
      expect(MultiSportCopy.navRide, 'Fahren');
      expect(MultiSportCopy.navDiscover, 'Touren');
      expect(MultiSportCopy.navParts, 'Teile');
    });

    test('home subtitle adapts by family', () {
      expect(
        MultiSportCopy.homeSubtitle(sport: BikeCategory.road),
        contains('Asphalt'),
      );
      expect(
        MultiSportCopy.homeSubtitle(sport: BikeCategory.urban),
        contains('Stadt'),
      );
      expect(
        MultiSportCopy.homeSubtitle(sport: BikeCategory.gravel),
        contains('Schotter'),
      );
    });

    test('preferred sports summary is German', () {
      expect(
        preferredSportsSummaryLine(
          primary: BikeCategory.mtbAm,
          sports: const [BikeCategory.mtbAm, BikeCategory.road],
        ),
        'Haupt: MTB · auch Rennrad',
      );
    });
  });
}
