/**
 * G-2 Validierungsstudienplan — Spec §7.5
 * Gate G2_SUSPENSION_GATE_PASSED bleibt false bis alle Kriterien erfüllt
 * oder Feature bewusst ausgeschlossen (Launch-Kriterium #4).
 */

import { G2_SUSPENSION_GATE_PASSED } from "@/lib/sensor/fni";

export type G2CriterionId =
  | "bottom_out"
  | "fni_spearman"
  | "fni_mount"
  | "lean_mae"
  | "impact_kappa"
  | "flow_icc"
  | "rec_fpr";

export interface G2Criterion {
  id: G2CriterionId;
  labelDe: string;
  metricDe: string;
  featureIfFail: string;
  status: "not_started" | "in_progress" | "pass" | "fail";
}

export interface G2StudyDesign {
  minRiders: number;
  minBikes: number;
  bikeRequirementsDe: string[];
  minMountTypes: number;
  minRideHours: number;
  minTerrainClasses: number;
  minWetSharePct: number;
  referenceDe: string;
  syncDe: string;
}

export const G2_STUDY_DESIGN: G2StudyDesign = {
  minRiders: 12,
  minBikes: 6,
  bikeRequirementsDe: [
    "Trail und Enduro",
    "Luft- und Stahlfeder-Dämpfer",
    "27,5″ und 29″",
  ],
  minMountTypes: 3,
  minRideHours: 40,
  minTerrainClasses: 4,
  minWetSharePct: 20,
  referenceDe:
    "Lineare Wegaufnehmer an Gabel und Dämpfer (kommerzielle Fahrwerkstelemetrie)",
  syncDe: "Zeitsynchron zum Smartphone / Sensor-Batch (200 Hz, 1-s-Blöcke)",
};

export const G2_CRITERIA: G2Criterion[] = [
  {
    id: "bottom_out",
    labelDe: "Durchschlagserkennung",
    metricDe: "Recall ≥ 0,80 und Precision ≥ 0,70 gegen Referenz",
    featureIfFail: "Durchschlagsverdacht / SR-SAG-02 Live",
    status: "not_started",
  },
  {
    id: "fni_spearman",
    labelDe: "FNI vs. reale Federwegsnutzung",
    metricDe: "Spearman ρ ≥ 0,75 innerhalb eines Bikes",
    featureIfFail: "FNI Live-Anzeige",
    status: "not_started",
  },
  {
    id: "fni_mount",
    labelDe: "FNI-Stabilität über Halterungen",
    metricDe: "Rangkorrelation zwischen Halterungstypen ρ ≥ 0,70",
    featureIfFail: "FNI bei multiplen Mounts",
    status: "not_started",
  },
  {
    id: "lean_mae",
    labelDe: "Schräglage",
    metricDe: "MAE ≤ 5° im Bereich 10–45°",
    featureIfFail: "Lean-Anzeige",
    status: "not_started",
  },
  {
    id: "impact_kappa",
    labelDe: "Impact-Klassifikation",
    metricDe: "gewichtetes Cohen's κ ≥ 0,6 gegen Referenzenergie",
    featureIfFail: "Impact-Counts / Härte",
    status: "not_started",
  },
  {
    id: "flow_icc",
    labelDe: "Flow-Score Wiederholbarkeit",
    metricDe: "ICC ≥ 0,70 bei gleichem Segment/Setup",
    featureIfFail: "Flow-Score Live / Bracketing-Nutzung",
    status: "not_started",
  },
  {
    id: "rec_fpr",
    labelDe: "Empfehlungs-Falsch-Positiv-Rate",
    metricDe: "≤ 10 % Blindreview durch 2 unabhängige Fahrwerkstechniker",
    featureIfFail: "Setup-Empfehlungen Live-Apply (F-AI-003)",
    status: "not_started",
  },
];

