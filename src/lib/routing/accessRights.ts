/**
 * F-NAV-001.1 — Wegerecht (versionierte Regel-Ebene)
 *
 * Startmärkte: Tirol (AT-7), Bayern (DE-BY). Weitere Jurisdiktionen später.
 * Gate G-5: Legal-Freigabe vor Launch; halbjährlich (A-07).
 *
 * Verhalten:
 * - bicycle=no / explizites Verbot → HARD BLOCK (Spec: DARF NICHT darüber routen)
 * - Grauzonen → Warnung, kein Optimismus
 * - UI: zurückhaltende Kurzfassung + optionaler „Mehr“-Modus
 *
 * KEINE Rechtsberatung. Öffentliche Quellen, Stand Demo 2026-08.
 */

import type { RouteEdgeDemo } from "./profiles";

export type JurisdictionId = "AT-7" | "DE-BY" | "OTHER_PENDING";

export type AccessSeverity = "block" | "warn" | "info";

export interface AccessFinding {
  ruleId: string;
  edgeId: string;
  severity: AccessSeverity;
  /** Zurückhaltende Kurzfassung (Default-UI) */
  short: string;
  /** Erweiterter „Mehr“-Modus — Quellen, Kontext, keine Handlungsaufforderung zum Regelbruch */
  more: string;
  sources: { label: string; url?: string }[];
}

export interface JurisdictionProfile {
  id: JurisdictionId;
  label: string;
  enabled: boolean;
  version: string;
  legalReviewedAt: string | null;
  nextReviewDue: string;
  /** Kurzer Vorspann, zurückhaltend */
  prefaceShort: string;
  prefaceMore: string;
}

export const JURISDICTIONS: Record<JurisdictionId, JurisdictionProfile> = {
  "AT-7": {
    id: "AT-7",
    label: "Tirol (AT)",
    enabled: true,
    version: "2026.08-draft",
    legalReviewedAt: null,
    nextReviewDue: "2026-09-01",
    prefaceShort:
      "Tirol: Radfahren im Wald nur mit Freigabe. Route prüft Verbotstags und unklare Abschnitte.",
    prefaceMore:
      "Nach Forstgesetz AT ist Radfahren im Wald (inkl. Forststraßen) grundsätzlich nur mit Zustimmung des Waldeigentümers/Forststraßenerhalters erlaubt. In Tirol erfolgt die allgemeine Freigabe typischerweise über das Mountainbike-Modell (privatrechtliche Verträge, oft Saison ca. 1.4.–31.10., beschilderte/offizielle Routen, z. B. radrouting.tirol). Abseits freigegebener Strecken drohen u. a. Verwaltungs- und Zivilfolgen. Diese App ersetzt keine Rechtsberatung; Beschilderung und aktuelle Freigaben vor Ort haben Vorrang. Gate G-5: Legal-Review ausstehend.",
  },
  "DE-BY": {
    id: "DE-BY",
    label: "Bayern (DE)",
    enabled: true,
    version: "2026.08-draft",
    legalReviewedAt: null,
    nextReviewDue: "2026-09-01",
    prefaceShort:
      "Bayern: Radfahren im Wald nur auf Straßen und geeigneten Wegen. Ungeeignete/gesperrte Abschnitte werden gemeldet.",
    prefaceMore:
      "BayWaldG Art. 13 Abs. 3 / BayNatSchG: Radfahren im Wald nur auf Straßen und geeigneten Wegen; Fußgänger haben Vorrang. Querfeldein und Rückegassen sind danach nicht vom Betretungsrecht umfasst. „Geeignet“ hängt vom Einzelfall ab (Breite, Belag, Übersichtlichkeit, Frequenz) — es gibt keine starre App-Wegebreite als Rechtsgarantie. Amtliche Verbote und zulässige Sperren sind zu beachten. Quellen u. a. gesetze-bayern.de, stmelf.bayern.de. Keine Rechtsberatung; Gate G-5 ausstehend.",
  },
  OTHER_PENDING: {
    id: "OTHER_PENDING",
    label: "Weitere Regionen (später)",
    enabled: false,
    version: "n/a",
    legalReviewedAt: null,
    nextReviewDue: "n/a",
    prefaceShort: "Noch nicht freigeschaltet — zuerst Tirol und Bayern.",
    prefaceMore:
      "Weitere DACH-Jurisdiktionen folgen nach Legal-Review (G-5). Bis dahin kein Routing-Anspruch für andere Regionen.",
  },
};

