/**
 * G-0 Workshop Operations — Einladung, Facilitator-Runbook, Pre-Read
 * Schließt G-0 NICHT. Nur Vorbereitung für echten Termin.
 */

import {
  G0_WORKSHOP_AGENDA,
  G0_WORKSHOP_PARTICIPANTS,
  g0WorkshopStatusSummary,
} from "./g0Workshop";
import { evaluateG0GoNoGo, g0StatusShort } from "./g0TeamSetup";

export const G0_WORKSHOP_META = {
  suggestedDurationMin: G0_WORKSHOP_AGENDA.reduce((n, a) => n + a.minutes, 0),
  suggestedSenderName: "Luka Basic",
  suggestedSenderEmail: "info@dmgservice.org",
  timezoneHint: "Europe/Berlin",
  titleDe: "AetherRide G-0 Decision-Workshop (Mobile-Stack + Backend)",
};

export const G0_PREREAD_CHECKLIST = [
  {
    id: "spec-51",
    ownerRole: "alle Pflichtteilnehmer",
    itemDe: "Spec §5.1 lesen (Flutter-Default + Gegenanzeige 2+2 native)",
  },
  {
    id: "g0-file",
    ownerRole: "Mobile Lead + Backend Lead",
    itemDe: "`g0TeamSetup.ts` Checkliste + Modul-Matrix skimmen",
  },
  {
    id: "channels",
    ownerRole: "Sensor/BLE",
    itemDe: "`nativeContracts.ts` Batch-Invariante (kein Sample/Channel)",
  },
  {
    id: "skills",
    ownerRole: "PO + Mobile Lead",
    itemDe: "Skill-Matrix vorbereiten: Flutter-Jahre vs. native iOS/Android-Köpfe",
  },
  {
    id: "backend",
    ownerRole: "Backend Lead",
    itemDe: "Kotlin XOR Go: Hiring, Ops, Team-Erfahrung skizzieren (1 Seite)",
  },
] as const;

export const G0_FACILITATOR_RUNBOOK = G0_WORKSHOP_AGENDA.map((a) => {
  const talking: Record<string, string[]> = {
    a1: [
      "Ziel laut vorlesen: Stack bestätigen oder §5.1 neu bewerten.",
      "Non-Goals: kein Flutter-Scaffold heute, kein Fake-GO.",
    ],
    a2: [
      "Zählen: erfahrene iOS / Android ohne Flutter?",
      "Wenn je ≥2: Gegenanzeige = true dokumentieren.",
    ],
    a3: [
      "Owner je Modul aus Matrix zuweisen (auch Interim).",
      "Sensor-Batch: 200 Hz, 1-s-Blöcke, kein MethodChannel/Sample.",
    ],
    a4: [
      "Entscheidung laut aussprechen: flutter | native_swift_kotlin.",
      "Bei Widerspruch Gegenanzeige vs. Choice → NO-GO bis Klärung.",
    ],
    a5: [
      "Genau eine Backend-Sprache: kotlin | go.",
      "Mischsprachigkeit explizit ablehnen.",
    ],
    a6: [
      "G-1 Bosch-Outreach parallel starten (nicht warten auf Flutter).",
      "dsp_core Rust-Spike Owner + Zeitraum notieren.",
    ],
    a7: [
      "Protokollfelder live ausfüllen.",
      "Closure-Schritte in g0TeamSetup vorlesen — Code erst NACH Protokoll.",
    ],
  };
  return {
    agendaId: a.id,
    minutes: a.minutes,
    titleDe: a.titleDe,
    talkingPointsDe: talking[a.id] ?? [a.goalDe],
  };
});

export function renderG0WorkshopInviteText(): string {
  const roles = G0_WORKSHOP_PARTICIPANTS.filter((p) => p.required)
    .map((p) => `- ${p.role}`)
    .join("\n");
  return [
    `Betreff: Einladung — ${G0_WORKSHOP_META.titleDe}`,
    "",
    "Hallo,",
    "",
    `bitte blockt ~${G0_WORKSHOP_META.suggestedDurationMin} Minuten für den G-0 Decision-Workshop.`,
    "Ergebnis: Mobile-Stack (Flutter vs. Native) + genau eine Backend-Sprache (Kotlin XOR Go).",
    "",
    "Pflichtrollen:",
    roles,
    "",
    "Pre-Read: siehe Workshop-Pack / Pre-Read-Checkliste.",
    "Zeitzone-Hinweis: " + G0_WORKSHOP_META.timezoneHint,
    "",
    "Mit freundlichen Grüßen",
    G0_WORKSHOP_META.suggestedSenderName,
    G0_WORKSHOP_META.suggestedSenderEmail,
    "",
    "— Termin manuell setzen; kein Auto-Calendar-Push.",
  ].join("\n");
}

/** Minimal-ICS ohne festen Slot — USER setzt DTSTART */
export function renderG0WorkshopIcsStub(opts?: {
  dtStartLocal?: string;
  uid?: string;
}): string {
  const uid = opts?.uid ?? `g0-workshop-${Date.now()}@aetherride`;
  const dt =
    opts?.dtStartLocal ??
    "20260820T100000"; /* Platzhalter — vor Versand anpassen */
  const dtEnd = "20260820T113000";
  return [
    "BEGIN:VCALENDAR",
    "VERSION:2.0",
    "PRODID:-//AetherRide//G0 Workshop//DE",
    "CALSCALE:GREGORIAN",
    "METHOD:PUBLISH",
    "BEGIN:VEVENT",
    `UID:${uid}`,
    `DTSTAMP:${new Date().toISOString().replace(/[-:]/g, "").replace(/\.\d{3}Z$/, "Z")}`,
    `DTSTART;TZID=${G0_WORKSHOP_META.timezoneHint}:${dt}`,
    `DTEND;TZID=${G0_WORKSHOP_META.timezoneHint}:${dtEnd}`,
    `SUMMARY:${G0_WORKSHOP_META.titleDe}`,
    "DESCRIPTION:Mobile-Stack + Backend-Sprache bestätigen. Pre-Read: Workshop-Pack. Gate G-0 bleibt offen bis Code-Closure.",
    "END:VEVENT",
    "END:VCALENDAR",
    "",
  ].join("\r\n");
}

export function renderG0FacilitatorRunbookMarkdown(): string {
  const go = evaluateG0GoNoGo();
  return [
    "# AetherRide — G-0 Facilitator-Runbook",
    "",
    `> ${g0WorkshopStatusSummary()}`,
    `> ${g0StatusShort()}`,
    `> Auto Go/No-Go jetzt: **${go.result}**`,
    "",
    "## Vor dem Termin",
    ...G0_PREREAD_CHECKLIST.map(
      (p) => `- [ ] (${p.ownerRole}) ${p.itemDe}`
    ),
    "",
    "## Ablauf",
    ...G0_FACILITATOR_RUNBOOK.flatMap((r) => [
      `### ${r.agendaId} · ${r.minutes}' — ${r.titleDe}`,
      ...r.talkingPointsDe.map((t) => `- ${t}`),
      "",
    ]),
    "## Nach dem Termin",
    "1. Protokoll in `G0_WORKSHOP_PROTOCOL` / Markdown finalisieren.",
    "2. Erst dann `g0TeamSetup.ts` Closure (kein vorgezogenes Flag).",
    "3. G-1 Outreach parallel anstoßen falls noch nicht geschehen.",
  ].join("\n");
}
