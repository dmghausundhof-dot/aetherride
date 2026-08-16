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
  evaluatePartAgainstGarage,
  type GarageFitBikeInput,
} from "@/lib/shop/garageFit";
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
  PARTS_BROWSE_SLOTS,
} from "@/lib/shop/softFit";
import { isPartsProduct } from "@/lib/shop/shopShelf";

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
    products: result.products
      .map(mapStorefrontProduct)
      .filter((p) =>
        isPartsProduct({
          tags: p.tags,
          productType: p.productType,
          handle: p.handle,
          title: p.name,
        })
      ),
    source: "storefront",
  };
}

export type PartsFilterInput = {
  slot?: string | null;
  fit?: "bike" | "all" | null;
  /** Legacy: einzelnes Bike (Soft-Fit). Wird zu `bikes` ergänzt, wenn gesetzt. */
  ctx?: SoftFitContext | null;
  /** Garage-Bikes inkl. Soft-Fit-Kontext — Union, optional auf ein Rad eingeschränkt. */
  bikes?: GarageFitBikeInput[];
  selectedBikeId?: string | null;
  /** hide unavailable */
  availableOnly?: boolean;
};

export type RankedPartsProduct = {
  product: PartsProduct;
  verdict: SoftFitVerdict;
  chip: string;
  /** z. B. "passt zu Canyon Grizl · 700c · Gravel" */
  fitLabel?: string | null;
  matchedBikeIds?: string[];
};

export function filterAndRankParts(
  products: PartsProduct[],
  input: PartsFilterInput
): RankedPartsProduct[] {
  const slot = normalizePartsSlot(input.slot);
  const fitMode = input.fit === "bike" ? "bike" : "all";
  const ctx = input.ctx ?? null;
  const bikes = input.bikes ?? [];
  const useGarage = bikes.length > 0;

  const list = products.filter((p) => {
    if (!isPartsProduct({ tags: p.tags, productType: p.productType, handle: p.handle, title: p.name })) {
      return false;
    }
    if (input.availableOnly && !p.availableForSale) return false;
    if (!productMatchesSlotFilter(p.softFit, p.productType, slot)) return false;
    if (useGarage) {
      const ev = evaluatePartAgainstGarage({
        tags: p.tags,
        title: p.name,
        productType: p.productType,
        slotKey: p.slotKey,
        description: p.description,
        softFit: p.softFit,
        bikes,
        selectedBikeId: input.selectedBikeId,
        fitMode,
      });
      return ev.visible;
    }
    if (!productMatchesSoftFitFilter(p.softFit, ctx, fitMode)) return false;
    return true;
  });

  const ranked = list.map((product) => {
    const slotLabel =
      product.softFit.slots[0] ||
      (product.slotKey !== "other" ? product.slotKey : undefined);

    if (useGarage) {
      const ev = evaluatePartAgainstGarage({
        tags: product.tags,
        title: product.name,
        productType: product.productType,
        slotKey: product.slotKey,
        description: product.description,
        softFit: product.softFit,
        bikes,
        selectedBikeId: input.selectedBikeId,
        fitMode,
      });
      return {
        product,
        verdict: ev.verdict,
        chip: softFitChipLabel(ev.verdict, slotLabel),
        fitLabel: ev.garage.label,
        matchedBikeIds: ev.garage.matchedBikes.map((b) => b.id),
      };
    }

    const verdict = softFitVerdict(product.softFit, ctx);
    return {
      product,
      verdict,
      chip: softFitChipLabel(verdict, slotLabel),
      fitLabel: null,
      matchedBikeIds: ctx ? [ctx.bikeId] : [],
    };
  });

  if (fitMode === "bike" && (useGarage || ctx)) {
    const rank = (row: RankedPartsProduct) => {
      if (row.fitLabel) return 0;
      if (row.verdict === "passt") return 1;
      if (row.verdict === "universal") return 2;
      return 3;
    };
    ranked.sort((a, b) => rank(a) - rank(b));
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
  params.set("door", "parts");
  const q = params.toString();
  return `/shop?${q}`;
}

/** Werkstatt / Verschleiß → Laden, nur Browse-Slots (kein fork-Raten). */
export function shopReplaceHref(opts: {
  bike: string;
  slot?: string | null;
}): string {
  const raw = opts.slot ? normalizePartsSlot(opts.slot) : undefined;
  const slot =
    raw && raw !== "all" && PARTS_BROWSE_SLOTS.some((s) => s.slot === raw)
      ? raw
      : undefined;
  return shopPartsHref({ bike: opts.bike, fit: "bike", slot });
}
