/**
 * GPS-first DACH coverage payload — seeds (bundled) + live OSM + weather +
 * Google Places (optional). Never 504: partial + warnings.
 */

import { overlayHintForPoint } from "./regions";
import { pickCoverageCatalog, pickCoverageSeeds } from "./seeds";
import {
  fetchOsmRoutesNear,
  fetchOsmTrailsNear,
  type OsmRoute,
  type OsmTrail,
} from "./osmLive";
import { fetchGooglePlacesNearby, type GooglePlacePoi } from "./google";
import { fetchSchweizMobilNear, type SchweizMobilHit } from "./schweizmobil";
import type { DachHonesty } from "./dach";

export type CoverageBikeClass = "mtb" | "gravel" | "road" | "urban";

export type CoveragePayload = {
  ok: true;
  lat: number;
  lng: number;
  inDach: boolean;
  honesty: DachHonesty;
  honestyLabel: string;
  bikeClass: CoverageBikeClass;
  nearbySeedCount: number;
  sources: string[];
  seeds: ReturnType<typeof pickCoverageSeeds>["seeds"];
  catalog: ReturnType<typeof pickCoverageCatalog>;
  trails: OsmTrail[];
  routes: OsmRoute[];
  places: GooglePlacePoi[];
  schweizmobil: SchweizMobilHit[];
  weather: {
    provider: string;
    trailHint?: string;
    current?: unknown;
    attribution: string;
  } | null;
  overlay: ReturnType<typeof overlayHintForPoint> & { bikeClass: CoverageBikeClass };
  google: {
    configured: boolean;
    role: "pois_search";
    places: number;
    warning?: string;
  };
  attribution: string[];
  warnings: string[];
};

const CACHE_TTL_MS = 10 * 60 * 1000;
const cache = new Map<string, { at: number; body: CoveragePayload }>();

function cacheKey(
  lat: number,
  lng: number,
  bike: CoverageBikeClass,
  live: boolean
): string {
  return `${lat.toFixed(3)}:${lng.toFixed(3)}:${bike}:${live ? "1" : "0"}`;
}

export function parseBikeClass(raw: string | null): CoverageBikeClass {
  const t = (raw ?? "").trim().toLowerCase();
  if (t === "mtb" || t === "emtb" || t === "trail") return "mtb";
  if (t === "gravel" || t === "ebike" || t === "etrekking") return "gravel";
  if (t === "urban" || t === "city") return "urban";
  return "road";
}

async function fetchWeather(lat: number, lng: number): Promise<{
  provider: string;
  trailHint?: string;
  current?: unknown;
  attribution: string;
} | null> {
  try {
    const api = new URL("https://api.open-meteo.com/v1/forecast");
    api.searchParams.set("latitude", String(lat));
    api.searchParams.set("longitude", String(lng));
    api.searchParams.set(
      "current",
      "temperature_2m,precipitation,weather_code,wind_speed_10m"
    );
    api.searchParams.set("forecast_days", "1");
    api.searchParams.set("timezone", "auto");
    const res = await fetch(api.toString(), {
      signal: AbortSignal.timeout(4000),
      next: { revalidate: 1800 },
    });
    if (!res.ok) return null;
    const data = (await res.json()) as {
      current?: { precipitation?: number };
    };
    const precip = data?.current?.precipitation ?? 0;
    const trailHint =
      precip >= 5 ? "wet_likely" : precip >= 1 ? "damp_possible" : "dry_likely";
    return {
      provider: "open-meteo",
      trailHint,
      current: data.current,
      attribution: "Weather data by Open-Meteo.com",
    };
  } catch {
    return null;
  }
}

export function assembleCoverageLocal(opts: {
  lat: number;
  lng: number;
  bikeClass?: CoverageBikeClass;
}): CoveragePayload {
  const bikeClass = opts.bikeClass ?? "road";
  const picked = pickCoverageSeeds(opts.lat, opts.lng);
  const catalog = pickCoverageCatalog(opts.lat, opts.lng);
  const overlay = overlayHintForPoint(opts.lng, opts.lat);
  const sources = ["seeds_dach", "catalog"];
  if (overlay.mode === "region_pack" && overlay.regionId) {
    sources.push(`overlay_pack:${overlay.regionId}`);
  } else if (overlay.mode === "dach_live") {
    sources.push(
      overlay.regionId
        ? `overlay_dach_live:${overlay.regionId}`
        : "overlay_dach_live"
    );
  } else {
    sources.push("overlay_live_osm");
  }
  return {
    ok: true,
    lat: opts.lat,
    lng: opts.lng,
    inDach: picked.inDach,
    honesty: picked.honesty,
    honestyLabel: picked.honestyLabel,
    bikeClass,
    nearbySeedCount: picked.nearbyCount,
    sources,
    seeds: picked.seeds,
    catalog,
    trails: [],
    routes: [],
    places: [],
    schweizmobil: [],
    weather: null,
    overlay: { ...overlay, bikeClass },
    google: {
      configured: false,
      role: "pois_search",
      places: 0,
      warning: "live=0",
    },
    attribution: ["© OpenStreetMap Mitwirkende", "Kuratierte Nähe-Seeds"],
    warnings: [],
  };
}

