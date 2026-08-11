import type { CompatAttrMap, CompatDimensionDef } from "./types";

/** Shopify tag prefixes → compat dimension ids (from gates pack). */
export function buildPrefixToDimension(
  dimensions: CompatDimensionDef[]
): Map<string, string> {
  const map = new Map<string, string>();
  for (const d of dimensions) {
    map.set(d.shopify_tag_prefix.toLowerCase(), d.id);
  }
  return map;
}

/**
 * Parse Shopify-style tags (`prefix:value`) into compat attrs.
 * Unknown prefixes are ignored. First match wins; later duplicate prefixes ignored.
 */
export function parseShopifyTags(
  tags: string[] | undefined,
  dimensions: CompatDimensionDef[]
): CompatAttrMap {
  const out: CompatAttrMap = {};
  if (!tags?.length) return out;
  const prefixMap = buildPrefixToDimension(dimensions);
  for (const raw of tags) {
    if (typeof raw !== "string") continue;
    const idx = raw.indexOf(":");
    if (idx <= 0) continue;
    const prefix = raw.slice(0, idx).trim().toLowerCase();
    const value = raw.slice(idx + 1).trim();
    if (!value) continue;
    const dim = prefixMap.get(prefix);
    if (!dim) continue;
    if (out[dim] !== undefined) continue;
    out[dim] = value;
  }
  return out;
}

export function mergeAttrs(
  base: CompatAttrMap,
  override?: CompatAttrMap
): CompatAttrMap {
  if (!override) return { ...base };
  return { ...base, ...override };
}
