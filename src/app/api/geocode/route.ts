import { NextResponse } from "next/server";
import { chromeLangFrom } from "@/lib/i18n/chromeLang";
import {
  dedupeGeocodeHits,
  queryLooksLikeStation,
  rankGeocodeHits,
} from "@/lib/geocode/photonRank";

export type GeocodeHit = {
  label: string;
  lat: number;
  lng: number;
  kind?: string;
  name?: string;
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
              : lang === "nl"
                ? "Minstens 2 tekens."
                : "Mindestens 2 Zeichen.",
    });
  }

  try {
    const photonLang = lang === "nl" ? "en" : lang;
    // DACH bias (override with lat/lon near user)
    const biasLat = url.searchParams.get("lat") ?? "48.0";
    const biasLon =
      url.searchParams.get("lon") ?? url.searchParams.get("lng") ?? "10.0";

    const photonUrl = (osmTag?: string) => {
      const photon = new URL("https://photon.komoot.io/api/");
      photon.searchParams.set("q", q);
      // Photon: default/en/de/fr. nl is not a Photon lang — use en.
      photon.searchParams.set("lang", photonLang);
      photon.searchParams.set("limit", String(Math.min(8, limit + 3)));
      photon.searchParams.set("lat", biasLat);
      photon.searchParams.set("lon", biasLon);
      if (osmTag) photon.searchParams.set("osm_tag", osmTag);
      return photon.toString();
    };

    const photonHeaders = {
      Accept: "application/json",
      "User-Agent": "FlowLine/1.0 (geocode; contact@aetherride.local)",
    } as const;

    const stationQ = queryLooksLikeStation(q);
    const [res, placeRes, stationRes] = await Promise.all([
      fetch(photonUrl(), {
        headers: photonHeaders,
        next: { revalidate: 3600 },
      }),
      fetch(photonUrl("place"), {
        headers: photonHeaders,
        next: { revalidate: 3600 },
      }).catch(() => null),
      stationQ
        ? fetch(photonUrl("railway"), {
            headers: photonHeaders,
            next: { revalidate: 3600 },
          }).catch(() => null)
        : Promise.resolve(null),
    ]);

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

    type PhotonFeature = {
      geometry?: { coordinates?: number[] };
      properties?: Record<string, unknown>;
    };
    const parseHits = (data: { features?: PhotonFeature[] }): GeocodeHit[] => {
      const hits: GeocodeHit[] = [];
      for (const f of data.features ?? []) {
        const coords = f.geometry?.coordinates;
        if (!coords || coords.length < 2) continue;
        const p = f.properties ?? {};
        const name = typeof p.name === "string" ? p.name.trim() : "";
        const parts = [
          name,
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
          ...(name ? { name } : {}),
        });
      }
      return hits;
    };

    const data = (await res.json()) as { features?: PhotonFeature[] };
    let hits = parseHits(data);
    if (placeRes?.ok) {
      try {
        const placeData = (await placeRes.json()) as {
          features?: PhotonFeature[];
        };
        hits = [...parseHits(placeData), ...hits];
      } catch {
        /* keep default hits */
      }
    }
    if (stationRes?.ok) {
      try {
        const stationData = (await stationRes.json()) as {
          features?: PhotonFeature[];
        };
        hits = [...parseHits(stationData), ...hits];
      } catch {
        /* keep default hits */
      }
    }
    hits = rankGeocodeHits(q, dedupeGeocodeHits(hits)).slice(0, limit);

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
