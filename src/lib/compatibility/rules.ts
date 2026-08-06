import type { ComponentSlot, RuleSeverity } from "@/types/garage";

/**
 * Deklarative Kompatibilitätsregeln (Spec 6.6 / F-GAR-003).
 * Quellen: BikeRadar Achsstandards, BIKE Magazin BB, S.H.I.S.,
 * SRAM/Shimano Freilauf, ETRTO-/Praxis-Reifen-Maulweite.
 */

export interface CompatibilityRuleDef {
  code: string;
  title: string;
  severity: RuleSeverity;
  slotA: ComponentSlot;
  slotB: ComponentSlot;
  /** Attribute die auf beiden Seiten vorhanden sein müssen */
  requiresA: string[];
  requiresB: string[];
  predicate: "equals" | "tire_rim_fit" | "rotor_within_max" | "seatpost_fit" | "shock_fit";
  onPass: "COMPATIBLE" | "CONDITIONAL";
  onFail: "INCOMPATIBLE" | "CONDITIONAL";
  conditionText?: string;
  explainFailDe: string;
  howToObtain: Record<string, string>;
  sourceUrl: string;
  reviewedBy: string;
  reviewedAt: string;
}

export const COMPATIBILITY_RULES: CompatibilityRuleDef[] = [
  {
    code: "RL-DRV-011",
    title: "Kassette benötigt passenden Freilaufkörper",
    severity: "functional",
    slotA: "cassette",
    slotB: "rear_hub",
    requiresA: ["freehub_standard"],
    requiresB: ["freehub_standard"],
    predicate: "equals",
    onPass: "COMPATIBLE",
    onFail: "INCOMPATIBLE",
    explainFailDe:
      "Die Kassette benötigt {a.freehub_standard}, deine Nabe hat {b.freehub_standard}. Ein Freilaufkörper-Tausch ist bei manchen Naben möglich – prüfe die Herstellerangabe.",
    howToObtain: {
      freehub_standard:
        "Aufdruck auf Freilaufkörper / Naben-Datenblatt (HG, Micro Spline, XD, XDR)",
    },
    sourceUrl: "https://www.sram.com/",
    reviewedBy: "AetherRide Editorial",
    reviewedAt: "2026-05-14",
  },
  {
    code: "RL-FRM-004",
    title: "Hinterbau-Einbaubreite muss zur Nabe passen",
    severity: "safety_critical",
    slotA: "frame",
    slotB: "rear_hub",
    requiresA: ["rear_spacing"],
    requiresB: ["rear_spacing"],
    predicate: "equals",
    onPass: "COMPATIBLE",
    onFail: "INCOMPATIBLE",
    explainFailDe:
      "Rahmen-Einbaubreite {a.rear_spacing} ≠ Nabe {b.rear_spacing}. Boost 148, 142×12 und Super Boost 157 sind nicht austauschbar (BikeRadar Achsstandards).",
    howToObtain: {
      rear_spacing:
        "Rahmen-Geometriedatenblatt bzw. Naben-Spec (135×10 QR, 142×12, 148×12 Boost, 157×12 SuperBoost)",
    },
    sourceUrl: "https://www.bikeradar.com/advice/buyers-guides/mtb-axle-standards",
    reviewedBy: "AetherRide Editorial",
    reviewedAt: "2026-05-14",
  },
  {
    code: "RL-SUS-007",
    title: "Dämpfer-Maß muss zur Rahmenvorgabe passen",
    severity: "safety_critical",
    slotA: "rear_shock",
    slotB: "frame",
    requiresA: ["eye_to_eye_mm", "stroke_mm", "mount_type"],
    requiresB: ["shock_eye_to_eye_mm", "shock_stroke_mm", "shock_mount_type"],
    predicate: "shock_fit",
    onPass: "COMPATIBLE",
    onFail: "INCOMPATIBLE",
    explainFailDe:
      "Dämpfer {a.eye_to_eye_mm}×{a.stroke_mm} ({a.mount_type}) passt nicht zur Rahmenvorgabe {b.shock_eye_to_eye_mm}×{b.shock_stroke_mm} ({b.shock_mount_type}).",
    howToObtain: {
      eye_to_eye_mm: "Aufdruck am Dämpfer oder Herstellerkatalog",
      stroke_mm: "Aufdruck am Dämpfer oder Herstellerkatalog",
      mount_type: "Trunnion vs. Standard Eyelet – Rahmen-Handbuch",
      shock_eye_to_eye_mm: "Rahmen-Geometrie / OEM-Spec",
      shock_stroke_mm: "Rahmen-Geometrie / OEM-Spec",
      shock_mount_type: "Rahmen-Handbuch",
    },
    sourceUrl: "https://www.ridefox.com/",
    reviewedBy: "AetherRide Editorial",
    reviewedAt: "2026-05-14",
  },
  {
    code: "RL-SUS-012",
    title: "Gabel-Schaft vs. Steuersatz (S.H.I.S.)",
    severity: "safety_critical",
    slotA: "fork",
    slotB: "headset",
    requiresA: ["steerer_type"],
    requiresB: ["steerer_type"],
    predicate: "equals",
    onPass: "COMPATIBLE",
    onFail: "INCOMPATIBLE",
    explainFailDe:
      "Gabel-Schaft {a.steerer_type} passt nicht zum Steuersatz {b.steerer_type}. S.H.I.S. erfordert passende Kombination (z. B. tapered 1,5″ mit ZS44/ZS56).",
    howToObtain: {
      steerer_type:
        "Gabel: 1⅛″ gerade oder tapered 1,5″; Steuersatz: ZS44/ZS56, IS42/IS52, EC34 …",
    },
    sourceUrl:
      "https://www.mountainflyermagazine.com/img/upimages/standardized_headset_identification_system.pdf",
    reviewedBy: "AetherRide Editorial",
    reviewedAt: "2026-05-14",
  },
  {
    code: "RL-BRK-003",
    title: "Bremssattel-Aufnahme am Rahmen/Gabel",
    severity: "safety_critical",
    slotA: "brake_rear",
    slotB: "frame",
    requiresA: ["brake_mount"],
    requiresB: ["brake_mount_rear"],
    predicate: "equals",
    onPass: "COMPATIBLE",
    onFail: "CONDITIONAL",
    conditionText: "Nur mit passendem Adapter (Post Mount ↔ IS).",
    explainFailDe:
      "Bremssattel {a.brake_mount} vs. Rahmenaufnahme {b.brake_mount_rear}. Adapter möglich – Montage durch Fachwerkstatt.",
    howToObtain: {
      brake_mount: "Bremssattel-Datenblatt (Post Mount, Flat Mount, IS)",
      brake_mount_rear: "Rahmen-Spec",
    },
    sourceUrl: "https://www.sram.com/",
    reviewedBy: "AetherRide Editorial",
    reviewedAt: "2026-05-14",
  },
  {
    code: "RL-BRK-008",
    title: "Bremsscheiben-Aufnahme vs. Nabe",
    severity: "safety_critical",
    slotA: "rotor_rear",
    slotB: "rear_hub",
    requiresA: ["rotor_mount"],
    requiresB: ["rotor_mount"],
    predicate: "equals",
    onPass: "COMPATIBLE",
    onFail: "INCOMPATIBLE",
    explainFailDe:
      "Scheibe {a.rotor_mount} passt nicht zur Nabe {b.rotor_mount} (6-Loch vs. Center Lock).",
    howToObtain: {
      rotor_mount: "Center Lock oder 6-Loch – auf Nabe/Scheibe angegeben",
    },
    sourceUrl: "https://bike.shimano.com/",
    reviewedBy: "AetherRide Editorial",
    reviewedAt: "2026-05-14",
  },
  {
    code: "RL-BRK-008F",
    title: "Bremsscheibe vorne vs. Vorderradnabe",
    severity: "safety_critical",
    slotA: "rotor_front",
    slotB: "front_hub",
    requiresA: ["rotor_mount"],
    requiresB: ["rotor_mount"],
    predicate: "equals",
    onPass: "COMPATIBLE",
    onFail: "INCOMPATIBLE",
    explainFailDe:
      "Vordere Scheibe {a.rotor_mount} passt nicht zur Nabe {b.rotor_mount}.",
    howToObtain: {
      rotor_mount: "Center Lock oder 6-Loch",
    },
    sourceUrl: "https://bike.shimano.com/",
    reviewedBy: "AetherRide Editorial",
    reviewedAt: "2026-05-14",
  },
  {
    code: "RL-WHL-005",
    title: "Reifenbreite zur Felgen-Maulweite",
    severity: "safety_critical",
    slotA: "tire_rear",
    slotB: "rear_rim",
    requiresA: ["tire_width_mm"],
    requiresB: ["internal_rim_width_mm"],
    predicate: "tire_rim_fit",
    onPass: "COMPATIBLE",
    onFail: "INCOMPATIBLE",
    conditionText:
      "Ohne Herstellerfreigabe gilt die ETRTO-/Praxis-Tabelle (Reifenbreite ≈ 1,4–2,4× Maulweite).",
    explainFailDe:
      "Reifenbreite {a.tire_width_mm} mm liegt außerhalb des empfohlenen Bereichs für Maulweite {b.internal_rim_width_mm} mm.",
    howToObtain: {
      tire_width_mm: "Seitenwand ETRTO / Herstellerangabe",
      internal_rim_width_mm: "Felgen-Datenblatt (IRW)",
    },
    sourceUrl: "https://de.elite-wheels.com/technology/how-to-optimize-mtb-wheels-for-trail-commute-xc/",
    reviewedBy: "AetherRide Editorial",
    reviewedAt: "2026-05-14",
  },
  {
    code: "RL-WHL-005F",
    title: "Vorderreifen zur Felgen-Maulweite",
    severity: "safety_critical",
    slotA: "tire_front",
    slotB: "front_rim",
    requiresA: ["tire_width_mm"],
    requiresB: ["internal_rim_width_mm"],
    predicate: "tire_rim_fit",
    onPass: "COMPATIBLE",
    onFail: "INCOMPATIBLE",
    conditionText:
      "Ohne Herstellerfreigabe gilt die Praxis-Tabelle Reifenbreite ≈ 1,4–2,4× Maulweite.",
    explainFailDe:
      "Vorderreifen {a.tire_width_mm} mm außerhalb des Bereichs für Maulweite {b.internal_rim_width_mm} mm.",
    howToObtain: {
      tire_width_mm: "ETRTO / Hersteller",
      internal_rim_width_mm: "Felgen-Datenblatt",
    },
    sourceUrl: "https://de.elite-wheels.com/technology/how-to-optimize-mtb-wheels-for-trail-commute-xc/",
    reviewedBy: "AetherRide Editorial",
    reviewedAt: "2026-05-14",
  },
  {
    code: "RL-WHL-009",
    title: "Reifen-Außenmaß vs. Rahmenfreigang",
    severity: "safety_critical",
    slotA: "tire_rear",
    slotB: "frame",
    requiresA: ["tire_width_mm"],
    requiresB: ["max_tire_width_mm"],
    predicate: "rotor_within_max",
    onPass: "COMPATIBLE",
    onFail: "INCOMPATIBLE",
    explainFailDe:
      "Reifenbreite {a.tire_width_mm} mm überschreitet Rahmenfreigang {b.max_tire_width_mm} mm.",
    howToObtain: {
      tire_width_mm: "ETRTO",
      max_tire_width_mm: "Rahmen-Herstellerangabe (ohne Schätzen!)",
    },
    sourceUrl: "https://www.transitionbikes.com/",
    reviewedBy: "AetherRide Editorial",
    reviewedAt: "2026-05-14",
  },
  {
    code: "RL-CKP-002",
    title: "Lenker-Klemmdurchmesser vs. Vorbau",
    severity: "safety_critical",
    slotA: "handlebar",
    slotB: "stem",
    requiresA: ["handlebar_clamp_mm"],
    requiresB: ["stem_clamp_mm"],
    predicate: "equals",
    onPass: "COMPATIBLE",
    onFail: "INCOMPATIBLE",
    explainFailDe:
      "Lenkerklemmung {a.handlebar_clamp_mm} mm ≠ Vorbau {b.stem_clamp_mm} mm (üblich 31,8 oder 35,0).",
    howToObtain: {
      handlebar_clamp_mm: "Aufdruck Lenker / Datenblatt",
      stem_clamp_mm: "Aufdruck Vorbau / Datenblatt",
    },
    sourceUrl: "https://www.renthal.com/",
    reviewedBy: "AetherRide Editorial",
    reviewedAt: "2026-05-14",
  },
  {
    code: "RL-SPT-006",
    title: "Sattelstützendurchmesser vs. Sitzrohr",
    severity: "safety_critical",
    slotA: "seatpost",
    slotB: "frame",
    requiresA: ["seatpost_diameter_mm", "min_insertion_mm"],
    requiresB: ["seatpost_diameter_mm", "max_seatpost_insertion_mm"],
    predicate: "seatpost_fit",
    onPass: "COMPATIBLE",
    onFail: "INCOMPATIBLE",
    explainFailDe:
      "Stütze Ø {a.seatpost_diameter_mm} mm / min. Einsteck {a.min_insertion_mm} mm passt nicht zu Rahmen Ø {b.seatpost_diameter_mm} mm / max. {b.max_seatpost_insertion_mm} mm.",
    howToObtain: {
      seatpost_diameter_mm: "27,2 / 30,9 / 31,6 / 34,9 mm – Rahmen & Stütze",
      min_insertion_mm: "Dropper-Handbuch (Mindest-Einstecktiefe)",
      max_seatpost_insertion_mm: "Rahmen-Geometrie",
    },
    sourceUrl: "https://oneupcomponents.com/",
    reviewedBy: "AetherRide Editorial",
    reviewedAt: "2026-05-14",
  },
  {
    code: "RL-BB-003",
    title: "Innenlager-Standard vs. Kurbelwelle",
    severity: "functional",
    slotA: "bottom_bracket",
    slotB: "crankset",
    requiresA: ["crank_axle"],
    requiresB: ["crank_axle"],
    predicate: "equals",
    onPass: "COMPATIBLE",
    onFail: "INCOMPATIBLE",
    explainFailDe:
      "Innenlager-Welle {a.crank_axle} ≠ Kurbel {b.crank_axle}. DUB (28,99 mm), 24 mm Shimano und 30 mm sind eigene Achsstandards (BIKE Magazin).",
    howToObtain: {
      crank_axle: "Kurbel-/IL-Datenblatt (DUB, 24mm, 30mm)",
      bb_standard: "Rahmen: BSA 68/73, T47, PF92, BB30, PF30",
    },
    sourceUrl:
      "https://www.bike-magazin.de/en/workshop/circuit-or-drive/mountain-bike-bottom-bracket-standards-an-overview-of-the-utter-chaos/",
    reviewedBy: "AetherRide Editorial",
    reviewedAt: "2026-05-14",
  },
  {
    code: "RL-BB-003F",
    title: "Innenlager vs. Rahmen-Standard",
    severity: "functional",
    slotA: "bottom_bracket",
    slotB: "frame",
    requiresA: ["bb_standard"],
    requiresB: ["bb_standard"],
    predicate: "equals",
    onPass: "COMPATIBLE",
    onFail: "INCOMPATIBLE",
    explainFailDe:
      "Innenlager {a.bb_standard} passt nicht zum Rahmen {b.bb_standard}.",
    howToObtain: {
      bb_standard: "Rahmen-Spec / IL-Verpackung",
    },
    sourceUrl:
      "https://www.bike-magazin.de/en/workshop/circuit-or-drive/mountain-bike-bottom-bracket-standards-an-overview-of-the-utter-chaos/",
    reviewedBy: "AetherRide Editorial",
    reviewedAt: "2026-05-14",
  },
  {
    code: "RL-EBK-002",
    title: "Motor-Interface nur bei OEM-Freigabe",
    severity: "safety_critical",
    slotA: "motor",
    slotB: "frame",
    requiresA: ["motor_interface"],
    requiresB: ["motor_interface"],
    predicate: "equals",
    onPass: "COMPATIBLE",
    onFail: "INCOMPATIBLE",
    explainFailDe:
      "Motortausch außerhalb der OEM-Freigabe ist unzulässig (EN 15194 / Produkthaftung). Frame {b.motor_interface} ≠ Motor {a.motor_interface}.",
    howToObtain: {
      motor_interface: "Rahmen-OEM und Motorhersteller (z. B. bosch_smart_system)",
    },
    sourceUrl: "https://www.bosch-ebike.com/",
    reviewedBy: "AetherRide Editorial",
    reviewedAt: "2026-05-14",
  },
  {
    code: "RL-FRM-004F",
    title: "Vorderrad-Achse vs. Gabel",
    severity: "safety_critical",
    slotA: "fork",
    slotB: "front_hub",
    requiresA: ["axle_front"],
    requiresB: ["axle_front"],
    predicate: "equals",
    onPass: "COMPATIBLE",
    onFail: "INCOMPATIBLE",
    explainFailDe:
      "Gabel-Achse {a.axle_front} ≠ Nabe {b.axle_front}. Boost 15×110 ist inkompatibel zu 15×100 (BikeRadar).",
    howToObtain: {
      axle_front: "Gabel-/Naben-Spec (15×100, 15×110 Boost, 20×110)",
    },
    sourceUrl: "https://www.bikeradar.com/advice/buyers-guides/mtb-axle-standards",
    reviewedBy: "AetherRide Editorial",
    reviewedAt: "2026-05-14",
  },
  {
    code: "RL-BRK-003F",
    title: "Bremssattel vorne vs. Gabelaufnahme",
    severity: "safety_critical",
    slotA: "brake_front",
    slotB: "fork",
    requiresA: ["brake_mount"],
    requiresB: ["brake_mount"],
    predicate: "equals",
    onPass: "COMPATIBLE",
    onFail: "CONDITIONAL",
    conditionText: "Nur mit passendem Adapter (Post Mount ↔ IS).",
    explainFailDe:
      "Vordere Bremse {a.brake_mount} vs. Gabelaufnahme {b.brake_mount}. Adapter möglich – Fachwerkstatt.",
    howToObtain: {
      brake_mount: "Bremssattel- bzw. Gabel-Datenblatt (Post Mount, IS)",
    },
    sourceUrl: "https://www.sram.com/",
    reviewedBy: "AetherRide Editorial",
    reviewedAt: "2026-08-06",
  },
  {
    code: "RL-DRV-012",
    title: "Kettenblatt-Aufnahme vs. Kurbel",
    severity: "functional",
    slotA: "chainring",
    slotB: "crankset",
    requiresA: ["chainring_bcd"],
    requiresB: ["chainring_bcd"],
    predicate: "equals",
    onPass: "COMPATIBLE",
    onFail: "INCOMPATIBLE",
    explainFailDe:
      "Kettenblatt {a.chainring_bcd} passt nicht zur Kurbel {b.chainring_bcd} (Direct Mount / BCD).",
    howToObtain: {
      chainring_bcd: "Kurbel-/Kettenblatt-Datenblatt (direct_mount, 104bcd, …)",
    },
    sourceUrl: "https://bike.shimano.com/",
    reviewedBy: "AetherRide Editorial",
    reviewedAt: "2026-08-06",
  },
  {
    code: "RL-WHL-010",
    title: "Reifen-Laufradgröße vs. Gabel",
    severity: "safety_critical",
    slotA: "tire_front",
    slotB: "fork",
    requiresA: ["wheel_size"],
    requiresB: ["wheel_size"],
    predicate: "equals",
    onPass: "COMPATIBLE",
    onFail: "INCOMPATIBLE",
    explainFailDe:
      "Vorderreifen {a.wheel_size} passt nicht zur Gabel-Freigabe {b.wheel_size}.",
    howToObtain: {
      wheel_size: "Gabel-Handbuch / Reifen-ETRTO (29, 27.5, 700c)",
    },
    sourceUrl: "https://www.ridefox.com/",
    reviewedBy: "AetherRide Editorial",
    reviewedAt: "2026-08-06",
  },
  {
    code: "RL-BRK-009",
    title: "Hintere Scheibendurchmesser vs. Rahmen-Maximum",
    severity: "safety_critical",
    slotA: "rotor_rear",
    slotB: "frame",
    requiresA: ["rotor_diameter_mm"],
    requiresB: ["max_rotor_rear_mm"],
    predicate: "rotor_within_max",
    onPass: "COMPATIBLE",
    onFail: "INCOMPATIBLE",
    explainFailDe:
      "Hintere Scheibe {a.rotor_diameter_mm} mm überschreitet Rahmen-Maximum {b.max_rotor_rear_mm} mm.",
    howToObtain: {
      rotor_diameter_mm: "Scheiben-Aufdruck / Katalog",
      max_rotor_rear_mm: "Rahmen-Handbuch",
    },
    sourceUrl: "https://www.sram.com/",
    reviewedBy: "AetherRide Editorial",
    reviewedAt: "2026-08-06",
  },
];
