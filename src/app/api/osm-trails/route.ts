/**
 * Live OSM-Trailnetz (Ways) — Singletrack/Cycleway mit Difficulty.
 * GET /api/osm-trails?lat=&lon=&radiusKm=
 *
 * Relations bleiben bei /api/osm-routes (Touren).
 * Hier: highway=path|track + mtb_scale, plus cycleways / bicycle-paths.
 */

import { NextResponse } from "next/server";

export type OsmTrail = {
  id: string;
  name: string;
  mtbScale: string;
  surface?: string;
  highway?: string;
  lengthKm: number;
  center: [number, number];
  geometry: [number, number][];
  url: string;
  source: "osm";
};

function haversineKm(a: [number, number], b: [number, number]): number {
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

function normalizeScale(raw?: string): string {
  if (!raw) return "offen";
  const t = raw.trim().toLowerCase();
  if (t === "0" || t.startsWith("s0")) return "S0";
  if (t === "1" || t.startsWith("s1")) return "S1";
  if (t === "2" || t.startsWith("s2")) return "S2";
  if (
    t === "3" ||
    t === "4" ||
    t === "5" ||
    t === "6" ||
    t.startsWith("s3") ||
    t.startsWith("s4") ||
    t.startsWith("s5")
  ) {
    return "S3+";
  }
  return raw.slice(0, 12);
}

export async function GET(req: Request) {
  const url = new URL(req.url);
  const lat = Number(url.searchParams.get("lat"));
  const lon = Number(url.searchParams.get("lon"));
  const radiusKm = Math.min(
    18,
    Math.max(3, Number(url.searchParams.get("radiusKm") || 8)),
  );

  if (!Number.isFinite(lat) || !Number.isFinite(lon)) {
    return NextResponse.json(
      { error: "lat_lon_required", trails: [] },
      { status: 400 },
    );
  }

  const radiusM = Math.round(radiusKm * 1000);
  const query = `
[out:json][timeout:26];
(
  way["highway"~"path|track"]["mtb_scale"](around:${radiusM},${lat},${lon});
  way["highway"="cycleway"](around:${radiusM},${lat},${lon});
  way["highway"="path"]["bicycle"~"yes|designated"](around:${radiusM},${lat},${lon});
);
out body geom;
`.trim();

  try {
    const res = await fetch("https://overpass-api.de/api/interpreter", {
      method: "POST",
      headers: {
        "Content-Type":
          "application/x-www-form-urlencoded;charset=UTF-8",
        Accept: "application/json",
      },
      body: `data=${encodeURIComponent(query)}`,
      next: { revalidate: 900 },
    });

    if (!res.ok) {
      return NextResponse.json({
        provider: "osm_overpass",
        trails: [],
        warning: `Overpass ${res.status}`,
      });
    }

    const json = (await res.json()) as {
      elements?: Array<{
        type: string;
        id: number;
        tags?: Record<string, string>;
        geometry?: Array<{ lat: number; lon: number }>;
      }>;
    };

    const trails: OsmTrail[] = [];
    for (const el of json.elements ?? []) {
      if (el.type !== "way") continue;
      const tags = el.tags ?? {};
      const geomRaw = el.geometry ?? [];
      if (geomRaw.length < 2) continue;

      const geometry: [number, number][] = [];
      for (const g of geomRaw) {
        if (!Number.isFinite(g.lat) || !Number.isFinite(g.lon)) continue;
        geometry.push([g.lon, g.lat]);
      }
      if (geometry.length < 2) continue;

      const step = Math.max(1, Math.floor(geometry.length / 80));
      const simplified = geometry.filter((_, i) => i % step === 0);
      const last = geometry[geometry.length - 1];
      if (
        simplified.length === 0 ||
        simplified[simplified.length - 1][0] !== last[0] ||
        simplified[simplified.length - 1][1] !== last[1]
      ) {
        simplified.push(last);
      }

      const lengthKm = pathLengthKm(simplified);
      if (lengthKm < 0.12 || lengthKm > 25) continue;

      const mtbScale = normalizeScale(tags.mtb_scale);
      const name =
        tags.name ||
        tags["name:de"] ||
        tags.ref ||
        (mtbScale !== "offen"
          ? `Trail ${mtbScale}`
          : tags.highway === "cycleway"
            ? "Radweg"
            : "Pfad");

      const mid = simplified[Math.floor(simplified.length / 2)];
      trails.push({
        id: `osm-way-${el.id}`,
        name,
        mtbScale,
        surface: tags.surface || tags.tracktype || undefined,
        highway: tags.highway,
        lengthKm: Math.round(lengthKm * 100) / 100,
        center: mid,
        geometry: simplified,
        url: `https://www.openstreetmap.org/way/${el.id}`,
        source: "osm",
      });
    }

    // Prefer named + scaled trails, then shorter nearby segments.
    trails.sort((a, b) => {
      const sa = a.mtbScale.startsWith("S") ? 0 : 1;
      const sb = b.mtbScale.startsWith("S") ? 0 : 1;
      if (sa !== sb) return sa - sb;
      return a.lengthKm - b.lengthKm;
    });

    const limited = trails.slice(0, 80);

    return NextResponse.json({
      provider: "osm_overpass",
      configured: true,
      lat,
      lon,
      radiusKm,
      trails: limited,
      attribution: "© OpenStreetMap Mitwirkende",
      legend: {
        S0: "#4CAF50",
        S1: "#8BC34A",
        S2: "#FFC107",
        "S3+": "#E53935",
        offen: "#90A4AE",
      },
    });
  } catch (e) {
    return NextResponse.json({
      provider: "osm_overpass",
      trails: [],
      warning: e instanceof Error ? e.message : "overpass_failed",
    });
  }
}
