/**
 * G-5 Anwalt-Übergabepaket (A-07)
 *
 * Zweck: Fachanwalt:in kann Wegerecht Tirol/Bayern prüfen und Sign-off erteilen.
 * Dieses Modul ist KEIN Rechtsgutachten und kein Sign-off.
 * Gate bleibt geschlossen, bis echte Legal-Freigabe die Closure-Felder setzt.
 */

import { JURISDICTIONS, type JurisdictionId } from "./accessRights";
import {
  G5_LEGAL_REVIEW_PASSED,
  LEGAL_REVIEW_BY_JURISDICTION,
  type JurisdictionLegalReview,
} from "./legalReview";

export type CounselOpinionNeeded =
  | "approve_as_is"
  | "approve_with_edits"
  | "reject_block_launch"
  | "defer";

export interface AccessRuleBriefItem {
  ruleId: string;
  jurisdiction: JurisdictionId | "GLOBAL";
  severity: "block" | "warn" | "info";
  /** Was die App technisch tut */
  productBehavior: string;
  /** Redaktionelle Rechts-Hypothese (zu prüfen) */
  legalHypothesisDe: string;
  counselQuestionDe: string;
}

export interface G5SignOffTemplate {
  jurisdictionId: JurisdictionId;
  /** Leer bis Anwalt ausfüllt */
  counselName: string | null;
  counselFirm: string | null;
  opinion: CounselOpinionNeeded | null;
  reviewedAt: string | null;
  nextReviewDue: string | null;
  conditionsDe: string[];
  requiredCopyEditsDe: string[];
  /** Explizit: darf App „juristisch geprüft“ anzeigen? */
  mayClaimLegallyReviewed: boolean;
}

export interface G5AttorneyMandate {
  title: string;
  specRefs: string[];
  startMarkets: JurisdictionId[];
  outOfScope: string[];
  deliverables: string[];
  reviewCadence: string;
  productConstraints: string[];
}

/** Mandatsgegenstand für Anwaltskanzlei */
export const G5_ATTORNEY_MANDATE: G5AttorneyMandate = {
  title: "Rechtsprüfung Wegerecht — Startmärkte Tirol (AT-7) und Bayern (DE-BY)",
  specRefs: [
    "F-NAV-001.1 (versionierte Regel-Ebene je Jurisdiktion)",
    "Gate G-5 / Launch-Kriterium #8",
    "Annahme A-07 (halbjährliche Nachprüfung)",
    "Risiko R-09 (Wettbewerbsanreize / Wegekonflikte — Hinweispflicht)",
  ],
  startMarkets: ["AT-7", "DE-BY"],
  outOfScope: [
    "Keine anderen AT-Bundesländer, keine anderen DE-Länder, keine CH (A-14)",
    "Keine ODbL/Heatmap-Prüfung (A-06 — separates Mandat)",
    "Keine Setup-Haftungstexte (A-08 / R-07 — separates Mandat)",
    "Keine App-Store-AGB / Impressum der Gesamt-App",
    "Keine Individualberatung für Nutzer:innen",
  ],
  deliverables: [
    "Schriftliche Stellungnahme je Jurisdiktion (approve / edits / reject)",
    "Freigabe oder Ablehnung der UI-Kurz-/Mehr-Texte (prefaceShort/prefaceMore)",
    "Freigabe oder Korrektur jeder Regel im Regelinventar (Block vs. Warn)",
    "Empfohlenes Datum nächste Nachprüfung (≤ 6 Monate, A-07)",
    "Ob die App „juristisch geprüft (G-5)“ anzeigen darf",
  ],
  reviewCadence: "Vor Launch und danach halbjährlich (A-07)",
  productConstraints: [
    "App DARF NICHT aktiv über bicycle=no / explizit gesperrte Wege routen",
    "Grauzonen: Warnung, kein Optimismus, keine Aufforderung zum Regelbruch",
    "Beschilderung und Eigentümerentscheidungen vor Ort haben Vorrang",
    "UI: zurückhaltende Kurzfassung + optionaler Mehr-Modus mit Quellen",
    "Keine Rechtsberatung durch die App",
  ],
};

