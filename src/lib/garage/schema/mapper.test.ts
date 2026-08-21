/**
 * G-SCH-03 mapper tests — run: npx tsx src/lib/garage/schema/mapper.test.ts
 */
import { planBikeSchema } from "./mapper";
import { schemaInviteSlots } from "./invites";

function assert(cond: boolean, msg: string) {
  if (!cond) throw new Error(msg);
}

// Road / gravel / city templates
assert(planBikeSchema({ category: "road" }).template === "road", "road");
assert(planBikeSchema({ category: "gravel" }).template === "gravel", "gravel");
assert(planBikeSchema({ category: "urban" }).template === "urban", "urban");
assert(planBikeSchema({ category: "cargo" }).template === "cargo", "cargo");
assert(planBikeSchema({ category: "folding" }).template === "folding", "folding");
assert(planBikeSchema({ category: "kids" }).template === "kids", "kids");
assert(
  planBikeSchema({ category: "etrekking" }).template === "etrekking",
  "etrekking"
);

assert(planBikeSchema({ category: "mtb_trail" }).template === "mtb_trail", "trail");
assert(planBikeSchema({ category: "mtb_am" }).template === "mtb_am", "am");
assert(planBikeSchema({ category: "mtb_enduro" }).template === "mtb_enduro", "enduro");
assert(planBikeSchema({ category: "dh" }).template === "dh", "dh");
assert(planBikeSchema({ category: "emtb" }).template === "emtb", "emtb");

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

const invited = schemaInviteSlots({
  hotspotSlots: ["tire_front", "fork", "frame", "saddle"],
  installed: [],
});
assert(invited.length === 2, "two invitations on an empty schema");
assert(invited[0] === "tire_front", "first core slot first");
assert(
  schemaInviteSlots({
    hotspotSlots: ["stem", "frame", "saddle"],
    installed: [],
  }).join() === "stem,saddle",
  "frame is not an invitation"
);

console.log("mapper.test.ts OK");
