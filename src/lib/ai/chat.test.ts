/**
 * Regression: Numeric-Guard + Produktempfehlungen + Heatmap k.
 * npx tsx src/lib/ai/chat.test.ts
 */
import {
  numericGuard,
  type RecommendationSet,
  buildChatRecommendation,
  detectTool,
} from "./chat";
import { buildHeatmap } from "@/lib/routing/heatmaps";
import { allProductRecommendations } from "@/lib/shop/recommendations";
import { buildEstimatedAssistLog } from "@/lib/ebike/assistLog";
import type { Bike, Ride, RiderProfile } from "@/types";

function assert(c: boolean, m: string) {
  if (!c) throw new Error(m);
}

const set: RecommendationSet = {
  toolName: "range",
  facts: [],
  numbers: [
    { value: 42, unit: "km", source: "range.low" },
    { value: 58, unit: "km", source: "range.high" },
  ],
  rawAnswer: "Reichweite 42–58 km laut Physikmodell.",
};

const ok = numericGuard("Die Prognose liegt bei 42 km bis 58 km.", set);
assert(ok.ok && !ok.usedFallback, "Whitelist-Zahlen erlaubt");

const bad = numericGuard("Ich schätze 999 km Reichweite.", set);
assert(!bad.ok && bad.usedFallback, "Halluzination verworfen");
assert(bad.text.includes("42"), "Fallback = Engine-Text");

const heat = buildHeatmap({ consentHeatmap: true, includeSeedFallback: true });
assert(heat.kThreshold === 5, "k=5");
assert(
  heat.segments.every((s) => s.uniqueUsers >= 5 || !s.visible),
  "unter k unsichtbar"
);
const heatEmpty = buildHeatmap({ consentHeatmap: true });
assert(heatEmpty.segments.length === 0, "ohne Seed kein Community-Demo");
assert(heatEmpty.coldStart, "Kaltstart ohne eigene Rides");

const bike: Bike = {
  id: "b1",
  name: "T",
  category: "mtb_enduro",
  type: "enduro",
  isActive: true,
  isEbike: false,
  createdAt: "2026-01-01T00:00:00.000Z",
  updatedAt: "2026-01-01T00:00:00.000Z",
  totalOdometerKm: 2000,
  totalHours: 80,
  setups: [],
  components: [
    {
      id: "c1",
      bikeId: "b1",
      slot: "chain",
      componentModelId: "x",
      installedAt: "2025-01-01T00:00:00.000Z",
      odometerKmAtInstall: 0,
      hoursAtInstall: 0,
      attributes: [],
      currentSettings: {},
    },
  ],
};
const rides: Ride[] = [
  {
    id: "r1",
    bikeId: "b1",
    sportType: "enduro",
    startTime: "2026-06-01T10:00:00.000Z",
    distanceM: 900000,
    elevationGainM: 20000,
    durationSec: 200000,
    summaryMetrics: {
      gForcePeak: 5,
      gForceRms: 1,
      leanAngleMax: 30,
      impactCount: 200,
      flowScore: 60,
    },
    notes: "nass",
  },
];
const recs = allProductRecommendations({ bike, rides });
assert(recs.length >= 1, "Wear → Produkt");
assert(recs.every((r) => r.triggeringDataPoint.length > 0), "Datenpunkt Pflicht");

const assist = buildEstimatedAssistLog({
  durationSec: 7200,
  distanceM: 28000,
  elevationGainM: 1100,
  preferredMode: "eco",
});
assert(assist.hasEstimates, "Schätzung markiert");
assert(assist.disclaimer.includes("Keine Motorsteuerung"), "F-EBK-000");

const profile: RiderProfile = {
  style: "flow",
  skillLevel: 3,
  preferences: {
    preferSteep: false,
    preferTechnical: true,
    preferFlow: true,
    eBikeAssistPreference: "tour",
  },
  fitnessIndicators: { avgRideDurationMin: 90, weeklyDistanceKm: 40 },
  riderWeightKg: 78,
};

