/**
 * G-5 — Versand an echte Kanzlei
 *
 * Bereitet Anschreiben + Checkliste vor. Versendet NICHT selbst E-Mails.
 * Status bleibt ready_to_send bis ein Mensch die Kanzlei kontaktiert.
 */

import {
  G5_ATTORNEY_MANDATE,
  G5_RULE_INVENTORY,
  attorneyPackageStatus,
  renderG5AttorneyBriefMarkdown,
} from "./g5AttorneyBrief";
import { G5_LEGAL_REVIEW_PASSED } from "./legalReview";

export type CounselDispatchStatus =
  | "package_ready"
  | "human_must_send"
  | "awaiting_counsel_reply"
  | "signed_off";

/** Vorschlag Firmenprofil — Auswahl durch PM, keine Empfehlung */
export interface CounselFirmCandidate {
  id: string;
  focusDe: string;
  whyRelevantDe: string;
  searchHintDe: string;
}

export const COUNSEL_FIRM_CANDIDATES: CounselFirmCandidate[] = [
  {
    id: "it-media-de",
    focusDe: "IT-/Medienrecht DE (App, Produkt, Haftung)",
    whyRelevantDe: "Bayern-Startmarkt + App-Disclaimer / Produkthaftung Schnittstelle",
    searchHintDe: "Fachanwalt IT-Recht / Medienrecht München oder DE bundesweit",
  },
  {
    id: "forst-freizeit-at",
    focusDe: "Forst-/Freizeit-/Wege­recht Österreich",
    whyRelevantDe: "Tirol MTB-Modell, Forstgesetz, Eigentümerfreigaben",
    searchHintDe: "Kanzlei mit Forstrecht / Naturschutz / Tourismusrecht AT (Innsbruck/Wien)",
  },
  {
    id: "dual-mandate",
    focusDe: "Kooperationsmandat DE+AT",
    whyRelevantDe: "Ein Lead mit Correspondent in der anderen Jurisdiktion",
    searchHintDe: "DACH-Kanzleinetz oder zwei getrennte Mandate AT-7 / DE-BY",
  },
];

export interface CounselDispatchMeta {
  status: CounselDispatchStatus;
  suggestedSenderName: string;
  suggestedSenderEmail: string;
  subjectDe: string;
  /** ISO wenn Mensch Versand bestätigt (lokal) */
  markedSentAt: string | null;
  attachments: { filename: string; descriptionDe: string }[];
}

const SENT_KEY = "aetherride.g5.counselMarkedSentAt";

export function getCounselMarkedSentAt(): string | null {
  if (typeof window === "undefined") return null;
  try {
    return localStorage.getItem(SENT_KEY);
  } catch {
    return null;
  }
}

export function markCounselPackageSentNow(): string {
  const ts = new Date().toISOString();
  if (typeof window !== "undefined") {
    localStorage.setItem(SENT_KEY, ts);
  }
  return ts;
}

export function clearCounselMarkedSent(): void {
  if (typeof window === "undefined") return;
  localStorage.removeItem(SENT_KEY);
}

export function getCounselDispatchMeta(): CounselDispatchMeta {
  const sent = getCounselMarkedSentAt();
  let status: CounselDispatchStatus = "package_ready";
  if (G5_LEGAL_REVIEW_PASSED) status = "signed_off";
  else if (sent) status = "awaiting_counsel_reply";
  else status = "human_must_send";

  return {
    status,
    suggestedSenderName: "Luka Basic",
    suggestedSenderEmail: "info@dmgservice.org",
    subjectDe:
      "AetherRide — Mandatsanfrage G-5 Wegerecht Tirol (AT) & Bayern (DE)",
    markedSentAt: sent,
    attachments: [
      {
        filename: "aetherride-g5-anwalt-briefing.md",
        descriptionDe: "Vollständiges Briefing inkl. Regeln und Sign-off-Vorlage",
      },
      {
        filename: "aetherride-g5-anschreiben.txt",
        descriptionDe: "E-Mail-Anschreiben (Copy-Paste)",
      },
    ],
  };
}

