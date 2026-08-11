/**
 * Shopify Storefront API client — Collection-driven Parts (featured-parts).
 * Token bleibt serverseitig (SHOPIFY_STOREFRONT_ACCESS_TOKEN).
 * Kein Storefront-Passwort in Code oder Env der App.
 */

import { SHOPIFY_STORE_BASE } from "@/lib/shop/catalog";

export const FEATURED_PARTS_COLLECTION = "featured-parts";

export type ShopifyMoney = {
  amount: string;
  currencyCode: string;
};

export type ShopifyStorefrontProduct = {
  id: string;
  handle: string;
  title: string;
  vendor: string;
  productType: string;
  tags: string[];
  description: string;
  availableForSale: boolean;
  featuredImage?: { url: string; altText?: string | null } | null;
  priceRange: { minVariantPrice: ShopifyMoney };
  onlineStoreUrl?: string | null;
};

export type FeaturedPartsFetchResult =
  | {
      ok: true;
      configured: true;
      collectionHandle: string;
      collectionTitle: string;
      products: ShopifyStorefrontProduct[];
      source: "storefront";
    }
  | {
      ok: false;
      configured: boolean;
      collectionHandle: string;
      products: [];
      error: string;
      code: "not_configured" | "collection_missing" | "http_error" | "graphql_error";
    };

type StorefrontConfig = {
  domain: string;
  token: string;
  apiVersion: string;
};

export function getShopifyStorefrontConfig(): StorefrontConfig | null {
  const token = (process.env.SHOPIFY_STOREFRONT_ACCESS_TOKEN || "").trim();
  if (!token) return null;
  const domain = (
    process.env.SHOPIFY_STORE_DOMAIN ||
    process.env.NEXT_PUBLIC_SHOPIFY_STORE_DOMAIN ||
    "dmg-haus-und-hof-shop.myshopify.com"
  )
    .trim()
    .replace(/^https?:\/\//, "")
    .replace(/\/$/, "");
  const apiVersion = (
    process.env.SHOPIFY_STOREFRONT_API_VERSION || "2025-01"
  ).trim();
  return { domain, token, apiVersion };
}

export function isShopifyStorefrontConfigured(): boolean {
  return getShopifyStorefrontConfig() != null;
}

const COLLECTION_PRODUCTS_QUERY = /* GraphQL */ `
  query FeaturedParts($handle: String!, $first: Int!, $after: String) {
    collection(handle: $handle) {
      id
      handle
      title
      products(first: $first, after: $after) {
        pageInfo {
          hasNextPage
          endCursor
        }
        edges {
          node {
            id
            handle
            title
            vendor
            productType
            tags
            description
            availableForSale
            featuredImage {
              url
              altText
            }
            priceRange {
              minVariantPrice {
                amount
                currencyCode
              }
            }
            onlineStoreUrl
          }
        }
      }
    }
  }
`;

type GqlCollectionResponse = {
  data?: {
    collection?: {
      id: string;
      handle: string;
      title: string;
      products: {
        pageInfo: { hasNextPage: boolean; endCursor?: string | null };
        edges: { node: ShopifyStorefrontProduct }[];
      };
    } | null;
  };
  errors?: { message: string }[];
};

async function storefrontFetch(
  config: StorefrontConfig,
  query: string,
  variables: Record<string, unknown>
): Promise<GqlCollectionResponse> {
  const url = `https://${config.domain}/api/${config.apiVersion}/graphql.json`;
  const res = await fetch(url, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "X-Shopify-Storefront-Access-Token": config.token,
    },
    body: JSON.stringify({ query, variables }),
    next: { revalidate: 300 },
  });
  if (!res.ok) {
    throw new Error(`Storefront HTTP ${res.status}`);
  }
  return (await res.json()) as GqlCollectionResponse;
}

/** Fetch all products in a collection (paginated). */
export async function fetchCollectionProducts(
  handle: string = FEATURED_PARTS_COLLECTION,
  opts?: { pageSize?: number; maxPages?: number }
): Promise<FeaturedPartsFetchResult> {
  const config = getShopifyStorefrontConfig();
  if (!config) {
    return {
      ok: false,
      configured: false,
      collectionHandle: handle,
      products: [],
      error:
        "Shopify Storefront nicht konfiguriert (SHOPIFY_STOREFRONT_ACCESS_TOKEN).",
      code: "not_configured",
    };
  }

  const pageSize = opts?.pageSize ?? 50;
  const maxPages = opts?.maxPages ?? 4;
  const products: ShopifyStorefrontProduct[] = [];
  let after: string | null = null;
  let collectionTitle = handle;

  try {
    for (let page = 0; page < maxPages; page++) {
      const json = await storefrontFetch(config, COLLECTION_PRODUCTS_QUERY, {
        handle,
        first: pageSize,
        after,
      });

      if (json.errors?.length) {
        return {
          ok: false,
          configured: true,
          collectionHandle: handle,
          products: [],
          error: json.errors.map((e) => e.message).join("; "),
          code: "graphql_error",
        };
      }

      const collection = json.data?.collection;
      if (!collection) {
        return {
          ok: false,
          configured: true,
          collectionHandle: handle,
          products: [],
          error: `Collection „${handle}“ nicht gefunden.`,
          code: "collection_missing",
        };
      }

      collectionTitle = collection.title;
      for (const edge of collection.products.edges) {
        products.push(edge.node);
      }

      if (!collection.products.pageInfo.hasNextPage) break;
      after = collection.products.pageInfo.endCursor ?? null;
      if (!after) break;
    }

    return {
      ok: true,
      configured: true,
      collectionHandle: handle,
      collectionTitle,
      products,
      source: "storefront",
    };
  } catch (err) {
    const message = err instanceof Error ? err.message : "Storefront-Fehler";
    return {
      ok: false,
      configured: true,
      collectionHandle: handle,
      products: [],
      error: message,
      code: message.startsWith("Storefront HTTP") ? "http_error" : "graphql_error",
    };
  }
}

export function shopifyStoreProductUrl(handle: string): string {
  return `${SHOPIFY_STORE_BASE}/products/${handle}`;
}
