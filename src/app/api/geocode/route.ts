import { NextResponse } from "next/server";
import { chromeLangFrom } from "@/lib/i18n/chromeLang";

export type GeocodeHit = {
  label: string;
  lat: number;
  lng: number;
  kind?: string;
};

/**
 * Adress-/Ortssuche via Photon (OSM/Komoot) — kein Fake.
 * GET /api/geocode?q=Freiburg Bahnhof&limit=5
 */
export async function GET(req: Request) {
  const url = new URL(req.url);
  const q = (url.searchParams.get("q") ?? "").trim();
  const limit = Math.min(
    8,
    Math.max(1, Number(url.searchParams.get("limit") ?? 5) || 5)
  );

  const lang = chromeLangFrom(url.searchParams.get("lang"));

  if (q.length < 2) {
    return NextResponse.json({
      hits: [] as GeocodeHit[],
      attribution: "© OpenStreetMap · Photon",
      message:
        lang === "en"
          ? "At least 2 characters."
          : lang === "fr"
            ? "Au moins 2 caractères."
            : lang === "it"
              ? "Almeno 2 caratteri."
              : "Mindestens 2 Zeichen.",
    });
  }

  try {
    const photon = new URL("https://photon.komoot.io/api/");
    photon.searchParams.set("q", q);
    photon.searchParams.set("lang", lang);
    photon.searchParams.set("limit", String(limit));
    // DACH bias (override with lat/lon near user)
    const biasLat = url.searchParams.get("lat") ?? "48.0";
    const biasLon =
      url.searchParams.get("lon") ?? url.searchParams.get("lng") ?? "10.0";
    photon.searchParams.set("lat", biasLat);
    photon.searchParams.set("lon", biasLon);

    const res = await fetch(photon.toString(), {
      headers: {
        Accept: "application/json",
        "User-Agent": "FlowLine/1.0 (geocode; contact@aetherride.local)",
      },
      next: { revalidate: 3600 },
    });

    if (!res.ok) {
      const { fetchGoogleGeocode } = await import("@/lib/coverage/google");
      const g = await fetchGoogleGeocode({
        q,
        lat: Number(biasLat),
        lng: Number(biasLon),
        limit,
        language: lang,
      });
      if (g.hits.length > 0) {
        return NextResponse.json({
          hits: g.hits.map((h) => ({
            label: h.label,
            lat: h.lat,
            lng: h.lng,
            kind: h.kind,
          })),
          attribution: "Powered by Google",
          query: q,
          provider: "google_geocoding",
          warning: `Photon ${res.status}`,
        });
      }
      return NextResponse.json(
        {
          hits: [],
          attribution: "© OpenStreetMap · Photon",
          error: `Photon ${res.status}`,
        },
        { status: 502 }
      );
    }

    const data = (await res.json()) as {
      features?: Array<{
        geometry?: { coordinates?: number[] };
        properties?: Record<string, unknown>;
      }>;
    };

    const hits: GeocodeHit[] = [];
    for (const f of data.features ?? []) {
      const coords = f.geometry?.coordinates;
      if (!coords || coords.length < 2) continue;
      const p = f.properties ?? {};
      const parts = [
        p.name,
        p.street,
        p.housenumber,
        p.postcode,
        p.city ?? p.town ?? p.village ?? p.county,
        p.state,
        p.country,
      ]
        .map((x) => (typeof x === "string" ? x.trim() : ""))
        .filter(Boolean);
      const label = [...new Set(parts)].join(", ");
      if (!label) continue;
      hits.push({
        label,
        lng: coords[0],
        lat: coords[1],
        kind: typeof p.type === "string" ? p.type : undefined,
      });
    }

    if (hits.length > 0) {
      return NextResponse.json({
        hits,
        attribution: "© OpenStreetMap contributors · Photon (Komoot)",
        query: q,
        provider: "photon",
      });
    }

    const { fetchGoogleGeocode } = await import("@/lib/coverage/google");
    const g = await fetchGoogleGeocode({
      q,
      lat: Number(biasLat),
      lng: Number(biasLon),
      limit,
      language: lang,
    });
    if (g.hits.length > 0) {
      return NextResponse.json({
        hits: g.hits.map((h) => ({
          label: h.label,
          lat: h.lat,
          lng: h.lng,
          kind: h.kind,
        })),
        attribution: "Powered by Google",
        query: q,
        provider: "google_geocoding",
      });
    }

    return NextResponse.json({
      hits: [],
      attribution: "© OpenStreetMap contributors · Photon (Komoot)",
      query: q,
      provider: "photon",
      warning: g.warning,
    });
  } catch (e) {
    return NextResponse.json(
      {
        hits: [],
        attribution: "© OpenStreetMap · Photon",
        error: e instanceof Error ? e.message : "geocode failed",
      },
      { status: 502 }
    );
  }
}
