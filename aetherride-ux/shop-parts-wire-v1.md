# Shop Parts Wire v1 (S-PART) + Shopify Integration Audit

Collection-driven Ersatzteile — **keine** hard-coded Produkt-Snapshots.
**Keine** stillen Links auf die Shopify-Passwort-Seite.

Unified Web+App flow tickets: see `shop-flow-web-app-v1.md` (S-FLOW-01…05).

## Recommendation (beste Shopify Integration)

**Prefer Storefront API in-app/web catalog** (`/shop`, `/shop/parts`, `/shop/p/[handle]`) over sending riders to the password-gated Online Store.

| Path | Why |
|------|-----|
| **Storefront API (chosen)** | Catalog, images, prices, tags/soft-fit without `/password`. Token server-side only. Demo-ready while store stays locked. |
| External Online Store | Hits `/password` until launch — only as explicit Owner Preview, never primary CTA. |
| Storefront password in client | **Forbidden** — never `NEXT_PUBLIC_*`, never API payload. Optional Eng-only `SHOPIFY_STOREFRONT_PASSWORD` for server smoke scripts. |

When the store goes public: set `SHOPIFY_ONLINE_STORE_LOCKED=false` and keep in-app catalog as primary; external checkout becomes secondary.

## Valid link paths (fixed)

| Path | Destination |
|------|-------------|
| `/shop` | Hub — Collection preview (featured-parts) |
| `/shop/parts` | featured-parts listing (Storefront API) |
| `/teile`, `/teile/*` | redirect → `/shop/parts` |
| `/parts`, `/parts/*` | redirect → `/shop/parts` |
| `/shop/parts?slot=brake_pads&fit=bike&bike=<id>` | Soft-fit filtered parts |
| `/shop/p/<handle>` | Live Storefront product only; unpublished → `/shop/parts` |
| `/api/shop/parts` | JSON collection |
| `/api/shop/products/<handle>` | JSON product (409 unpublished → redirectTo parts) |
| `/api/shop/status` | `{ storefrontApiConfigured, onlineStoreLocked }` — no secrets |
| App Shop tab → Web Parts | `{API_BASE}/shop/parts` |
| App product tap | `{API_BASE}/shop/p/<handle>` (live only) |
| App Shop hub button | `{API_BASE}/shop` |

### Unpublished Phase-A bike handles (never link as live products)

`orbea-terra-m20`, `specialized-diverge-carbon`, `cube-attain-gtc-race`,
`canyon-ultimate-cf-sl-8`, `canyon-commuter-7-0` → CTA `/shop/parts` only.

### Removed as primary CTAs (password wall / 404)

| Old | Now |
|-----|-----|
| `*.myshopify.com/products/<unpublished>` | Hidden / → `/shop/parts` |
| `*.myshopify.com/collections/featured-*` | In-app `/shop/parts` |
| Bare merchant homepages | Deep product/search URLs |
| Silent `target=_blank` to password | `ShopifyOutboundButton` / App dialog |

## Env

- `SHOPIFY_STOREFRONT_ACCESS_TOKEN` (required for live products)
- `SHOPIFY_STORE_DOMAIN` (optional)
- `SHOPIFY_STOREFRONT_API_VERSION` (optional, default `2025-01`)
- `SHOPIFY_ONLINE_STORE_LOCKED` (default `true`)
- `SHOPIFY_STOREFRONT_PASSWORD` (optional Eng smoke, server-only)

## Soft-fit + Garage-Fit filter contract

Unchanged soft-fit tags: `slot`, `bike`, `fit`, tags `magura_shape`, `pad:shape-*`, `caliper:mt*`, `size`, `shift_compat`.

Garage-Fit (Teileshop passt zur Garage) — nur echte Felder, keine OEM-SKUs:

| Quelle | Felder |
|--------|--------|
| Bike | Kategorie, Laufradgröße, E-Bike-Flag, Schaltungsfamilie aus verbauten Teilen |
| Produkt | Tags `category:` / `sport:` / `wheel:` / `ebike` / `shift_compat:` plus Titel-Heuristik (z. B. `29×`, `40-622`) |

- Leere Garage → alle Teile + Banner „Bike anlegen“
- Mit Bikes → default `fit=bike` (Union), Chip pro Bike, Toggle „Nur passende Teile“
- Label nur bei nachgewiesenem Match: `passt zu Canyon Grizl · 700c · Gravel`

## Garage CTA

**Passt zu deinem Bike** → `/shop/parts?bike=<id>&fit=bike`
