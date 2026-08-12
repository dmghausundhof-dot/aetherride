/// Component slots + installed parts (Spiegel src/types/garage.ts).

enum ComponentSlot {
  frame,
  fork,
  rearShock,
  headset,
  stem,
  handlebar,
  grips,
  seatpost,
  saddle,
  frontHub,
  rearHub,
  frontRim,
  rearRim,
  tireFront,
  tireRear,
  cassette,
  chain,
  crankset,
  bottomBracket,
  frontDerailleur,
  rearDerailleur,
  shifter,
  brakeFront,
  brakeRear,
  rotorFront,
  rotorRear,
  motor,
  battery,
  display,
  other,
}

extension ComponentSlotLabel on ComponentSlot {
  String get label => switch (this) {
        ComponentSlot.frame => 'Rahmen',
        ComponentSlot.fork => 'Gabel',
        ComponentSlot.rearShock => 'Dämpfer',
        ComponentSlot.headset => 'Steuersatz',
        ComponentSlot.stem => 'Vorbau',
        ComponentSlot.handlebar => 'Lenker',
        ComponentSlot.grips => 'Griffe',
        ComponentSlot.seatpost => 'Sattelstütze',
        ComponentSlot.saddle => 'Sattel',
        ComponentSlot.frontHub => 'Nabe vorn',
        ComponentSlot.rearHub => 'Nabe hinten',
        ComponentSlot.frontRim => 'Felge vorn',
        ComponentSlot.rearRim => 'Felge hinten',
        ComponentSlot.tireFront => 'Reifen vorn',
        ComponentSlot.tireRear => 'Reifen hinten',
        ComponentSlot.cassette => 'Kassette',
        ComponentSlot.chain => 'Kette',
        ComponentSlot.crankset => 'Kurbel',
        ComponentSlot.bottomBracket => 'Innenlager',
        ComponentSlot.frontDerailleur => 'Umwerfer',
        ComponentSlot.rearDerailleur => 'Schaltwerk',
        ComponentSlot.shifter => 'Schalthebel',
        ComponentSlot.brakeFront => 'Bremse vorn',
        ComponentSlot.brakeRear => 'Bremse hinten',
        ComponentSlot.rotorFront => 'Scheibe vorn',
        ComponentSlot.rotorRear => 'Scheibe hinten',
        ComponentSlot.motor => 'Motor',
        ComponentSlot.battery => 'Akku',
        ComponentSlot.display => 'Display',
        ComponentSlot.other => 'Sonstiges',
      };

  /// Maps Dart enum → web/JSON slot id (snake_case).
  String get apiId => switch (this) {
        ComponentSlot.rearShock => 'rear_shock',
        ComponentSlot.frontHub => 'front_hub',
        ComponentSlot.rearHub => 'rear_hub',
        ComponentSlot.frontRim => 'front_rim',
        ComponentSlot.rearRim => 'rear_rim',
        ComponentSlot.tireFront => 'tire_front',
        ComponentSlot.tireRear => 'tire_rear',
        ComponentSlot.bottomBracket => 'bottom_bracket',
        ComponentSlot.frontDerailleur => 'front_derailleur',
        ComponentSlot.rearDerailleur => 'rear_derailleur',
        ComponentSlot.brakeFront => 'brake_front',
        ComponentSlot.brakeRear => 'brake_rear',
        ComponentSlot.rotorFront => 'rotor_front',
        ComponentSlot.rotorRear => 'rotor_rear',
        _ => name,
      };

  static ComponentSlot? fromApiId(String id) {
    for (final s in ComponentSlot.values) {
      if (s.apiId == id || s.name == id) return s;
    }
    return null;
  }
}

/// Grobe Gruppen für die Garage — 25 Einzelzeilen sind zu viel auf einmal.
enum ComponentGroup {
  suspension,
  wheels,
  cockpit,
  drivetrain,
  brakes,
  power,
  other,
}

extension ComponentGroupLabel on ComponentGroup {
  String get label => switch (this) {
        ComponentGroup.suspension => 'Fahrwerk',
        ComponentGroup.wheels => 'Laufräder',
        ComponentGroup.cockpit => 'Cockpit',
        ComponentGroup.drivetrain => 'Antrieb',
        ComponentGroup.brakes => 'Bremsen',
        ComponentGroup.power => 'E-Bike',
        ComponentGroup.other => 'Weiteres',
      };
}

extension ComponentSlotGroup on ComponentSlot {
  ComponentGroup get group => switch (this) {
        ComponentSlot.frame ||
        ComponentSlot.fork ||
        ComponentSlot.rearShock =>
          ComponentGroup.suspension,
        ComponentSlot.frontHub ||
        ComponentSlot.rearHub ||
        ComponentSlot.frontRim ||
        ComponentSlot.rearRim ||
        ComponentSlot.tireFront ||
        ComponentSlot.tireRear =>
          ComponentGroup.wheels,
        ComponentSlot.headset ||
        ComponentSlot.stem ||
        ComponentSlot.handlebar ||
        ComponentSlot.grips ||
        ComponentSlot.seatpost ||
        ComponentSlot.saddle =>
          ComponentGroup.cockpit,
        ComponentSlot.cassette ||
        ComponentSlot.chain ||
        ComponentSlot.crankset ||
        ComponentSlot.bottomBracket ||
        ComponentSlot.frontDerailleur ||
        ComponentSlot.rearDerailleur ||
        ComponentSlot.shifter =>
          ComponentGroup.drivetrain,
        ComponentSlot.brakeFront ||
        ComponentSlot.brakeRear ||
        ComponentSlot.rotorFront ||
        ComponentSlot.rotorRear =>
          ComponentGroup.brakes,
        ComponentSlot.motor ||
        ComponentSlot.battery ||
        ComponentSlot.display =>
          ComponentGroup.power,
        ComponentSlot.other => ComponentGroup.other,
      };
}

const coreInstallSlots = <ComponentSlot>[
  ComponentSlot.frame,
  ComponentSlot.fork,
  ComponentSlot.rearShock,
  ComponentSlot.rearHub,
  ComponentSlot.cassette,
  ComponentSlot.tireRear,
  ComponentSlot.rearRim,
  ComponentSlot.brakeRear,
  ComponentSlot.rotorRear,
  ComponentSlot.seatpost,
  ComponentSlot.handlebar,
  ComponentSlot.stem,
  ComponentSlot.bottomBracket,
  ComponentSlot.crankset,
  ComponentSlot.motor,
];

class BikeComponent {
  const BikeComponent({
    required this.id,
    required this.bikeId,
    required this.slot,
    this.manufacturer,
    this.model,
    this.catalogModelId,
    this.installedAt,
    this.removedAt,
    this.odometerKm = 0,
    this.attributes = const {},
  });

  final String id;
  final String bikeId;
  final ComponentSlot slot;
  final String? manufacturer;
  final String? model;
  final String? catalogModelId;
  final DateTime? installedAt;
  final DateTime? removedAt;
  final double odometerKm;

  /// Attribute key → string/number value (for compat engine).
  final Map<String, dynamic> attributes;

  bool get isInstalled => removedAt == null;

  String get displayName {
    final parts = [
      if (manufacturer != null && manufacturer!.isNotEmpty) manufacturer!,
      if (model != null && model!.isNotEmpty) model!,
    ];
    return parts.isEmpty ? slot.label : parts.join(' ');
  }
}