export async function assembleCoverageLive(opts: {
  lat: number;
  lng: number;
  bikeClass?: CoverageBikeClass;
  radiusKm?: number;
  skipCache?: boolean;
}): Promise<CoveragePayload> {
  const bikeClass = opts.bikeClass ?? "road";
  const key = cacheKey(opts.lat, opts.lng, bikeClass, true);
  if (!opts.skipCache) {
    const hit = cache.get(key);
    if (hit && Date.now() - hit.at < CACHE_TTL_MS) return hit.body;
  }

  const base = assembleCoverageLocal({
    lat: opts.lat,
    lng: opts.lng,
    bikeClass,
  });
  const radiusKm = Math.min(18, Math.max(3, opts.radiusKm ?? 8));
  const warnings = [...base.warnings];
  const sources = [...base.sources];
  const attribution = [...base.attribution];

  const [trailsR, routesR, weatherR, placesR, chR] = await Promise.allSettled([
    fetchOsmTrailsNear({ lat: opts.lat, lon: opts.lng, radiusKm }),
    fetchOsmRoutesNear({
      lat: opts.lat,
      lon: opts.lng,
      radiusKm: Math.min(36, radiusKm * 3),
    }),
    fetchWeather(opts.lat, opts.lng),
    fetchGooglePlacesNearby({
      lat: opts.lat,
      lng: opts.lng,
      radiusM: Math.round(Math.min(8, radiusKm) * 1000),
    }),
    fetchSchweizMobilNear({ lat: opts.lat, lng: opts.lng }),
  ]);

  let trails: OsmTrail[] = [];
  if (trailsR.status === "fulfilled") {
    trails = trailsR.value.trails;
    if (trailsR.value.warning) warnings.push(trailsR.value.warning);
    if (trails.length) sources.push("osm_overpass_trails");
  } else {
    warnings.push("OSM-Trails offline");
  }

  let routes: OsmRoute[] = [];
  if (routesR.status === "fulfilled") {
    routes = routesR.value.routes;
    if (routesR.value.warning) warnings.push(routesR.value.warning);
    if (routes.length) sources.push("osm_overpass_routes");
  } else {
    warnings.push("OSM-Routen offline");
  }

  let weather = base.weather;
  if (weatherR.status === "fulfilled" && weatherR.value) {
    weather = weatherR.value;
    sources.push("open_meteo");
    attribution.push(weatherR.value.attribution);
  } else {
    warnings.push("Wetter offline");
  }

  let places: GooglePlacePoi[] = [];
  let google = base.google;
  if (placesR.status === "fulfilled") {
    const g = placesR.value;
    places = g.places;
    google = {
      configured: g.configured,
      role: "pois_search",
      places: g.places.length,
      warning: g.warning,
    };
    if (g.configured && g.places.length) {
      sources.push("google_places");
      attribution.push(g.attribution);
    } else if (!g.configured) {
      warnings.push(g.warning ?? "Google nicht konfiguriert");
    } else if (g.warning) {
      warnings.push(g.warning);
    }
  }

  let schweizmobil: SchweizMobilHit[] = [];
  if (chR.status === "fulfilled") {
    schweizmobil = chR.value.hits;
    if (chR.value.hits.length) {
      sources.push("schweizmobil_ogd");
      attribution.push(chR.value.attribution);
    } else if (chR.value.warning) {
      warnings.push(chR.value.warning);
    }
  }

  const body: CoveragePayload = {
    ...base,
    sources: [...new Set(sources)],
    trails,
    routes,
    places,
    schweizmobil,
    weather,
    google,
    attribution: [...new Set(attribution)],
    warnings,
  };
  cache.set(key, { at: Date.now(), body });
  return body;
}
