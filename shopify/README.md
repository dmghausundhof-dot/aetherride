# FlowLine Shopify theme (Dawn)

Storefront for **dmg-haus-und-hof-shop**. Look: Hof-adjacent (dark ground, steel hairline, mint) — orange stays the ride CTA in the app, not shop chrome.

Theme path: `shopify/theme` (Dawn via `shopify theme init --clone-url=https://github.com/Shopify/dawn.git`).

## Preview

```bash
cd shopify/theme
shopify theme dev --store dmg-haus-und-hof-shop.myshopify.com --environment aetherride
```

First run opens Shopify login in the browser. After that, CLI prints:

- local preview (`http://127.0.0.1:9292`)
- theme editor link
- shareable preview link

Password-protected storefront:

```bash
shopify theme dev --store dmg-haus-und-hof-shop.myshopify.com --environment aetherride --store-password "$SHOPIFY_STOREFRONT_PASSWORD"
```

Do not put the storefront password in `NEXT_PUBLIC_*` or the Flutter app.

## Push (unpublished development theme)

```bash
cd shopify/theme
shopify theme push --store dmg-haus-und-hof-shop.myshopify.com --unpublished --environment aetherride
```

Live publish is intentional and separate (`shopify theme publish`). Do not run it from this README.

## Check

```bash
cd shopify/theme
shopify theme check
```

## App gateway URLs

Flutter Shop tab opens Custom Tabs:

- Home: `SHOPIFY_STOREFRONT_URL/`
- Für dein Rad: `/collections/featured-parts/{handleized-tags}` (e.g. `category-gravel+wheel-700c`)
- Merchandise: `/collections/merchandise` (never fit-filtered)

Garage-bike DRAFT products (`tag:garage-bike`, handle `ar-garage-*`) are hidden on the storefront.
