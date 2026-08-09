import { NextResponse } from "next/server";

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

  if (q.length < 2) {
    return NextResponse.json({
      hits: [] as GeocodeHit[],
      attribution: "© OpenStreetMap · Photon",
      message: "Mindestens 2 Zeichen.",
    });
  }

  try {
    const photon = new URL("https://photon.komoot.io/api/");
    photon.searchParams.set("q", q);
    photon.searchParams.set("lang", "de");
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
        "User-Agent": "AetherRide/1.0 (geocode; contact@aetherride.local)",
      },
      next: { revalidate: 3600 },
    });

    if (!res.ok) {
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

    return NextResponse.json({
      hits,
      attribution: "© OpenStreetMap contributors · Photon (Komoot)",
      query: q,
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
