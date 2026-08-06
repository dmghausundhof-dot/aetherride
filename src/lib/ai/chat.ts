/**
 * F-AI-001 Numeric-Guard + F-AI-004 Chat-Tools
 *
 * Regel: LLM trifft keine Entscheidungen und erzeugt keine Zahlen.
 * Es formuliert nur Engine-Ergebnisse. Numeric-Guard verwirft
 * nicht belegte Zahlen (Ziel Verwerfungsrate < 2 %).
 */

import {
  aggregateVerdict,
  checkBikeCompatibility,
  checkCandidateOnBike,
} from "@/lib/compatibility/engine";
import { suggestRoutes } from "@/lib/routing/suggestions";
import { SHOP_PRODUCTS } from "@/lib/shop/catalog";
import { allProductRecommendations } from "@/lib/shop/recommendations";
import { estimateRange } from "@/lib/ebike/range";
import type { Bike, Ride, RiderProfile, Setup } from "@/types";
import type { RangeCalibration } from "@/lib/ebike/range";

export interface WhitelistedNumber {
  value: number;
  unit: string;
  source: string;
}

export interface RecommendationSet {
  facts: string[];
  numbers: WhitelistedNumber[];
  toolName: string;
  rawAnswer: string;
}

export interface GuardResult {
  ok: boolean;
  text: string;
  rejectedNumbers: string[];
  usedFallback: boolean;
}

const NUMBER_RE =
  /(-?\d+(?:[.,]\d+)?)\s*(km|hm|mm|psi|bar|%|kg|W|Wh|min|h|€|eur|klicks?|clk)?/gi;

export function extractNumbers(text: string): { value: number; unit: string }[] {
  const out: { value: number; unit: string }[] = [];
  let m: RegExpExecArray | null;
  const re = new RegExp(NUMBER_RE);
  while ((m = re.exec(text)) !== null) {
    out.push({
      value: Number(m[1].replace(",", ".")),
      unit: (m[2] || "").toLowerCase(),
    });
  }
  return out;
}

export function numericGuard(
  llmText: string,
  set: RecommendationSet
): GuardResult {
  const allowed = new Set(
    set.numbers.map((n) => `${n.value}|${n.unit.toLowerCase()}`)
  );
  // also allow bare values that appear in whitelist
  const allowedValues = new Set(set.numbers.map((n) => n.value));
  const found = extractNumbers(llmText);
  const rejected: string[] = [];

  for (const n of found) {
    const key = `${n.value}|${n.unit}`;
    const ok =
      allowed.has(key) ||
      (n.unit === "" && allowedValues.has(n.value)) ||
      set.numbers.some(
        (w) =>
          Math.abs(w.value - n.value) < 0.01 &&
          (!n.unit || w.unit.toLowerCase() === n.unit)
      );
    if (!ok) rejected.push(`${n.value}${n.unit}`);
  }

  if (rejected.length > 0) {
    return {
      ok: false,
      text: set.rawAnswer,
      rejectedNumbers: rejected,
      usedFallback: true,
    };
  }
  return {
    ok: true,
    text: llmText,
    rejectedNumbers: [],
    usedFallback: false,
  };
}

/** Deterministische „Formulierung“ — Demo ohne echtes LLM */
function formulate(set: RecommendationSet): string {
  return set.rawAnswer;
}

export type ChatToolName =
  | "garage"
  | "compat"
  | "setup_history"
  | "ride_stats"
  | "route_search"
  | "product_search"
  | "range";

