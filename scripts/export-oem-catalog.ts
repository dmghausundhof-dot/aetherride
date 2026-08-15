/**
 * Export curated OEM catalog → data/catalog/oem-seed.json
 */
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import { COMPONENT_CATALOG } from "../src/lib/catalog/components";
import { BIKE_CATALOG } from "../src/lib/catalog/bikes";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const outPath = path.join(__dirname, "../data/catalog/oem-seed.json");

function attrsToMap(
  attrs: {
    key: string;
    valueNum?: number;
    valueEnum?: string;
    valueText?: string;
    unit?: string;
  }[]
): Record<string, string | number> {
  const out: Record<string, string | number> = {};
  for (const a of attrs) {
    if (a.valueNum !== undefined) out[a.key] = a.valueNum;
    else if (a.valueEnum !== undefined) out[a.key] = a.valueEnum;
    else if (a.valueText !== undefined) out[a.key] = a.valueText;
  }
  return out;
}

const components = COMPONENT_CATALOG.map((c) => ({
  id: c.id,
  slot: c.slot,
  manufacturer: c.manufacturer,
  model: c.model,
  variant: c.variant,
  year: c.modelYear ?? null,
  attributes: attrsToMap(c.attributes),
  source: c.source === "oem" || c.source === "manufacturer_doc" ? c.source : "oem",
  sourceUrl: c.sourceUrl,
  verifiedAt: c.verifiedAt,
}));

const manufacturers = BIKE_CATALOG.map((m) => ({
  id: m.id,
  name: m.name,
  bikes: m.bikes.map((b) => ({
    id: b.id,
    name: b.name,
    category: b.category,
    year: b.year,
    frameSizeOptions: b.frameSizeOptions,
    travelFrontMm: b.travelFrontMm ?? null,
    travelRearMm: b.travelRearMm ?? null,
    wheelSizeFront: b.wheelSizeFront,
    wheelSizeRear: b.wheelSizeRear,
    isEbike: b.isEbike,
    weightKgApprox: b.weightKgApprox ?? null,
    sourceUrl: b.sourceUrl,
    geometryBySize: b.geometryBySize ?? [],
    oem_components: Object.entries(b.oemComponents ?? {}).map(([slot, modelId]) => ({
      slot,
      component_model_id: modelId,
    })),
    // Map-Form für API/Wizard-Parity (Postgres speichert oft Array)
    oemComponents: b.oemComponents ?? {},
  })),
}));

const payload = {
  exportedAt: new Date().toISOString(),
  source: "src/lib/catalog (OEM curated, no synthetic_seed)",
  components,
  manufacturers,
};

fs.mkdirSync(path.dirname(outPath), { recursive: true });
fs.writeFileSync(outPath, JSON.stringify(payload, null, 2));
console.log(
  JSON.stringify(
    {
      ok: true,
      path: outPath,
      components: components.length,
      manufacturers: manufacturers.length,
      bikes: manufacturers.reduce((n, m) => n + m.bikes.length, 0),
    },
    null,
    2
  )
);