type RuleFn = (edge: RouteEdgeDemo) => Omit<AccessFinding, "edgeId"> | null;

const GLOBAL_BICYCLE_NO: RuleFn = (e) => {
  if (e.bicycleAccess !== "no") return null;
  return {
    ruleId: "GLOBAL-bicycle-no",
    severity: "block",
    short: "Abschnitt mit Radfahrverbot — wird nicht geroutet.",
    more: "OSM-Tag bicycle=no bzw. explizites Verbot. Spec F-NAV-001.1: Die App routet nicht über gesperrte Wege. Vor Ort kann die Lage abweichen; Beschilderung und Eigentümerentscheidungen haben Vorrang.",
    sources: [
      { label: "Spec F-NAV-001.1" },
      { label: "OSM access/bicycle" },
    ],
  };
};

const TIROL_RULES: RuleFn[] = [
  GLOBAL_BICYCLE_NO,
  (e) => {
    if (e.bicycleAccess !== "dismount") return null;
    return {
      ruleId: "AT-7-dismount",
      severity: "warn",
      short: "Schiebeabschnitt markiert — bitte zu Fuß prüfen.",
      more: "Tag bicycle=dismount. Keine Aufforderung, Regeln zu umgehen. Ob Schieben vor Ort geboten oder nur empfohlen ist, ergibt sich aus Beschilderung und Freigabe.",
      sources: [{ label: "OSM bicycle=dismount" }],
    };
  },
  (e) => {
    // Forst-/Waldweg ohne positive Freigabe-Hinweise → Grauzone Tirol
    const forestLike =
      e.highway === "track" ||
      e.highway === "path" ||
      e.surface === "ground" ||
      e.surface === "dirt";
    const noPositive =
      e.bicycleAccess !== "yes" &&
      e.mtbOfficial !== true &&
      e.bicycleAccess !== "dismount";
    if (!forestLike || !noPositive || e.bicycleAccess === "no") return null;
    return {
      ruleId: "AT-7-forest-unverified",
      severity: "warn",
      short: "Wald-/Forstabschnitt ohne bestätigte Freigabe — unsicher.",
      more: "In Tirol/Österreich ist Radfahren im Wald ohne Zustimmung grundsätzlich nicht erlaubt. Ohne OSM-Hinweis auf Freigabe (z. B. bicycle=yes, route=mtb, lokale Freigabe) bewertet die App den Abschnitt nicht optimistisch. Offizielle Tiroler MTB-Routen sind u. a. über das Mountainbike-Modell und Karten wie radrouting.tirol ausgewiesen (typisch Saisonfenster). Bitte Freigabe und Beschilderung selbst prüfen.",
      sources: [
        {
          label: "BMLUK — Radfahren im Wald",
          url: "https://www.bmluk.gv.at/themen/wald/wald-freizeit/verhalten_wald/radfahrenimwald.html",
        },
        {
          label: "oesterreich.gv.at",
          url: "https://www.oesterreich.gv.at/de/themen/reisen_und_freizeit/freizeit-in-der-natur/freizeit_im_wald/Seite.3750060",
        },
        { label: "Land Tirol MTB-Modell (öffentl. Infos)" },
      ],
    };
  },
  (e) => {
    if (e.mtbOfficial === true && e.bicycleAccess !== "no") {
      return {
        ruleId: "AT-7-official-hint",
        severity: "info",
        short: "Als freigegeben markiert (Kartendaten) — vor Ort prüfen.",
        more: "Die Kante trägt einen Freigabe-Hinweis in den Demo-/OSM-Daten. Freigaben können saisonal oder wegen Forstarbeiten entfallen. Keine Garantie; radrouting.tirol / Beschilderung maßgeblich.",
        sources: [{ label: "Tirol MTB-Modell / lokale Freigaben" }],
      };
    }
    return null;
  },
];

