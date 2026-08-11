import { NextResponse } from "next/server";
import {
  configuredRoutingEngine,
  isLiveRoutingConfigured,
  isUsingPublicOsrm,
} from "@/lib/routing/engine";
import { hasStoreLinks, siteOrigin, ANDROID_PACKAGE } from "@/lib/web/appLinks";

/**
 * GET /api/ops/env-check
 * Keine Secrets — nur booleans / Status für Ops & Smoke.
 */
function set(name: string): boolean {
  const v = process.env[name];
  return Boolean(v && String(v).trim().length > 0);
}

export async function GET() {
  const supabase = set("NEXT_PUBLIC_SUPABASE_URL") && set("NEXT_PUBLIC_SUPABASE_ANON_KEY");
  const routingLive = isLiveRoutingConfigured();
  const engine = configuredRoutingEngine();

  const checks = {
    appUrl: set("NEXT_PUBLIC_APP_URL") || set("NEXT_PUBLIC_SITE_URL"),
    siteOrigin: siteOrigin() || null,
    supabasePublic: supabase,
    supabaseServiceRole: set("SUPABASE_SERVICE_ROLE_KEY"),
    stripe: set("STRIPE_SECRET_KEY") && set("STRIPE_WEBHOOK_SECRET"),
    stripePublishable: set("NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY"),
    xai: set("XAI_API_KEY"),
    routing: {
      engine,
      liveConfigured: routingLive,
      publicOsrm: isUsingPublicOsrm(),
      graphhopperKey: set("GRAPHHOPPER_API_KEY"),
      valhallaUrl: set("VALHALLA_URL"),
      osrmUrl: set("OSRM_URL"),
      routingLiveFlag: set("NEXT_PUBLIC_ROUTING_LIVE"),
    },
    stores: {
      hasLinks: hasStoreLinks(),
      appStore: set("NEXT_PUBLIC_APP_STORE_URL"),
      playStore: set("NEXT_PUBLIC_PLAY_STORE_URL"),
    },
    appLinks: {
      iosTeamId: set("NEXT_PUBLIC_IOS_TEAM_ID"),
      androidPackage: ANDROID_PACKAGE,
      androidSha256: set("NEXT_PUBLIC_ANDROID_SHA256_FINGERPRINTS") ||
        set("ANDROID_SHA256_FINGERPRINTS"),
    },
    legal: {
      imprint: set("NEXT_PUBLIC_LEGAL_IMPRINT"),
      email: set("NEXT_PUBLIC_LEGAL_EMAIL"),
    },
    partners: {
      outdooractive: set("OUTDOORACTIVE_API_KEY"),
      mapillary: set("MAPILLARY_ACCESS_TOKEN"),
      strava: set("STRAVA_CLIENT_ID") && set("STRAVA_CLIENT_SECRET"),
      stadia: set("STADIA_API_KEY") || set("NEXT_PUBLIC_STADIA_API_KEY"),
      shopifyStorefront: set("SHOPIFY_STOREFRONT_ACCESS_TOKEN"),
    },
  };

  const criticalOk =
    checks.supabasePublic &&
    checks.routing.liveConfigured &&
    (checks.appUrl || process.env.VERCEL_URL);

  return NextResponse.json({
    ok: criticalOk,
    service: "aetherride-env-check",
    vercel: Boolean(process.env.VERCEL),
    nodeEnv: process.env.NODE_ENV,
    checks,
    hints: [
      !checks.supabasePublic && "NEXT_PUBLIC_SUPABASE_* setzen",
      !checks.routing.liveConfigured &&
        "GRAPHHOPPER_API_KEY oder VALHALLA_URL/OSRM_URL setzen",
      checks.routing.publicOsrm &&
        "Prod: ALLOW_PUBLIC_OSRM=false + eigenen Engine-Key",
      !checks.stores.hasLinks && "Store-URLs optional bis Release",
      !checks.appLinks.androidSha256 &&
        "App Links: NEXT_PUBLIC_ANDROID_SHA256_FINGERPRINTS",
      !checks.appLinks.iosTeamId && "Universal Links: NEXT_PUBLIC_IOS_TEAM_ID",
      !checks.stripe && "Billing: Stripe Keys + Webhook",
      !checks.partners.shopifyStorefront &&
        "Shop Parts: SHOPIFY_STOREFRONT_ACCESS_TOKEN (featured-parts)",
    ].filter(Boolean),
  });
}
