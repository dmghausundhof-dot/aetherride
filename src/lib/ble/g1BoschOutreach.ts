/**
 * G-1 — Bosch LDI Outreach / Zugangsklärung (Spec §8.1 / B-1…B-3)
 * Gate bleibt offen bis Zugang + Bedingungen dokumentiert sind.
 * Kein Fake „LDI freigeschaltet“.
 */

export const G1_BOSCH_ACCESS_CLEARED: boolean = false;

export type G1OutreachStatus =
  | "not_started"
  | "package_ready"
  | "outreach_sent"
  | "awaiting_bosch"
  | "terms_reviewed"
  | "access_cleared"
  | "blocked_no_ldi";

export interface G1DataPointRow {
  id: string;
  labelDe: string;
  inFreeLdiList: boolean;
  adapterField: string | null;
  notesDe: string;
}

/** Freie LDI-Liste laut Spec 0.4.1 / §8.1 — Inventar für Outreach */
export const G1_LDI_DATA_INVENTORY: G1DataPointRow[] = [
  {
    id: "speed",
    labelDe: "Geschwindigkeit",
    inFreeLdiList: true,
    adapterField: "speedKmh",
    notesDe: "Read-only",
  },
  {
    id: "soc",
    labelDe: "Akku-Ladestand",
    inFreeLdiList: true,
    adapterField: "batterySocPercent",
    notesDe: "Read-only",
  },
  {
    id: "rider_power",
    labelDe: "Fahrerleistung",
    inFreeLdiList: true,
    adapterField: "riderPowerW",
    notesDe: "Read-only",
  },
  {
    id: "cadence",
    labelDe: "Trittfrequenz",
    inFreeLdiList: true,
    adapterField: "cadenceRpm",
    notesDe: "Read-only",
  },
  {
    id: "odometer",
    labelDe: "Gesamtdistanz",
    inFreeLdiList: true,
    adapterField: "odometerKm",
    notesDe: "Read-only",
  },
  {
    id: "light",
    labelDe: "Lichtstatus / Helligkeit",
    inFreeLdiList: true,
    adapterField: "lightStatus",
    notesDe: "inkl. ambientBrightness",
  },
  {
    id: "lock",
    labelDe: "eBike-Lock / Stillstand / Ladegerät",
    inFreeLdiList: true,
    adapterField: "systemLock",
    notesDe: "bikeNotDriving, chargerConnected",
  },
  {
    id: "assist_mode",
    labelDe: "Assist-Modus lesen/schreiben",
    inFreeLdiList: false,
    adapterField: null,
    notesDe: "Nicht in freier Liste → Logging nur Schätzung (F-EBK-005)",
  },
  {
    id: "motor_write",
    labelDe: "Assist/Motor schreiben",
    inFreeLdiList: false,
    adapterField: null,
    notesDe: "Out of scope MVP — Nice-to-Have, nicht versprechen",
  },
];

export const G1_OUTREACH_STEPS = [
  {
    id: "B-1",
    titleDe: "Registrierung / Entwicklerkanal + AGB/Markenrichtlinien",
    status: "pending" as const,
    dueHintDe: "Vor Sprint 1",
  },
  {
    id: "B-2",
    titleDe: "LDI Spec-PDF / UUID-Mapping gegen Demo-Contract prüfen",
    status: "pending" as const,
    dueHintDe: "Nach Zugang",
  },
  {
    id: "B-3",
    titleDe: "Native LDI-Adapter (CoreBluetooth / Android BLE) — nach G-0",
    status: "pending" as const,
    dueHintDe: "Sprint 3–5",
  },
] as const;

export const G1_A01_CHECKLIST = [
  "Aktuelle Bosch LDI Nutzungsbedingungen gelesen und abgelegt",
  "Markenrichtlinien (Logo/„Bosch eBike“-Nennung) geprüft",
  "Klärung: Registrierungspflicht für Dritt-Apps ja/nein",
  "Scope: nur smart system; ältere Generationen → Stufe 0 UI",
  "Keine Marketing-Aussage „Bosch-Partner“ ohne Freigabe",
] as const;

export const G1_SIGNOFF = {
  outreachContact: null as string | null,
  boschTicketOrRef: null as string | null,
  termsReviewedAt: null as string | null,
  reviewedBy: null as string | null,
  mayClaimLdiReady: false,
  notesDe: null as string | null,
};

const SENT_KEY = "aetherride.g1.outreachMarkedSentAt";

export function getG1MarkedSentAt(): string | null {
  if (typeof window === "undefined") return null;
  try {
    return localStorage.getItem(SENT_KEY);
  } catch {
    return null;
  }
}

export function markG1OutreachSentNow(): string {
  const ts = new Date().toISOString();
  if (typeof window !== "undefined") {
    localStorage.setItem(SENT_KEY, ts);
  }
  return ts;
}

export function clearG1OutreachMarkedSent() {
  if (typeof window !== "undefined") {
    localStorage.removeItem(SENT_KEY);
  }
}

export function isG1Closed(): boolean {
  return (
    G1_BOSCH_ACCESS_CLEARED === true &&
    G1_SIGNOFF.mayClaimLdiReady === true &&
    G1_SIGNOFF.termsReviewedAt != null
  );
}