/** Regelinventar — was Legal prüfen muss */
export const G5_RULE_INVENTORY: AccessRuleBriefItem[] = [
  {
    ruleId: "GLOBAL-bicycle-no",
    jurisdiction: "GLOBAL",
    severity: "block",
    productBehavior:
      "Kante mit bicycleAccess=no wird aus der Route entfernt (Hard Block).",
    legalHypothesisDe:
      "Explizites Radfahrverbot (OSM/Behörde) rechtfertigt Routing-Ausschluss gemäß Spec F-NAV-001.1.",
    counselQuestionDe:
      "Ist Hard-Block bei bicycle=no in AT-7 und DE-BY rechtlich und produkthaftungsseitig angemessen?",
  },
  {
    ruleId: "AT-7-forest-unverified",
    jurisdiction: "AT-7",
    severity: "warn",
    productBehavior:
      "Wald-/Forst-ähnliche Kanten ohne positive Freigabe → Warnung, kein Block.",
    legalHypothesisDe:
      "Nach Forstgesetz AT ist Radfahren im Wald grundsätzlich zustimmungspflichtig; ohne Freigabe-Hinweis keine optimistische Route.",
    counselQuestionDe:
      "Reicht Warnung (statt Block) bei unbestätigtem Waldabschnitt? Welche Formulierung ist haftungssicher?",
  },
  {
    ruleId: "AT-7-dismount",
    jurisdiction: "AT-7",
    severity: "warn",
    productBehavior: "bicycle=dismount → Warnung „Schiebeabschnitt prüfen“.",
    legalHypothesisDe:
      "Schieben kann geboten oder empfohlen sein; App fordert keinen Regelbruch.",
    counselQuestionDe: "Warn-Text und Severity für bicycle=dismount OK?",
  },
  {
    ruleId: "AT-7-official-hint",
    jurisdiction: "AT-7",
    severity: "info",
    productBehavior:
      "mtbOfficial=true → Info „als freigegeben markiert — vor Ort prüfen“.",
    legalHypothesisDe:
      "Kartendaten-Freigabe ist Hinweis, keine Garantie (Saison/Forstarbeiten).",
    counselQuestionDe:
      "Darf die App Freigabe-Hinweise aus Kartendaten so anzeigen? Haftungsrisiko bei veralteten Tags?",
  },
  {
    ruleId: "DE-BY-suitability-uncertain",
    jurisdiction: "DE-BY",
    severity: "warn",
    productBehavior:
      "Schmale path/footway oder widthM<2 ohne bicycle=yes → Warnung zur Eignung; keine starre Meter-Rechtsaussage.",
    legalHypothesisDe:
      "BayWaldG Art. 13 Abs. 3: nur Straßen und geeignete Wege; Eignung ist Einzelfall.",
    counselQuestionDe:
      "Ist die Heuristik (Warnung bei schmalen Pfaden) zulässig, solange keine Meter-Grenze als Rechtsgarantie behauptet wird?",
  },
  {
    ruleId: "DE-BY-offtrail",
    jurisdiction: "DE-BY",
    severity: "block",
    productBehavior: "offTrail=true → Hard Block (nicht geroutet).",
    legalHypothesisDe:
      "Querfeldein ist in Bayern vom Betretungsrecht für Radfahren nicht gedeckt.",
    counselQuestionDe:
      "Hard-Block für Querfeldein haltbar? Abgrenzung Rückegasse / Trampelpfad?",
  },
  {
    ruleId: "DE-BY-dismount",
    jurisdiction: "DE-BY",
    severity: "warn",
    productBehavior: "bicycle=dismount → Warnung inkl. Fußgängervorrang-Hinweis.",
    legalHypothesisDe: "Eignung + Fußgängervorrang zusätzlich relevant.",
    counselQuestionDe: "Formulierung für Bayern OK?",
  },
];

