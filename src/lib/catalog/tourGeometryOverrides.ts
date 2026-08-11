/**
 * Redaktionelle Tour-Linien (GeoJSON [lng,lat]).
 * Override vor Live-Routing. Optional: data/catalog/tour-geometry-overrides.json
 */

export type GeometryOverride = {
  coordinates: [number, number][];
  distanceM?: number;
  durationS?: number;
  shape?: "loop" | "out_and_back" | "point_to_point";
  source?: string;
};

/** Offset km → [lng,lat] around center [lng,lat] */
function offset(
  lng: number,
  lat: number,
  eastKm: number,
  northKm: number
): [number, number] {
  const dLat = northKm / 111;
  const dLng = eastKm / (111 * Math.max(0.2, Math.cos((lat * Math.PI) / 180)));
  return [lng + dLng, lat + dLat];
}

function loopRing(
  lng: number,
  lat: number,
  rKm: number,
  n = 6
): [number, number][] {
  const pts: [number, number][] = [];
  for (let i = 0; i < n; i++) {
    const a = (i / n) * Math.PI * 2;
    pts.push(
      offset(lng, lat, Math.cos(a) * rKm, Math.sin(a) * rKm * 0.85)
    );
  }
  pts.push(pts[0]);
  return pts;
}

function corridor(
  lng: number,
  lat: number,
  spanKm: number,
  bearingEast = true
): [number, number][] {
  const half = spanKm / 2;
  const e = bearingEast ? 1 : 0.3;
  const n = bearingEast ? 0.15 : 1;
  return [
    offset(lng, lat, -half * e, -half * n * 0.4),
    offset(lng, lat, -half * e * 0.3, half * n * 0.2),
    offset(lng, lat, half * e * 0.2, half * n * 0.35),
    offset(lng, lat, half * e, -half * n * 0.1),
  ];
}

type Spec = {
  lng: number;
  lat: number;
  loop: boolean;
  rKm: number;
  distanceM: number;
  durationS: number;
};

