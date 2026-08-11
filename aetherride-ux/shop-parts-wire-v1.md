# Shop Parts Wire v1 (S-PART)

Collection-driven Ersatzteile — **keine** hard-coded Produkt-Snapshots.

## Routes

| Route | Role |
|-------|------|
| `/shop` | Hub: Featured Bikes + CTA → Parts |
| `/shop/parts` | Listing aus Shopify Collection `featured-parts` |
| `GET /api/shop/parts` | Storefront API Proxy (Token serverseitig) |

## Env

- `SHOPIFY_STOREFRONT_ACCESS_TOKEN` (required for live products)
- `SHOPIFY_STORE_DOMAIN` (optional, default `dmg-haus-und-hof-shop.myshopify.com`)
- `SHOPIFY_STOREFRONT_API_VERSION` (optional, default `2025-01`)

**Do not** store or push the Online Store password.

## Filter contract (unchanged)

Query params on `/shop/parts`:

| Param | Values | Notes |
|-------|--------|-------|
| `slot` | `all` \| `brake_pads` \| `grips` \| `fluid` \| `chain` \| `tire` \| `cassette` \| `bar_tape` | Legacy `brake_pads_front/rear` → `brake_pads` |
| `bike` | bike id | Garage context |
| `fit` | `bike` \| `all` | Soft-Fit gegen aktives Bike |
| `focus` | product handle | Scroll/highlight |

### Soft-fit product tags

- `slot:<key>`
- `magura_shape:7\|8`
- `pad:shape-7\|8`
- `caliper:mt*` / `caliper:mt5` / `caliper:mt7`
- `size:S\|L`
- `shift_compat:<token>`

Soft: Produkte ohne relevantes Soft-Fit-Tag bleiben sichtbar. Bei `fit=bike` werden klare Widersprüche ausgeblendet.

## Garage CTA

Label: **Passt zu deinem Bike** → `/shop/parts?bike=<id>&fit=bike`  
Ohne Bike: skip-friendly → `/shop/parts`
