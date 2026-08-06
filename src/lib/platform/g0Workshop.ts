/**
 * G-0 Decision-Workshop — Agenda, Pre-Read, Protokollvorlage
 *
 * Dokumentiert den Workshop-Prozess. Schließt G-0 NICHT automatisch.
 * Closure nur durch manuelles Setzen der Felder in g0TeamSetup.ts nach echtem Workshop.
 */

import {
  G0_DECISION,
  G0_NON_GOALS,
  G0_SPRINT0_PLAN,
  NATIVE_MODULE_MATRIX,
  evaluateG0GoNoGo,
  g0StatusShort,
  isG0Closed,
  type BackendLanguageChoice,
  type MobileStackChoice,
} from "./g0TeamSetup";

export interface WorkshopAgendaItem {
  id: string;
  minutes: number;
  titleDe: string;
  goalDe: string;
}

export interface WorkshopParticipantRole {
  role: string;
  required: boolean;
  responsibilityDe: string;
}

export const G0_WORKSHOP_PARTICIPANTS: WorkshopParticipantRole[] = [
  {
    role: "Product Owner / PM",
    required: true,
    responsibilityDe: "Entscheidung dokumentieren, Scope Sprint 1",
  },
  {
    role: "Mobile Lead (iOS und/oder Android)",
    required: true,
    responsibilityDe: "Gegenanzeige §5.1, Sensor/BLE-Verfügbarkeit",
  },
  {
    role: "Backend Lead",
    required: true,
    responsibilityDe: "Kotlin XOR Go festlegen",
  },
  {
    role: "Sensor/BLE-Spezialist:in",
    required: true,
    responsibilityDe: "Spec: nicht verhandelbar — Anwesenheit oder benannter Proxy",
  },
  {
    role: "Design (optional)",
    required: false,
    responsibilityDe: "Flutter vs. Native UI-Risiken",
  },
];

export const G0_WORKSHOP_AGENDA: WorkshopAgendaItem[] = [
  {
    id: "a1",
    minutes: 10,
    titleDe: "Ziel & Non-Goals",
    goalDe: "G-0 = Stack bestätigen oder §5.1 neu bewerten — kein Flutter-Scaffold heute",
  },
  {
    id: "a2",
    minutes: 15,
    titleDe: "Team-Skills & Gegenanzeige",
    goalDe:
      "Je 2 erfahrene iOS+Android ohne Flutter? Dann Gegenanzeige = true → Native bevorzugen",
  },
  {
    id: "a3",
    minutes: 15,
    titleDe: "Sensor/BLE & Modul-Matrix",
    goalDe: "Owner je Native-Modul; Batch-Invariante (kein Sample/Channel)",
  },
  {
    id: "a4",
    minutes: 15,
    titleDe: "Mobile-Stack-Entscheidung",
    goalDe: "flutter | native_swift_kotlin — mit Begründung",
  },
  {
    id: "a5",
    minutes: 10,
    titleDe: "Backend-Sprache",
    goalDe: "Genau eine: kotlin | go",
  },
  {
    id: "a6",
    minutes: 10,
    titleDe: "Sprint-0 & G-1 Parallel",
    goalDe: "Bosch LDI Outreach; dsp_core Spike planen",
  },
  {
    id: "a7",
    minutes: 10,
    titleDe: "Protokoll & Closure-Check",
    goalDe: "Felder für g0TeamSetup ausfüllen; Go/No-Go festhalten",
  },
];

/** Spec §5.1 Entscheidungsfaktoren — Workshop-Scorecard (leer) */
export const G0_SCORECARD_FACTORS = [
  {
    id: "time_to_market",
    labelDe: "Time-to-Market UI",
    flutterHint: "oft schneller bei einem Team",
    nativeHint: "zwei Codebases",
  },
  {
    id: "sensor_ble_risk",
    labelDe: "Sensor/BLE-Risiko",
    flutterHint: "FFI/Channels nötig",
    nativeHint: "direkter Plattformzugriff",
  },
  {
    id: "hiring",
    labelDe: "Hiring / vorhandene Skills",
    flutterHint: "Flutter-Erfahrung vorhanden?",
    nativeHint: "2+2 native ohne Flutter = Gegenanzeige",
  },
  {
    id: "long_term",
    labelDe: "Langfristige Wartung",
    flutterHint: "eine UI-Codebase",
    nativeHint: "plattformnative UX/APIs",
  },
] as const;

export interface G0WorkshopProtocolDraft {
  workshopDate: string | null;
  facilitator: string | null;
  attendees: string[];
  gegenanzeigeApplies: boolean | null;
  sensorBleSpecialistName: string | null;
  chosenStack: MobileStackChoice;
  backendLanguage: BackendLanguageChoice;
  rationale: string | null;
  actionItems: string[];
  /** Nach Workshop manuell true setzen, wenn Protokoll final */
  protocolFinalized: boolean;
}

/** Leer — wird nach Workshop ausgefüllt und in Code übernommen */
export const G0_WORKSHOP_PROTOCOL: G0WorkshopProtocolDraft = {
  workshopDate: null,
  facilitator: null,
  attendees: [],
  gegenanzeigeApplies: null,
  sensorBleSpecialistName: null,
  chosenStack: "undecided",
  backendLanguage: "undecided",
  rationale: null,
  actionItems: [],
  protocolFinalized: false,
};

const WORKSHOP_DONE_KEY = "aetherride.g0.workshopScheduledOrDoneNote";

