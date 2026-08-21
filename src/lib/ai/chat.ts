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
import { isShopEnabled } from "@/lib/shop/shopEnabled";
import { estimateRange } from "@/lib/ebike/range";
import { honestClimbM } from "@/lib/ride/rideTelemetry";
import {
  buildCoachWatch,
  formulateCoachWatch,
  type CoachNotice,
} from "@/lib/ai/coachWatch";
import {
  isElectricBike,
  normalizeBike,
  normalizeBikes,
  normalizeRides,
} from "@/lib/ai/normalize";
import type {
  Bike,
  MaintenanceInterval,
  Ride,
  RideFeedback,
  RiderProfile,
} from "@/types";
import type { RangeCalibration } from "@/lib/ebike/range";
import type { ChromeLang } from "@/lib/i18n/chromeLang";
import { chatCopy } from "@/lib/i18n/chatCopy";
import { fetchOpenMeteoWeather } from "@/lib/weather/openMeteoWeather";
import {
  formatRideWindowLabel,
  profileAllowsRideWindow,
  rideWindowNumbers,
} from "@/lib/weather/rideWindow";

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

/** Deterministische Formulierung — Fallback ohne LLM */
export function formulateDeterministic(set: RecommendationSet): string {
  return set.rawAnswer;
}

export type ChatToolName =
  | "garage"
  | "compat"
  | "setup_history"
  | "ride_stats"
  | "route_search"
  | "product_search"
  | "range"
  | "watch"
  | "ride_window";

export type ChatContext = {
  bike?: Bike;
  bikes: Bike[];
  rides: Ride[];
  profile: RiderProfile;
  calibration?: RangeCalibration | null;
  intervals?: MaintenanceInterval[];
  rideFeedbacks?: RideFeedback[];
  /** Clientseitig berechnete Hinweise (App) — sonst baut der Server sie. */
  notices?: CoachNotice[];
  lang?: ChromeLang;
  /** Required for ride_window — no invented GPS. */
  lat?: number | null;
  lon?: number | null;
  /** Routing / soil profile id (gravel, mtb_enduro, …). */
  routingProfile?: string | null;
};

/** Engine-Ergebnisse ohne LLM — für Numeric-Guard Whitelist */
export function buildChatRecommendation(
  tool: ChatToolName,
  query: string,
  ctx: ChatContext
): RecommendationSet {
  try {
    return buildChatRecommendationInner(tool, query, ctx);
  } catch {
    return {
      toolName: tool,
      facts: [],
      numbers: [],
      rawAnswer: chatCopy(ctx.lang ?? "de").incompleteData,
    };
  }
}