export const G5_SIGNOFF_TEMPLATES: Record<
  "AT-7" | "DE-BY",
  G5SignOffTemplate
> = {
  "AT-7": {
    jurisdictionId: "AT-7",
    counselName: null,
    counselFirm: null,
    opinion: null,
    reviewedAt: null,
    nextReviewDue: null,
    conditionsDe: [],
    requiredCopyEditsDe: [],
    mayClaimLegallyReviewed: false,
  },
  "DE-BY": {
    jurisdictionId: "DE-BY",
    counselName: null,
    counselFirm: null,
    opinion: null,
    reviewedAt: null,
    nextReviewDue: null,
    conditionsDe: [],
    requiredCopyEditsDe: [],
    mayClaimLegallyReviewed: false,
  },
};

/**
 * Closure-Anleitung — nur nach echter Anwalts-Freigabe ausführen.
 * Diese Funktion ändert KEINE Gates; sie dokumentiert den Prozess.
 */
export function g5ClosureProcedureDe(): string[] {
  return [
    "1. Anwalt liefert Stellungnahme + ausgefüllte Sign-off-Felder je AT-7 und DE-BY.",
    "2. PM/Legal übernimmt Textkorrekturen in accessRights.ts (preface + Regeltexte).",
    "3. In legalReview.ts je Jurisdiktion: status → legal_signed_off, legalReviewedAt, legalReviewer setzen.",
    "4. In accessRights.ts JURISDICTIONS.*.legalReviewedAt auf dasselbe Datum setzen.",
    "5. G5_LEGAL_REVIEW_PASSED = true nur wenn BEIDE Startmärkte signed-off und mayClaimLegallyReviewed=true.",
    "6. Tests anpassen: legalReviewedAt != null / Gate geschlossen erwarten.",
    "7. Halbjahres-Reminder (A-07) auf nextReviewDue legen — bei Überschreitung Gate wieder öffnen.",
    "8. NIEMALS Sign-off ohne Anwaltsdokument im Repo/Contract-Ablage behaupten.",
  ];
}

export function attorneyPackageStatus(): {
  readyForCounsel: boolean;
  gatePassed: boolean;
  pendingSignOff: ("AT-7" | "DE-BY")[];
  summaryDe: string;
} {
  const pending = (["AT-7", "DE-BY"] as const).filter(
    (id) => G5_SIGNOFF_TEMPLATES[id].opinion == null
  );
  return {
    readyForCounsel: true,
    gatePassed: G5_LEGAL_REVIEW_PASSED === true,
    pendingSignOff: [...pending],
    summaryDe: G5_LEGAL_REVIEW_PASSED
      ? "G-5 Sign-off vorhanden."
      : "Anwalt-Paket redaktionell bereit · Sign-off ausstehend · Gate offen.",
  };
}

function reviewBlock(id: JurisdictionId): JurisdictionLegalReview {
  return LEGAL_REVIEW_BY_JURISDICTION[id];
}

