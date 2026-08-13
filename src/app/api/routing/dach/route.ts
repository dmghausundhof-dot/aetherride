import { NextResponse } from "next/server";
import {
  DACH_REGIONS,
  dachCoverageStats,
} from "@/lib/coverage/dachRegions";
import {
  configuredEngineForProfile,
  configuredRoutingEngine,
  isLiveRoutingConfigured,
} from "@/lib/routing/engine";
import { isOrsConfigured, orsProfileFor } from "@/lib/routing/openRouteService";
import type { RoutingProfile } from "@/lib/routing/profiles";

const PROFILES: RoutingProfile[] = [
  "road",
  "gravel",
  "mtb_enduro",
  "mtb_allmountain",
  "urban",
  "ebike",
  "emtb",
  "hiking",
];

/**
 * GET /api/routing/dach
 * Named DACH coverage (packs + envelopes) + which engine serves each profile.
 * No upstream ORS calls — metadata only.
 */
export async function GET() {
  const stats = dachCoverageStats();
  return NextResponse.json({
    ok: stats.missingProbes.length === 0,
    liveConfigured: isLiveRoutingConfigured(),
    primaryEngine: configuredRoutingEngine(),
    openrouteservice: {
      configured: isOrsConfigured(),
      role: "dach_cycling",
      attribution: "Directions © openrouteservice.org by HeiGIT",
    },
    profiles: Object.fromEntries(
      PROFILES.map((p) => [
        p,
        {
          engine: configuredEngineForProfile(p),
          orsProfile: orsProfileFor(p),
        },
      ])
    ),
    coverage: stats,
    regions: DACH_REGIONS.map((r) => ({
      id: r.id,
      name: r.name,
      country: r.country,
      kind: r.kind,
      bbox: r.bbox,
      center: r.center,
      sports: r.sports ?? [],
    })),
    attribution: [
      "© OpenStreetMap Mitwirkende",
      "Directions © openrouteservice.org by HeiGIT — when ORS key is set",
    ],
  });
}