/** Zentren aus demoGeometry + typische Maße */
const SPECS: Record<string, Spec> = {
  "idea-koenigstuhl": {
    lng: 8.726,
    lat: 49.398,
    loop: true,
    rKm: 3.2,
    distanceM: 18000,
    durationS: 110 * 60,
  },
  "idea-odenwald-trail": {
    lng: 8.82,
    lat: 49.45,
    loop: true,
    rKm: 4.5,
    distanceM: 28000,
    durationS: 140 * 60,
  },
  "idea-neckartal-gravel": {
    lng: 8.68,
    lat: 49.38,
    loop: false,
    rKm: 12,
    distanceM: 42000,
    durationS: 150 * 60,
  },
  "r-heidelberg-city": {
    lng: 8.705,
    lat: 49.41,
    loop: true,
    rKm: 2.2,
    distanceM: 14000,
    durationS: 50 * 60,
  },
  "idea-kaltenbronn": {
    lng: 8.425,
    lat: 48.642,
    loop: true,
    rKm: 5.5,
    distanceM: 34000,
    durationS: 160 * 60,
  },
  "idea-schauinsland": {
    lng: 7.898,
    lat: 47.912,
    loop: true,
    rKm: 3.8,
    distanceM: 22000,
    durationS: 130 * 60,
  },
  "idea-dreisam-city": {
    lng: 7.845,
    lat: 47.995,
    loop: true,
    rKm: 1.8,
    distanceM: 12000,
    durationS: 45 * 60,
  },
  "idea-kaiserstuhl-road": {
    lng: 7.67,
    lat: 48.09,
    loop: true,
    rKm: 6.5,
    distanceM: 48000,
    durationS: 140 * 60,
  },
  "r-kitz-gravel": {
    lng: 12.39,
    lat: 47.45,
    loop: true,
    rKm: 7.5,
    distanceM: 62100,
    durationS: 180 * 60,
  },
  "r-hochkoenig-emtb": {
    lng: 13.1,
    lat: 47.42,
    loop: false,
    rKm: 10,
    distanceM: 41200,
    durationS: 165 * 60,
  },
  "r-wilder-kaiser-hike": {
    lng: 12.3,
    lat: 47.56,
    loop: false,
    rKm: 5,
    distanceM: 14200,
    durationS: 300 * 60,
  },
  "r-inn-flat": {
    lng: 12.17,
    lat: 47.56,
    loop: false,
    rKm: 14,
    distanceM: 34000,
    durationS: 90 * 60,
  },
  "r-freiburg-city": {
    lng: 7.842,
    lat: 47.999,
    loop: true,
    rKm: 2.5,
    distanceM: 18500,
    durationS: 55 * 60,
  },
  "r-schwarzwald-gravel": {
    lng: 7.95,
    lat: 48.05,
    loop: true,
    rKm: 8,
    distanceM: 58000,
    durationS: 210 * 60,
  },
  "r-bodensee-road": {
    lng: 9.18,
    lat: 47.66,
    loop: false,
    rKm: 28,
    distanceM: 72000,
    durationS: 200 * 60,
  },
  "r-stuttgart-urban": {
    lng: 9.16,
    lat: 48.76,
    loop: true,
    rKm: 3.2,
    distanceM: 22000,
    durationS: 70 * 60,
  },
  "r-tegernsee-gravel": {
    lng: 11.76,
    lat: 47.71,
    loop: true,
    rKm: 6,
    distanceM: 45000,
    durationS: 150 * 60,
  },
  "r-vosges-gravel": {
    lng: 6.84,
    lat: 47.82,
    loop: true,
    rKm: 6.2,
    distanceM: 42000,
    durationS: 180 * 60,
  },
  "r-alsace-road": {
    lng: 7.45,
    lat: 48.08,
    loop: false,
    rKm: 18,
    distanceM: 55000,
    durationS: 160 * 60,
  },
  "r-annecy-road": {
    lng: 6.13,
    lat: 45.9,
    loop: true,
    rKm: 5.5,
    distanceM: 40000,
    durationS: 120 * 60,
  },
  "r-morzine-emtb": {
    lng: 6.71,
    lat: 46.18,
    loop: false,
    rKm: 8,
    distanceM: 28000,
    durationS: 150 * 60,
  },
  "r-provence-gravel": {
    lng: 5.23,
    lat: 43.84,
    loop: true,
    rKm: 6.5,
    distanceM: 48000,
    durationS: 170 * 60,
  },
  "r-bretagne-coast": {
    lng: -3.48,
    lat: 48.83,
    loop: false,
    rKm: 12,
    distanceM: 38000,
    durationS: 110 * 60,
  },
  "r-rhein-radweg": {
    lng: 8.48,
    lat: 49.45,
    loop: false,
    rKm: 16,
    distanceM: 46000,
    durationS: 130 * 60,
  },
  "r-neckar-touring": {
    lng: 8.95,
    lat: 49.35,
    loop: false,
    rKm: 18,
    distanceM: 52000,
    durationS: 170 * 60,
  },
  "r-pfalz-gravel": {
    lng: 7.95,
    lat: 49.2,
    loop: true,
    rKm: 7,
    distanceM: 54000,
    durationS: 190 * 60,
  },
  "r-karlsruhe-urban": {
    lng: 8.4,
    lat: 49.01,
    loop: true,
    rKm: 2.2,
    distanceM: 16000,
    durationS: 50 * 60,
  },
  "r-donau-touring": {
    lng: 10.35,
    lat: 48.55,
    loop: false,
    rKm: 22,
    distanceM: 68000,
    durationS: 220 * 60,
  },
  "r-muenchen-road": {
    lng: 11.4,
    lat: 48.05,
    loop: false,
    rKm: 20,
    distanceM: 58000,
    durationS: 160 * 60,
  },
  "r-elbe-touring": {
    lng: 13.6,
    lat: 51.1,
    loop: false,
    rKm: 12,
    distanceM: 32000,
    durationS: 100 * 60,
  },
  "r-eifel-gravel": {
    lng: 6.7,
    lat: 50.35,
    loop: true,
    rKm: 7.5,
    distanceM: 61000,
    durationS: 200 * 60,
  },
};

function buildFromSpec(id: string, s: Spec): GeometryOverride {
  const coordinates = s.loop
    ? loopRing(s.lng, s.lat, s.rKm)
    : corridor(s.lng, s.lat, s.rKm * 2);
  return {
    coordinates,
    distanceM: s.distanceM,
    durationS: s.durationS,
    shape: s.loop ? "loop" : "point_to_point",
    source: "editorial-approx",
  };
}

const BUILTIN: Record<string, GeometryOverride> = Object.fromEntries(
  Object.entries(SPECS).map(([id, s]) => [id, buildFromSpec(id, s)])
);

let fileOverrides: Record<string, GeometryOverride> | null = null;

export function listBuiltinOverrideIds(): string[] {
  return Object.keys(BUILTIN);
}

export function getTourGeometryOverride(
  tourId: string
): GeometryOverride | null {
  if (fileOverrides === null && typeof process !== "undefined") {
    try {
      // eslint-disable-next-line @typescript-eslint/no-require-imports
      const fs = require("fs") as typeof import("fs");
      // eslint-disable-next-line @typescript-eslint/no-require-imports
      const path = require("path") as typeof import("path");
      const p = path.join(
        process.cwd(),
        "data/catalog/tour-geometry-overrides.json"
      );
      if (fs.existsSync(p)) {
        fileOverrides = JSON.parse(fs.readFileSync(p, "utf8")) as Record<
          string,
          GeometryOverride
        >;
      } else {
        fileOverrides = {};
      }
    } catch {
      fileOverrides = {};
    }
  }
  return (
    (fileOverrides && fileOverrides[tourId]) || BUILTIN[tourId] || null
  );
}
