/// Deklarative Kompat-Regeln — Spiegel src/lib/compatibility/rules.ts (16 Regeln).

import '../component.dart';

enum RuleSeverity { functional, safetyCritical }

enum CompatVerdict {
  compatible,
  conditional,
  incompatible,
  insufficientData,
}

typedef CompatPredicate = String; // equals|tire_rim_fit|rotor_within_max|seatpost_fit|shock_fit

class CompatibilityRuleDef {
  const CompatibilityRuleDef({
    required this.code,
    required this.title,
    required this.severity,
    required this.slotA,
    required this.slotB,
    required this.requiresA,
    required this.requiresB,
    required this.predicate,
    required this.onPass,
    required this.onFail,
    required this.explainFailDe,
    required this.howToObtain,
    this.conditionText,
    this.sourceUrl = '',
  });

  final String code;
  final String title;
  final RuleSeverity severity;
  final ComponentSlot slotA;
  final ComponentSlot slotB;
  final List<String> requiresA;
  final List<String> requiresB;
  final CompatPredicate predicate;
  final CompatVerdict onPass;
  final CompatVerdict onFail;
  final String explainFailDe;
  final Map<String, String> howToObtain;
  final String? conditionText;
  final String sourceUrl;
}

class CompatibilityResult {
  const CompatibilityResult({
    required this.verdict,
    required this.ruleCode,
    required this.title,
    required this.severity,
    required this.explainDe,
    this.missingAttributes = const [],
    this.conditionText,
    this.safetyWorkshopHint,
    this.sourceUrl,
    this.valuesA = const {},
    this.valuesB = const {},
  });

  final CompatVerdict verdict;
  final String ruleCode;
  final String title;
  final RuleSeverity severity;
  final String explainDe;
  final List<({String key, String howToObtain})> missingAttributes;
  final String? conditionText;
  final String? safetyWorkshopHint;
  final String? sourceUrl;

  /// Stringified rule attributes — UI fills l10n templates, domain stays DE.
  final Map<String, String> valuesA;
  final Map<String, String> valuesB;
}

