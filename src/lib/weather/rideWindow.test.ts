/**
 * npx tsx src/lib/weather/rideWindow.test.ts
 */
import assert from "node:assert/strict";
import {
  formatRideWindowLabel,
  hourOfIso,
  pickRideWindow,
  profileAllowsRideWindow,
  rideWindowCopyIsHof,
  rideWindowNumbers,
  type RideWindowHour,
} from "./rideWindow";

assert.equal(profileAllowsRideWindow("gravel"), true);
assert.equal(profileAllowsRideWindow("mtb_enduro"), true);
assert.equal(profileAllowsRideWindow("emtb"), true);
assert.equal(profileAllowsRideWindow("road"), false);
assert.equal(profileAllowsRideWindow("urban"), false);
assert.equal(profileAllowsRideWindow("ebike"), false);
assert.equal(profileAllowsRideWindow(undefined), false);

assert.equal(hourOfIso("2026-08-20T16:00"), 16);

function hour(
  t: string,
  precipitation: number,
  precipitationProbability: number,
  windSpeedKmh = 12
): RideWindowHour {
  return { time: t, precipitation, precipitationProbability, windSpeedKmh };
}

const morningWet = Array.from({ length: 12 }, (_, i) => {
  const h = 8 + i;
  const pad = String(h).padStart(2, "0");
  const wet = h < 16;
  return hour(
    `2026-08-20T${pad}:00`,
    wet ? 1.2 : 0,
    wet ? 80 : 12
  );
});

const picked = pickRideWindow({
  nowIso: "2026-08-20T08:00",
  sunriseIso: "2026-08-20T06:10",
  sunsetIso: "2026-08-20T20:30",
  hours: morningWet,
});
assert.equal(picked.kind, "drier");
if (picked.kind === "drier") {
  assert.ok(picked.startHour >= 16, String(picked.startHour));
  const label = formatRideWindowLabel(picked, "de");
  assert.ok(label.includes("Uhr"));
  assert.ok(label.includes("trockener"));
  assert.ok(rideWindowCopyIsHof(label));
  assert.ok(!/go|mm|psi/i.test(label));
  const nums = rideWindowNumbers(picked);
  assert.ok(nums.some((n) => n.value === picked.startHour));
}

const allDry = morningWet.map((h) =>
  hour(h.time, 0, 5, 8)
);
assert.equal(
  pickRideWindow({
    nowIso: "2026-08-20T08:00",
    sunriseIso: "2026-08-20T06:10",
    sunsetIso: "2026-08-20T20:30",
    hours: allDry,
  }).kind,
  "all_dry"
);
assert.equal(
  formatRideWindowLabel({ kind: "all_dry" }, "de"),
  "heute den ganzen Tag eher trocken"
);
assert.ok(
  rideWindowCopyIsHof(formatRideWindowLabel({ kind: "all_dry" }, "de"))
);

const allWet = morningWet.map((h) => hour(h.time, 2, 90, 20));
assert.equal(
  pickRideWindow({
    nowIso: "2026-08-20T08:00",
    sunriseIso: "2026-08-20T06:10",
    sunsetIso: "2026-08-20T20:30",
    hours: allWet,
  }).kind,
  "none"
);
assert.ok(
  !/\d/.test(formatRideWindowLabel({ kind: "none" }, "de")),
  "none copy has no clock numbers"
);

assert.equal(formatRideWindowLabel({ kind: "none" }, "en"), "no clearer window today");

console.log("rideWindow.test.ts OK");