export function g1StatusBadge(): string {
  if (isG1Closed()) return "G-1 freigegeben";
  if (getG1MarkedSentAt()) return "G-1 Outreach markiert versendet · Zugang offen";
  return "G-1 Outreach-Paket bereit · Zugang ausstehend";
}

export function getG1OutreachMeta() {
  const sent = getG1MarkedSentAt();
  let status: G1OutreachStatus = "package_ready";
  if (isG1Closed()) status = "access_cleared";
  else if (sent) status = "outreach_sent";
  return {
    status,
    gatePassed: G1_BOSCH_ACCESS_CLEARED,
    markedSentAt: sent,
    freePoints: G1_LDI_DATA_INVENTORY.filter((d) => d.inFreeLdiList).length,
    blockedPoints: G1_LDI_DATA_INVENTORY.filter((d) => !d.inFreeLdiList).length,
    suggestedSenderName: "Luka Basic",
    suggestedSenderEmail: "info@dmgservice.org",
    publicInfoUrls: [
      "https://www.bosch-ebike.com/us/business/live-data-interface",
      "https://www.bosch-ebike.com/en/company/industry-solutions/cloud-api-ebike-sdk",
    ],
  };
}

export function renderG1BoschCoverLetter(): string {
  return [
    "Betreff: AetherRide — Anfrage Bosch Live Data Interface (Dritt-App, read-only)",
    "",
    "Sehr geehrte Damen und Herren,",
    "",
    "wir entwickeln AetherRide, eine Multi-Bike-App (MTB/E-MTB) und möchten das",
    "dokumentierte Live Data Interface (LDI) für das Bosch smart system read-only nutzen.",
    "",
    "Bitte teilen Sie uns mit:",
    "1. Registrierung / Entwicklerzugang und aktuelle Nutzungsbedingungen",
    "2. Markenrichtlinien für UI-Nennung",
    "3. Ob die öffentliche Datenpunktliste unverändert gilt (kein Assist-Schreiben)",
    "",
    "Beilage: Datenpunkt-Inventar + technische Demo-Contract-Notiz.",
    "Wir steuern keinen Motor und schreiben keine Assist-Modi.",
    "",
    "Mit freundlichen Grüßen",
    "Luka Basic",
    "info@dmgservice.org",
    "",
    "— Versand manuell; kein Auto-Mail.",
  ].join("\n");
}

export function renderG1BoschOutreachMarkdown(): string {
  const meta = getG1OutreachMeta();
  return [
    "# AetherRide — G-1 Bosch LDI Outreach Pack",
    "",
    "> Kein Fake-Zugang. Simulator ≠ Production-BLE.",
    `> G1_BOSCH_ACCESS_CLEARED = ${String(G1_BOSCH_ACCESS_CLEARED)} · ${g1StatusBadge()}`,
    "",
    "## Ziel (Spec §8.1)",
    "Zugang und Bedingungen klären (B-1). Danach Spec-Mapping (B-2), native Adapter nach G-0 (B-3).",
    "Bei Nichterfüllung: E-Bike-Telemetrie entfällt, Stufe 0 bleibt; Marketing anpassen.",
    "",
    "## Absender-Vorschlag",
    `- ${meta.suggestedSenderName} <${meta.suggestedSenderEmail}>`,
    "",
    "## Öffentliche Info-URLs",
    ...meta.publicInfoUrls.map((u) => `- ${u}`),
    "",
    "## Schritte",
    ...G1_OUTREACH_STEPS.map(
      (s) => `- [ ] **${s.id}** ${s.titleDe} (${s.dueHintDe})`
    ),
    "",
    "## A-01 Checkliste",
    ...G1_A01_CHECKLIST.map((x) => `- [ ] ${x}`),
    "",
    "## Datenpunkt-Inventar",
    "| ID | Größe | In freier LDI-Liste | Adapter | Notiz |",
    "|---|---|---|---|---|",
    ...G1_LDI_DATA_INVENTORY.map(
      (d) =>
        `| ${d.id} | ${d.labelDe} | ${d.inFreeLdiList ? "ja" : "nein"} | ${d.adapterField ?? "—"} | ${d.notesDe} |`
    ),
    "",
    "## Code-Ist (Web-Demo)",
    "- `src/lib/ble/BoschLDI.ts` — Web-Simulator + Client-Contract",
    "- `src/lib/ebike/MotorSystemAdapter.ts` — BoschLdiAdapter Stufe 1 read-only",
    "- Assist-Modus: nicht in freier Liste → Schätzung in assistLog",
    "",
    "## Sign-off-Vorlage",
    `- outreachContact: ${G1_SIGNOFF.outreachContact ?? "_"}`,
    `- boschTicketOrRef: ${G1_SIGNOFF.boschTicketOrRef ?? "_"}`,
    `- termsReviewedAt: ${G1_SIGNOFF.termsReviewedAt ?? "_"}`,
    `- reviewedBy: ${G1_SIGNOFF.reviewedBy ?? "_"}`,
    `- mayClaimLdiReady: ${String(G1_SIGNOFF.mayClaimLdiReady)}`,
    "",
    "## Closure",
    "1. Bedingungen + Marke dokumentieren (A-01).",
    "2. UUID/Spec gegen Contract mappen.",
    "3. Erst dann `G1_BOSCH_ACCESS_CLEARED = true` und mayClaimLdiReady.",
    "4. Native BLE erst nach G-0 Stack-Entscheidung.",
  ].join("\n");
}
