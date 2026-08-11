/**
 * Loop honesty — linear excluded, closed included.
 * Run: npx tsx src/lib/discover/loopHonesty.test.ts
 */
import {
  filterHonestLoopSuggestions,
  isHonestLoop,
  isHonestLoopSuggestion,
  isOutAndBackQuickOption,
  sanitizeDraftForRundkurs,
  seedIsLoopFlag,
  trackIsClosedLoop,
} from "./loopHonesty";

function assert(cond: boolean, msg: string) {
  if (!cond) throw new Error(msg);
}

// --- Flag honesty ---
assert(seedIsLoopFlag({ is_loop: true }) === true, "is_loop true");
assert(seedIsLoopFlag({ is_loop: false }) === false, "is_loop false");
assert(seedIsLoopFlag({}) === false, "missing is_loop is not a loop");
assert(seedIsLoopFlag({ loop: true }) === true, "legacy loop true");
assert(seedIsLoopFlag({ closed: true }) === true, "closed true");
assert(isHonestLoopSuggestion({ loop: true }) === true, "suggestion loop");
assert(isHonestLoopSuggestion({ loop: false }) === false, "suggestion linear");
assert(
  isHonestLoopSuggestion({
    id: "seed-route-spree-commute",
    loop: true,
  }) === false,
  "Spree Alltagsrunde never passes even if loop lied"
);
assert(
  isHonestLoopSuggestion({
    id: "other",
    name: "Spree-Radweg Alltagsrunde",
    loop: true,
  }) === false,
  "Alltagsrunde title never passes"
);

// --- Geometry: closed ring ---
const closed: [number, number][] = (() => {
  const lng = 13.405;
  const lat = 52.473;
  const r = 0.04; // ~4 km radius → well over 1 km path
  const pts: [number, number][] = [];
  for (let i = 0; i < 16; i++) {
    const a = (i / 16) * Math.PI * 2;
    pts.push([lng + Math.cos(a) * r, lat + Math.sin(a) * r * 0.6]);
  }
  pts.push(pts[0]); // close
  return pts;
})();
assert(trackIsClosedLoop(closed) === true, "closed ring is loop");
assert(
  isHonestLoop({ loopFlag: false, trackLngLat: closed }) === true,
  "geometry overrides false flag to loop"
);

// --- Geometry: linear A→B ---
const linear: [number, number][] = [
  [13.4, 52.52],
  [13.42, 52.53],
  [13.45, 52.54],
  [13.5, 52.55],
];
assert(trackIsClosedLoop(linear) === false, "linear is not loop");
assert(
  isHonestLoop({ loopFlag: true, trackLngLat: linear }) === false,
  "P2P geometry never passes even with lying flag"
);

// ~180 m trailhead gap still closed under 200 m Spec tolerance
const almostClosed: [number, number][] = closed.map(
  (p) => [...p] as [number, number]
);
almostClosed[almostClosed.length - 1] = [
  almostClosed[0][0] + 0.0024,
  almostClosed[0][1],
];
assert(
  trackIsClosedLoop(almostClosed) === true,
  "~180 m gap still counts as loop (≤200 m)"
);

// --- Flag-only (no track) — seed path ---
assert(
  isHonestLoop({ loopFlag: true, trackLngLat: null }) === true,
  "seed is_loop without track ok"
);
assert(
  isHonestLoop({ loopFlag: false, trackLngLat: null }) === false,
  "linear seed without track excluded"
);

// --- Out-and-back Quick pads ---
assert(
  isOutAndBackQuickOption({
    id: "quick-n",
    label: "60 min · Norden",
    reason: "Out-and-back Richtung Norden",
  }) === true,
  "Norden out-and-back detected"
);
assert(
  isOutAndBackQuickOption({
    id: "seed-loop-tempelhofer-60",
    label: "Tempelhofer Feld",
    reason: "Rundkurs-Seed",
  }) === false,
  "honest seed not out-and-back"
);

const rail = filterHonestLoopSuggestions([
  { id: "seed-loop-tempelhofer-60", loop: true },
  { id: "seed-route-spree-commute", loop: false },
  { id: "seed-route-spree-commute", loop: true },
  { id: "linear-x", loop: false },
]);
assert(rail.length === 1, "~60 rail keeps only honest loop");
assert(rail[0].id === "seed-loop-tempelhofer-60", "Tempelhofer kept");

const cleared = sanitizeDraftForRundkurs({
  mode: "quick",
  label: "60 min · Norden",
  computed: {
    geometry: {
      coordinates: [
        [13.4, 52.52],
        [13.41, 52.53],
        [13.42, 52.54],
        [13.43, 52.55],
      ],
    },
  },
});
assert(cleared.computed == null && cleared.label === "", "sanitize Norden draft");

console.log("loopHonesty.test.ts OK");
