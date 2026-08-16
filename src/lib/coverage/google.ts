/**
 * Google Maps Platform — Places / Geocoding / Elevation.
 *
 * ToS: never draw Google tiles or Directions polylines on MapLibre.
 * Places = named POI pins + "Powered by Google" + deep-link to Google Maps.
 * Key stays server-side (`GOOGLE_MAPS_API_KEY`). Missing key → honest empty.
 */

import { chromeLangFrom, type ChromeLang } from "@/lib/i18n/chromeLang";

export type GooglePlaceKind = "bike_shop" | "repair" | "cafe" | "other";

export type GooglePlacePoi = {
  id: string;
  name: string;
  kind: GooglePlaceKind;
  lat: number;
  lng: number;
  mapsUrl: string;
  types: string[];
  source: "google_places";
};

export type GooglePlacesResult = {
  configured: boolean;
  places: GooglePlacePoi[];
  attribution: string;
  warning?: string;
  provider?: "places_new" | "places_legacy" | "none";
};

const ATTRIBUTION = "Powered by Google";

export function googleMapsApiKey(): string {
  return (
    process.env.GOOGLE_MAPS_API_KEY?.trim() ||
    process.env.GOOGLE_PLACES_API_KEY?.trim() ||
    ""
  );
}

export function isGoogleConfigured(): boolean {
  return googleMapsApiKey().length > 8;
}

function kindFromTypes(types: string[]): GooglePlaceKind {
  const t = new Set(types.map((x) => x.toLowerCase()));
  if (t.has("bicycle_store")) return "bike_shop";
  if ([...t].some((x) => x.includes("repair") || x.includes("bicycle"))) {
    return "repair";
  }
  if (t.has("cafe") || t.has("bakery")) return "cafe";
  return "other";
}

function mapsUrlFor(placeId: string, lat: number, lng: number): string {
  const q = new URLSearchParams({
    api: "1",
    query: `${lat},${lng}`,
    query_place_id: placeId,
  });
  return `https://www.google.com/maps/search/?${q}`;
}

type FetchLike = typeof fetch;

async function placesNewNearby(
  lat: number,
  lng: number,
  radiusM: number,
  key: string,
  fetchImpl: FetchLike,
  language: ChromeLang = "de"
): Promise<GooglePlacePoi[] | null> {
  const res = await fetchImpl("https://places.googleapis.com/v1/places:searchNearby", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "X-Goog-Api-Key": key,
      "X-Goog-FieldMask":
        "places.id,places.displayName,places.location,places.types,places.googleMapsUri",
    },
    body: JSON.stringify({
      includedTypes: ["bicycle_store"],
      maxResultCount: 10,
      languageCode: language,
      rankPreference: "DISTANCE",
      locationRestriction: {
        circle: {
          center: { latitude: lat, longitude: lng },
          radius: radiusM,
        },
      },
    }),
    signal: AbortSignal.timeout(4500),
  });
  if (!res.ok) return null;
  const json = (await res.json()) as {
    places?: Array<{
      id?: string;
      displayName?: { text?: string };
      location?: { latitude?: number; longitude?: number };
      types?: string[];
      googleMapsUri?: string;
    }>;
  };
  const out: GooglePlacePoi[] = [];
  for (const p of json.places ?? []) {
    const plat = p.location?.latitude;
    const plng = p.location?.longitude;
    const id = p.id?.trim();
    const name = p.displayName?.text?.trim();
    if (!id || !name || !Number.isFinite(plat) || !Number.isFinite(plng)) continue;
    const types = Array.isArray(p.types) ? p.types : [];
    out.push({
      id: `gplace-${id}`,
      name,
      kind: kindFromTypes(types),
      lat: plat as number,
      lng: plng as number,
      mapsUrl: p.googleMapsUri || mapsUrlFor(id, plat as number, plng as number),
      types,
      source: "google_places",
    });
  }
  return out;
}

