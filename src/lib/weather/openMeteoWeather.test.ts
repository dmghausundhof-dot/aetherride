/**
 * npx tsx src/lib/weather/openMeteoWeather.test.ts
 */
import assert from "node:assert/strict";
import { dailyIndexForNow } from "./openMeteoWeather";

const days = ["2026-08-17", "2026-08-18", "2026-08-19", "2026-08-20"];
assert.equal(dailyIndexForNow(days, "2026-08-20T16:00"), 3);
assert.equal(dailyIndexForNow(days, "2026-08-17T08:00"), 0);
assert.equal(dailyIndexForNow([], "2026-08-20T16:00"), -1);
assert.equal(dailyIndexForNow(days, undefined), 3);
assert.notEqual(
  dailyIndexForNow(days, "2026-08-20T06:10"),
  0,
  "today is not past_days index 0"
);

console.log("openMeteoWeather.test.ts OK");
