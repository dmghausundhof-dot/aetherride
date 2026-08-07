/**
 * Seed trail segments for Discover overlay / Tour↔Track join.
 * Demo geometry — not a partner geometry mirror.
 */

export type TrailSegment = {
  id: string;
  name: string;
  geometry: GeoJSON.LineString;
  difficulty?: string;
  provider: "seed" | "osm" | "gpx" | "outdooractive";
  /** Approximate center [lng, lat] */
  center: [number, number];
};

function line(
  coords: [number, number][]
): GeoJSON.LineString {
  return { type: "LineString", coordinates: coords };
}

/** Schwarzwald / Demo corridor segments */
export const SEED_TRAILS: TrailSegment[] = [
  {
    id: "trail-kaltenbronn-flow",
    name: "Kaltenbronn Flow",
    difficulty: "S1–S2",
    provider: "seed",
    center: [8.42, 48.64],
    geometry: line([
      [8.41, 48.635],
      [8.418, 48.638],
      [8.425, 48.642],
      [8.432, 48.646],
      [8.438, 48.65],
    ]),
  },
  {
    id: "trail-baden-ridge",
    name: "Baden Ridge Traverse",
    difficulty: "S2",
    provider: "seed",
    center: [8.25, 48.05],
    geometry: line([
      [8.22, 48.03],
      [8.235, 48.04],
      [8.25, 48.05],
      [8.265, 48.055],
      [8.28, 48.06],
    ]),
  },
  {
    id: "trail-freiburg-west",
    name: "Freiburg West Connector",
    difficulty: "S0–S1",
    provider: "seed",
    center: [7.82, 47.98],
    geometry: line([
      [7.8, 47.97],
      [7.81, 47.975],
      [7.82, 47.98],
      [7.83, 47.985],
      [7.84, 47.99],
    ]),
  },
  {
    id: "trail-mooswald",
    name: "Mooswald Singletrack",
    difficulty: "S1",
    provider: "seed",
    center: [7.78, 48.01],
    geometry: line([
      [7.77, 48.005],
      [7.775, 48.008],
      [7.78, 48.012],
      [7.785, 48.015],
      [7.79, 48.018],
    ]),
  },
];

export function trailsNear(
  center: [number, number],
  radiusDeg = 0.35
): TrailSegment[] {
  const [lng, lat] = center;
  return SEED_TRAILS.filter((t) => {
    const d = Math.hypot(t.center[0] - lng, t.center[1] - lat);
    return d <= radiusDeg;
  });
}

export function getTrailById(id: string): TrailSegment | undefined {
  return SEED_TRAILS.find((t) => t.id === id);
}
