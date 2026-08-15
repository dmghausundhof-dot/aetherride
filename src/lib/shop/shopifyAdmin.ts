/**
 * Shopify Admin GraphQL — Garage-Bike upsert (kein Storefront-Token).
 * Merchant-owned Metafields (`aetherride`), nicht $app (keine Shopify-App-TOML).
 *
 * Docs: https://shopify.dev/docs/api/admin-graphql/latest/mutations/productSet
 *       https://shopify.dev/docs/api/admin-graphql/latest/mutations/metafieldsSet
 */

export const SHOPIFY_ADMIN_API_VERSION_DEFAULT = "2025-01";

export type ShopifyAdminConfig = {
  domain: string;
  token: string;
  apiVersion: string;
};

export function getShopifyAdminConfig(): ShopifyAdminConfig | null {
  const token = (
    process.env.SHOPIFY_ADMIN_ACCESS_TOKEN ||
    process.env.SHOPIFY_ADMIN_API_TOKEN ||
    process.env.SHOPIFY_ADMIN_TOKEN ||
    ""
  ).trim();
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
    process.env.SHOPIFY_ADMIN_API_VERSION || SHOPIFY_ADMIN_API_VERSION_DEFAULT
  ).trim();
  return { domain, token, apiVersion };
}

export function isShopifyAdminConfigured(): boolean {
  return getShopifyAdminConfig() != null;
}

export const PRODUCT_BY_HANDLE_QUERY = /* GraphQL */ `
  query GarageBikeByHandle($query: String!) {
    products(first: 1, query: $query) {
      edges {
        node {
          id
          handle
          status
          tags
        }
      }
    }
  }
`;

export const PRODUCT_SET_MUTATION = /* GraphQL */ `
  mutation UpsertGarageBike(
    $identifier: ProductSetIdentifiers
    $input: ProductSetInput!
  ) {
    productSet(identifier: $identifier, input: $input, synchronous: true) {
      product {
        id
        handle
        status
        tags
      }
      userErrors {
        field
        message
      }
    }
  }
`;

export const METAFIELDS_SET_MUTATION = /* GraphQL */ `
  mutation SetGarageBikeMetafields($metafields: [MetafieldsSetInput!]!) {
    metafieldsSet(metafields: $metafields) {
      metafields {
        id
        key
        namespace
      }
      userErrors {
        field
        message
      }
    }
  }
`;

type GqlError = { message: string };

export type AdminGqlResult<T> = {
  data?: T;
  errors?: GqlError[];
};

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

export async function shopifyAdminGraphql<T>(
  query: string,
  variables: Record<string, unknown>,
  config: ShopifyAdminConfig = getShopifyAdminConfig()!
): Promise<AdminGqlResult<T>> {
  const url = `https://${config.domain}/admin/api/${config.apiVersion}/graphql.json`;
  let lastStatus = 0;
  for (let attempt = 0; attempt < 3; attempt++) {
    const res = await fetch(url, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-Shopify-Access-Token": config.token,
      },
      body: JSON.stringify({ query, variables }),
    });
    lastStatus = res.status;
    if (res.status === 429 || res.status >= 500) {
      await sleep(400 * 2 ** attempt);
      continue;
    }
    if (!res.ok) {
      const text = await res.text();
      throw new Error(`Shopify Admin HTTP ${res.status}: ${text.slice(0, 240)}`);
    }
    return (await res.json()) as AdminGqlResult<T>;
  }
  throw new Error(`Shopify Admin HTTP ${lastStatus} nach Retries`);
}

export type AdminProductRef = {
  id: string;
  handle: string;
  status?: string;
  tags?: string[];
};

export async function findProductByHandle(
  handle: string,
  config?: ShopifyAdminConfig
): Promise<AdminProductRef | null> {
  const cfg = config ?? getShopifyAdminConfig();
  if (!cfg) return null;
  const json = await shopifyAdminGraphql<{
    products?: {
      edges?: { node: AdminProductRef }[];
    };
  }>(PRODUCT_BY_HANDLE_QUERY, { query: `handle:${handle}` }, cfg);
  if (json.errors?.length) {
    throw new Error(json.errors.map((e) => e.message).join("; "));
  }
  return json.data?.products?.edges?.[0]?.node ?? null;
}

export type ProductSetInput = {
  title: string;
  handle: string;
  descriptionHtml: string;
  vendor: string;
  productType: string;
  status: "DRAFT";
  tags: string[];
  productOptions?: { name: string; values: { name: string }[] }[];
  variants?: {
    sku: string;
    price: string;
    optionValues: { optionName: string; name: string }[];
    inventoryPolicy?: "DENY";
  }[];
};

export async function upsertProductByHandle(opts: {
  handle: string;
  input: ProductSetInput;
  includeVariants: boolean;
  config?: ShopifyAdminConfig;
}): Promise<AdminProductRef> {
  const cfg = opts.config ?? getShopifyAdminConfig();
  if (!cfg) {
    throw new Error("Shop nicht verbunden");
  }
  const input: ProductSetInput = { ...opts.input };
  if (!opts.includeVariants) {
    delete input.productOptions;
    delete input.variants;
  }
  const json = await shopifyAdminGraphql<{
    productSet?: {
      product?: AdminProductRef | null;
      userErrors?: { field?: string[]; message: string }[];
    };
  }>(
    PRODUCT_SET_MUTATION,
    {
      identifier: { handle: opts.handle },
      input,
    },
    cfg
  );
  if (json.errors?.length) {
    throw new Error(json.errors.map((e) => e.message).join("; "));
  }
  const payload = json.data?.productSet;
  const userErrors = payload?.userErrors ?? [];
  if (userErrors.length) {
    throw new Error(userErrors.map((e) => e.message).join("; "));
  }
  const product = payload?.product;
  if (!product?.id) {
    throw new Error("Shopify productSet lieferte kein Produkt");
  }
  return product;
}

export async function setGarageBikeMetafields(opts: {
  productId: string;
  bikeId: string;
  fitJson: string;
  config?: ShopifyAdminConfig;
}): Promise<void> {
  const cfg = opts.config ?? getShopifyAdminConfig();
  if (!cfg) throw new Error("Shop nicht verbunden");
  const json = await shopifyAdminGraphql<{
    metafieldsSet?: {
      userErrors?: { message: string }[];
    };
  }>(
    METAFIELDS_SET_MUTATION,
    {
      metafields: [
        {
          ownerId: opts.productId,
          namespace: "aetherride",
          key: "garage_bike_id",
          type: "single_line_text_field",
          value: opts.bikeId,
        },
        {
          ownerId: opts.productId,
          namespace: "aetherride",
          key: "fit",
          type: "json",
          value: opts.fitJson,
        },
      ],
    },
    cfg
  );
  if (json.errors?.length) {
    throw new Error(json.errors.map((e) => e.message).join("; "));
  }
  const userErrors = json.data?.metafieldsSet?.userErrors ?? [];
  if (userErrors.length) {
    throw new Error(userErrors.map((e) => e.message).join("; "));
  }
}
