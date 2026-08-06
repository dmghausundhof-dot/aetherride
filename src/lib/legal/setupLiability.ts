/**
 * A-08 — Haftungs-/Hinweistexte Setup-Empfehlungen (R-07 / Spec 7.4)
 *
 * Fachanwalt-Formulierung ausstehend (A-08 Monat 5).
 * Hier: redaktioneller Entwurf, Gate offen — kein „juristisch geprüft“.
 */

export const A08_LEGAL_REVIEW_PASSED: boolean = false;

export type A08Status = "editorial_draft" | "legal_signed_off";

export interface SetupLiabilityCopy {
  status: A08Status;
  version: string;
  legalReviewedAt: string | null;
  legalReviewer: string | null;
  shortDe: string;
  longDe: string;
  workshopSafetyDe: string;
  templateNoteDe: string;
  acceptancePromptDe: string;
}

export const SETUP_LIABILITY: SetupLiabilityCopy = {
  status: "editorial_draft",
  version: "2026.08-draft",
  legalReviewedAt: null,
  legalReviewer: null,
  shortDe:
    "Setup-Hinweise sind unverbindliche Beobachtungen. Keine Garantie für Sicherheit oder Unfallsfreiheit. Herstellergrenzen und Fachwerkstatt haben Vorrang. Keine Rechtsberatung (A-08 ausstehend).",
  longDe:
    "AetherRide gibt Setup-Hinweise auf Basis von Sensorik, Nutzerfeedback und Herstellerbereichen. Das ersetzt keine Einweisung, keine Wartung und keine individuelle Risikoabschätzung. Empfohlene Werte bleiben innerhalb dokumentierter Herstellergrenzen. Sicherheitsrelevante Eingriffe (Bremsen, Lenkkopf, Federwegsumbau, Steuersatz, Gabelservice) werden nicht empfohlen — dort nur der Hinweis auf eine Fachwerkstatt. Bei niedriger Konfidenz erscheint nur eine Beobachtung ohne Handlungsaufforderung. Die Nutzung erfolgt auf eigene Verantwortung. Produkthaftpflicht und final geprüfte Hinweistexte folgen nach Legal-Review (A-08 / R-07).",
  workshopSafetyDe:
    "Sicherheitsrelevante Eingriffe: bitte Fachwerkstatt — keine App-Empfehlung.",
  templateNoteDe:
    "Setup-Vorlagen sind Ausgangspunkte (F-SET-002), keine individuellen Empfehlungen.",
  acceptancePromptDe:
    "Ich habe den Setup-Hinweis gelesen und verstehe, dass er unverbindlich ist.",
};

const ACCEPT_KEY = "aetherride.a08.acceptedAt";

export function isA08Closed(): boolean {
  return (
    A08_LEGAL_REVIEW_PASSED === true &&
    SETUP_LIABILITY.status === "legal_signed_off" &&
    SETUP_LIABILITY.legalReviewedAt != null
  );
}

export function a08StatusBadge(): string {
  return isA08Closed() ? "A-08 freigegeben" : "A-08 Entwurf · Legal ausstehend";
}

export function getA08AcceptanceAt(): string | null {
  if (typeof window === "undefined") return null;
  try {
    return localStorage.getItem(ACCEPT_KEY);
  } catch {
    return null;
  }
}

export function setA08AcceptedNow(): string {
  const ts = new Date().toISOString();
  if (typeof window !== "undefined") {
    localStorage.setItem(ACCEPT_KEY, ts);
  }
  return ts;
}

export function hasA08Acceptance(): boolean {
  return getA08AcceptanceAt() != null;
}
