/**
 * Featured-parts Collection → Parts listing model.
 * Collection-driven — no hard-coded product snapshot.
 */

import {
  FEATURED_PARTS_COLLECTION,
  fetchCollectionProducts,
  shopifyStoreProductUrl,
  type ShopifyStorefrontProduct,
} from "@/lib/shop/shopifyStorefront";
import {
  normalizePartsSlot,
  parseSoftFitTags,
  productMatchesSlotFilter,
  productMatchesSoftFitFilter,
  softFitChipLabel,
  softFitVerdict,
  type SoftFitContext,
  type SoftFitTags,
  type SoftFitVerdict,
} from "@/lib/shop/softFit";

export type PartsProduct = {
  id: string;
  handle: string;
  name: string;
  manufacturer: string;
  productType: string;
  description: string;
  priceEur: number;
  currencyCode: string;
  imageUrl?: string;
  imageAlt?: string;
  availableForSale: boolean;
  affiliateUrl: string;
  tags: string[];
  softFit: SoftFitTags;
  /** Primary browse slot if tagged */
  slotKey: string;
};

export type PartsCatalogResult =
  | {
      ok: true;
      configured: true;
      collectionHandle: string;
      collectionTitle: string;
      products: PartsProduct[];
      source: "storefront";
    }
  | {
      ok: false;
      configured: boolean;
      collectionHandle: string;
      products: [];
      error: string;
      code: string;
    };

function priceToEur(amount: string, currencyCode: string): number {
  const n = Number.parseFloat(amount);
  if (!Number.isFinite(n)) return 0;
  if (currencyCode === "EUR") return Math.round(n * 100) / 100;
  // Store is EUR for AetherRide; keep amount as-is for other codes
  return Math.round(n * 100) / 100;
}

export function mapStorefrontProduct(p: ShopifyStorefrontProduct): PartsProduct {
  const softFit = parseSoftFitTags(p.tags ?? []);
  const slotKey = softFit.slots[0] ?? normalizePartsSlot(
    p.productType.toLowerCase().replace(/\s+/g, "_")
  );
  return {
    id: p.id,
    handle: p.handle,
    name: p.title,
    manufacturer: p.vendor || "AetherRide Shop",
    productType: p.productType || "",
    description: (p.description || "").trim(),
    priceEur: priceToEur(
      p.priceRange.minVariantPrice.amount,
      p.priceRange.minVariantPrice.currencyCode
    ),
    currencyCode: p.priceRange.minVariantPrice.currencyCode || "EUR",
    imageUrl: p.featuredImage?.url,
    imageAlt: p.featuredImage?.altText ?? undefined,
    availableForSale: p.availableForSale,
    affiliateUrl: p.onlineStoreUrl || shopifyStoreProductUrl(p.handle),
    tags: p.tags ?? [],
    softFit,
    slotKey: slotKey === "all" ? "other" : slotKey,
  };
}

export async function loadFeaturedParts(): Promise<PartsCatalogResult> {
  const result = await fetchCollectionProducts(FEATURED_PARTS_COLLECTION);
  if (!result.ok) {
    return {
      ok: false,
      configured: result.configured,
      collectionHandle: result.collectionHandle,
      products: [],
      error: result.error,
      code: result.code,
    };
  }
  return {
    ok: true,
    configured: true,
    collectionHandle: result.collectionHandle,
    collectionTitle: result.collectionTitle,
    products: result.products.map(mapStorefrontProduct),
    source: "storefront",
  };
}

export type PartsFilterInput = {
  slot?: string | null;
  fit?: "bike" | "all" | null;
  ctx?: SoftFitContext | null;
  /** hide unavailable */
  availableOnly?: boolean;
};

export type RankedPartsProduct = {
  product: PartsProduct;
  verdict: SoftFitVerdict;
  chip: string;
};

export function filterAndRankParts(
  products: PartsProduct[],
  input: PartsFilterInput
): RankedPartsProduct[] {
  const slot = normalizePartsSlot(input.slot);
  const fitMode = input.fit === "bike" ? "bike" : "all";
  const ctx = input.ctx ?? null;

  const list = products.filter((p) => {
    if (input.availableOnly && !p.availableForSale) return false;
    if (!productMatchesSlotFilter(p.softFit, p.productType, slot)) return false;
    if (!productMatchesSoftFitFilter(p.softFit, ctx, fitMode)) return false;
    return true;
  });

  const ranked = list.map((product) => {
    const verdict = softFitVerdict(product.softFit, ctx);
    const slotLabel =
      product.softFit.slots[0] ||
      (product.slotKey !== "other" ? product.slotKey : undefined);
    return {
      product,
      verdict,
      chip: softFitChipLabel(verdict, slotLabel),
    };
  });

  // Prefer "passt" when bike fit active
  if (fitMode === "bike" && ctx) {
    const rank = (v: SoftFitVerdict) =>
      v === "passt" ? 0 : v === "universal" ? 1 : 2;
    ranked.sort((a, b) => rank(a.verdict) - rank(b.verdict));
  }

  return ranked;
}

export function shopPartsHref(opts?: {
  slot?: string;
  bike?: string;
  fit?: "bike" | "all";
  focus?: string;
}): string {
  const params = new URLSearchParams();
  if (opts?.slot) params.set("slot", opts.slot);
  if (opts?.bike) params.set("bike", opts.bike);
  if (opts?.fit) params.set("fit", opts.fit);
  if (opts?.focus) params.set("focus", opts.focus);
  const q = params.toString();
  return q ? `/shop/parts?${q}` : "/shop/parts";
}