const BAYERN_RULES: RuleFn[] = [
  GLOBAL_BICYCLE_NO,
  (e) => {
    if (e.bicycleAccess !== "dismount") return null;
    return {
      ruleId: "DE-BY-dismount",
      severity: "warn",
      short: "Schiebehinweis in den Kartendaten.",
      more: "bicycle=dismount. In Bayern zählt zudem die Eignung des Weges und der Vorrang von Fußgängern. Bitte Situation vor Ort einschätzen.",
      sources: [{ label: "OSM bicycle=dismount" }],
    };
  },
  (e) => {
    // Schmale paths / ungeeignete Wege — Grauzone „geeignet?“
    const narrowPath =
      e.highway === "path" ||
      e.highway === "footway" ||
      (e.widthM != null && e.widthM < 2);
    const noBikeYes = e.bicycleAccess !== "yes";
    if (!narrowPath || e.bicycleAccess === "no") return null;
    if (e.highway === "track" && (e.surface === "gravel" || e.surface === "compacted"))
      return null; // typisch eher geeignet — keine Warnung
    if (!noBikeYes && e.widthM != null && e.widthM >= 2) return null;
    return {
      ruleId: "DE-BY-suitability-uncertain",
      severity: "warn",
      short: "Eignung des Weges für Radverkehr unklar.",
      more: "BayWaldG Art. 13 Abs. 3: Radfahren nur auf Straßen und geeigneten Wegen. Ob ein Weg geeignet ist, ist Einzelfall (Breite, Belag, Übersichtlichkeit, Frequenz) — die App setzt keine starre Meter-Grenze als Rechtsaussage. Schmale Steige/Pfade und Rückegassen gelten in Behördenhinweisen häufig als ungeeignet bzw. nicht umfasst. Fußgänger haben Vorrang. Keine Rechtsberatung.",
      sources: [
        {
          label: "BayWaldG Art. 13",
          url: "https://www.gesetze-bayern.de/Content/Document/BayWaldG-13",
        },
        {
          label: "StMELF Bayern — Erholung im Wald",
          url: "https://www.stmelf.bayern.de/wald/wald_mensch/erholung-und-freizeit-im-wald/index.html",
        },
      ],
    };
  },
  (e) => {
    if (e.offTrail === true) {
      return {
        ruleId: "DE-BY-offtrail",
        severity: "block",
        short: "Querfeldein / abseits von Wegen — nicht geroutet.",
        more: "In Bayern ist Radfahren abseits geeigneter Wege (Querfeldein) nach den genannten Vorschriften nicht vom Betretungsrecht gedeckt. Die Route schließt solche Abschnitte aus.",
        sources: [
          {
            label: "StMELF Bayern",
            url: "https://www.stmelf.bayern.de/wald/wald_mensch/erholung-und-freizeit-im-wald/index.html",
          },
        ],
      };
    }
    return null;
  },
];

function rulesFor(j: JurisdictionId): RuleFn[] {
  if (j === "AT-7") return TIROL_RULES;
  if (j === "DE-BY") return BAYERN_RULES;
  return [GLOBAL_BICYCLE_NO];
}

export interface AccessEvaluation {
  jurisdiction: JurisdictionId;
  profile: JurisdictionProfile;
  findings: AccessFinding[];
  blocked: boolean;
  blockedEdgeIds: Set<string>;
  /** Kurz-Warnungen für Default-UI */
  warningsShort: string[];
  legalGateOpen: boolean;
  legalNoteShort: string;
  legalNoteMore: string;
}

export function evaluateAccessForEdges(
  edges: RouteEdgeDemo[],
  jurisdiction: JurisdictionId = "AT-7"
): AccessEvaluation {
  const profile = JURISDICTIONS[jurisdiction] ?? JURISDICTIONS["AT-7"];
  const findings: AccessFinding[] = [];
  const blockedEdgeIds = new Set<string>();

  for (const e of edges) {
    for (const rule of rulesFor(profile.id)) {
      const hit = rule(e);
      if (!hit) continue;
      findings.push({ ...hit, edgeId: e.id });
      if (hit.severity === "block") blockedEdgeIds.add(e.id);
    }
  }

  // Dedup short messages for UI
  const warningsShort = [
    ...new Set(
      findings
        .filter((f) => f.severity === "block" || f.severity === "warn")
        .map((f) => f.short)
    ),
  ];

  return {
    jurisdiction: profile.id,
    profile,
    findings,
    blocked: blockedEdgeIds.size > 0,
    blockedEdgeIds,
    warningsShort,
    legalGateOpen: profile.legalReviewedAt != null,
    legalNoteShort: profile.legalReviewedAt
      ? "Wegerecht juristisch geprüft (G-5)."
      : "Hinweisstand öffentlich · Legal-Review (G-5) ausstehend — keine Rechtsberatung.",
    legalNoteMore: profile.prefaceMore,
  };
}

/** Für RouteResult.accessWarnings — Kurzfassung */
export function accessWarningsFromEval(ev: AccessEvaluation): string[] {
  return [
    ev.profile.prefaceShort,
    ...ev.warningsShort,
    ev.legalNoteShort,
  ];
}