function buildChatRecommendationInner(
  tool: ChatToolName,
  query: string,
  ctx: ChatContext
): RecommendationSet {
  const q = query.toLowerCase();
  const bikes = normalizeBikes(ctx.bikes);
  const rides = normalizeRides(ctx.rides);
  const bike = normalizeBike(ctx.bike) ?? bikes.find((b) => b.isActive) ?? bikes[0];
  let set: RecommendationSet;

  switch (tool) {
    case "watch": {
      const notices =
        Array.isArray(ctx.notices) && ctx.notices.length > 0
          ? ctx.notices
          : buildCoachWatch({
              bikes,
              rides,
              intervals: ctx.intervals,
              profile: ctx.profile,
              calibration: ctx.calibration,
              rideFeedbacks: ctx.rideFeedbacks,
            });
      set = {
        toolName: tool,
        facts: notices.map((n) => `${n.severity}: ${n.title}`),
        numbers: notices.flatMap((n) => n.numbers),
        rawAnswer: formulateCoachWatch(notices, ctx.lang ?? "de"),
      };
      break;
    }
    case "garage": {
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
            ? chatCopy(ctx.lang ?? "de").noBikeStand
            : chatCopy(ctx.lang ?? "de").garageStand(
                bikes.map((b) => b.name).join(", ")
              ),
      };
      break;
    }
    case "compat": {
      if (!bike) {
        set = {
          toolName: tool,
          facts: [],
          numbers: [],
          rawAnswer: chatCopy(ctx.lang ?? "de").noBikeCompat,
        };
        break;
      }
      const results = checkBikeCompatibility(bike);
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
      if (!bike) {
        set = {
          toolName: tool,
          facts: [],
          numbers: [],
          rawAnswer: chatCopy(ctx.lang ?? "de").noBikeSetup,
        };
        break;
      }
      const setups = [...(bike.setups ?? [])].sort((a, b) => b.version - a.version);
      set = {
        toolName: tool,
        facts: setups.map(
          (s) =>
            `v${s.version} ${s.label} (${s.conditions})${s.isCurrent ? " AKTUELL" : ""}`
        ),
        numbers: setups.map((s) => ({
          value: s.version,
          unit: "",
          source: "setup.version",
        })),
        rawAnswer:
          setups.length === 0
            ? chatCopy(ctx.lang ?? "de").noSetups
            : `Setup-Historie: ${setups
                .slice(0, 5)
                .map((s) => `v${s.version} „${s.label}"`)
                .join("; ")}. Immutable Snapshots (F-SET-001).`,
      };
      break;
    }
    case "ride_stats": {
      const km = rides.reduce((s, r) => s + r.distanceM / 1000, 0);
      const hm = rides.reduce(
        (s, r) => s + honestClimbM(r.track, r.elevationGainM),
        0
      );
      set = {
        toolName: tool,
        facts: [
          `${rides.length} Rides`,
          `${km.toFixed(1)} km`,
          `${hm.toFixed(0)} hm`,
        ],
        numbers: [
          { value: rides.length, unit: "", source: "rides.count" },
          { value: Math.round(km * 10) / 10, unit: "km", source: "rides.km" },
          { value: Math.round(hm), unit: "hm", source: "rides.hm" },
        ],
        rawAnswer: chatCopy(ctx.lang ?? "de").rideStats(
          String(rides.length),
          km.toFixed(1),
          String(Math.round(hm))
        ),
      };
      break;
    }
    case "route_search": {
      if (!bike) {
        set = {
          toolName: tool,
          facts: [],
          numbers: [],
          rawAnswer: chatCopy(ctx.lang ?? "de").noBikeRoute,
        };
        break;
      }
      const routes = suggestRoutes({
        bike,
        profile: ctx.profile,
        availableMinutes: /lang|long|marathon|3\s*h|3h/.test(q) ? 180 : 120,
      });
      const top = routes[0];
      set = {
        toolName: tool,
        facts: routes
          .slice(0, 3)
          .map((r) => `${r.name}: ${r.reasons.join(" · ")}`),
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
          : chatCopy(ctx.lang ?? "de").noRoutes,
      };
      break;
    }
    case "product_search": {
      if (!isShopEnabled()) {
        set = {
          toolName: tool,
          facts: ["Laden pausiert"],
          numbers: [],
          rawAnswer: chatCopy(ctx.lang ?? "de").shopPaused,
        };
        break;
      }
      if (!bike) {
        set = {
          toolName: tool,
          facts: [],
          numbers: [],
          rawAnswer: chatCopy(ctx.lang ?? "de").noBikeShop,
        };
        break;
      }
      const current = (bike.setups ?? []).find((s) => s.isCurrent);
      const recs = allProductRecommendations({
        bike,
        rides,
        setup: current,
      });
      const catalogHits = SHOP_PRODUCTS.filter((p) =>
        q
          .split(/\s+/)
          .some((w) => w.length > 2 && p.name.toLowerCase().includes(w))
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
          checkCandidateOnBike(bike, p.slot, p.componentModelId)
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
      if (!bike || !isElectricBike(bike)) {
        set = {
          toolName: tool,
          facts: [],
          numbers: [],
          rawAnswer: chatCopy(ctx.lang ?? "de").rangeEbikeOnly,
        };
        break;
      }
      const est = estimateRange({
        bike,
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
        rawAnswer: chatCopy(ctx.lang ?? "de").rangeAnswer(
          String(est.kmLow),
          String(est.kmHigh),
          String(est.whPerKmLow),
          String(est.whPerKmHigh),
          est.confidence
        ),
      };
      break;
    }
    case "ride_window": {
      const copy = chatCopy(ctx.lang ?? "de");
      const lat = ctx.lat;
      const lon = ctx.lon;
      if (
        typeof lat !== "number" ||
        typeof lon !== "number" ||
        !Number.isFinite(lat) ||
        !Number.isFinite(lon)
      ) {
        set = {
          toolName: tool,
          facts: [],
          numbers: [],
          rawAnswer: copy.rideWindowNeedGps,
        };
        break;
      }
      if (!profileAllowsRideWindow(routingProfileFromCtx(ctx))) {
        set = {
          toolName: tool,
          facts: [],
          numbers: [],
          rawAnswer: copy.rideWindowSport,
        };
        break;
      }
      set = {
        toolName: tool,
        facts: [],
        numbers: [],
        rawAnswer: copy.incompleteData,
      };
      break;
    }
    default:
      set = {
        toolName: "garage",
        facts: [],
        numbers: [],
        rawAnswer: chatCopy(ctx.lang ?? "de").unknownTool,
      };
  }

  return set;
}

function routingProfileFromCtx(ctx: ChatContext): string | null {
  return ctx.routingProfile ?? ctx.bike?.category ?? null;
}

export async function buildRideWindowRecommendation(
  ctx: ChatContext
): Promise<RecommendationSet> {
  const copy = chatCopy(ctx.lang ?? "de");
  const lat = ctx.lat;
  const lon = ctx.lon;
  if (
    typeof lat !== "number" ||
    typeof lon !== "number" ||
    !Number.isFinite(lat) ||
    !Number.isFinite(lon)
  ) {
    return {
      toolName: "ride_window",
      facts: [],
      numbers: [],
      rawAnswer: copy.rideWindowNeedGps,
    };
  }
  const routingProfile = routingProfileFromCtx(ctx);
  if (!profileAllowsRideWindow(routingProfile)) {
    return {
      toolName: "ride_window",
      facts: [],
      numbers: [],
      rawAnswer: copy.rideWindowSport,
    };
  }
  try {
    const weather = await fetchOpenMeteoWeather({
      lat,
      lon,
      profile: routingProfile,
      lang: ctx.lang ?? "de",
    });
    const win = weather.rideWindow;
    if (!win) {
      return {
        toolName: "ride_window",
        facts: [],
        numbers: [],
        rawAnswer: formatRideWindowLabel({ kind: "none" }, ctx.lang ?? "de"),
      };
    }
    const numbers =
      win.kind === "drier" &&
      typeof win.startHour === "number" &&
      typeof win.endHour === "number"
        ? rideWindowNumbers({
            kind: "drier",
            startHour: win.startHour,
            endHour: win.endHour,
            startIso: "",
            endIso: "",
          })
        : [];
    return {
      toolName: "ride_window",
      facts: [win.label],
      numbers,
      rawAnswer: win.label,
    };
  } catch {
    return {
      toolName: "ride_window",
      facts: [],
      numbers: [],
      rawAnswer: formatRideWindowLabel({ kind: "none" }, ctx.lang ?? "de"),
    };
  }
}

export async function resolveChatRecommendation(
  tool: ChatToolName,
  query: string,
  ctx: ChatContext
): Promise<RecommendationSet> {
  if (tool === "ride_window") return buildRideWindowRecommendation(ctx);
  return buildChatRecommendation(tool, query, ctx);
}

export function runChatTool(
  tool: ChatToolName,
  query: string,
  ctx: ChatContext
): GuardResult {
  const set = buildChatRecommendation(tool, query, ctx);
  let drafted = formulateDeterministic(set);
  if (/erfinde|halluzin/i.test(query)) {
    drafted += " Zusätzlich empfehle ich 999 km Reichweite.";
  }
  return numericGuard(drafted, set);
}

export function detectTool(query: string): ChatToolName {
  const q = query.toLowerCase();
  if (
    /steht an|f[äa]llig|überf[äa]llig|hinweis|überwach|was ist los|\bcoach\b|ansteh|what.?s due|what is due|\bdue\?|est dû|scadenza|aan de beurt/.test(
      q
    )
  ) {
    return "watch";
  }
  if (/kompat|\bpasst\b|incompat|compatib/.test(q)) return "compat";
  if (
    /setup|zugstufe|dämpferklick|gabelzug|reifensag|\brebound\b|réglage/.test(q)
  ) {
    return "setup_history";
  }
  if (
    /fenster|trockener|wann\s+(fahr|reiten|los)|when is it drier|plus sec|più asciutto|vandaag droger|ride window/.test(
      q
    )
  ) {
    return "ride_window";
  }
  if (/route|trail|tour|entdeck|itin[eé]rair|itinerar/.test(q)) {
    return "route_search";
  }
  if (
    /produkt|shop|kauf|belag|kette|reifen|wear parts|usure|consumabil|slijtdelen/.test(
      q
    )
  ) {
    return "product_search";
  }
  if (
    /reichweite|akku|wh\/km|\brange\b|autonomie|autonomia|actieradius/.test(q)
  ) {
    return "range";
  }
  if (
    /statistik|fahrten|rides?\b|kilometer|h[oö]henmeter|sorties|uscite|ritten|recent rides|dernières|ultime uscite|laatste ritten/.test(
      q
    )
  ) {
    return "ride_stats";
  }
  return "garage";
}

