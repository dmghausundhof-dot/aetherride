import bikeEntitySchema from "./bike-entity-schema-v1.json";
import gates from "./compat-gates-v1.json";
import { parseShopifyTags } from "./tags";
import type {
  BikeEntityModel,
  BikeSchemaSummary,
  CompatAttrMap,
  CompatDimensionDef,
  CompatGatesRuleset,
} from "./types";

const schema = bikeEntitySchema as {
  version: string;
  geometry_required: boolean;
  notes: string[];
  groups: Record<string, Record<string, { maps_to_compat_dim: string }>>;
  value_aliases: Record<string, string>;
  omit_values: string[];
  compat_tags_field: string;
};

const ruleset = gates as CompatGatesRuleset;
const dimensions = ruleset.dimensions as CompatDimensionDef[];

/** Research aliases that must normalize or hard_blocks never match. */
const VALUE_ALIASES: Record<string, string> = {
  ...schema.value_aliases,
  shimano_hg_plus_12: "hg_plus_12",
  sram_eagle_12: "eagle_12",
  sram_t_type: "ttype_flattop",
  smart_system: "smart",
  system_2: "system2",
  bpc3400_smart_4a: "bpc3400_smart",
  bcs220_system2_4a: "bcs220_system2",
  "31.8": "31_8",
  "35.0": "35_0",
  "25.4": "25_4",
  none: "na",
};

const OMIT_VALUES = new Set(
  (schema.omit_values ?? ["unknown", ""]).map((v) => v.toLowerCase())
);

/**
 * Normalize a raw entity / tag value into a gates-pack enum token.
 * - magura `none` → `na`
 * - `unknown` → omit (returns undefined)
 * - clamp decimals → underscore form
 */
export function normalizeCompatValue(
  raw: unknown,
  dim?: string
): string | undefined {
  if (raw === null || raw === undefined) return undefined;
  let s = String(raw).trim();
  if (!s) return undefined;

  const lower = s.toLowerCase();
  if (OMIT_VALUES.has(lower)) return undefined;

  if (VALUE_ALIASES[s] !== undefined) s = VALUE_ALIASES[s];
  else if (VALUE_ALIASES[lower] !== undefined) s = VALUE_ALIASES[lower];

  // Magura shape: explicit none → na (alias), unknown already omitted
  if (dim === "magura_pad_shape" && lower === "none") s = "na";

  // Clamp OD: tolerate "31.8mm" / "35,0"
  if (dim === "display_clamp_od" || /^(25|31|35)[.,]\d/.test(s)) {
    const cleaned = s.replace(/mm$/i, "").replace(",", ".").trim();
    if (VALUE_ALIASES[cleaned]) s = VALUE_ALIASES[cleaned];
    else if (/^\d+\.\d+$/.test(cleaned)) s = cleaned.replace(".", "_");
  }

  return s;
}

function readGroup(
  bike: BikeEntityModel,
  group: string
): Record<string, unknown> | undefined {
  const g = bike[group];
  if (!g || typeof g !== "object" || Array.isArray(g)) return undefined;
  return g as Record<string, unknown>;
}

/**
 * Flatten Bike Entity Schema v1 nested model → flat compat attrs.
 * Only fields with maps_to_compat_dim are read. Geometry never required.
 */
export function flattenBikeModelToAttrs(bike: BikeEntityModel): CompatAttrMap {
  const attrs: CompatAttrMap = {};

  for (const [groupName, fields] of Object.entries(schema.groups)) {
    const group = readGroup(bike, groupName);
    if (!group) continue;
    for (const [fieldName, meta] of Object.entries(fields)) {
      const dim = meta.maps_to_compat_dim;
      const normalized = normalizeCompatValue(group[fieldName], dim);
      if (normalized === undefined) continue;
      attrs[dim] = normalized;
    }
  }

  // compat_tags[] → attrs (fill gaps; explicit nested fields win)
  const tags = bike.compat_tags;
  if (Array.isArray(tags)) {
    const fromTags = parseShopifyTags(
      tags.filter((t): t is string => typeof t === "string"),
      dimensions
    );
    for (const [dim, value] of Object.entries(fromTags)) {
      const normalized = normalizeCompatValue(value, dim);
      if (normalized === undefined) continue;
      if (attrs[dim] === undefined) attrs[dim] = normalized;
    }
  }

  return attrs;
}

/** Thin field-contract summary for GET /api/compat/bike-schema */
export function getBikeSchemaSummary(): BikeSchemaSummary {
  const fields: BikeSchemaSummary["fields"] = [];
  for (const [group, groupFields] of Object.entries(schema.groups)) {
    for (const [field, meta] of Object.entries(groupFields)) {
      fields.push({
        group,
        field,
        maps_to_compat_dim: meta.maps_to_compat_dim,
      });
    }
  }
  return {
    version: schema.version,
    geometry_required: !!schema.geometry_required,
    fields,
    value_aliases: { ...VALUE_ALIASES },
    notes: [...(schema.notes ?? [])],
  };
}