async function placesLegacyNearby(
  lat: number,
  lng: number,
  radiusM: number,
  key: string,
  fetchImpl: FetchLike,
  language: ChromeLang = "de"
): Promise<GooglePlacePoi[] | null> {
  const url = new URL("https://maps.googleapis.com/maps/api/place/nearbysearch/json");
  url.searchParams.set("location", `${lat},${lng}`);
  url.searchParams.set("radius", String(Math.round(radiusM)));
  url.searchParams.set("type", "bicycle_store");
  url.searchParams.set("language", language);
  url.searchParams.set("key", key);
  const res = await fetchImpl(url.toString(), {
    signal: AbortSignal.timeout(4500),
  });
  if (!res.ok) return null;
  const json = (await res.json()) as {
    status?: string;
    results?: Array<{
      place_id?: string;
      name?: string;
      geometry?: { location?: { lat?: number; lng?: number } };
      types?: string[];
    }>;
  };
  if (json.status && json.status !== "OK" && json.status !== "ZERO_RESULTS") {
    return null;
  }
  const out: GooglePlacePoi[] = [];
  for (const p of json.results ?? []) {
    const plat = p.geometry?.location?.lat;
    const plng = p.geometry?.location?.lng;
    const id = p.place_id?.trim();
    const name = p.name?.trim();
    if (!id || !name || !Number.isFinite(plat) || !Number.isFinite(plng)) continue;
    const types = Array.isArray(p.types) ? p.types : [];
    out.push({
      id: `gplace-${id}`,
      name,
      kind: kindFromTypes(types),
      lat: plat as number,
      lng: plng as number,
      mapsUrl: mapsUrlFor(id, plat as number, plng as number),
      types,
      source: "google_places",
    });
  }
  return out;
}

/**
 * Nearby bike shops (GPS radius only). No DACH-wide crawl.
 */
export async function fetchGooglePlacesNearby(opts: {
  lat: number;
  lng: number;
  radiusM?: number;
  key?: string;
  fetchImpl?: FetchLike;
  language?: ChromeLang;
}): Promise<GooglePlacesResult> {
  const key = (opts.key ?? googleMapsApiKey()).trim();
  if (key.length <= 8) {
    return {
      configured: false,
      places: [],
      attribution: ATTRIBUTION,
      warning: "Google nicht konfiguriert",
      provider: "none",
    };
  }
  const radiusM = Math.min(8000, Math.max(800, opts.radiusM ?? 4000));
  const fetchImpl = opts.fetchImpl ?? fetch;
  const language = chromeLangFrom(opts.language);
  try {
    const neu = await placesNewNearby(opts.lat, opts.lng, radiusM, key, fetchImpl, language);
    if (neu) {
      return {
        configured: true,
        places: neu.slice(0, 12),
        attribution: ATTRIBUTION,
        provider: "places_new",
      };
    }
    const legacy = await placesLegacyNearby(
      opts.lat,
      opts.lng,
      radiusM,
      key,
      fetchImpl,
      language
    );
    if (legacy) {
      return {
        configured: true,
        places: legacy.slice(0, 12),
        attribution: ATTRIBUTION,
        provider: "places_legacy",
      };
    }
    return {
      configured: true,
      places: [],
      attribution: ATTRIBUTION,
      warning: "Google Places ohne Treffer",
      provider: "none",
    };
  } catch (e) {
    return {
      configured: true,
      places: [],
      attribution: ATTRIBUTION,
      warning: e instanceof Error ? e.message : "google_places_failed",
      provider: "none",
    };
  }
}

export type GoogleGeocodeHit = {
  label: string;
  lat: number;
  lng: number;
  kind?: string;
  source: "google_geocoding";
};

