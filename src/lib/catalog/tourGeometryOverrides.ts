/**
 * Redaktionelle Tour-Linien (GeoJSON [lng,lat]).
 * OSRM-Prebake in data/catalog/tour-geometry-overrides.json gewinnt;
 * sonst SPECS, sonst dichte Näherung aus dem öffentlichen Katalog.
 */

import bakedRaw from "../../../data/catalog/tour-geometry-overrides.json";
import { getPublicTour } from "./publicTours";

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
  n = 18
): [number, number][] {
  const pts: [number, number][] = [];
  const count = Math.max(12, n);
  for (let i = 0; i < count; i++) {
    const a = (i / count) * Math.PI * 2;
    pts.push(
      offset(lng, lat, Math.cos(a) * rKm, Math.sin(a) * rKm * 0.85)
    );
  }
  pts.push(pts[0]);
  return pts;
}

/** Extra vertices so Discover does not treat the line as a 4-point ruler. */
function densify(
  coords: [number, number][],
  minPts = 16
): [number, number][] {
  if (coords.length >= minPts) return coords;
  if (coords.length < 2) return coords;
  const out: [number, number][] = [];
  const gaps = coords.length - 1;
  const per = Math.max(1, Math.ceil((minPts - 1) / gaps));
  for (let i = 0; i < gaps; i++) {
    const a = coords[i];
    const b = coords[i + 1];
    out.push(a);
    for (let s = 1; s < per; s++) {
      const t = s / per;
      out.push([a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t]);
    }
  }
  out.push(coords[coords.length - 1]);
  return out;
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
  "r-heidelberg-road": {
    lng: 8.71,
    lat: 49.41,
    loop: true,
    rKm: 4.0,
    distanceM: 28000,
    durationS: 85 * 60,
  },
  "r-mannheim-urban": {
    lng: 8.47,
    lat: 49.49,
    loop: true,
    rKm: 2.0,
    distanceM: 14000,
    durationS: 45 * 60,
  },
  "r-odenwald-gravel": {
    lng: 8.75,
    lat: 49.48,
    loop: true,
    rKm: 6.5,
    distanceM: 48000,
    durationS: 165 * 60,
  },
  "r-kaiserstuhl-gravel": {
    lng: 7.67,
    lat: 48.09,
    loop: true,
    rKm: 5.0,
    distanceM: 36000,
    durationS: 120 * 60,
  },
  "r-freiburg-road": {
    lng: 7.78,
    lat: 48.0,
    loop: true,
    rKm: 7.0,
    distanceM: 52000,
    durationS: 145 * 60,
  },
  "r-schauinsland-emtb": {
    lng: 7.9,
    lat: 47.91,
    loop: true,
    rKm: 4.5,
    distanceM: 34000,
    durationS: 140 * 60,
  },
  "r-titisee-road": {
    lng: 8.15,
    lat: 47.91,
    loop: false,
    rKm: 10,
    distanceM: 44000,
    durationS: 160 * 60,
  },
  "r-stuttgart-road": {
    lng: 9.1,
    lat: 48.78,
    loop: true,
    rKm: 5.5,
    distanceM: 41000,
    durationS: 130 * 60,
  },
  "r-muenchen-urban": {
    lng: 11.59,
    lat: 48.15,
    loop: true,
    rKm: 2.4,
    distanceM: 19000,
    durationS: 55 * 60,
  },
  "r-chiemsee-road": {
    lng: 12.4,
    lat: 47.86,
    loop: true,
    rKm: 9.0,
    distanceM: 64000,
    durationS: 180 * 60,
  },
  "r-nuernberg-urban": {
    lng: 11.08,
    lat: 49.45,
    loop: true,
    rKm: 2.8,
    distanceM: 21000,
    durationS: 60 * 60,
  },
  "r-koeln-urban": {
    lng: 6.96,
    lat: 50.94,
    loop: true,
    rKm: 3.0,
    distanceM: 24000,
    durationS: 70 * 60,
  },
  "r-mainz-road": {
    lng: 8.25,
    lat: 50.0,
    loop: false,
    rKm: 16,
    distanceM: 56000,
    durationS: 155 * 60,
  },
  "r-konstanz-urban": {
    lng: 9.18,
    lat: 47.66,
    loop: true,
    rKm: 2.2,
    distanceM: 17000,
    durationS: 50 * 60,
  },
  "r-ulm-urban": {
    lng: 9.99,
    lat: 48.4,
    loop: true,
    rKm: 2.0,
    distanceM: 15000,
    durationS: 45 * 60,
  },
  "r-starnberg-road": {
    lng: 11.34,
    lat: 47.99,
    loop: true,
    rKm: 7.5,
    distanceM: 52000,
    durationS: 150 * 60,
  },
  "r-ammersee-gravel": {
    lng: 11.1,
    lat: 48.0,
    loop: true,
    rKm: 6.2,
    distanceM: 46000,
    durationS: 155 * 60,
  },
  "r-garmisch-emtb": {
    lng: 11.1,
    lat: 47.49,
    loop: true,
    rKm: 5.0,
    distanceM: 38000,
    durationS: 150 * 60,
  },
  "r-lindau-road": {
    lng: 9.68,
    lat: 47.55,
    loop: false,
    rKm: 10,
    distanceM: 34000,
    durationS: 100 * 60,
  },
  "r-friedrichshafen-urban": {
    lng: 9.48,
    lat: 47.65,
    loop: true,
    rKm: 2.1,
    distanceM: 16000,
    durationS: 48 * 60,
  },
  "r-regensburg-urban": {
    lng: 12.1,
    lat: 49.02,
    loop: true,
    rKm: 2.3,
    distanceM: 18000,
    durationS: 55 * 60,
  },
  "r-augsburg-road": {
    lng: 10.9,
    lat: 48.37,
    loop: true,
    rKm: 6.5,
    distanceM: 48000,
    durationS: 135 * 60,
  },
  "r-passau-touring": {
    lng: 13.46,
    lat: 48.57,
    loop: false,
    rKm: 12,
    distanceM: 42000,
    durationS: 140 * 60,
  },
  "r-wuerzburg-road": {
    lng: 9.93,
    lat: 49.79,
    loop: true,
    rKm: 6.0,
    distanceM: 44000,
    durationS: 130 * 60,
  },
  "r-dresden-urban": {
    lng: 13.74,
    lat: 51.05,
    loop: true,
    rKm: 2.6,
    distanceM: 20000,
    durationS: 60 * 60,
  },
  "r-innsbruck-road": {
    lng: 11.39,
    lat: 47.27,
    loop: true,
    rKm: 6.5,
    distanceM: 48000,
    durationS: 140 * 60,
  },
  "r-zillertal-gravel": {
    lng: 11.87,
    lat: 47.23,
    loop: true,
    rKm: 7.2,
    distanceM: 55000,
    durationS: 180 * 60,
  },
  "r-chamonix-emtb": {
    lng: 6.87,
    lat: 45.92,
    loop: true,
    rKm: 4.2,
    distanceM: 32000,
    durationS: 135 * 60,
  },
  "r-geneve-urban": {
    lng: 6.15,
    lat: 46.2,
    loop: true,
    rKm: 2.8,
    distanceM: 22000,
    durationS: 65 * 60,
  },
  "r-hamburg-alster": {
    lng: 10.0,
    lat: 53.557,
    loop: true,
    rKm: 2.8,
    distanceM: 18000,
    durationS: 55 * 60,
  },
  "r-kiel-foerde": {
    lng: 10.14,
    lat: 54.323,
    loop: true,
    rKm: 5.0,
    distanceM: 32000,
    durationS: 95 * 60,
  },
  "r-berlin-tempelhof": {
    lng: 13.404,
    lat: 52.474,
    loop: true,
    rKm: 1.9,
    distanceM: 12000,
    durationS: 40 * 60,
  },
  "r-potsdam-havel": {
    lng: 13.064,
    lat: 52.399,
    loop: true,
    rKm: 6.0,
    distanceM: 38000,
    durationS: 130 * 60,
  },
  "r-duesseldorf-rhein": {
    lng: 6.773,
    lat: 51.227,
    loop: true,
    rKm: 3.5,
    distanceM: 22000,
    durationS: 65 * 60,
  },
  "r-frankfurt-main": {
    lng: 8.682,
    lat: 50.11,
    loop: true,
    rKm: 2.5,
    distanceM: 16000,
    durationS: 50 * 60,
  },
  "r-leipzig-neuseen": {
    lng: 12.372,
    lat: 51.247,
    loop: true,
    rKm: 6.7,
    distanceM: 42000,
    durationS: 130 * 60,
  },
  "r-wien-donauinsel": {
    lng: 16.414,
    lat: 48.222,
    loop: true,
    rKm: 3.8,
    distanceM: 24000,
    durationS: 70 * 60,
  },
  "r-zuerich-see": {
    lng: 8.545,
    lat: 47.354,
    loop: true,
    rKm: 3.2,
    distanceM: 20000,
    durationS: 65 * 60,
  },
};

