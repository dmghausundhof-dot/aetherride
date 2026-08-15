/**
 * DACH (+ LI) GPS honesty — no Heidelberg/Berlin default when the rider
 * is in Wien. Nearby FR/IT fringe is "outside" for curated-seed claims.
 */

export type DachHonesty = "dach_curated" | "dach_thin" | "outside_dach";

/** Generous country boxes (not a cadastral boundary). */
export function pointInGermany(lat: number, lng: number): boolean {
  return lat >= 47.27 && lat <= 55.1 && lng >= 5.86 && lng <= 15.05;
}

export function pointInAustria(lat: number, lng: number): boolean {
  return lat >= 46.37 && lat <= 49.02 && lng >= 9.53 && lng <= 17.17;
}

export function pointInSwitzerland(lat: number, lng: number): boolean {
  return lat >= 45.82 && lat <= 47.81 && lng >= 5.96 && lng <= 10.49;
}

export function pointInLiechtenstein(lat: number, lng: number): boolean {
  return lat >= 47.04 && lat <= 47.27 && lng >= 9.47 && lng <= 9.64;
}

export function pointInDach(lat: number, lng: number): boolean {
  return (
    pointInGermany(lat, lng) ||
    pointInAustria(lat, lng) ||
    pointInSwitzerland(lat, lng) ||
    pointInLiechtenstein(lat, lng)
  );
}

export function dachHonesty(opts: {
  inDach: boolean;
  nearbySeedCount: number;
}): DachHonesty {
  if (!opts.inDach) return "outside_dach";
  return opts.nearbySeedCount >= 3 ? "dach_curated" : "dach_thin";
}

export function dachHonestyLabel(honesty: DachHonesty): string {
  switch (honesty) {
    case "dach_curated":
      return "~60 Min um dich";
    case "dach_thin":
      return "Wenige kuratierte Seeds in der Nähe — OSM-Trails live";
    case "outside_dach":
      return "Außerhalb DACH — weniger kuratierte Seeds, OSM-Viewport live";
  }
}
