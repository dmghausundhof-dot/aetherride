import '../bike.dart';
import '../component.dart';
import '../setup.dart';

/// How the Werkstatt setup surface should read for this bike.
///
/// Honest: only real bike fields and installed garage parts. No invented
/// OEM SKUs, no fake SoC, no MTB suspension UI on a road bike.
enum WerkstattKind { mtb, gravel, road, urban, hiking }

enum WerkstattEmphasis {
  tires,
  suspension,
  suspensionUnknown,
  dropper,
  wheel,
  cockpit,
  bagsCockpit,
  lightsRack,
  drivetrain,
  batteryHonest,
}

class WerkstattSetupPlan {
  const WerkstattSetupPlan({
    required this.kind,
    required this.hasElectricAssist,
    required this.hasSuspension,
    required this.hasRearShock,
    required this.hasDropper,
    required this.emphasis,
    required this.emphasisSlots,
    required this.primaryAdjusterKey,
    this.wheelLabel,
  });

  final WerkstattKind kind;
  final bool hasElectricAssist;
  final bool hasSuspension;
  final bool hasRearShock;
  final bool hasDropper;
  final List<WerkstattEmphasis> emphasis;
  final List<ComponentSlot> emphasisSlots;
  final String primaryAdjusterKey;
  final String? wheelLabel;
}

bool componentLooksLikeDropper(BikeComponent c) {
  if (c.slot != ComponentSlot.seatpost || !c.isInstalled) return false;
  final blob = [
    c.model,
    c.manufacturer,
    c.catalogModelId,
    ...c.attributes.entries.map((e) => '${e.key} ${e.value}'),
  ].whereType<String>().join(' ').toLowerCase();
  return blob.contains('dropper') ||
      blob.contains('vario') ||
      blob.contains('reverb') ||
      blob.contains('transfer') ||
      blob.contains('oneup') ||
      RegExp(r'\blev\b').hasMatch(blob);
}

WerkstattKind werkstattKindFor(BikeCategory category) {
  return switch (category) {
    BikeCategory.mtbTrail ||
    BikeCategory.mtbAm ||
    BikeCategory.mtbEnduro ||
    BikeCategory.dh ||
    BikeCategory.emtb =>
      WerkstattKind.mtb,
    BikeCategory.gravel => WerkstattKind.gravel,
    BikeCategory.road => WerkstattKind.road,
    BikeCategory.urban || BikeCategory.etrekking => WerkstattKind.urban,
    BikeCategory.hiking => WerkstattKind.hiking,
  };
}

/// Setup surface for the selected bike. Travel / installed fork+shock decide
/// Fahrwerk — MTB without those fields does not get invented Fox numbers.
WerkstattSetupPlan planWerkstattSetup({
  required Bike bike,
  List<BikeComponent> components = const [],
}) {
  final kind = werkstattKindFor(bike.category);
  final installed = components.where((c) => c.isInstalled).toList();
  final hasForkComp = installed.any((c) => c.slot == ComponentSlot.fork);
  final hasShockComp = installed.any((c) => c.slot == ComponentSlot.rearShock);
  final travelF = bike.travelFrontMm ?? 0;
  final travelR = bike.travelRearMm ?? 0;
  final hasRearShock = travelR > 0 || hasShockComp;
  final hasSuspension =
      travelF > 0 || travelR > 0 || hasForkComp || hasShockComp;
  final hasDropper = installed.any(componentLooksLikeDropper);
  final wheelLabel = bike.wheelSize?.label;

  final emphasis = <WerkstattEmphasis>[
    WerkstattEmphasis.tires,
    if (wheelLabel != null) WerkstattEmphasis.wheel,
    if (hasSuspension) WerkstattEmphasis.suspension,
    if (kind == WerkstattKind.mtb && !hasSuspension)
      WerkstattEmphasis.suspensionUnknown,
    if (hasDropper) WerkstattEmphasis.dropper,
    if (kind == WerkstattKind.gravel) WerkstattEmphasis.bagsCockpit,
    if (kind == WerkstattKind.road) WerkstattEmphasis.cockpit,
    if (kind == WerkstattKind.urban) WerkstattEmphasis.lightsRack,
    if (kind == WerkstattKind.gravel || kind == WerkstattKind.road)
      WerkstattEmphasis.drivetrain,
    if (bike.hasElectricAssist) WerkstattEmphasis.batteryHonest,
  ];

  final slots = <ComponentSlot>[
    ComponentSlot.tireFront,
    ComponentSlot.tireRear,
    if (hasSuspension) ComponentSlot.fork,
    if (hasRearShock) ComponentSlot.rearShock,
    if (kind == WerkstattKind.gravel || kind == WerkstattKind.road) ...[
      ComponentSlot.handlebar,
      ComponentSlot.stem,
      ComponentSlot.cassette,
    ],
    if (kind == WerkstattKind.urban) ...[
      ComponentSlot.handlebar,
      ComponentSlot.stem,
      ComponentSlot.light,
      ComponentSlot.lock,
      ComponentSlot.rack,
      ComponentSlot.chain,
    ],
    if (kind == WerkstattKind.gravel) ComponentSlot.bags,
    if (hasDropper || kind == WerkstattKind.mtb) ComponentSlot.seatpost,
    if (bike.hasElectricAssist) ...[
      ComponentSlot.motor,
      ComponentSlot.battery,
      ComponentSlot.display,
    ],
  ];

  return WerkstattSetupPlan(
    kind: kind,
    hasElectricAssist: bike.hasElectricAssist,
    hasSuspension: hasSuspension,
    hasRearShock: hasRearShock,
    hasDropper: hasDropper,
    emphasis: emphasis,
    emphasisSlots: slots,
    primaryAdjusterKey:
        hasSuspension ? 'fork.rebound' : 'tire_front.pressure_psi',
    wheelLabel: wheelLabel,
  );
}

List<SetupValue> defaultSetupValuesFor(WerkstattSetupPlan plan) {
  if (plan.hasSuspension) {
    return BikeSetup.defaultValues();
  }
  final front = switch (plan.kind) {
    WerkstattKind.gravel => 36.0,
    WerkstattKind.road => 72.0,
    WerkstattKind.urban => 45.0,
    WerkstattKind.mtb || WerkstattKind.hiking => 22.0,
  };
  final rear = front + (plan.kind == WerkstattKind.road ? 4 : 2);
  return [
    SetupValue(
      adjusterKey: 'tire_front.pressure_psi',
      valueNum: front,
      unit: 'psi',
    ),
    SetupValue(
      adjusterKey: 'tire_rear.pressure_psi',
      valueNum: rear,
      unit: 'psi',
    ),
  ];
}