const bikeWithoutSetups = {
  ...bike,
  setups: undefined,
} as unknown as Bike;

const hist = buildChatRecommendation("setup_history", "Setups", {
  bike: bikeWithoutSetups,
  bikes: [bikeWithoutSetups],
  rides,
  profile,
});
assert(
  !/iterable|typeerror/i.test(hist.rawAnswer),
  "setup_history ohne setups kein Dump"
);

const shop = buildChatRecommendation("product_search", "Kette", {
  bike: bikeWithoutSetups,
  bikes: [bikeWithoutSetups],
  rides,
  profile,
});
assert(
  !/iterable|typeerror/i.test(shop.rawAnswer),
  "product_search ohne setups kein Dump"
);

assert(detectTool("What’s due?") === "watch", "en watch");
assert(detectTool("Qu'est-ce qui est dû ?") === "watch", "fr watch");
assert(detectTool("Résumé de mes dernières sorties") === "ride_stats", "fr rides");
assert(detectTool("Riassunto delle mie ultime uscite") === "ride_stats", "it rides");
assert(detectTool("Samenvatting van mijn laatste ritten") === "ride_stats", "nl rides");
assert(detectTool("Quelle autonomie avec la batterie actuelle ?") === "range", "fr range");
assert(detectTool("Wann ist es heute trockener?") === "ride_window", "de window");
assert(detectTool("When is it drier today?") === "ride_window", "en window");

const windowSet: RecommendationSet = {
  toolName: "ride_window",
  facts: ["heute 16–18 Uhr trockener"],
  numbers: [
    { value: 16, unit: "", source: "weather.window.start" },
    { value: 18, unit: "", source: "weather.window.end" },
  ],
  rawAnswer: "heute 16–18 Uhr trockener",
};
const windowOk = numericGuard("heute 16–18 Uhr trockener", windowSet);
assert(windowOk.ok && !windowOk.usedFallback, "window hours allowed");
const windowMm = numericGuard("heute 12 mm nass", windowSet);
assert(!windowMm.ok && windowMm.usedFallback, "invented mm rejected");

const noGpsWindow = buildChatRecommendation("ride_window", "Fenster", {
  bike,
  bikes: [bike],
  rides,
  profile,
});
assert(!/\d/.test(noGpsWindow.rawAnswer) || noGpsWindow.numbers.length === 0, noGpsWindow.rawAnswer);
assert(noGpsWindow.numbers.length === 0, "no GPS → no hours");

const roadGpsWindow = buildChatRecommendation("ride_window", "Fenster", {
  bike: { ...bike, category: "road", type: "road" },
  bikes: [{ ...bike, category: "road", type: "road" }],
  rides,
  profile,
  lat: 49.3,
  lon: 8.6,
  routingProfile: "road",
});
assert(roadGpsWindow.numbers.length === 0, "road → no hours");
assert(/gravel|mtb/i.test(roadGpsWindow.rawAnswer), roadGpsWindow.rawAnswer);

const statsEn = buildChatRecommendation("ride_stats", "rides", {
  bike,
  bikes: [bike],
  rides,
  profile,
  lang: "en",
});
assert(statsEn.rawAnswer.includes("stored rides"), statsEn.rawAnswer);

const noBikeEn = buildChatRecommendation("range", "range", {
  bikes: [bike],
  rides,
  profile,
  lang: "en",
});
assert(noBikeEn.rawAnswer.includes("e-bike") || noBikeEn.rawAnswer.includes("Range"), noBikeEn.rawAnswer);
assert(statsEn.rawAnswer.includes("20.0") || statsEn.rawAnswer.includes("900"), statsEn.rawAnswer);

console.log("chat.test.ts OK", {
  guardReject: bad.rejectedNumbers,
  heatVisible: heat.segments.filter((s) => s.visible).length,
  productRecs: recs.length,
  assistModes: assist.modeSharePct,
});
