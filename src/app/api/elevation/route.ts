import { NextResponse } from "next/server";
import { buildElevationFromTrack } from "@/lib/routing/elevationProfile";

/**
 * Elevation lookup via Open-Elevation (public API) or passthrough track elev.
 * POST { locations: [{lat,lng}] } or { track: [{lat,lng,elev?}] }
 */
export async function POST(req: Request) {
  try {
    const body = await req.json();
    const track = Array.isArray(body.track) ? body.track : null;
    const locations = Array.isArray(body.locations) ? body.locations : null;

    if (track?.length) {
      const hasElev = track.some(
        (p: { elev?: number }) => p.elev != null && Number.isFinite(p.elev)
      );
      if (hasElev) {
        return NextResponse.json(buildElevationFromTrack(track, "track"));
      }
    }

    const pts = (track || locations || []) as { lat: number; lng: number }[];
    if (pts.length < 2) {
      return NextResponse.json({ error: "need track or locations" }, { status: 400 });
    }

    // Sample every nth point to stay within public API limits
    const step = Math.max(1, Math.floor(pts.length / 80));
    const sample = pts.filter((_, i) => i % step === 0 || i === pts.length - 1);

    const { fetchGoogleElevation, isGoogleConfigured } = await import(
      "@/lib/coverage/google"
    );
    if (isGoogleConfigured()) {
      const g = await fetchGoogleElevation({ points: sample });
      if (g.ok && g.points.length >= 2) {
        return NextResponse.json({
          ...buildElevationFromTrack(g.points, "api"),
          provider: "google_elevation",
        });
      }
    }

    const res = await fetch("https://api.open-elevation.com/api/v1/lookup", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        locations: sample.map((p) => ({ latitude: p.lat, longitude: p.lng })),
      }),
    });

    if (!res.ok) {
      return NextResponse.json(
        { error: "elevation_upstream", status: res.status },
        { status: 502 }
      );
    }

    const data = await res.json();
    const results = data.results || [];
    const enriched = sample.map((p, i) => ({
      lat: p.lat,
      lng: p.lng,
      elev: results[i]?.elevation ?? null,
    }));

    return NextResponse.json({
      ...buildElevationFromTrack(enriched, "api"),
      provider: "open-elevation",
    });
  } catch (e) {
    return NextResponse.json(
      { error: e instanceof Error ? e.message : "elevation failed" },
      { status: 500 }
    );
  }
}
