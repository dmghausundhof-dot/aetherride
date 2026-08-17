import '../bike.dart';
import '../component.dart';
import '../setup.dart';
import '../sport/discipline_ux.dart';

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
    required this.showsFahrwerk,
    required this.hasRearShock,
    required this.hasDropper,
    required this.emphasis,
    required this.emphasisSlots,
    required this.primaryAdjusterKey,
    this.wheelLabel,
  });

  final WerkstattKind kind;
  final bool hasElectricAssist;
  /// Physical: travel or an installed fork/shock.
  final bool hasSuspension;
  /// SAG / Federweg-UI — only when the sport cares and the bike has Fahrwerk.
  final bool showsFahrwerk;
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
    BikeCategory.urban ||
    BikeCategory.etrekking ||
    BikeCategory.cargo ||
    BikeCategory.folding ||
    BikeCategory.kids =>
      WerkstattKind.urban,
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
  final showsFahrwerk =
      hasSuspension && bike.category.showsSuspensionUx;
  final hasDropper = installed.any(componentLooksLikeDropper);
  final wheelLabel = bike.wheelSize?.label;

  final emphasis = <WerkstattEmphasis>[
    WerkstattEmphasis.tires,
    if (wheelLabel != null) WerkstattEmphasis.wheel,
    if (showsFahrwerk) WerkstattEmphasis.suspension,
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
    if (showsFahrwerk) ComponentSlot.fork,
    if (showsFahrwerk && hasRearShock) ComponentSlot.rearShock,
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
    showsFahrwerk: showsFahrwerk,
    hasRearShock: hasRearShock,
    hasDropper: hasDropper,
    emphasis: emphasis,
    emphasisSlots: slots,
    primaryAdjusterKey:
        showsFahrwerk ? 'fork.rebound' : 'tire_front.pressure_psi',
    wheelLabel: wheelLabel,
  );
}

/// Empty until the rider logs a number. Fox/psi tables live in opt-in
/// templates — never as the bike's current setup.
List<SetupValue> defaultSetupValuesFor(WerkstattSetupPlan plan) {
  return switch (plan.kind) {
    WerkstattKind.mtb ||
    WerkstattKind.gravel ||
    WerkstattKind.road ||
    WerkstattKind.urban ||
    WerkstattKind.hiking =>
      const [],
  };
}
