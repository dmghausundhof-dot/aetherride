/**
 * A-06 — Anwalt-Briefing ODbL / OSM-Ableitungen (R-08)
 * Kein Fake-Sign-off. Mandat getrennt von G-5/A-08.
 */

export const A06_LEGAL_REVIEW_PASSED: boolean = false;

export type A06DataClass =
  | "likely_derived_db"
  | "likely_own_data"
  | "borderline"
  | "attribution_only";

export interface A06InventoryItem {
  id: string;
  labelDe: string;
  codePath: string;
  classificationHypothesis: A06DataClass;
  counselQuestionDe: string;
}

export const A06_MANDATE = {
  title: "ODbL-Bewertung AetherRide-Datenbestände (OSM-Ableitungen) — A-06",
  specRefs: [
    "A-06",
    "R-08 ODbL Share-alike",
    "F-NAV-005 Heatmaps (OSM-Snap, k≥5)",
    "Kap. 8.4 Kartenlizenzen / Namensnennung",
  ],
  outOfScope: [
    "Wegerecht G-5",
    "Setup-Haftung A-08",
    "Mapillary-Lizenz im Detail (nur Attribution-Hinweis)",
  ],
  deliverables: [
    "Klassifikation je Datenbestand: abgeleitete DB vs. eigene Daten vs. Grenzfall",
    "Welche Aggregate unterliegen Share-alike?",
    "Architektur-Empfehlung: Trennung OSM-abgeleitet / eigen",
    "Ob aktuelle Attribution auf Kartenansicht ausreicht",
    "Ob Demo-Heatmaps mit osmWayId problematisch sind",
  ],
};

export const A06_INVENTORY: A06InventoryItem[] = [
  {
    id: "heatmap-agg",
    labelDe: "Heatmap-Segmente (Nutzeraggregate auf OSM-Geometrie / Snap)",
    codePath: "src/lib/routing/heatmaps.ts",
    classificationHypothesis: "likely_derived_db",
    counselQuestionDe:
      "Gelten k-anonymisierte Intensity-Aggregate auf OSM-Ways als abgeleitete Datenbank?",
  },
  {
    id: "enriched-access",
    labelDe: "Angereicherte Wegattribute (bicycleAccess, mtbOfficial, width)",
    codePath: "src/lib/routing/accessRights.ts + RouteEdgeDemo",
    classificationHypothesis: "borderline",
    counselQuestionDe:
      "Wann wird OSM-Tag + App-Regel zu einer ableitungspflichtigen DB?",
  },
  {
    id: "demo-routing-cost",
    labelDe: "Demo-Routing-Kostenfunktion (keine Valhalla-DB)",
    codePath: "src/lib/routing/engine.ts",
    classificationHypothesis: "likely_own_data",
    counselQuestionDe: "Eigene Kostenlogik ohne OSM-Extract — Share-alike?",
  },
  {
    id: "map-tiles-attrib",
    labelDe: "Kartenkacheln + ODbL-Namensnennung in MapView",
    codePath: "src/components/MapView.tsx",
    classificationHypothesis: "attribution_only",
    counselQuestionDe: "Reicht sichtbare Attribution auf jeder Kartenansicht?",
  },
  {
    id: "trail-view",
    labelDe: "Trail View / Mapillary-Hinweise",
    codePath: "src/lib/routing/trailView.ts",
    classificationHypothesis: "attribution_only",
    counselQuestionDe: "Abgrenzung ODbL vs. Mapillary CC BY-SA?",
  },
  {
    id: "garage-catalog",
    labelDe: "Bike-/Komponentenkatalog (OEM-Specs)",
    codePath: "src/lib/catalog/*",
    classificationHypothesis: "likely_own_data",
    counselQuestionDe: "Kein OSM-Bezug — Bestätigung?",
  },
];

export const A06_SIGNOFF = {
  counselName: null as string | null,
  counselFirm: null as string | null,
  opinion: null as
    | "approve_architecture"
    | "require_separation"
    | "reject_heatmap"
    | "defer"
    | null,
  reviewedAt: null as string | null,
  mayClaimOdblCleared: false,
};

export function isA06Closed(): boolean {
  return (
    A06_LEGAL_REVIEW_PASSED === true &&
    A06_SIGNOFF.reviewedAt != null &&
    A06_SIGNOFF.mayClaimOdblCleared === true
  );
}

export function a06StatusBadge(): string {
  return isA06Closed()
    ? "A-06 freigegeben"
    : "A-06 Entwurf · Legal ausstehend";
}

export function renderA06AttorneyBriefMarkdown(): string {
  return [
    "# AetherRide — A-06 Anwalt-Briefing (ODbL / OSM)",
    "",
    "> Redaktioneller Entwurf. Kein Gutachten. Gate offen.",
    `> A06_LEGAL_REVIEW_PASSED = ${String(A06_LEGAL_REVIEW_PASSED)} · ${a06StatusBadge()}`,
    "",
    `## Mandat: ${A06_MANDATE.title}`,
    ...A06_MANDATE.specRefs.map((r) => `- ${r}`),
    "",
    "### Außerhalb",
    ...A06_MANDATE.outOfScope.map((x) => `- ${x}`),
    "",
    "### Deliverables",
    ...A06_MANDATE.deliverables.map((x) => `- ${x}`),
    "",
    "## Dateninventar (Hypothesen — zu klassifizieren)",
    ...A06_INVENTORY.flatMap((i) => [
      `### ${i.id} — ${i.labelDe}`,
      `- Code: \`${i.codePath}\``,
      `- Hypothese: \`${i.classificationHypothesis}\``,
      `- Frage: ${i.counselQuestionDe}`,
      "",
    ]),
    "## Sign-off-Vorlage",
    `- counselName: ${A06_SIGNOFF.counselName ?? "_"}`,
    `- opinion: ${A06_SIGNOFF.opinion ?? "_"}`,
    `- mayClaimOdblCleared: ${String(A06_SIGNOFF.mayClaimOdblCleared)}`,
    "",
    "## Closure",
    "1. Architektur-Trennung laut Stellungnahme umsetzen falls require_separation.",
    "2. A06_LEGAL_REVIEW_PASSED = true nur nach mayClaimOdblCleared.",
    "3. Heatmap/Attribution-Texte anpassen.",
  ].join("\n");
}

export function renderA06CoverLetter(): string {
  return [
    "Betreff: AetherRide — Mandatsanfrage A-06 ODbL / OSM-Ableitungen",
    "",
    "Sehr geehrte Damen und Herren,",
    "",
    "wir benötigen eine Bewertung, welche unserer Datenbestände (insb. Heatmap-Aggregate",
    "und angereicherte Wegattribute) als von OpenStreetMap abgeleitete Datenbank im",
    "Sinne der ODbL gelten (Share-alike / R-08).",
    "",
    "Beilage: Markdown-Briefing mit Dateninventar.",
    "Nicht Teil: Wegerecht G-5, Setup-Haftung A-08.",
    "",
    "Mit freundlichen Grüßen",
    "Luka Basic",
    "info@dmgservice.org",
    "",
    "— Versand manuell; kein Auto-Mail.",
  ].join("\n");
}
