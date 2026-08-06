/**
 * F-NAV-001.1 — Wegerecht (versionierte Regel-Ebene je Jurisdiktion)
 *
 * Gate G-5: Rechtsprüfung vor Markteinführung; halbjährlich (A-07).
 * App DARF NICHT aktiv über gesperrte Wege routen.
 *
 * Demo-Regeln für AT/DE — KEINE Rechtsberatung; Legal muss freigeben.
 */

import type { RouteEdgeDemo } from "./profiles";

export type JurisdictionId =
  | "AT-7" // Tirol (Demo)
  | "AT-5" // Salzburg
  | "DE-BY"
  | "DE-BW"
  | "CH-default";

export interface AccessRule {
  id: string;
  jurisdiction: JurisdictionId;
  version: string;
  /** ISO-Datum der juristischen Prüfung */
  legalReviewedAt: string | null;
  nextReviewDue: string;
  description: string;
  /** true = Route blockieren; false = nur warnen */
  hardBlock: boolean;
  match: (edge: RouteEdgeDemo) => boolean;
}

/**
 * Vereinfachte Demo-Regeln. Quelle: öffentlich bekannte Tendenzen
 * (z. B. Tirol: Forstwege/beschränkte MTB-Freigabe) — muss Legal validieren (G-5).
 */
export const ACCESS_RULES: AccessRule[] = [
  {
    id: "AT-7-bicycle-no",
    jurisdiction: "AT-7",
    version: "2026.08-draft",
    legalReviewedAt: null,
    nextReviewDue: "2026-09-01",
    description:
      "Wege mit bicycle=no / explizitem Radfahrverbot — nicht routen (Demo AT-Tirol).",
    hardBlock: true,
    match: (e) => e.bicycleAccess === "no",
  },
  {
    id: "AT-7-dismount",
    jurisdiction: "AT-7",
    version: "2026.08-draft",
    legalReviewedAt: null,
    nextReviewDue: "2026-09-01",
    description: "bicycle=dismount — Route mit Hinweis, Schiebe-Passage.",
    hardBlock: false,
    match: (e) => e.bicycleAccess === "dismount",
  },
  {
    id: "DE-BY-unknown-forest",
    jurisdiction: "DE-BY",
    version: "2026.08-draft",
    legalReviewedAt: null,
    nextReviewDue: "2026-09-01",
    description:
      "Bayern Demo: unklare Befahrbarkeit auf path ohne bicycle-Tag — Warnung, kein Optimismus.",
    hardBlock: false,
    match: (e) =>
      e.highway === "path" &&
      (e.bicycleAccess === "unknown" || e.bicycleAccess == null),
  },
];

export interface AccessEvaluation {
  warnings: string[];
  blocked: boolean;
  blockedEdgeIds: Set<string>;
  jurisdiction: JurisdictionId;
  legalGateOpen: boolean;
  legalNote: string;
}

export function evaluateAccessForEdges(
  edges: RouteEdgeDemo[],
  jurisdiction: JurisdictionId = "AT-7"
): AccessEvaluation {
  const rules = ACCESS_RULES.filter((r) => r.jurisdiction === jurisdiction);
  const warnings: string[] = [];
  const blockedEdgeIds = new Set<string>();
  let blocked = false;

  // Auch bicycle=no global als Hard-Block (Spec: DARF NICHT über gesperrte Wege)
  for (const e of edges) {
    for (const rule of rules) {
      if (!rule.match(e)) continue;
      if (rule.hardBlock) {
        blocked = true;
        blockedEdgeIds.add(e.id);
        warnings.push(`Gesperrt: ${rule.description} [${rule.id}]`);
      } else {
        warnings.push(`Hinweis: ${rule.description} [${rule.id}]`);
      }
    }
    if (e.bicycleAccess === "no" && !blockedEdgeIds.has(e.id)) {
      blocked = true;
      blockedEdgeIds.add(e.id);
      warnings.push(`Gesperrt: bicycle=no auf Kante ${e.id}`);
    }
  }

  const reviewed = rules.every((r) => r.legalReviewedAt != null);
  return {
    warnings,
    blocked,
    blockedEdgeIds,
    jurisdiction,
    legalGateOpen: reviewed,
    legalNote: reviewed
      ? "Wegerechts-Ebene juristisch geprüft (G-5)."
      : "G-5 offen: Demo-Regeln — Markteinführung erst nach Legal-Freigabe (A-07).",
  };
}
