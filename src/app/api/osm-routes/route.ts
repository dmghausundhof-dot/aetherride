import { NextResponse } from "next/server";

type OsmRoute = {
  id: string;
  title: string;
  type: string;
  difficulty?: string;
  lengthKm?: number;
  elevationM?: number;
  durationMin?: number;
  summary?: string;
  url?: string;
  center?: [number, number];
  geometry?: [number, number][];
  source: "osm";
};

function haversineKm(
  a: [number, number],
  b: [number, number],
): number {
  const toRad = (d: number) => (d * Math.PI) / 180;
  const R = 6371;
  const dLat = toRad(b[1] - a[1]);
  const dLon = toRad(b[0] - a[0]);
  const lat1 = toRad(a[1]);
  const lat2 = toRad(b[1]);
  const h =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(lat1) * Math.cos(lat2) * Math.sin(dLon / 2) ** 2;
  return 2 * R * Math.asin(Math.sqrt(h));
}

function pathLengthKm(coords: [number, number][]): number {
  let sum = 0;
  for (let i = 1; i < coords.length; i++) {
    sum += haversineKm(coords[i - 1], coords[i]);
  }
  return sum;
}

/**
 * Live OSM-Routen (relation route=bicycle|mtb|hiking) — DACH+FR.
 * GET /api/osm-routes?lat=&lon=&radiusKm=
 */
export async function GET(req: Request) {
  const url = new URL(req.url);
  const lat = Number(url.searchParams.get("lat"));
  const lon = Number(url.searchParams.get("lon"));
  const radiusKm = Math.min(
    40,
    Math.max(5, Number(url.searchParams.get("radiusKm") || 18)),
  );

  if (!Number.isFinite(lat) || !Number.isFinite(lon)) {
    return NextResponse.json(
      { error: "lat_lon_required", routes: [] },
      { status: 400 },
    );
  }

  const radiusM = Math.round(radiusKm * 1000);
  const query = `
[out:json][timeout:28];
(
  relation["route"="bicycle"](around:${radiusM},${lat},${lon});
  relation["route"="mtb"](around:${radiusM},${lat},${lon});
  relation["route"="hiking"](around:${radiusM},${lat},${lon});
  relation["route"="cycling"](around:${radiusM},${lat},${lon});
);
out body geom;
`.trim();

  try {
    const res = await fetch("https://overpass-api.de/api/interpreter", {
      method: "POST",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded;charset=UTF-8",
        Accept: "application/json",
      },
      body: `data=${encodeURIComponent(query)}`,
      next: { revalidate: 900 },
    });

    if (!res.ok) {
      return NextResponse.json({
        provider: "osm_overpass",
        routes: [],
        warning: `Overpass ${res.status}`,
      });
    }

    const json = (await res.json()) as {
      elements?: Array<{
        type: string;
        id: number;
        tags?: Record<string, string>;
        members?: Array<{
          type: string;
          role?: string;
          geometry?: Array<{ lat: number; lon: number }>;
        }>;
      }>;
    };

    const routes: OsmRoute[] = [];
    for (const el of json.elements ?? []) {
      if (el.type !== "relation") continue;
      const tags = el.tags ?? {};
      const name =
        tags.name || tags["name:de"] || tags.ref || tags.operator;
      if (!name) continue;

      const geometry: [number, number][] = [];
      for (const m of el.members ?? []) {
        if (!m.geometry?.length) continue;
        for (const g of m.geometry) {
          if (!Number.isFinite(g.lat) || !Number.isFinite(g.lon)) continue;
          geometry.push([g.lon, g.lat]);
        }
      }
      if (geometry.length < 2) continue;

      // Simplify: keep every Nth point for mobile polylines
      const step = Math.max(1, Math.floor(geometry.length / 180));
      const simplified = geometry.filter((_, i) => i % step === 0);
      if (
        simplified.length === 0 ||
        simplified[simplified.length - 1][0] !==
          geometry[geometry.length - 1][0] ||
        simplified[simplified.length - 1][1] !==
          geometry[geometry.length - 1][1]
      ) {
        simplified.push(geometry[geometry.length - 1]);
      }

      const lengthKm = pathLengthKm(simplified);
      if (lengthKm < 1.5 || lengthKm > 180) continue;

      const routeType = tags.route || "bicycle";
      const mid = simplified[Math.floor(simplified.length / 2)];
      const durationMin = Math.round((lengthKm / 14) * 60);

      routes.push({
        id: `osm-${el.id}`,
        title: name,
        type: routeType,
        difficulty:
          tags.mtb_scale || tags.sac_scale || tags.network || undefined,
        lengthKm: Math.round(lengthKm * 10) / 10,
        durationMin,
        summary: [
          tags.description?.slice(0, 120),
          routeType === "mtb" ? "OSM MTB-Route" : "OSM Rad-/Wanderroute",
          tags.network ? `Netz ${tags.network}` : null,
        ]
          .filter(Boolean)
          .join(" · "),
        url: `https://www.openstreetmap.org/relation/${el.id}`,
        center: mid,
        geometry: simplified,
        source: "osm",
      });
    }

    routes.sort((a, b) => (a.lengthKm ?? 99) - (b.lengthKm ?? 99));
    // Cap: genug DACH-Vielfalt, ohne Discover/Warm zu fluten.
    const limited = routes.slice(0, 36);

    return NextResponse.json({
      provider: "osm_overpass",
      configured: true,
      usingDemoFallback: false,
      lat,
      lon,
      radiusKm,
      routes: limited,
      tours: limited, // Discover erwartet oft `tours`
      attribution: "© OpenStreetMap Mitwirkende",
    });
  } catch (e) {
    return NextResponse.json({
      provider: "osm_overpass",
      routes: [],
      tours: [],
      warning: e instanceof Error ? e.message : "overpass_failed",
    });
  }
}