/** Geocoding API fallback when Photon is empty. */
export async function fetchGoogleGeocode(opts: {
  q: string;
  lat?: number;
  lng?: number;
  limit?: number;
  key?: string;
  fetchImpl?: FetchLike;
  language?: ChromeLang;
}): Promise<{ hits: GoogleGeocodeHit[]; warning?: string }> {
  const key = (opts.key ?? googleMapsApiKey()).trim();
  if (key.length <= 8) return { hits: [], warning: "Google nicht konfiguriert" };
  const q = opts.q.trim();
  if (q.length < 2) return { hits: [] };
  try {
    const url = new URL("https://maps.googleapis.com/maps/api/geocode/json");
    url.searchParams.set("address", q);
    url.searchParams.set("language", chromeLangFrom(opts.language));
    url.searchParams.set("region", "de");
    url.searchParams.set("key", key);
    if (Number.isFinite(opts.lat) && Number.isFinite(opts.lng)) {
      const lat = opts.lat as number;
      const lng = opts.lng as number;
      const d = 1.2;
      url.searchParams.set("bounds", `${lat - d},${lng - d}|${lat + d},${lng + d}`);
    }
    const res = await (opts.fetchImpl ?? fetch)(url.toString(), {
      signal: AbortSignal.timeout(4000),
    });
    if (!res.ok) return { hits: [], warning: `Google Geocoding ${res.status}` };
    const json = (await res.json()) as {
      status?: string;
      results?: Array<{
        formatted_address?: string;
        geometry?: { location?: { lat?: number; lng?: number } };
        types?: string[];
      }>;
    };
    if (json.status && json.status !== "OK" && json.status !== "ZERO_RESULTS") {
      return { hits: [], warning: `Google Geocoding ${json.status}` };
    }
    const hits: GoogleGeocodeHit[] = [];
    const limit = Math.min(8, Math.max(1, opts.limit ?? 5));
    for (const r of json.results ?? []) {
      const lat = r.geometry?.location?.lat;
      const lng = r.geometry?.location?.lng;
      const label = r.formatted_address?.trim();
      if (!label || !Number.isFinite(lat) || !Number.isFinite(lng)) continue;
      hits.push({
        label,
        lat: lat as number,
        lng: lng as number,
        kind: r.types?.[0],
        source: "google_geocoding",
      });
      if (hits.length >= limit) break;
    }
    return { hits };
  } catch (e) {
    return {
      hits: [],
      warning: e instanceof Error ? e.message : "google_geocode_failed",
    };
  }
}

/** Point elevation via Google Elevation API (optional, GPS/track sample). */
export async function fetchGoogleElevation(opts: {
  points: { lat: number; lng: number }[];
  key?: string;
  fetchImpl?: FetchLike;
}): Promise<{
  ok: boolean;
  points: { lat: number; lng: number; elev: number | null }[];
  warning?: string;
}> {
  const key = (opts.key ?? googleMapsApiKey()).trim();
  if (key.length <= 8) {
    return { ok: false, points: [], warning: "Google nicht konfiguriert" };
  }
  const sample = opts.points.slice(0, 80);
  if (sample.length === 0) return { ok: false, points: [] };
  try {
    const url = new URL("https://maps.googleapis.com/maps/api/elevation/json");
    url.searchParams.set(
      "locations",
      sample.map((p) => `${p.lat},${p.lng}`).join("|")
    );
    url.searchParams.set("key", key);
    const res = await (opts.fetchImpl ?? fetch)(url.toString(), {
      signal: AbortSignal.timeout(5000),
    });
    if (!res.ok) return { ok: false, points: [], warning: `Google Elevation ${res.status}` };
    const json = (await res.json()) as {
      status?: string;
      results?: Array<{ elevation?: number; location?: { lat?: number; lng?: number } }>;
    };
    if (json.status && json.status !== "OK") {
      return { ok: false, points: [], warning: `Google Elevation ${json.status}` };
    }
    const points = sample.map((p, i) => ({
      lat: p.lat,
      lng: p.lng,
      elev:
        typeof json.results?.[i]?.elevation === "number"
          ? json.results[i].elevation!
          : null,
    }));
    return { ok: true, points };
  } catch (e) {
    return {
      ok: false,
      points: [],
      warning: e instanceof Error ? e.message : "google_elevation_failed",
    };
  }
}
