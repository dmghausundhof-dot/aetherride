import 'package:aetherride_mobile/domain/bike.dart';
import 'package:aetherride_mobile/domain/component.dart';
import 'package:aetherride_mobile/domain/garage/bike_schema_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('planBikeSchema', () {
    test('maps categories to templates', () {
      expect(planBikeSchema(category: BikeCategory.road).assetKey, 'road');
      expect(planBikeSchema(category: BikeCategory.gravel).assetKey, 'gravel');
      expect(planBikeSchema(category: BikeCategory.urban).assetKey, 'urban');
      expect(planBikeSchema(category: BikeCategory.cargo).assetKey, 'cargo');
      expect(planBikeSchema(category: BikeCategory.folding).assetKey, 'folding');
      expect(planBikeSchema(category: BikeCategory.kids).assetKey, 'kids');
      expect(planBikeSchema(category: BikeCategory.etrekking).assetKey, 'etrekking');
      expect(planBikeSchema(category: BikeCategory.mtbTrail).assetKey, 'mtb_trail');
      expect(planBikeSchema(category: BikeCategory.emtb).assetKey, 'emtb');
    });

    test('hardtail trail hides shock; AM shows shock', () {
      final trail = planBikeSchema(category: BikeCategory.mtbTrail);
      expect(trail.showShock, isFalse);
      expect(trail.hotspotSlots, isNot(contains(ComponentSlot.rearShock)));

      final trailFully = planBikeSchema(
        category: BikeCategory.mtbTrail,
        hasRearShock: true,
      );
      expect(trailFully.showShock, isTrue);
      expect(trailFully.hotspotSlots, contains(ComponentSlot.rearShock));

      expect(planBikeSchema(category: BikeCategory.mtbAm).showShock, isTrue);
    });

    test('eBike layers', () {
      final roadE = planBikeSchema(category: BikeCategory.road, isEbike: true);
      expect(roadE.showEbike, isTrue);
      expect(roadE.hotspotSlots, contains(ComponentSlot.motor));
      expect(roadE.hotspotSlots, contains(ComponentSlot.battery));

      final emtb = planBikeSchema(category: BikeCategory.emtb);
      expect(emtb.showEbike, isTrue);
      expect(emtb.showShock, isTrue);
    });

    test('hiking has no template', () {
      final hike = planBikeSchema(category: BikeCategory.hiking);
      expect(hike.template, isNull);
      expect(hike.assetKey, isNull);
    });
  });
}
