import { NextResponse } from "next/server";
import { chromeLangFrom, type ChromeLang } from "@/lib/i18n/chromeLang";
import {
  cinemaPlaceQuery,
  dedupeGeocodeHits,
  dropStationJunkHits,
  queryLooksLikeStation,
  rankGeocodeHits,
  stationFallbackQueries,
} from "@/lib/geocode/photonRank";
import { photonHitsFromCollection } from "@/lib/geocode/photonFeature";

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
  const latParam = url.searchParams.get("lat");
  const lonParam =
    url.searchParams.get("lon") ?? url.searchParams.get("lng");
  const reverseLat = latParam != null ? Number(latParam) : NaN;
  const reverseLon = lonParam != null ? Number(lonParam) : NaN;

  if (q.length < 2) {
    if (
      Number.isFinite(reverseLat) &&
      Number.isFinite(reverseLon) &&
      Math.abs(reverseLat) <= 90 &&
      Math.abs(reverseLon) <= 180
    ) {
      return reverseGeocode({
        lat: reverseLat,
        lon: reverseLon,
        lang,
      });
    }
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
    const biasLat = latParam ?? "48.0";
    const biasLon = lonParam ?? "10.0";
    const userBias =
      latParam != null && lonParam != null
        ? { lat: Number(latParam), lng: Number(lonParam) }
        : undefined;

    const photonUrl = (opts?: { osmTag?: string; query?: string }) => {
      const photon = new URL("https://photon.komoot.io/api/");
      photon.searchParams.set("q", opts?.query ?? q);
      // Photon: default/en/de/fr. nl is not a Photon lang — use en.
      photon.searchParams.set("lang", photonLang);
      photon.searchParams.set("limit", String(Math.min(8, limit + 3)));
      photon.searchParams.set("lat", biasLat);
      photon.searchParams.set("lon", biasLon);
      if (opts?.osmTag) photon.searchParams.set("osm_tag", opts.osmTag);
      return photon.toString();
    };

    const photonHeaders = {
      Accept: "application/json",
      "User-Agent": "FlowLine/1.0 (geocode; contact@aetherride.local)",
    } as const;

    const cinemaPlace = cinemaPlaceQuery(q);
    const stationQ = queryLooksLikeStation(q);
    const [res, placeRes, cinemaRes, stationRes] = await Promise.all([
      fetch(photonUrl(), {
        headers: photonHeaders,
        next: { revalidate: 3600 },
      }),
      fetch(photonUrl({ osmTag: "place" }), {
        headers: photonHeaders,
        next: { revalidate: 3600 },
      }).catch(() => null),
      cinemaPlace != null
        ? fetch(
            photonUrl({
              osmTag: "amenity:cinema",
              query: cinemaPlace || q,
            }),
            {
              headers: photonHeaders,
              next: { revalidate: 3600 },
            }
          ).catch(() => null)
        : Promise.resolve(null),
      stationQ
        ? fetch(photonUrl({ osmTag: "railway:station" }), {
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
        const osmKey = typeof p.osm_key === "string" ? p.osm_key : "";
        const osmValue = typeof p.osm_value === "string" ? p.osm_value : "";
        let kind = typeof p.type === "string" ? p.type : undefined;
        if (
          osmKey === "railway" &&
          (osmValue === "station" || osmValue === "halt" || osmValue === "stop")
        ) {
          kind = "station";
        } else if (osmKey === "building" && osmValue === "train_station") {
          kind = "station";
        }
        hits.push({
          label,
          lng: coords[0],
          lat: coords[1],
          kind,
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
          features?: unknown[];
        };
        hits = [...photonHitsFromCollection(placeData), ...hits];
      } catch {
        /* keep default hits */
      }
    }
    if (cinemaRes?.ok) {
      try {
        const cinemaData = (await cinemaRes.json()) as {
          features?: PhotonFeature[];
        };
        hits = [...parseHits(cinemaData), ...hits];
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
    if (stationQ) {
      const haveRailwayStation = hits.some((h) => h.kind === "station");
      for (const alt of stationFallbackQueries(q)) {
        try {
          const tagged = await fetch(
            photonUrl({ osmTag: "railway:station", query: alt }),
            {
              headers: photonHeaders,
              next: { revalidate: 3600 },
            }
          ).catch(() => null);
          if (tagged?.ok) {
            const taggedData = (await tagged.json()) as {
              features?: PhotonFeature[];
            };
            hits = [...hits, ...parseHits(taggedData)];
          }
          if (!haveRailwayStation) {
            const altRes = await fetch(photonUrl({ query: alt }), {
              headers: photonHeaders,
              next: { revalidate: 3600 },
            });
            if (!altRes.ok) continue;
            const altData = (await altRes.json()) as {
              features?: PhotonFeature[];
            };
            hits = [...hits, ...parseHits(altData)];
          }
        } catch {
          /* keep existing hits */
        }
      }
    }
    hits = dropStationJunkHits(
      q,
      rankGeocodeHits(q, dedupeGeocodeHits(hits), userBias)
    ).slice(0, limit);

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

const PHOTON_HEADERS = {
  Accept: "application/json",
  "User-Agent": "FlowLine/1.0 (geocode; contact@aetherride.local)",
} as const;

/** GET /api/geocode?lat=&lon= — Photon reverse, no invented names. */
async function reverseGeocode(opts: {
  lat: number;
  lon: number;
  lang: ChromeLang;
}) {
  const photonLang = opts.lang === "nl" ? "en" : opts.lang;
  const photon = new URL("https://photon.komoot.io/reverse");
  photon.searchParams.set("lat", String(opts.lat));
  photon.searchParams.set("lon", String(opts.lon));
  photon.searchParams.set("lang", photonLang);
  try {
    const res = await fetch(photon.toString(), {
      headers: PHOTON_HEADERS,
      next: { revalidate: 3600 },
    });
    if (!res.ok) {
      return NextResponse.json({
        hits: [] as GeocodeHit[],
        attribution: "© OpenStreetMap · Photon",
        provider: "photon",
        warning: `Photon reverse ${res.status}`,
      });
    }
    const data = (await res.json()) as { features?: unknown[] };
    const hits = photonHitsFromCollection(data).slice(0, 1);
    return NextResponse.json({
      hits,
      attribution: "© OpenStreetMap contributors · Photon (Komoot)",
      provider: "photon",
      reverse: true,
    });
  } catch (e) {
    return NextResponse.json(
      {
        hits: [] as GeocodeHit[],
        attribution: "© OpenStreetMap · Photon",
        error: e instanceof Error ? e.message : "reverse geocode failed",
      },
      { status: 502 }
    );
  }
}
