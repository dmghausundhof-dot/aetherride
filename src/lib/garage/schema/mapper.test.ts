/**
 * G-SCH-03 mapper tests — run: npx tsx src/lib/garage/schema/mapper.test.ts
 */
import { planBikeSchema } from "./mapper";

function assert(cond: boolean, msg: string) {
  if (!cond) throw new Error(msg);
}

// Road / gravel / city templates
assert(planBikeSchema({ category: "road" }).template === "road", "road");
assert(planBikeSchema({ category: "gravel" }).template === "gravel", "gravel");
assert(planBikeSchema({ category: "urban" }).template === "city", "urban→city");
assert(
  planBikeSchema({ category: "etrekking" }).template === "city",
  "etrekking→city"
);

// MTB family → mtb template
assert(planBikeSchema({ category: "mtb_trail" }).template === "mtb", "trail");
assert(planBikeSchema({ category: "mtb_am" }).template === "mtb", "am");
assert(planBikeSchema({ category: "mtb_enduro" }).template === "mtb", "enduro");
assert(planBikeSchema({ category: "dh" }).template === "mtb", "dh");
assert(planBikeSchema({ category: "emtb" }).template === "mtb", "emtb");

// Hardtail vs fully
const trailHt = planBikeSchema({ category: "mtb_trail" });
assert(trailHt.showShock === false, "trail hardtail default");
assert(!trailHt.hotspotSlots.includes("rear_shock"), "no shock hotspot HT");

const trailFully = planBikeSchema({
  category: "mtb_trail",
  hasRearShock: true,
});
assert(trailFully.showShock === true, "trail + installed shock");
assert(trailFully.hotspotSlots.includes("rear_shock"), "shock hotspot");

const am = planBikeSchema({ category: "mtb_am" });
assert(am.showShock === true, "AM fully");

// eBike layers
const roadE = planBikeSchema({ category: "road", isEbike: true });
assert(roadE.showEbike === true, "road isEbike");
assert(roadE.hotspotSlots.includes("motor"), "motor slot");
assert(roadE.hotspotSlots.includes("battery"), "battery slot");

const emtb = planBikeSchema({ category: "emtb" });
assert(emtb.showEbike === true, "emtb e");
assert(emtb.showShock === true, "emtb shock");

const etrek = planBikeSchema({ category: "etrekking" });
assert(etrek.showEbike === true, "etrekking e");
assert(etrek.showShock === false, "etrekking no shock");

// Hiking
const hike = planBikeSchema({ category: "hiking" });
assert(hike.template === null, "hiking no svg");
assert(hike.kind === "hiking", "hiking kind");
assert(hike.hotspotSlots.includes("hiking_shoes"), "hiking slots");

// Hit-target slots always include core bike parts
const road = planBikeSchema({ category: "road" });
for (const s of [
  "tire_front",
  "fork",
  "frame",
  "crankset",
  "tire_rear",
] as const) {
  assert(road.hotspotSlots.includes(s), `core ${s}`);
}

console.log("mapper.test.ts OK");