const compatibilityRules = <CompatibilityRuleDef>[
  CompatibilityRuleDef(
    code: 'RL-DRV-011',
    title: 'Kassette benötigt passenden Freilaufkörper',
    severity: RuleSeverity.functional,
    slotA: ComponentSlot.cassette,
    slotB: ComponentSlot.rearHub,
    requiresA: ['freehub_standard'],
    requiresB: ['freehub_standard'],
    predicate: 'equals',
    onPass: CompatVerdict.compatible,
    onFail: CompatVerdict.incompatible,
    explainFailDe:
        'Die Kassette benötigt {a.freehub_standard}, deine Nabe hat {b.freehub_standard}.',
    howToObtain: {
      'freehub_standard': 'Aufdruck Freilaufkörper / Naben-Datenblatt',
    },
  ),
  CompatibilityRuleDef(
    code: 'RL-FRM-004',
    title: 'Hinterbau-Einbaubreite muss zur Nabe passen',
    severity: RuleSeverity.safetyCritical,
    slotA: ComponentSlot.frame,
    slotB: ComponentSlot.rearHub,
    requiresA: ['rear_spacing'],
    requiresB: ['rear_spacing'],
    predicate: 'equals',
    onPass: CompatVerdict.compatible,
    onFail: CompatVerdict.incompatible,
    explainFailDe:
        'Rahmen-Einbaubreite {a.rear_spacing} ≠ Nabe {b.rear_spacing}.',
    howToObtain: {'rear_spacing': 'Rahmen-/Naben-Spec (Boost 148, 142×12, …)'},
  ),
  CompatibilityRuleDef(
    code: 'RL-SUS-007',
    title: 'Dämpfer-Maß muss zur Rahmenvorgabe passen',
    severity: RuleSeverity.safetyCritical,
    slotA: ComponentSlot.rearShock,
    slotB: ComponentSlot.frame,
    requiresA: ['eye_to_eye_mm', 'stroke_mm', 'mount_type'],
    requiresB: ['shock_eye_to_eye_mm', 'shock_stroke_mm', 'shock_mount_type'],
    predicate: 'shock_fit',
    onPass: CompatVerdict.compatible,
    onFail: CompatVerdict.incompatible,
    explainFailDe:
        'Dämpfer {a.eye_to_eye_mm}×{a.stroke_mm} ({a.mount_type}) passt nicht zur Rahmenvorgabe.',
    howToObtain: {
      'eye_to_eye_mm': 'Dämpfer-Aufdruck',
      'stroke_mm': 'Dämpfer-Katalog',
      'mount_type': 'Trunnion vs. Eyelet',
    },
  ),
  CompatibilityRuleDef(
    code: 'RL-SUS-012',
    title: 'Gabel-Schaft vs. Steuersatz (S.H.I.S.)',
    severity: RuleSeverity.safetyCritical,
    slotA: ComponentSlot.fork,
    slotB: ComponentSlot.headset,
    requiresA: ['steerer_type'],
    requiresB: ['steerer_type'],
    predicate: 'equals',
    onPass: CompatVerdict.compatible,
    onFail: CompatVerdict.incompatible,
    explainFailDe:
        'Gabel-Schaft {a.steerer_type} passt nicht zum Steuersatz {b.steerer_type}.',
    howToObtain: {'steerer_type': '1⅛″ oder tapered 1,5″ / S.H.I.S.'},
  ),
  CompatibilityRuleDef(
    code: 'RL-BRK-003',
    title: 'Bremssattel-Aufnahme am Rahmen',
    severity: RuleSeverity.safetyCritical,
    slotA: ComponentSlot.brakeRear,
    slotB: ComponentSlot.frame,
    requiresA: ['brake_mount'],
    requiresB: ['brake_mount_rear'],
    predicate: 'equals',
    onPass: CompatVerdict.compatible,
    onFail: CompatVerdict.conditional,
    conditionText: 'Nur mit passendem Adapter (Post Mount ↔ IS).',
    explainFailDe:
        'Bremssattel {a.brake_mount} vs. Rahmenaufnahme {b.brake_mount_rear}.',
    howToObtain: {
      'brake_mount': 'Post Mount / Flat Mount / IS',
      'brake_mount_rear': 'Rahmen-Spec',
    },
  ),
  CompatibilityRuleDef(
    code: 'RL-BRK-008',
    title: 'Bremsscheiben-Aufnahme vs. Nabe',
    severity: RuleSeverity.safetyCritical,
    slotA: ComponentSlot.rotorRear,
    slotB: ComponentSlot.rearHub,
    requiresA: ['rotor_mount'],
    requiresB: ['rotor_mount'],
    predicate: 'equals',
    onPass: CompatVerdict.compatible,
    onFail: CompatVerdict.incompatible,
    explainFailDe: 'Scheibe {a.rotor_mount} ≠ Nabe {b.rotor_mount}.',
    howToObtain: {'rotor_mount': 'Center Lock oder 6-Loch'},
  ),
  CompatibilityRuleDef(
    code: 'RL-BRK-008F',
    title: 'Bremsscheibe vorne vs. Vorderradnabe',
    severity: RuleSeverity.safetyCritical,
    slotA: ComponentSlot.rotorFront,
    slotB: ComponentSlot.frontHub,
    requiresA: ['rotor_mount'],
    requiresB: ['rotor_mount'],
    predicate: 'equals',
    onPass: CompatVerdict.compatible,
    onFail: CompatVerdict.incompatible,
    explainFailDe: 'Vordere Scheibe {a.rotor_mount} ≠ Nabe {b.rotor_mount}.',
    howToObtain: {'rotor_mount': 'Center Lock oder 6-Loch'},
  ),
  CompatibilityRuleDef(
    code: 'RL-WHL-005',
    title: 'Reifenbreite zur Felgen-Maulweite',
    severity: RuleSeverity.safetyCritical,
    slotA: ComponentSlot.tireRear,
    slotB: ComponentSlot.rearRim,
    requiresA: ['tire_width_mm'],
    requiresB: ['internal_rim_width_mm'],
    predicate: 'tire_rim_fit',
    onPass: CompatVerdict.compatible,
    onFail: CompatVerdict.incompatible,
    explainFailDe:
        'Reifenbreite {a.tire_width_mm} mm außerhalb Bereich für Maulweite {b.internal_rim_width_mm} mm.',
    howToObtain: {
      'tire_width_mm': 'ETRTO',
      'internal_rim_width_mm': 'Felgen-Datenblatt',
    },
  ),
  CompatibilityRuleDef(
    code: 'RL-WHL-005F',
    title: 'Vorderreifen zur Felgen-Maulweite',
    severity: RuleSeverity.safetyCritical,
    slotA: ComponentSlot.tireFront,
    slotB: ComponentSlot.frontRim,
    requiresA: ['tire_width_mm'],
    requiresB: ['internal_rim_width_mm'],
    predicate: 'tire_rim_fit',
    onPass: CompatVerdict.compatible,
    onFail: CompatVerdict.incompatible,
    explainFailDe:
        'Vorderreifen {a.tire_width_mm} mm außerhalb Bereich für {b.internal_rim_width_mm} mm.',
    howToObtain: {
      'tire_width_mm': 'ETRTO',
      'internal_rim_width_mm': 'Felgen-Datenblatt',
    },
  ),
  CompatibilityRuleDef(
    code: 'RL-WHL-009',
    title: 'Reifen-Außenmaß vs. Rahmenfreigang',
    severity: RuleSeverity.safetyCritical,
    slotA: ComponentSlot.tireRear,
    slotB: ComponentSlot.frame,
    requiresA: ['tire_width_mm'],
    requiresB: ['max_tire_width_mm'],
    predicate: 'rotor_within_max',
    onPass: CompatVerdict.compatible,
    onFail: CompatVerdict.incompatible,
    explainFailDe:
        'Reifenbreite {a.tire_width_mm} mm > Rahmenfreigang {b.max_tire_width_mm} mm.',
    howToObtain: {
      'tire_width_mm': 'ETRTO',
      'max_tire_width_mm': 'Rahmen-Herstellerangabe',
    },
  ),
  CompatibilityRuleDef(
    code: 'RL-CKP-002',
    title: 'Lenker-Klemmdurchmesser vs. Vorbau',
    severity: RuleSeverity.safetyCritical,
    slotA: ComponentSlot.handlebar,
    slotB: ComponentSlot.stem,
    requiresA: ['handlebar_clamp_mm'],
    requiresB: ['stem_clamp_mm'],
    predicate: 'equals',
    onPass: CompatVerdict.compatible,
    onFail: CompatVerdict.incompatible,
    explainFailDe:
        'Lenkerklemmung {a.handlebar_clamp_mm} mm ≠ Vorbau {b.stem_clamp_mm} mm.',
    howToObtain: {
      'handlebar_clamp_mm': '31,8 oder 35,0',
      'stem_clamp_mm': 'Vorbau-Datenblatt',
    },
  ),
  CompatibilityRuleDef(
    code: 'RL-SPT-006',
    title: 'Sattelstützendurchmesser vs. Sitzrohr',
    severity: RuleSeverity.safetyCritical,
    slotA: ComponentSlot.seatpost,
    slotB: ComponentSlot.frame,
    requiresA: ['seatpost_diameter_mm', 'min_insertion_mm'],
    requiresB: ['seatpost_diameter_mm', 'max_seatpost_insertion_mm'],
    predicate: 'seatpost_fit',
    onPass: CompatVerdict.compatible,
    onFail: CompatVerdict.incompatible,
    explainFailDe:
        'Stütze Ø {a.seatpost_diameter_mm} passt nicht zu Rahmen Ø {b.seatpost_diameter_mm}.',
    howToObtain: {
      'seatpost_diameter_mm': '27,2 / 30,9 / 31,6 / 34,9',
      'min_insertion_mm': 'Dropper-Handbuch',
      'max_seatpost_insertion_mm': 'Rahmen-Geometrie',
    },
  ),
  CompatibilityRuleDef(
    code: 'RL-BB-003',
    title: 'Innenlager-Standard vs. Kurbelwelle',
    severity: RuleSeverity.functional,
    slotA: ComponentSlot.bottomBracket,
    slotB: ComponentSlot.crankset,
    requiresA: ['crank_axle'],
    requiresB: ['crank_axle'],
    predicate: 'equals',
    onPass: CompatVerdict.compatible,
    onFail: CompatVerdict.incompatible,
    explainFailDe: 'Innenlager-Welle {a.crank_axle} ≠ Kurbel {b.crank_axle}.',
    howToObtain: {'crank_axle': 'DUB / 24mm / 30mm'},
  ),
  CompatibilityRuleDef(
    code: 'RL-BB-003F',
    title: 'Innenlager vs. Rahmen-Standard',
    severity: RuleSeverity.functional,
    slotA: ComponentSlot.bottomBracket,
    slotB: ComponentSlot.frame,
    requiresA: ['bb_standard'],
    requiresB: ['bb_standard'],
    predicate: 'equals',
    onPass: CompatVerdict.compatible,
    onFail: CompatVerdict.incompatible,
    explainFailDe: 'Innenlager {a.bb_standard} ≠ Rahmen {b.bb_standard}.',
    howToObtain: {'bb_standard': 'BSA / T47 / PF92 / …'},
  ),
  CompatibilityRuleDef(
    code: 'RL-EBK-002',
    title: 'Motor-Interface nur bei OEM-Freigabe',
    severity: RuleSeverity.safetyCritical,
    slotA: ComponentSlot.motor,
    slotB: ComponentSlot.frame,
    requiresA: ['motor_interface'],
    requiresB: ['motor_interface'],
    predicate: 'equals',
    onPass: CompatVerdict.compatible,
    onFail: CompatVerdict.incompatible,
    explainFailDe:
        'Motortausch außerhalb OEM-Freigabe unzulässig. Frame {b.motor_interface} ≠ Motor {a.motor_interface}.',
    howToObtain: {'motor_interface': 'z. B. bosch_smart_system'},
  ),
  CompatibilityRuleDef(
    code: 'RL-FRM-004F',
    title: 'Vorderrad-Achse vs. Gabel',
    severity: RuleSeverity.safetyCritical,
    slotA: ComponentSlot.fork,
    slotB: ComponentSlot.frontHub,
    requiresA: ['axle_front'],
    requiresB: ['axle_front'],
    predicate: 'equals',
    onPass: CompatVerdict.compatible,
    onFail: CompatVerdict.incompatible,
    explainFailDe: 'Gabel-Achse {a.axle_front} ≠ Nabe {b.axle_front}.',
    howToObtain: {'axle_front': '15×100 / 15×110 Boost / …'},
  ),
];
