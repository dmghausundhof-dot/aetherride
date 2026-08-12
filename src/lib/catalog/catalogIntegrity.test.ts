/**
 * Katalog-Integrität: OEM-Refs auflösbar, Shock/Seatpost-Fit konsistent.
 * Ausführen: npx tsx src/lib/catalog/catalogIntegrity.test.ts
 */
import { BIKE_CATALOG, catalogStats } from "./bikes";
import { COMPONENT_CATALOG, getComponentModel } from "./components";
import { COMPATIBILITY_RULES } from "@/lib/compatibility/rules";

function assert(cond: boolean, msg: string) {
  if (!cond) throw new Error(msg);
}

const stats = catalogStats();
assert(stats.manufacturers >= 45, `Erwarte ≥45 Hersteller, got ${stats.manufacturers}`);
assert(stats.bikes >= 65, `Erwarte ≥65 Bikes, got ${stats.bikes}`);
assert(
  COMPONENT_CATALOG.length >= 170,
  `Erwarte ≥170 kuratierte OEM-Komponenten, got ${COMPONENT_CATALOG.length}`
);
assert(
  !COMPONENT_CATALOG.some(
    (c) =>
      /scale5|synthetic/i.test(c.model) ||
      /^Seed |^Bulk /i.test(c.manufacturer)
  ),
  "Kein Scale5-/Seed-Padding im Bundle-Katalog erlaubt"
);
assert(COMPATIBILITY_RULES.length >= 15, `Erwarte ≥15 Regeln, got ${COMPATIBILITY_RULES.length}`);

const ids = new Set(COMPONENT_CATALOG.map((c) => c.id));
assert(ids.size === COMPONENT_CATALOG.length, "Doppelte Komponenten-IDs");

let missingOem = 0;
const missingList: string[] = [];
for (const mfr of BIKE_CATALOG) {
  for (const bike of mfr.bikes) {
    for (const [slot, modelId] of Object.entries(bike.oemComponents ?? {})) {
      if (!modelId) continue;
      if (!ids.has(modelId)) {
        missingOem += 1;
        missingList.push(`${bike.id}.${slot}=${modelId}`);
      }
    }
  }
}
assert(missingOem === 0, `Fehlende OEM-Refs:\n${missingList.join("\n")}`);

/** Shock eye/stroke/mount muss zu Rahmen passen, wenn beide Modelle existieren */
let shockMismatches = 0;
const shockIssues: string[] = [];
for (const mfr of BIKE_CATALOG) {
  for (const bike of mfr.bikes) {
    const frameId = bike.oemComponents?.frame;
    const shockId = bike.oemComponents?.rear_shock;
    if (!frameId || !shockId) continue;
    const frame = getComponentModel(frameId);
    const shock = getComponentModel(shockId);
    if (!frame || !shock) continue;
    const fEye = frame.attributes.find((a) => a.key === "shock_eye_to_eye_mm")?.valueNum;
    const fStroke = frame.attributes.find((a) => a.key === "shock_stroke_mm")?.valueNum;
    const fMount = frame.attributes.find((a) => a.key === "shock_mount_type")?.valueEnum;
    const sEye = shock.attributes.find((a) => a.key === "eye_to_eye_mm")?.valueNum;
    const sStroke = shock.attributes.find((a) => a.key === "stroke_mm")?.valueNum;
    const sMount = shock.attributes.find((a) => a.key === "mount_type")?.valueEnum;
    if (
      fEye !== undefined &&
      sEye !== undefined &&
      fStroke !== undefined &&
      sStroke !== undefined &&
      fMount &&
      sMount
    ) {
      if (fEye !== sEye || fStroke !== sStroke || fMount !== sMount) {
        shockMismatches += 1;
        shockIssues.push(
          `${bike.id}: frame ${fEye}×${fStroke} ${fMount} vs shock ${sEye}×${sStroke} ${sMount}`
        );
      }
    }
  }
}
assert(shockMismatches === 0, `Shock-Mismatch:\n${shockIssues.join("\n")}`);

/** Seatpost-Ø muss zum Rahmen passen */
let seatMismatches = 0;
const seatIssues: string[] = [];
for (const mfr of BIKE_CATALOG) {
  for (const bike of mfr.bikes) {
    const frameId = bike.oemComponents?.frame;
    const postId = bike.oemComponents?.seatpost;
    if (!frameId || !postId) continue;
    const frame = getComponentModel(frameId);
    const post = getComponentModel(postId);
    if (!frame || !post) continue;
    const fDia = frame.attributes.find((a) => a.key === "seatpost_diameter_mm")?.valueNum;
    const pDia = post.attributes.find((a) => a.key === "diameter_mm")?.valueNum;
    if (fDia !== undefined && pDia !== undefined && fDia !== pDia) {
      seatMismatches += 1;
      seatIssues.push(`${bike.id}: frame Ø${fDia} vs post Ø${pDia}`);
    }
  }
}
assert(seatMismatches === 0, `Seatpost-Mismatch:\n${seatIssues.join("\n")}`);

console.log(
  JSON.stringify(
    {
      ok: true,
      manufacturers: stats.manufacturers,
      bikes: stats.bikes,
      oemRefs: stats.oemRefs,
      components: COMPONENT_CATALOG.length,
    },
    null,
    2
  )
);