/** E-Mail-Anschreiben zum Kopieren */
export function renderG5CounselCoverLetter(): string {
  const meta = getCounselDispatchMeta();
  const pkg = attorneyPackageStatus();
  return [
    `Betreff: ${meta.subjectDe}`,
    "",
    "Sehr geehrte Damen und Herren,",
    "",
    "wir entwickeln die Outdoor-/Bike-App AetherRide und benötigen eine",
    "juristische Prüfung der Wegerechts-Regel­ebene für die Startmärkte",
    "Tirol (Österreich) und Bayern (Deutschland) — Spec-Gate G-5 / A-07.",
    "",
    "Mandatsgegenstand (Kurz):",
    `- ${G5_ATTORNEY_MANDATE.title}`,
    `- ${G5_RULE_INVENTORY.length} App-Regeln (Block/Warn/Info) inkl. UI-Texte`,
    "- Schriftliche Stellungnahme + Sign-off je Jurisdiktion",
    "- Aussage, ob die App „juristisch geprüft“ anzeigen darf",
    "",
    "Ausdrücklich NICHT Teil dieses Mandats:",
    ...G5_ATTORNEY_MANDATE.outOfScope.map((x) => `- ${x}`),
    "",
    "Beilage: Markdown-Briefing mit Quellen, Regelinventar und Sign-off-Vorlage.",
    `Aktueller interner Status: ${pkg.summaryDe}`,
    "",
    "Bitte teilen Sie uns mit:",
    "1) Ob Sie das Mandat übernehmen können (AT und/oder DE)",
    "2) Honorarrahmen / Zeitbedarf",
    "3) Benötigte zusätzliche Unterlagen",
    "",
    "Mit freundlichen Grüßen",
    meta.suggestedSenderName,
    meta.suggestedSenderEmail,
    "AetherRide / DMG",
    "",
    "—",
    "Hinweis: Dieses Anschreiben wurde vorbereitet; der Versand erfolgt manuell.",
  ].join("\n");
}

export function renderG5CounselDispatchChecklistMarkdown(): string {
  const meta = getCounselDispatchMeta();
  const lines = [
    "# G-5 — Checkliste Versand an Kanzlei",
    "",
    `Status: **${meta.status}** (kein Auto-Versand)`,
    "",
    "## Vor dem Versand",
    "- [ ] Kanzlei ausgewählt (IT/Medien DE und/oder Forst/Freizeit AT)",
    "- [ ] Briefing-Markdown heruntergeladen und Anhang geprüft",
    "- [ ] Anschreiben personalisiert (Anrede, Kanzleiname)",
    "- [ ] Absender-Signatur korrekt",
    "- [ ] Intern: PM + Product Owner kennen Mandatsgrenzen (kein A-06/A-08)",
    "",
    "## Kandidatenprofile (zur Auswahl)",
    ...COUNSEL_FIRM_CANDIDATES.flatMap((c) => [
      `### ${c.id}`,
      `- Fokus: ${c.focusDe}`,
      `- Relevanz: ${c.whyRelevantDe}`,
      `- Suche: ${c.searchHintDe}`,
      "",
    ]),
    "## Nach dem Versand",
    "- [ ] In der App „Als versendet markieren“ tippen (lokaler Zeitstempel)",
    "- [ ] Antwort/Honorarangebot abheften",
    "- [ ] Bei Sign-off: Closure-Prozedur in g5AttorneyBrief.ts befolgen",
    "",
    "## Anschreiben (Vorschau)",
    "```",
    renderG5CounselCoverLetter(),
    "```",
    "",
    "## Briefing angehängt",
    `Dateigröße-Hinweis: Briefing ca. ${renderG5AttorneyBriefMarkdown().length} Zeichen.`,
  ];
  return lines.join("\n");
}

export function counselDispatchStatusLabel(status: CounselDispatchStatus): string {
  switch (status) {
    case "package_ready":
      return "Paket bereit";
    case "human_must_send":
      return "Mensch muss an Kanzlei senden";
    case "awaiting_counsel_reply":
      return "Warte auf Kanzlei-Antwort";
    case "signed_off":
      return "Sign-off vorhanden";
  }
}
