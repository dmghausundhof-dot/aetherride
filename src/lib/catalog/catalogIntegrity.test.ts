/**
 * Katalog-Integrität: OEM-Refs auflösbar, Shock/Seatpost-Fit konsistent.
 * Ausführen: npx tsx src/lib/catalog/catalogIntegrity.test.ts
 */
import { BIKE_CATALOG, catalogStats } from "./bikes";
import { COMPONENT_CATALOG, getComponentModel, searchComponentModels } from "./components";
import { COMPATIBILITY_RULES } from "@/lib/compatibility/rules";

function assert(cond: boolean, msg: string) {
  if (!cond) throw new Error(msg);
}

const stats = catalogStats();
assert(stats.manufacturers >= 57, `Erwarte ≥57 Hersteller, got ${stats.manufacturers}`);
assert(stats.bikes >= 140, `Erwarte ≥140 Bikes, got ${stats.bikes}`);
assert(
  COMPONENT_CATALOG.length >= 250,
  `Erwarte ≥250 kuratierte OEM-Komponenten, got ${COMPONENT_CATALOG.length}`
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

/** Reach/Stack nur für Katalog-Größen, mit Quelle */
let geoIssues = 0;
const geoList: string[] = [];
for (const mfr of BIKE_CATALOG) {
  for (const bike of mfr.bikes) {
    for (const row of bike.geometryBySize ?? []) {
      if (!bike.frameSizeOptions.includes(row.size)) {
        geoIssues += 1;
        geoList.push(`${bike.id}: Geometrie-Größe ${row.size} nicht in frameSizeOptions`);
      }
      if (!(row.reachMm > 0) || !(row.stackMm > 0) || !row.sourceUrl) {
        geoIssues += 1;
        geoList.push(`${bike.id} ${row.size}: Reach/Stack/sourceUrl unvollständig`);
      }
    }
  }
}
assert(geoIssues === 0, `Geometrie-Fehler:\n${geoList.join("\n")}`);

const emptyHits = searchComponentModels("cassette", "", 3);
assert(emptyHits.length <= 3, "Suche ohne Query ist gedeckelt");
assert(
  emptyHits.every((m) => m.slot === "cassette"),
  "Suche ohne Query bleibt im Slot"
);
const namedHits = searchComponentModels("cassette", "sram", 8);
assert(
  namedHits.every((m) => m.slot === "cassette"),
  "Namenssuche bleibt im Slot"
);

const cats = new Set(
  BIKE_CATALOG.flatMap((m) => m.bikes.map((b) => b.category))
);
for (const need of ["cargo", "folding", "kids"] as const) {
  assert(cats.has(need), `Kategorie ${need} fehlt im OEM-Katalog`);
}

/** Marken ohne aktuelles Analog-OEM — bewusst E-only, nicht erfinden. */
const INTENTIONAL_E_ONLY = new Set([
  "Rotwild",
  "Haibike",
  "Flyer",
  "Riese & Müller",
  "Kalkhoff",
]);
for (const m of BIKE_CATALOG) {
  const hasAnalog = m.bikes.some((b) => !b.isEbike);
  const hasE = m.bikes.some((b) => b.isEbike);
  if (hasE && !hasAnalog) {
    assert(
      INTENTIONAL_E_ONLY.has(m.name),
      `E-only ohne Intent-Whitelist: ${m.name} — Analog nur mit OEM-Beleg ergänzen`
    );
  }
}

console.log(
  JSON.stringify(
    {
      ok: true,
      manufacturers: stats.manufacturers,
      bikes: stats.bikes,
      oemRefs: stats.oemRefs,
      components: COMPONENT_CATALOG.length,
      geometryBikes: BIKE_CATALOG.reduce(
        (n, m) => n + m.bikes.filter((b) => (b.geometryBySize?.length ?? 0) > 0).length,
        0
      ),
    },
    null,
    2
  )
);
