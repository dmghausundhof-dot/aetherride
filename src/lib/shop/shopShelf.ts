/**
 * Shop-Regale: Werkstatt-Teile vs. Merchandise vs. Garage-Fit-Hook.
 *
 * Merch wird nie über Garage-Fit (category/wheel/ebike/shift) gefiltert.
 * Garage-Bike-Produkte sind interne Fit-Hooks, kein Verkaufsregal.
 */

export type ShopShelf = "parts" | "merch" | "garage_hook" | "other";

export const MERCH_COLLECTION_HANDLE = "merchandise";
export const GARAGE_BIKE_TAG = "garage-bike";
export const GARAGE_BIKE_HANDLE_PREFIX = "ar-garage-";
export const GARAGE_BIKE_PRODUCT_TYPE = "Garage Bike";

const MERCH_TAG_KEYS = new Set([
  "merch",
  "merchandise",
  "slot:merch",
  "product:merch",
]);

const GARAGE_HOOK_TAGS = new Set([
  GARAGE_BIKE_TAG,
  "garage_bike",
  "aetherride-garage",
  "garage-hook",
  "garage_hook",
]);

const PARTS_SLOT_KEYS = new Set([
  "brake_pads",
  "grips",
  "fluid",
  "chain",
  "tire",
  "cassette",
  "bar_tape",
  "rotor",
  "brake",
  "fork",
  "shock",
  "battery",
  "motor",
  "display",
]);

const MERCH_TYPE_RE =
  /\b(t-?shirts?|tees?\b|hoodie|cap|kappe|hat\b|mütze|beanie|flasche|bottles?|trinkflasche|sticker|aufkleber|socken?|socks?|apparel|merch(?:andise)?|bekleidung|mug|tasse|tote|jersey|trikot|jacke|jacket|shirt)\b/i;

const PARTS_TYPE_RE =
  /\b(tire|tyre|reifen|chain|kette|cassette|kassette|pad|belag|grip|griff|fluid|öl|oil|brake|bremse|rotor|fork|gabel|shock|dämpfer|derailleur|schaltung|bar.?tape|lenkerband)\b/i;

const FIT_TAG_RE =
  /^(?:category|cat|sport|discipline|fit|bike_type|wheel|wheel_size|laufrad|iso|shift_compat|drivetrain|groupset):/i;

export type ShopProductClassInput = {
  tags?: string[];
  productType?: string;
  handle?: string;
  title?: string;
  collectionHandle?: string;
};

export type ShopProductClass = {
  shelf: ShopShelf;
  reason: string;
};

function normTags(tags: string[] | undefined): string[] {
  return (tags ?? []).map((t) => t.trim().toLowerCase()).filter(Boolean);
}

export function isGarageBikeHook(input: ShopProductClassInput): boolean {
  const handle = (input.handle ?? "").trim().toLowerCase();
  if (handle.startsWith(GARAGE_BIKE_HANDLE_PREFIX)) return true;
  const type = (input.productType ?? "").trim().toLowerCase();
  if (type === "garage bike" || type === "garage-bike") return true;
  return normTags(input.tags).some((t) => GARAGE_HOOK_TAGS.has(t));
}

export function hasExplicitMerchTag(tags: string[] | undefined): boolean {
  return normTags(tags).some((t) => MERCH_TAG_KEYS.has(t));
}

export function hasPartsSlotTag(tags: string[] | undefined): boolean {
  for (const t of normTags(tags)) {
    const m = /^slot:(.+)$/.exec(t);
    if (!m) continue;
    const key = m[1].replace(/-/g, "_");
    if (PARTS_SLOT_KEYS.has(key)) return true;
  }
  return false;
}

export function hasGarageFitTag(tags: string[] | undefined): boolean {
  return (tags ?? []).some((t) => FIT_TAG_RE.test(t.trim()));
}

export function classifyShopProduct(
  input: ShopProductClassInput
): ShopProductClass {
  if (isGarageBikeHook(input)) {
    return { shelf: "garage_hook", reason: "garage-bike" };
  }

  const collection = (input.collectionHandle ?? "").trim().toLowerCase();
  const merchCollection =
    collection === MERCH_COLLECTION_HANDLE || collection === "merch";

  if (hasExplicitMerchTag(input.tags) || merchCollection) {
    return { shelf: "merch", reason: merchCollection ? "collection" : "tag:merch" };
  }

  if (hasPartsSlotTag(input.tags)) {
    return { shelf: "parts", reason: "slot" };
  }

  const type = input.productType ?? "";
  const title = input.title ?? "";
  const blob = `${type} ${title}`;

  if (MERCH_TYPE_RE.test(blob) && !PARTS_TYPE_RE.test(blob)) {
    return { shelf: "merch", reason: "productType" };
  }

  if (hasGarageFitTag(input.tags) || PARTS_TYPE_RE.test(blob)) {
    return { shelf: "parts", reason: hasGarageFitTag(input.tags) ? "fit-tag" : "productType" };
  }

  if (collection === "featured-parts") {
    return { shelf: "parts", reason: "featured-parts" };
  }

  return { shelf: "other", reason: "unclassified" };
}

export function isMerchProduct(input: ShopProductClassInput): boolean {
  return classifyShopProduct(input).shelf === "merch";
}

export function isPartsProduct(input: ShopProductClassInput): boolean {
  return classifyShopProduct(input).shelf === "parts";
}

export function splitShopProducts<T extends ShopProductClassInput>(
  products: T[]
): { parts: T[]; merch: T[]; other: T[] } {
  const parts: T[] = [];
  const merch: T[] = [];
  const other: T[] = [];
  for (const p of products) {
    const shelf = classifyShopProduct(p).shelf;
    if (shelf === "parts") parts.push(p);
    else if (shelf === "merch") merch.push(p);
    else other.push(p);
  }
  return { parts, merch, other };
}