/** Markdown-Briefing zum Kopieren an die Kanzlei */
export function renderG5AttorneyBriefMarkdown(): string {
  const lines: string[] = [];
  lines.push("# AetherRide — G-5 Anwalt-Briefing (Wegerecht)");
  lines.push("");
  lines.push(
    "> **Status:** Redaktioneller Entwurf zur Prüfung. Kein Gutachten. Kein Sign-off."
  );
  lines.push(`> Gate G5_LEGAL_REVIEW_PASSED = ${String(G5_LEGAL_REVIEW_PASSED)}`);
  lines.push("");
  lines.push("## 1. Mandat");
  lines.push(`**${G5_ATTORNEY_MANDATE.title}**`);
  lines.push("");
  lines.push("### Spec-Referenzen");
  for (const r of G5_ATTORNEY_MANDATE.specRefs) lines.push(`- ${r}`);
  lines.push("");
  lines.push("### Produktzwänge");
  for (const r of G5_ATTORNEY_MANDATE.productConstraints) lines.push(`- ${r}`);
  lines.push("");
  lines.push("### Außerhalb des Mandats");
  for (const r of G5_ATTORNEY_MANDATE.outOfScope) lines.push(`- ${r}`);
  lines.push("");
  lines.push("### Erwartete Deliverables");
  for (const r of G5_ATTORNEY_MANDATE.deliverables) lines.push(`- ${r}`);
  lines.push("");
  lines.push(`**Prüfrhythmus:** ${G5_ATTORNEY_MANDATE.reviewCadence}`);
  lines.push("");

  for (const id of ["AT-7", "DE-BY"] as const) {
    const profile = JURISDICTIONS[id];
    const review = reviewBlock(id);
    lines.push(`## 2. Jurisdiktion ${profile.label} (\`${id}\`)`);
    lines.push("");
    lines.push(`- Regelversion App: \`${profile.version}\``);
    lines.push(`- legalReviewedAt: \`${String(profile.legalReviewedAt)}\``);
    lines.push(`- Nächste Prüfung geplant: ${profile.nextReviewDue}`);
    lines.push(`- Review-Status: ${review.status}`);
    lines.push("");
    lines.push("### UI-Vorspann (Kurz)");
    lines.push(profile.prefaceShort);
    lines.push("");
    lines.push("### UI-Vorspann (Mehr)");
    lines.push(profile.prefaceMore);
    lines.push("");
    lines.push("### Quellen (redaktionell gesichtet)");
    for (const s of review.sources) {
      lines.push(`- ${s.label}${s.url ? ` — ${s.url}` : ""}`);
    }
    lines.push("");
    lines.push("### Offene Fragen an Legal");
    for (const q of review.openQuestions) lines.push(`- ${q}`);
    lines.push("");
  }

  lines.push("## 3. Regelinventar (zu prüfen)");
  lines.push("");
  for (const rule of G5_RULE_INVENTORY) {
    lines.push(`### \`${rule.ruleId}\` (${rule.jurisdiction} · ${rule.severity})`);
    lines.push(`- **Produktverhalten:** ${rule.productBehavior}`);
    lines.push(`- **Hypothese:** ${rule.legalHypothesisDe}`);
    lines.push(`- **Frage an Counsel:** ${rule.counselQuestionDe}`);
    lines.push("");
  }

  lines.push("## 4. Sign-off-Vorlage (auszufüllen durch Anwalt:in)");
  lines.push("");
  for (const id of ["AT-7", "DE-BY"] as const) {
    const t = G5_SIGNOFF_TEMPLATES[id];
    lines.push(`### ${id}`);
    lines.push(`- counselName: ${t.counselName ?? "_"}`);
    lines.push(`- counselFirm: ${t.counselFirm ?? "_"}`);
    lines.push(
      `- opinion: ${t.opinion ?? "_ (approve_as_is | approve_with_edits | reject_block_launch | defer)_"}`
    );
    lines.push(`- reviewedAt (ISO): ${t.reviewedAt ?? "_"}`);
    lines.push(`- nextReviewDue: ${t.nextReviewDue ?? "_"}`);
    lines.push(
      `- mayClaimLegallyReviewed: ${String(t.mayClaimLegallyReviewed)}`
    );
    lines.push(`- conditions / requiredCopyEdits: (frei)`);
    lines.push("");
  }

  lines.push("## 5. Closure in der Codebase (nach Sign-off)");
  for (const s of g5ClosureProcedureDe()) lines.push(s);
  lines.push("");
  lines.push("---");
  lines.push(
    "Kontakt Produkt: AetherRide PM/Legal-Owner · Dokumentversion 2026.08-draft"
  );

  return lines.join("\n");
}