export function getG0WorkshopLocalNote(): string | null {
  if (typeof window === "undefined") return null;
  try {
    return localStorage.getItem(WORKSHOP_DONE_KEY);
  } catch {
    return null;
  }
}

export function setG0WorkshopLocalNote(note: string) {
  if (typeof window === "undefined") return;
  localStorage.setItem(WORKSHOP_DONE_KEY, note);
}

export function g0WorkshopStatusSummary(): string {
  if (isG0Closed()) return "G-0 geschlossen — Stack bestätigt.";
  if (G0_WORKSHOP_PROTOCOL.protocolFinalized) {
    return "Protokoll finalisiert — Code-Closure in g0TeamSetup.ts noch ausstehend.";
  }
  const go = evaluateG0GoNoGo();
  return `Workshop ausstehend · aktueller Go/No-Go: ${go.result} · ${g0StatusShort()}`;
}

export function renderG0WorkshopPackMarkdown(): string {
  const go = evaluateG0GoNoGo();
  const totalMin = G0_WORKSHOP_AGENDA.reduce((n, a) => n + a.minutes, 0);
  const lines: string[] = [
    "# AetherRide — G-0 Decision-Workshop Pack",
    "",
    "> Gate bleibt offen bis echte Entscheidung in `g0TeamSetup.ts` eingetragen ist.",
    `> Aktuell: ${g0WorkshopStatusSummary()}`,
    "",
    "## Ziel",
    "Vor Sprint 1 Mobile-Stack (Flutter vs. Native) und Backend-Sprache (Kotlin XOR Go) bestätigen — Spec §5.1 / Gate G-0.",
    "",
    "## Teilnehmer",
    ...G0_WORKSHOP_PARTICIPANTS.map(
      (p) =>
        `- ${p.required ? "**Pflicht**" : "Optional"}: ${p.role} — ${p.responsibilityDe}`
    ),
    "",
    `## Agenda (~${totalMin} Min)`,
    ...G0_WORKSHOP_AGENDA.flatMap((a) => [
      `### ${a.id} · ${a.minutes} Min — ${a.titleDe}`,
      a.goalDe,
      "",
    ]),
    "## Pre-Read (vor dem Termin)",
    "- Spec §5.1 Architekturentscheidung Flutter + Gegenanzeige",
    "- `src/lib/platform/g0TeamSetup.ts` Checkliste + Modul-Matrix",
    "- `src/lib/platform/nativeContracts.ts` Channel-Invarianten",
    "",
    "## Native-Modul-Matrix (Ist Web-Demo)",
    "| Modul | Web | Owner-Rolle | Channel/FFI |",
    "|---|---|---|---|",
    ...NATIVE_MODULE_MATRIX.map(
      (r) =>
        `| ${r.specModule} | ${r.webDemo} | ${r.ownerRole} | \`${r.channelOrFfi}\` |`
    ),
    "",
    "## Scorecard (im Workshop ausfüllen)",
    "| Faktor | Flutter-Notiz | Native-Notiz | Team-Score |",
    "|---|---|---|---|",
    ...G0_SCORECARD_FACTORS.map(
      (f) => `| ${f.labelDe} | ${f.flutterHint} | ${f.nativeHint} | _ |`
    ),
    "",
    "## Non-Goals",
    ...G0_NON_GOALS.map((x) => `- ${x}`),
    "",
    "## Sprint-0 danach",
    ...G0_SPRINT0_PLAN.map((x) => `- ${x}`),
    "",
    "## Protokollvorlage",
    "",
    `- Datum: ${G0_WORKSHOP_PROTOCOL.workshopDate ?? "_"}`,
    `- Facilitator: ${G0_WORKSHOP_PROTOCOL.facilitator ?? "_"}`,
    `- Teilnehmende: ${G0_WORKSHOP_PROTOCOL.attendees.join(", ") || "_"}`,
    `- Gegenanzeige trifft zu?: ${String(G0_WORKSHOP_PROTOCOL.gegenanzeigeApplies)}`,
    `- Sensor/BLE-Spezialist:in: ${G0_WORKSHOP_PROTOCOL.sensorBleSpecialistName ?? "_"}`,
    `- chosenStack: \`${G0_WORKSHOP_PROTOCOL.chosenStack}\``,
    `- backendLanguage: \`${G0_WORKSHOP_PROTOCOL.backendLanguage}\``,
    `- rationale: ${G0_WORKSHOP_PROTOCOL.rationale ?? "_"}`,
    `- Action Items:`,
    "  - _",
    "",
    "## Closure in Code (nach Workshop)",
    "1. `G0_DECISION`-Felder setzen (gegenanzeige, sensorBle, stack, backend, decidedAt/By, rationale).",
    "2. Checklisten-Items auf `done: true`.",
    "3. `status: \"stack_confirmed\"` und `G0_MOBILE_STACK_CONFIRMED = true`.",
    "4. Tests in `g0TeamSetup.test.ts` an Closure anpassen.",
    "5. README Gate-Tabelle aktualisieren.",
    "",
    "## Aktueller automatischer Go/No-Go (ohne Workshop-Daten)",
    `- Ergebnis: **${go.result}**`,
    ...go.reasons.map((r) => `- ${r}`),
    "",
    `Checklist offen: ${G0_DECISION.checklist.filter((c) => !c.done).length}/${G0_DECISION.checklist.length}`,
  ];
  return lines.join("\n");
}