export function runChatTool(
  tool: ChatToolName,
  query: string,
  ctx: {
    bike?: Bike;
    bikes: Bike[];
    rides: Ride[];
    profile: RiderProfile;
    calibration?: RangeCalibration | null;
  }
): GuardResult {
  const q = query.toLowerCase();
  let set: RecommendationSet;

  switch (tool) {
    case "garage": {
      const bikes = ctx.bikes;
      set = {
        toolName: tool,
        facts: bikes.map(
          (b) =>
            `${b.name}: ${b.category}, ${b.components.filter((c) => !c.removedAt).length} Teile, ${b.totalOdometerKm.toFixed(0)} km`
        ),
        numbers: bikes.flatMap((b) => [
          { value: b.totalOdometerKm, unit: "km", source: "garage.odometer" },
          {
            value: b.components.filter((c) => !c.removedAt).length,
            unit: "",
            source: "garage.parts",
          },
        ]),
        rawAnswer:
          bikes.length === 0
            ? "Keine Bikes in der Garage — Daten fehlen."
            : `In deiner Garage: ${bikes.map((b) => b.name).join(", ")}. Aktive Komponenten und km stammen aus dem Garage-Store.`,
      };
      break;
    }
    case "compat": {
      if (!ctx.bike) {
        set = {
          toolName: tool,
          facts: [],
          numbers: [],
          rawAnswer: "Kein aktives Bike — Kompatibilität nicht prüfbar.",
        };
        break;
      }
      const results = checkBikeCompatibility(ctx.bike);
      const verdict = results.length
        ? aggregateVerdict(results)
        : "INSUFFICIENT_DATA";
      set = {
        toolName: tool,
        facts: [
          `Gesamturteil ${verdict}`,
          ...results.slice(0, 5).map((r) => `${r.ruleCode}: ${r.explainDe}`),
        ],
        numbers: [{ value: results.length, unit: "", source: "compat.rules" }],
        rawAnswer: `Kompat-Engine (kein ML): Urteil ${verdict} aus ${results.length} Regelprüfungen. ${
          results[0]?.explainDe ?? "Keine Detailregeln ausgelöst."
        }`,
      };
      break;
    }
    case "setup_history": {
      if (!ctx.bike) {
        set = {
          toolName: tool,
          facts: [],
          numbers: [],
          rawAnswer: "Kein Bike — Setup-Historie fehlt.",
        };
        break;
      }
      const setups = [...ctx.bike.setups].sort((a, b) => b.version - a.version);
      set = {
        toolName: tool,
        facts: setups.map(
          (s) => `v${s.version} ${s.label} (${s.conditions})${s.isCurrent ? " AKTUELL" : ""}`
        ),
        numbers: setups.map((s) => ({
          value: s.version,
          unit: "",
          source: "setup.version",
        })),
        rawAnswer:
          setups.length === 0
            ? "Keine Setup-Versionen vorhanden."
            : `Setup-Historie: ${setups
                .slice(0, 5)
                .map((s) => `v${s.version} „${s.label}"`)
                .join("; ")}. Immutable Snapshots (F-SET-001).`,
      };
      break;
    }
    case "ride_stats": {
      const rides = ctx.rides;
      const km = rides.reduce((s, r) => s + r.distanceM / 1000, 0);
      const hm = rides.reduce((s, r) => s + r.elevationGainM, 0);
      set = {
        toolName: tool,
        facts: [`${rides.length} Rides`, `${km.toFixed(1)} km`, `${hm.toFixed(0)} hm`],
        numbers: [
          { value: rides.length, unit: "", source: "rides.count" },
          { value: Math.round(km * 10) / 10, unit: "km", source: "rides.km" },
          { value: Math.round(hm), unit: "hm", source: "rides.hm" },
        ],
        rawAnswer: `Ride-Statistik: ${rides.length} Fahrten, ${km.toFixed(1)} km, ${Math.round(hm)} hm — nur aus gespeicherten Rides.`,
      };
      break;
    }
    case "route_search": {
      if (!ctx.bike) {
        set = {
          toolName: tool,
          facts: [],
          numbers: [],
          rawAnswer: "Routensuche braucht ein aktives Bike.",
        };
        break;
      }
      const routes = suggestRoutes({
        bike: ctx.bike,
        profile: ctx.profile,
        availableMinutes: /lang|marathon|3\s*h/.test(q) ? 180 : 120,
      });
      const top = routes[0];
      set = {
        toolName: tool,
        facts: routes.slice(0, 3).map((r) => `${r.name}: ${r.reasons.join(" · ")}`),
        numbers: top
          ? [
              { value: top.distanceKm, unit: "km", source: "route.distance" },
              { value: top.elevationM, unit: "hm", source: "route.elev" },
              { value: top.durationMin, unit: "min", source: "route.duration" },
              { value: top.matchScore, unit: "%", source: "route.score" },
            ]
          : [],
        rawAnswer: top
          ? `Vorschlag „${top.name}": ${top.distanceKm} km, ${top.elevationM} hm, ${top.durationMin} min (Score ${top.matchScore} %). Gründe: ${top.reasons.join("; ")}.`
          : "Keine Routen für diese Kategorie.",
      };
      break;
    }
    case "product_search": {
      if (!ctx.bike) {
        set = {
          toolName: tool,
          facts: [],
          numbers: [],
          rawAnswer: "Produktsuche braucht aktives Bike.",
        };
        break;
      }
      const current = ctx.bike.setups.find((s) => s.isCurrent);
      const recs = allProductRecommendations({
        bike: ctx.bike,
        rides: ctx.rides,
        setup: current,
      });
      const catalogHits = SHOP_PRODUCTS.filter((p) =>
        q.split(/\s+/).some((w) => w.length > 2 && p.name.toLowerCase().includes(w))
      ).slice(0, 3);
      if (recs[0]) {
        const r = recs[0];
        set = {
          toolName: tool,
          facts: [r.triggeringDataPoint, r.reason],
          numbers: [
            { value: r.product.priceEur, unit: "€", source: "product.price" },
          ],
          rawAnswer: `${r.title}. Auslöser: ${r.triggeringDataPoint}. ${r.reason} Preis ${r.product.priceEur} € (Affiliate).`,
        };
      } else if (catalogHits[0]) {
        const p = catalogHits[0];
        const verdict = aggregateVerdict(
          checkCandidateOnBike(ctx.bike, p.slot, p.componentModelId)
        );
        set = {
          toolName: tool,
          facts: [`Kompat ${verdict}`, p.description],
          numbers: [{ value: p.priceEur, unit: "€", source: "product.price" }],
          rawAnswer: `${p.name}: ${p.priceEur} €, Kompat-Urteil ${verdict} (Engine).`,
        };
      } else {
        set = {
          toolName: tool,
          facts: [],
          numbers: [],
          rawAnswer:
            "Keine Produktempfehlung ohne Datenanlass (F-SHP-002) und kein Katalogtreffer.",
        };
      }
      break;
    }
    case "range": {
      if (!ctx.bike?.isEbike) {
        set = {
          toolName: tool,
          facts: [],
          numbers: [],
          rawAnswer: "Reichweite nur für E-Bikes.",
        };
        break;
      }
      const est = estimateRange({
        bike: ctx.bike,
        profile: ctx.profile,
        calibration: ctx.calibration ?? undefined,
      });
      set = {
        toolName: tool,
        facts: est.factors,
        numbers: [
          { value: est.kmLow, unit: "km", source: "range.low" },
          { value: est.kmHigh, unit: "km", source: "range.high" },
          { value: est.whPerKmLow, unit: "Wh", source: "range.whlow" },
          { value: est.whPerKmHigh, unit: "Wh", source: "range.whhigh" },
        ],
        rawAnswer: `Reichweite ${est.kmLow}–${est.kmHigh} km (${est.whPerKmLow}–${est.whPerKmHigh} Wh/km), Konfidenz ${est.confidence}.`,
      };
      break;
    }
    default:
      set = {
        toolName: "garage",
        facts: [],
        numbers: [],
        rawAnswer: "Unbekanntes Werkzeug — Daten fehlen.",
      };
  }

  // Simulate LLM that sometimes invents a number — Guard catches it
  let drafted = formulate(set);
  if (/erfinde|halluzin/i.test(query)) {
    drafted += " Zusätzlich empfehle ich 999 km Reichweite.";
  }

  return numericGuard(drafted, set);
}

export function detectTool(query: string): ChatToolName {
  const q = query.toLowerCase();
  if (/kompat|passt|incompat/.test(q)) return "compat";
  if (/setup|sag|zugstufe|dämpfer|gabel/.test(q)) return "setup_history";
  if (/route|trail|tour|entdeck/.test(q)) return "route_search";
  if (/produkt|shop|kauf|belag|kette|reifen/.test(q)) return "product_search";
  if (/reichweite|akku|wh\/km|range/.test(q)) return "range";
  if (/ride|fahrt|statistik|km|hm/.test(q)) return "ride_stats";
  return "garage";
}
