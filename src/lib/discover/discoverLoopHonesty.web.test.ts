/**
 * Concrete Test-Agent fails for D-60-LOOP-FILTER-01 (Web).
 * Run: npx tsx src/lib/discover/discoverLoopHonesty.web.test.ts
 */
import {
  filterHonestLoopSuggestions,
  isHonestLoopSuggestion,
  isOutAndBackQuickOption,
  sanitizeDraftForRundkurs,
} from "./loopHonesty";
import { curatedSixtyMinLoopSuggestions } from "./curatedP0Seeds";
import { computeQuickOptions } from "@/lib/routing/planDraft";

function assert(cond: boolean, msg: string) {
  if (!cond) throw new Error(msg);
}

const berlin: [number, number] = [13.405, 52.52];

// --- Fail 1: Route=Rundkurs must not surface „60 min · Norden“ ---
assert(
  isOutAndBackQuickOption({
    id: "quick-n",
    label: "60 min · Norden",
    reason: "Out-and-back Richtung Norden",
  }),
  "detect Norden out-and-back"
);

const cleared = sanitizeDraftForRundkurs({
  mode: "quick" as const,
  label: "60 min · Norden",
  computed: {
    geometry: {
      type: "LineString",
      coordinates: [
        [13.4, 52.52],
        [13.41, 52.53],
        [13.42, 52.54],
        [13.43, 52.55],
      ],
    },
    engine: "graphhopper",
  },
});
assert(cleared.computed == null, "map draft clears Norden A→B under Rundkurs");
assert(cleared.label === "", "Norden label cleared");

void (async () => {
  const blocked = await computeQuickOptions(berlin, "urban", 60, {
    allowOutAndBack: false,
    limit: 1,
  });
  assert(blocked.options.length === 0, "computeQuickOptions loopsOnly → empty");
  assert(
    !blocked.options.some((q) => /norden/i.test(q.label)),
    "no Norden in blocked quick"
  );

  // --- Fail 2: ~60 MIN RUNDKURSE never lists Spree Alltagsrunde / A→B ---
  const rail = curatedSixtyMinLoopSuggestions(berlin);
  assert(
    !rail.some((r) => r.id === "seed-route-spree-commute"),
    "Spree commute id excluded from curated ~60"
  );
  assert(
    !rail.some((r) => /alltagsrunde/i.test(r.name)),
    "Alltagsrunde title excluded from curated ~60"
  );
  assert(
    rail.every((r) => r.loop === true),
    "every ~60 rail card is loop (no A→B badge)"
  );
  assert(
    !isHonestLoopSuggestion({
      id: "seed-route-spree-commute",
      name: "Spree-Radweg Alltagsrunde",
      loop: true,
    }),
    "Spree Alltagsrunde blocked even if loop flag lied"
  );

  const mixed = filterHonestLoopSuggestions([
    {
      id: "seed-loop-tempelhofer-60",
      name: "Tempelhofer Feld",
      loop: true,
    },
    {
      id: "seed-route-spree-commute",
      name: "Spree-Radweg Alltagsrunde",
      loop: false,
    },
    {
      id: "x",
      name: "Fake Alltagsrunde",
      loop: true,
    },
  ]);
  assert(mixed.length === 1, "rail filter keeps Tempelhofer only");
  assert(mixed[0].id === "seed-loop-tempelhofer-60", "Tempelhofer kept");

  console.log("discoverLoopHonesty.web.test.ts OK");
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