export const G2_PHASES = [
  {
    id: "p0",
    titleDe: "Vorbereitung",
    items: [
      "Telemetrie-Hardware + Sync-Protokoll festlegen",
      "Mount-Typen definieren (Lenker/Stem/…)",
      "Ethik/Einwilligung Fahrer, Datenhaltung",
      "dsp_core Referenzpipeline gegen Telemetrie (Desktop)",
    ],
  },
  {
    id: "p1",
    titleDe: "Feldstudie",
    items: [
      `≥ ${G2_STUDY_DESIGN.minRiders} Fahrer, ≥ ${G2_STUDY_DESIGN.minBikes} Bikes`,
      `≥ ${G2_STUDY_DESIGN.minRideHours} h, ≥ ${G2_STUDY_DESIGN.minTerrainClasses} Terrainklassen, ≥ ${G2_STUDY_DESIGN.minWetSharePct} % nass`,
      "Blindsegment-Wiederholungen für Flow-ICC",
    ],
  },
  {
    id: "p2",
    titleDe: "Auswertung",
    items: [
      "Alle 7 Kriterien berechnen und dokumentieren",
      "Zwei unabhängige Techniker: Empfehlungs-Blindreview",
      "Teilversagen → betroffenes Feature dunkel lassen (Spec 7.5)",
    ],
  },
  {
    id: "p3",
    titleDe: "Gate-Entscheidung",
    items: [
      "Bestehen: G2_SUSPENSION_GATE_PASSED = true + öffentliche Genauigkeitszusammenfassung im Produkt",
      "Oder: Feature ausgeschlossen (Launch #4) — kein „vorläufig live“",
      "A-03: ζ-Zugstufen-Bänder aus Studie aktualisieren",
    ],
  },
] as const;

export function g2StudyStatusSummary(): string {
  if (G2_SUSPENSION_GATE_PASSED) {
    return "G-2 bestanden — Fahrwerks-Features freigegeben.";
  }
  const started = G2_CRITERIA.filter((c) => c.status !== "not_started").length;
  return `Studienplan bereit · Gate offen · Kriterien gestartet: ${started}/${G2_CRITERIA.length}`;
}

export function renderG2StudyPlanMarkdown(): string {
  return [
    "# AetherRide — G-2 Validierungsstudienplan (Spec §7.5)",
    "",
    "> Kein Fake-Pass. FNI/Durchschlag/Setup-Apply bleiben gated.",
    `> G2_SUSPENSION_GATE_PASSED = ${String(G2_SUSPENSION_GATE_PASSED)}`,
    `> ${g2StudyStatusSummary()}`,
    "",
    "## Studiendesign",
    `- Referenz: ${G2_STUDY_DESIGN.referenceDe}`,
    `- Sync: ${G2_STUDY_DESIGN.syncDe}`,
    `- Fahrer ≥ ${G2_STUDY_DESIGN.minRiders}`,
    `- Bikes ≥ ${G2_STUDY_DESIGN.minBikes}: ${G2_STUDY_DESIGN.bikeRequirementsDe.join("; ")}`,
    `- Halterungen ≥ ${G2_STUDY_DESIGN.minMountTypes}`,
    `- Fahrstunden ≥ ${G2_STUDY_DESIGN.minRideHours}`,
    `- Terrainklassen ≥ ${G2_STUDY_DESIGN.minTerrainClasses}, nass ≥ ${G2_STUDY_DESIGN.minWetSharePct} %`,
    "",
    "## Bestehenskriterien (alle MÜSSEN)",
    "| ID | Größe | Kriterium | Bei Fail dunkel | Status |",
    "|---|---|---|---|---|",
    ...G2_CRITERIA.map(
      (c) =>
        `| ${c.id} | ${c.labelDe} | ${c.metricDe} | ${c.featureIfFail} | ${c.status} |`
    ),
    "",
    "## Phasen",
    ...G2_PHASES.flatMap((p) => [
      `### ${p.id} — ${p.titleDe}`,
      ...p.items.map((i) => `- ${i}`),
      "",
    ]),
    "## Code-Anbindung (Ist)",
    "- `src/lib/sensor/fni.ts` — FNI + Bottom-out Engine, Gate-Flag",
    "- `src/lib/sensor/SensorFusion.ts` — Live-Pipeline gated",
    "- `src/lib/ai/setupRecommendation.ts` — observationOnly bis Gate",
    "- Lean / Impact / Flow: bestehende Sensor-Module — Metriken in Studie messen",
    "",
    "## Closure",
    "1. Alle Kriterien pass **oder** betroffene Features dauerhaft aus.",
    "2. Öffentliche Genauigkeitszusammenfassung im Produkt.",
    "3. Erst dann G2_SUSPENSION_GATE_PASSED = true.",
  ].join("\n");
}
