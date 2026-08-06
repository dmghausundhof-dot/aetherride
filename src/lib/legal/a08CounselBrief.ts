/**
 * A-08 — Anwalt-Briefing Setup-Haftung (R-07 / Spec 7.4)
 * Kein Fake-Sign-off. Mandat getrennt von G-5/A-06.
 */

import {
  A08_LEGAL_REVIEW_PASSED,
  SETUP_LIABILITY,
  a08StatusBadge,
} from "./setupLiability";

export interface A08SignOffTemplate {
  counselName: string | null;
  counselFirm: string | null;
  opinion: "approve_as_is" | "approve_with_edits" | "reject" | "defer" | null;
  reviewedAt: string | null;
  mayClaimLegallyReviewed: boolean;
  requiredCopyEditsDe: string[];
}

export const A08_MANDATE = {
  title: "Haftungsrechtliche Bewertung Setup-Empfehlungen (DE/EU) — A-08",
  specRefs: ["A-08", "R-07", "Spec 7.4 Harte Grenzen", "F-AI-003", "F-SET-002"],
  outOfScope: [
    "Wegerecht (G-5 / A-07)",
    "ODbL/OSM-Ableitungen (A-06)",
    "App-Store-AGB / Impressum gesamt",
  ],
  deliverables: [
    "Freigabe oder Korrektur der UI-Hinweistexte (short/long/workshop/template)",
    "Ob Onboarding-Acceptance rechtlich ausreichend ist",
    "Ob „unverbindliche Beobachtung“ / observationOnly-Formulierung haltbar ist",
    "Ob die App „juristisch geprüfte Hinweistexte“ behaupten darf",
    "Empfehlung zu Produkthaftpflicht-Dokumentation",
  ],
};

export const A08_COPY_INVENTORY = [
  { id: "shortDe", label: "Kurztext Post-Ride / Banner", text: SETUP_LIABILITY.shortDe },
  { id: "longDe", label: "Langtext Onboarding", text: SETUP_LIABILITY.longDe },
  { id: "workshopSafetyDe", label: "Werkstatt-Safety-Zeile", text: SETUP_LIABILITY.workshopSafetyDe },
  { id: "templateNoteDe", label: "F-SET-002 Vorlagen-Hinweis", text: SETUP_LIABILITY.templateNoteDe },
  { id: "acceptancePromptDe", label: "Onboarding-Checkbox", text: SETUP_LIABILITY.acceptancePromptDe },
];

export const A08_HARD_LIMITS_FOR_COUNSEL = [
  "Empfohlene Werte immer innerhalb Hersteller-adjusters",
  "Maximal eine Empfehlung pro Ride",
  "Keine Empfehlung ohne ≥2 unabhängige Belege",
  "Keine Empfehlungen zu Bremsen/Lenkkopf/Federwegsumbau/Steuersatz/Gabelservice — nur Fachwerkstatt",
  "Konfidenz niedrig → nur Beobachtung ohne Handlungsaufforderung",
  "Bottom-out bis G-2: observationOnly (User-Entscheidung C)",
];

export const A08_SIGNOFF: A08SignOffTemplate = {
  counselName: null,
  counselFirm: null,
  opinion: null,
  reviewedAt: null,
  mayClaimLegallyReviewed: false,
  requiredCopyEditsDe: [],
};

export function renderA08AttorneyBriefMarkdown(): string {
  return [
    "# AetherRide — A-08 Anwalt-Briefing (Setup-Haftung)",
    "",
    "> Redaktioneller Entwurf. Kein Gutachten. Gate offen.",
    `> A08_LEGAL_REVIEW_PASSED = ${String(A08_LEGAL_REVIEW_PASSED)} · ${a08StatusBadge()}`,
    "",
    `## Mandat: ${A08_MANDATE.title}`,
    ...A08_MANDATE.specRefs.map((r) => `- Spec: ${r}`),
    "",
    "### Außerhalb",
    ...A08_MANDATE.outOfScope.map((x) => `- ${x}`),
    "",
    "### Deliverables",
    ...A08_MANDATE.deliverables.map((x) => `- ${x}`),
    "",
    "## Harte Grenzen 7.4 (Produkt — zu prüfen)",
    ...A08_HARD_LIMITS_FOR_COUNSEL.map((x) => `- ${x}`),
    "",
    "## Textinventar",
    ...A08_COPY_INVENTORY.flatMap((c) => [
      `### ${c.id} — ${c.label}`,
      c.text,
      "",
    ]),
    "## Sign-off-Vorlage",
    `- counselName: ${A08_SIGNOFF.counselName ?? "_"}`,
    `- counselFirm: ${A08_SIGNOFF.counselFirm ?? "_"}`,
    `- opinion: ${A08_SIGNOFF.opinion ?? "_"}`,
    `- reviewedAt: ${A08_SIGNOFF.reviewedAt ?? "_"}`,
    `- mayClaimLegallyReviewed: ${String(A08_SIGNOFF.mayClaimLegallyReviewed)}`,
    "",
    "## Closure nach Sign-off",
    "1. Texte in setupLiability.ts aktualisieren.",
    "2. status → legal_signed_off, legalReviewedAt/Reviewer setzen.",
    "3. A08_LEGAL_REVIEW_PASSED = true nur bei mayClaimLegallyReviewed.",
    "4. Tests anpassen.",
  ].join("\n");
}

export function renderA08CoverLetter(): string {
  return [
    "Betreff: AetherRide — Mandatsanfrage A-08 Setup-Haftungshinweise (DE/EU)",
    "",
    "Sehr geehrte Damen und Herren,",
    "",
    "wir bitten um Prüfung und Formulierung der Hinweistexte zu Setup-Empfehlungen",
    "in unserer Bike-App (Produkthaftung / R-07 / Spec 7.4).",
    "",
    "Beilage: Markdown-Briefing mit Textinventar und Sign-off-Vorlage.",
    "Nicht Teil des Mandats: Wegerecht (G-5), ODbL (A-06).",
    "",
    "Mit freundlichen Grüßen",
    "Luka Basic",
    "info@dmgservice.org",
    "",
    "— Versand manuell; kein Auto-Mail.",
  ].join("\n");
}
