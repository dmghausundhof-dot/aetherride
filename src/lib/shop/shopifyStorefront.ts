/**
 * Shopify Storefront API client — Collection-driven Parts (featured-parts).
 * Token bleibt serverseitig (SHOPIFY_STOREFRONT_ACCESS_TOKEN).
 * Kein Storefront-Passwort in Code oder Env der App.
 */

import { SHOPIFY_STORE_BASE } from "@/lib/shop/catalog";

export const FEATURED_PARTS_COLLECTION = "featured-parts";
export const MERCHANDISE_COLLECTION = "merchandise";

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
    products?: {
      pageInfo: { hasNextPage: boolean; endCursor?: string | null };
      edges: { node: ShopifyStorefrontProduct }[];
    };
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

const PRODUCTS_BY_QUERY = /* GraphQL */ `
  query ShopProducts($query: String!, $first: Int!, $after: String) {
    products(first: $first, after: $after, query: $query) {
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
`;

export type ProductsQueryResult =
  | {
      ok: true;
      configured: true;
      products: ShopifyStorefrontProduct[];
    }
  | {
      ok: false;
      configured: boolean;
      products: [];
      error: string;
      code: "not_configured" | "http_error" | "graphql_error";
    };

/** Storefront product search (z. B. tag:merch). */
export async function fetchProductsByQuery(
  query: string,
  opts?: { pageSize?: number; maxPages?: number }
): Promise<ProductsQueryResult> {
  const config = getShopifyStorefrontConfig();
  if (!config) {
    return {
      ok: false,
      configured: false,
      products: [],
      error: "Shopify Storefront nicht konfiguriert (SHOPIFY_STOREFRONT_ACCESS_TOKEN).",
      code: "not_configured",
    };
  }
  const pageSize = opts?.pageSize ?? 50;
  const maxPages = opts?.maxPages ?? 3;
  const products: ShopifyStorefrontProduct[] = [];
  let after: string | null = null;
  try {
    for (let page = 0; page < maxPages; page++) {
      const json = await storefrontFetch(config, PRODUCTS_BY_QUERY, {
        query,
        first: pageSize,
        after,
      });
      if (json.errors?.length) {
        return {
          ok: false,
          configured: true,
          products: [],
          error: json.errors.map((e) => e.message).join("; "),
          code: "graphql_error",
        };
      }
      const conn = json.data?.products;
      if (!conn) break;
      for (const edge of conn.edges) products.push(edge.node);
      if (!conn.pageInfo.hasNextPage) break;
      after = conn.pageInfo.endCursor ?? null;
      if (!after) break;
    }
    return { ok: true, configured: true, products };
  } catch (err) {
    const message = err instanceof Error ? err.message : "Storefront-Fehler";
    return {
      ok: false,
      configured: true,
      products: [],
      error: message,
      code: message.startsWith("Storefront HTTP") ? "http_error" : "graphql_error",
    };
  }
}

const PRODUCT_BY_HANDLE_QUERY = /* GraphQL */ `
  query ProductByHandle($handle: String!) {
    product(handle: $handle) {
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
`;

export type ProductByHandleResult =
  | { ok: true; product: ShopifyStorefrontProduct }
  | {
      ok: false;
      configured: boolean;
      error: string;
      code: "not_configured" | "not_found" | "http_error" | "graphql_error";
    };

export async function fetchProductByHandle(
  handle: string
): Promise<ProductByHandleResult> {
  const config = getShopifyStorefrontConfig();
  if (!config) {
    return {
      ok: false,
      configured: false,
      error: "Shopify Storefront nicht konfiguriert.",
      code: "not_configured",
    };
  }
  try {
    const url = `https://${config.domain}/api/${config.apiVersion}/graphql.json`;
    const res = await fetch(url, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-Shopify-Storefront-Access-Token": config.token,
      },
      body: JSON.stringify({
        query: PRODUCT_BY_HANDLE_QUERY,
        variables: { handle },
      }),
      next: { revalidate: 300 },
    });
    if (!res.ok) {
      return {
        ok: false,
        configured: true,
        error: `Storefront HTTP ${res.status}`,
        code: "http_error",
      };
    }
    const json = (await res.json()) as {
      data?: { product?: ShopifyStorefrontProduct | null };
      errors?: { message: string }[];
    };
    if (json.errors?.length) {
      return {
        ok: false,
        configured: true,
        error: json.errors.map((e) => e.message).join("; "),
        code: "graphql_error",
      };
    }
    const product = json.data?.product;
    if (!product) {
      return {
        ok: false,
        configured: true,
        error: `Produkt „${handle}“ nicht gefunden.`,
        code: "not_found",
      };
    }
    return { ok: true, product };
  } catch (err) {
    return {
      ok: false,
      configured: true,
      error: err instanceof Error ? err.message : "Storefront-Fehler",
      code: "graphql_error",
    };
  }
}
