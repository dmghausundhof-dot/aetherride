import 'bike_schema_anchors.dart';
import 'bike_schema_mapper.dart';
import 'die_box.dart';
import '../bike.dart';
import '../component.dart';

const radStandGroundAsset = 'assets/garage/stand-ground.svg';
const radStandHeaderAsset = 'assets/garage/header-stand.svg';
const radEmptyStandAsset = 'assets/garage/empty-stand.svg';
const radEmptyStandMarkAsset = 'assets/garage/empty-stand-mark.svg';
const radNoPhotoAsset = 'assets/garage/no-photo.svg';
const radHikingAsset = 'assets/garage/silhouettes/hiking.svg';

/// Category silhouette on the stand — same mapping as web `radSilhouetteSrc`.
String radSilhouetteAsset(Bike bike) {
  final plan = planBikeSchema(
    category: bike.category,
    isEbike: bike.hasElectricAssist,
  );
  if (plan.assetKey != null) {
    return schemaAssetPath[plan.assetKey!] ?? radNoPhotoAsset;
  }
  if (bike.category == BikeCategory.hiking) return radHikingAsset;
  return radNoPhotoAsset;
}

/// FlowLine Rad-Stand marks — same names as web `radMark.ts`.
String radMarkForItem(DieBoxItemId id) => switch (id) {
      DieBoxItemId.setActive => 'stand',
      DieBoxItemId.pressureUnknown => 'pressure',
      DieBoxItemId.sagUnknown => 'sag',
      DieBoxItemId.travelUnknown => 'travel',
      DieBoxItemId.chainTeach => 'chain',
      DieBoxItemId.lightsMissing => 'lights',
      DieBoxItemId.lockMissing => 'lock',
      DieBoxItemId.rackMissing => 'rack',
      DieBoxItemId.bagsMissing => 'bags',
      DieBoxItemId.brakesUnknown => 'brakes',
      DieBoxItemId.dueCare => 'care',
      DieBoxItemId.pairCsc => 'battery',
      DieBoxItemId.parkTrail => 'setup',
      DieBoxItemId.serviceAppointment => 'care',
    };

String radMarkForReadiness(DieBoxReadiness r) => switch (r) {
      DieBoxReadiness.ready => 'ready',
      DieBoxReadiness.almost => 'almost',
      DieBoxReadiness.unknown => 'unknown',
    };

String radMarkForChip(String label) {
  switch (label) {
    case 'Licht':
      return 'lights';
    case 'Schloss':
      return 'lock';
    case 'Träger':
      return 'rack';
    case 'Taschen':
      return 'bags';
    case 'Reifen':
    case 'Druck':
      return 'pressure';
    case 'Vario':
    case 'Park | Trail':
      return 'setup';
    case 'Bremsen':
      return 'brakes';
    case 'Federweg':
      return 'travel';
    case 'CSC':
      return 'battery';
    case 'SAG':
      return 'sag';
    case 'Kette':
      return 'chain';
    case 'Cockpit':
      return 'cockpit';
    case 'Ausweis':
      return 'identity';
  }
  if (RegExp(r'mm$', caseSensitive: false).hasMatch(label.trim()) ||
      RegExp(r'\d+\s*/\s*.*mm', caseSensitive: false).hasMatch(label)) {
    return 'travel';
  }
  if (RegExp(r'^(700c|650b|27\.5"|29"|27_5|26"|24"|20"|16")$',
          caseSensitive: false)
      .hasMatch(label.trim())) {
    return 'pressure';
  }
  return 'parts';
}

String radMarkForSlot(ComponentSlot slot) => switch (slot) {
      ComponentSlot.tireFront ||
      ComponentSlot.tireRear =>
        'pressure',
      ComponentSlot.fork || ComponentSlot.rearShock => 'sag',
      ComponentSlot.chain ||
      ComponentSlot.cassette ||
      ComponentSlot.crankset ||
      ComponentSlot.frontDerailleur ||
      ComponentSlot.rearDerailleur =>
        'chain',
      ComponentSlot.brakeFront ||
      ComponentSlot.brakeRear ||
      ComponentSlot.rotorFront ||
      ComponentSlot.rotorRear =>
        'brakes',
      ComponentSlot.light => 'lights',
      ComponentSlot.lock => 'lock',
      ComponentSlot.rack => 'rack',
      ComponentSlot.bags => 'bags',
      ComponentSlot.battery ||
      ComponentSlot.motor ||
      ComponentSlot.display =>
        'battery',
      ComponentSlot.handlebar ||
      ComponentSlot.stem ||
      ComponentSlot.grips =>
        'cockpit',
      _ => 'parts',
    };
