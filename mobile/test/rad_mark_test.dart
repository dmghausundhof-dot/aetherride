import 'package:aetherride_mobile/domain/bike.dart';
import 'package:aetherride_mobile/domain/component.dart';
import 'package:aetherride_mobile/domain/garage/die_box.dart';
import 'package:aetherride_mobile/domain/garage/rad_mark.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Rad-Stand marks match the web mapping', () {
    expect(radMarkForItem(DieBoxItemId.pressureUnknown), 'pressure');
    expect(radMarkForItem(DieBoxItemId.sagUnknown), 'sag');
    expect(radMarkForItem(DieBoxItemId.lightsMissing), 'lights');
    expect(radMarkForItem(DieBoxItemId.dueCare), 'care');
    expect(radMarkForItem(DieBoxItemId.setActive), 'stand');
    expect(radMarkForItem(DieBoxItemId.parkTrail), 'setup');

    expect(radMarkForReadiness(DieBoxReadiness.ready), 'ready');
    expect(radMarkForReadiness(DieBoxReadiness.almost), 'almost');
    expect(radMarkForReadiness(DieBoxReadiness.unknown), 'unknown');

    expect(radMarkForChip('Druck'), 'pressure');
    expect(radMarkForChip('Licht'), 'lights');
    expect(radMarkForChip('Ausweis'), 'identity');
    expect(radMarkForChip('140/150 mm'), 'travel');
    expect(radMarkForChip('29"'), 'pressure');
    expect(radMarkForChip('700c'), 'pressure');

    expect(radMarkForSlot(ComponentSlot.tireFront), 'pressure');
    expect(radMarkForSlot(ComponentSlot.chain), 'chain');
    expect(radMarkForSlot(ComponentSlot.brakeRear), 'brakes');
    expect(radMarkForSlot(ComponentSlot.battery), 'battery');
    expect(radMarkForSlot(ComponentSlot.handlebar), 'cockpit');
    expect(radMarkForSlot(ComponentSlot.frame), 'parts');
  });

  test('Silhouette assets sit on the stand, hiking is not a dashed bike', () {
    expect(
      radSilhouetteAsset(Bike(id: 'g', name: 'G', category: BikeCategory.gravel)),
      'assets/garage/silhouettes/gravel.svg',
    );
    expect(
      radSilhouetteAsset(Bike(id: 'e', name: 'E', category: BikeCategory.emtb)),
      'assets/garage/silhouettes/emtb.svg',
    );
    expect(
      radSilhouetteAsset(
        Bike(id: 'h', name: 'Tour', category: BikeCategory.hiking),
      ),
      radHikingAsset,
    );
    expect(radHikingAsset, isNot(radNoPhotoAsset));
  });
}