function buildFromSpec(id: string, s: Spec): GeometryOverride {
  const coordinates = s.loop
    ? loopRing(s.lng, s.lat, s.rKm)
    : densify(corridor(s.lng, s.lat, s.rKm * 2));
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

const FILE = bakedRaw as unknown as Record<string, GeometryOverride>;

export function listBuiltinOverrideIds(): string[] {
  return Object.keys(BUILTIN);
}

function overrideFromPublicTour(tourId: string): GeometryOverride | null {
  const tour = getPublicTour(tourId);
  if (!tour) return null;
  const [lng, lat] = tour.center;
  const rKm = Math.max(1.2, Math.min(tour.distanceKm / (2 * Math.PI), 14));
  const coordinates = tour.loop
    ? loopRing(lng, lat, rKm, 18)
    : densify(
        corridor(lng, lat, Math.min(Math.max(tour.distanceKm * 0.45, 4), 40))
      );
  return {
    coordinates,
    distanceM: Math.round(tour.distanceKm * 1000),
    durationS: Math.round(tour.durationMin * 60),
    shape: tour.loop ? "loop" : "point_to_point",
    source: "editorial-approx",
  };
}

export function getTourGeometryOverride(
  tourId: string
): GeometryOverride | null {
  const baked = FILE[tourId];
  if (baked?.coordinates && baked.coordinates.length >= 8) return baked;
  return BUILTIN[tourId] ?? overrideFromPublicTour(tourId);
}
