# Shop Flow Web + App v1 (S-FLOW)

Unified **Web + App → Shopify** flow. Collection-driven (`featured-parts`), no dead links, no silent password walls.

Companion: `shop-parts-wire-v1.md` (S-PART soft-fit tags & Storefront rules).

## Recommendation

Primary catalog = **Storefront API in AetherRide** (`/shop`, `/shop/parts`, `/shop/p/[handle]`).  
External Online Store only as explicit Owner Preview while locked. Never ship storefront password to clients.

---

## Tickets

### S-FLOW-01 — Canonical routes & aliases

| Path | Behavior |
|------|----------|
| `/shop` | Hub — parts preview, live featured bikes (Storefront-confirmed only) |
| `/shop/parts` | `featured-parts` listing + soft-fit |
| `/shop/p/<handle>` | Live product; missing/404 → `/shop/parts` |
| `/teile`, `/teile/*` | redirect → `/shop/parts` |
| `/parts`, `/parts/*` | redirect → `/shop/parts` |
| App tab **Teile** | In-app Storefront grid + bridge to Web hub/parts/product |
| `aetherride://shop` · `://teile` · `://parts` | App → Shop tab (index 4) |

Pages must render designed UI (never blank 404 for `/shop` / `/shop/parts`).

### S-FLOW-02 — Password / empty / error states

- `SHOPIFY_ONLINE_STORE_LOCKED` (default true) → banner + Owner-Preview dialog before myshopify.
- Empty collection / missing token → designed empty + retry + “Im Browser öffnen”.
- Unpublished handles → omit cards / redirect to collection (no dead product CTAs).
- Password never in `NEXT_PUBLIC_*`, App bundle, or API JSON.

### S-FLOW-03 — App ↔ Web bridge (one flow)

| Surface | Opens |
|---------|--------|
| App product tap | `{API_BASE}/shop/p/<handle>` |
| App **Web · Parts** | `{API_BASE}/shop/parts?bike=<id>&fit=bike[&slot=]` |
| App **Shop-Hub** | `{API_BASE}/shop` |
| App Garage → Shop | Web parts with `bike=` (+ slot when known), not a dead tab |
| Web nav **Teile** | `/shop` |
| Garage CTA | `/shop/parts?bike=<id>&fit=bike` |

Same collection, same soft-fit query contract on Web; App lists Storefront JSON and deep-links into Web for full Soft-Fit ranking.

### S-FLOW-04 — Dealer / „Zum Händler“ CTAs

- Real **product** or **product-search** URLs only.
- Never bare merchant homepages.
- Omit CTA when URL unknown or not deep enough.
- Shopify product URLs OK when deep (`/products/<handle>`); locked store → Owner Preview, not silent `/password`.

### S-FLOW-05 — Soft-fit + Garage continuity

- Query: `slot`, `bike`, `fit=bike|all`, `focus`.
- Web Garage / Home wear alerts → `/shop/parts?slot=…&bike=…&fit=bike`.
- App Garage maintenance Shop → same Web URL pattern with bike (+ mapped slot when possible).
- Tags contract unchanged (see S-PART): `slot:*`, `magura_shape`, `pad:shape-*`, `caliper:mt*`, `size`, `shift_compat`.

---

## Env

```
SHOPIFY_STOREFRONT_ACCESS_TOKEN=
SHOPIFY_STORE_DOMAIN=dmg-haus-und-hof-shop.myshopify.com
SHOPIFY_ONLINE_STORE_LOCKED=true
```

When store goes public: `SHOPIFY_ONLINE_STORE_LOCKED=false`; keep in-app catalog primary.
