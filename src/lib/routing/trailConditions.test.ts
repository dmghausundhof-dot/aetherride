/**
 * Trail-Conditions lokal
 */
import {
  TRAIL_CONDITION_LABELS,
  latestConditionFor,
  loadTrailConditions,
  saveTrailConditions,
  upsertTrailCondition,
} from "./trailConditions";

function assert(c: boolean, m: string) {
  if (!c) throw new Error(m);
}

saveTrailConditions([]);
assert(loadTrailConditions().length === 0, "empty");
upsertTrailCondition({
  routeOrTrailId: "r-alpbach-enduro",
  labelDe: "Enduro Alpbachtal",
  condition: "wet",
});
const latest = latestConditionFor("r-alpbach-enduro");
assert(latest?.condition === "wet", "wet");
assert(TRAIL_CONDITION_LABELS.wet === "Nass", "label");
upsertTrailCondition({
  routeOrTrailId: "r-alpbach-enduro",
  labelDe: "Enduro Alpbachtal",
  condition: "dry",
});
assert(latestConditionFor("r-alpbach-enduro")?.condition === "dry", "replace");
assert(loadTrailConditions().length === 1, "one per route");

console.log("trailConditions.test OK");
