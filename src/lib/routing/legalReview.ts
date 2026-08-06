/**
 * G-5 — Legal-Review Wegerecht (A-07)
 *
 * Spec: Markteinführung nur in juristisch geprüften Ländern;
 * Rechtsstand vor Release und danach halbjährlich prüfen.
 *
 * Diese Datei implementiert die Review-Struktur und das ehrliche Gate.
 * Sie setzt KEINEN Anwalts-Review voraus und behauptet keinen.
 * Closure: Legal setzt `legalReviewedAt` + `G5_LEGAL_REVIEW_PASSED = true`
 * und `status: "legal_signed_off"` (plus synchron `JURISDICTIONS.*.legalReviewedAt`).
 */

import type { JurisdictionId } from "./accessRights";

/** Master-Gate analog G-2 — false bis externe Legal-Freigabe. */
export const G5_LEGAL_REVIEW_PASSED: boolean = false;

export type LegalChecklistStatus =
  | "open"
  | "editorial_done"
  | "legal_signed_off";

export interface LegalSourceCheck {
  id: string;
  label: string;
  url?: string;
  /** Redaktionell gesichtet (nicht = juristisch geprüft) */
  editorialCheckedAt: string | null;
}

export interface JurisdictionLegalReview {
  jurisdictionId: JurisdictionId;
  status: LegalChecklistStatus;
  draftAuthor: string;
  draftVersion: string;
  /** Nur setzen nach echter Legal-Freigabe */
  legalReviewedAt: string | null;
  legalReviewer: string | null;
  nextReviewDue: string;
  sources: LegalSourceCheck[];
  openQuestions: string[];
  /** Launch in dieser Jurisdiktion erlaubt? */
  launchEligible: boolean;
}

const REVIEW_AT = "2026-08-06";

export const LEGAL_REVIEW_BY_JURISDICTION: Record<
  JurisdictionId,
  JurisdictionLegalReview
> = {
  "AT-7": {
    jurisdictionId: "AT-7",
    status: "editorial_done",
    draftAuthor: "AetherRide Editorial",
    draftVersion: "2026.08-draft",
    legalReviewedAt: null,
    legalReviewer: null,
    nextReviewDue: "2026-09-01",
    sources: [
      {
        id: "at-forst-rad",
        label: "BMLUK — Radfahren im Wald",
        url: "https://www.bmluk.gv.at/themen/wald/wald-freizeit/verhalten_wald/radfahrenimwald.html",
        editorialCheckedAt: REVIEW_AT,
      },
      {
        id: "at-gv-wald",
        label: "oesterreich.gv.at — Freizeit im Wald",
        url: "https://www.oesterreich.gv.at/de/themen/reisen_und_freizeit/freizeit-in-der-natur/freizeit_im_wald/Seite.3750060",
        editorialCheckedAt: REVIEW_AT,
      },
      {
        id: "at-tirol-mtb",
        label: "Land Tirol / radrouting.tirol (MTB-Modell)",
        editorialCheckedAt: REVIEW_AT,
      },
    ],
    openQuestions: [
      "Saisonfenster und Vertragspartner je Route — Aktualität 2026?",
      "Verhältnis Forstgesetz zu lokalen MTB-Verträgen — Legal-Formulierung?",
      "Haftungs-Disclaimer-Text für App-Store / Onboarding (A-08)?",
    ],
    launchEligible: false,
  },
  "DE-BY": {
    jurisdictionId: "DE-BY",
    status: "editorial_done",
    draftAuthor: "AetherRide Editorial",
    draftVersion: "2026.08-draft",
    legalReviewedAt: null,
    legalReviewer: null,
    nextReviewDue: "2026-09-01",
    sources: [
      {
        id: "by-waldg-13",
        label: "BayWaldG Art. 13",
        url: "https://www.gesetze-bayern.de/Content/Document/BayWaldG-13",
        editorialCheckedAt: REVIEW_AT,
      },
      {
        id: "by-stmelf",
        label: "StMELF Bayern — Erholung im Wald",
        url: "https://www.stmelf.bayern.de/wald/wald_mensch/erholung-und-freizeit-im-wald/index.html",
        editorialCheckedAt: REVIEW_AT,
      },
    ],
    openQuestions: [
      "Operationalisierung „geeigneter Weg“ ohne starre Meter-Grenze — Legal OK?",
      "Querfeldein / Rückegassen — Block-Regel juristisch haltbar?",
      "Abgleich BayNatSchG Betretungsrecht — Formulierung Kurz/Mehr?",
    ],
    launchEligible: false,
  },
  OTHER_PENDING: {
    jurisdictionId: "OTHER_PENDING",
    status: "open",
    draftAuthor: "AetherRide Editorial",
    draftVersion: "n/a",
    legalReviewedAt: null,
    legalReviewer: null,
    nextReviewDue: "n/a",
    sources: [],
    openQuestions: [
      "Weitere DACH-Jurisdiktionen (AT andere Bundesländer, DE andere Länder, CH) nach G-5 je Markt.",
    ],
    launchEligible: false,
  },
};

/** G-5 geschlossen nur wenn Master-Gate UND Jurisdiktion legal signed-off. */
export function isG5ClosedFor(jurisdictionId: JurisdictionId): boolean {
  const review = LEGAL_REVIEW_BY_JURISDICTION[jurisdictionId];
  return (
    G5_LEGAL_REVIEW_PASSED === true &&
    review.legalReviewedAt != null &&
    review.status === "legal_signed_off"
  );
}

export function g5StatusShort(jurisdictionId: JurisdictionId): string {
  if (isG5ClosedFor(jurisdictionId)) {
    return "Wegerecht juristisch geprüft (G-5).";
  }
  const review = LEGAL_REVIEW_BY_JURISDICTION[jurisdictionId];
  if (review.status === "editorial_done") {
    return "Öffentlicher Hinweisstand · redaktionell gesichtet · Legal-Review (G-5) ausstehend — keine Rechtsberatung.";
  }
  return "Wegerecht: Regelwerk noch nicht freigeschaltet · Gate G-5 offen.";
}

export function g5StatusBadge(jurisdictionId: JurisdictionId): string {
  return isG5ClosedFor(jurisdictionId) ? "Gate G-5 geschlossen" : "Gate G-5 offen";
}

export function listLaunchBlockedJurisdictions(): JurisdictionId[] {
  return (Object.keys(LEGAL_REVIEW_BY_JURISDICTION) as JurisdictionId[]).filter(
    (id) => !isG5ClosedFor(id)
  );
}

export function getLegalReview(
  jurisdictionId: JurisdictionId
): JurisdictionLegalReview {
  return LEGAL_REVIEW_BY_JURISDICTION[jurisdictionId];
}
