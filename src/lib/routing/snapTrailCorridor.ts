/**
 * Pick an OSM trail/cycleway that belongs on an A–B route the engine missed.
 * Used after GraphHopper `bike` (often skips path/track) so MTB/Gravel
 * can still put real trails into the nav line. City/E-Bike use the
 * separate cycleway snap — not path/track corridor splice.
 */

import type { ClientRouteResult, RoutingProfile } from "@/lib/routing/profiles";
import { isRideProfileId, isTrailSuitable } from "@/lib/routing/profiles";
import type { NavStep } from "@/lib/routing/navSteps";
import {
  haversineM,
  lineLengthM,
  pointAlongRoute,
  projectOntoRoute,
} from "@/lib/routing/routeProgress";
import type { TrailSegment } from "@/lib/routing/trailSegments";

const MIN_TRAIL_M = 250;
const MAX_ENDPOINT_OFF_M = 700;
const ALREADY_ON_ROUTE_M = 32;
const MAX_DETOUR = 1.55;
const DEST_ON_TRAIL_M = 90;
const LAST_MILE_MAX_M = 2000;

/** City cycleway: short slices, tight tube, no park-path fishing. */
const CITY_MIN_M = 80;
const CITY_MAX_ENDPOINT_OFF_M = 55;
const CITY_ALREADY_ON_ROUTE_M = 24;
const CITY_MAX_DETOUR = 1.18;
const CITY_MIN_SPAN_M = 70;
const CITY_MIN_ROUTE_M = 800;
const CITY_OVERLAP_PAD_M = 40;

export function profileWantsCorridorTrails(profile: RoutingProfile): boolean {
  return (
    profile === "mtb_allmountain" ||
    profile === "mtb_enduro" ||
    profile === "downhill" ||
    profile === "emtb" ||
    profile === "gravel" ||
    profile === "hiking"
  );
}

function orientTowardFrom(
  coords: [number, number][],
  from: [number, number],
): [number, number][] {
  if (coords.length < 2) return coords;
  const start = coords[0];
  const end = coords[coords.length - 1];
  const d0 = haversineM(from[1], from[0], start[1], start[0]);
  const d1 = haversineM(from[1], from[0], end[1], end[0]);
  return d1 < d0 ? [...coords].reverse() : coords;
}

function medianCrossTrackM(
  coords: [number, number][],
  route: [number, number][],
): number {
  if (coords.length === 0) return Infinity;
  const samples = 5;
  const ds: number[] = [];
  for (let i = 0; i < samples; i++) {
    const t = i / (samples - 1);
    const idx = Math.min(
      coords.length - 1,
      Math.round(t * (coords.length - 1)),
    );
    const p = coords[idx];
    ds.push(projectOntoRoute(route, p[1], p[0]).crossTrackM);
  }
  ds.sort((a, b) => a - b);
  return ds[Math.floor(ds.length / 2)] ?? Infinity;
}

/** Ride scale from OSM `mtb:scale` — not an untagged farm track. */
export function trailHasRideScale(difficulty?: string): boolean {
  return /S[0-3]/i.test(difficulty ?? "");
}

/**
 * Cycleway / bridleway, or a way with a real MTB scale.
 * Untagged path/track is usually a farm or field path.
 */
export function trailIsCorridorEligible(trail: {
  highway?: string;
  difficulty?: string;
}): boolean {
  const hw = (trail.highway ?? "").toLowerCase();
  if (hw === "cycleway" || hw === "bridleway") return true;
  return trailHasRideScale(trail.difficulty);
}

function highwayOk(profile: RoutingProfile, highway?: string): boolean {
  const hw = (highway ?? "").toLowerCase();
  if (profile === "urban" || profile === "ebike") {
    return hw === "cycleway" || hw === "path";
  }
  if (profile === "gravel") {
    return hw === "track" || hw === "path" || hw === "cycleway";
  }
  if (profile === "hiking") {
    return hw === "path" || hw === "footway" || hw === "track";
  }
  return hw === "path" || hw === "track";
}

function trailFitsProfile(
  profile: RoutingProfile,
  trail: TrailSegment,
): boolean {
  if (!highwayOk(profile, trail.highway)) return false;
  if (!isRideProfileId(profile)) {
    return (
      (trail.highway ?? "") === "cycleway" || (trail.highway ?? "") === "path"
    );
  }
  return isTrailSuitable(profile, {
    highway: trail.highway,
    mtb_scale: trail.difficulty,
    surface: trail.surface,
  });
}

export function destLiesOnTrail(
  trail: TrailSegment,
  to: [number, number],
  maxOffM = DEST_ON_TRAIL_M,
): boolean {
  const coords = (trail.geometry?.coordinates ?? []) as [number, number][];
  if (coords.length < 2) return false;
  return projectOntoRoute(coords, to[1], to[0]).crossTrackM <= maxOffM;
}

function closestAlongInWindow(
  coords: [number, number][],
  lat: number,
  lng: number,
  aM: number,
  bM: number,
): number {
  const lo = Math.min(aM, bM);
  const hi = Math.max(aM, bM);
  let bestAlong = lo;
  let bestD = Infinity;
  for (let m = lo; m <= hi; m += 40) {
    const p = pointAlongRoute(coords, m);
    const d = haversineM(lat, lng, p[1], p[0]);
    if (d < bestD) {
      bestD = d;
      bestAlong = m;
    }
  }
  const end = pointAlongRoute(coords, hi);
  const dEnd = haversineM(lat, lng, end[1], end[0]);
  if (dEnd < bestD) bestAlong = hi;
  return bestAlong;
}

function sliceBetween(
  coords: [number, number][],
  startM: number,
  endM: number,
): [number, number][] {
  const lo = Math.min(startM, endM);
  const hi = Math.max(startM, endM);
  const start = pointAlongRoute(coords, lo);
  const end = pointAlongRoute(coords, hi);
  const out: [number, number][] = [start];
  let walked = 0;
  for (let i = 1; i < coords.length; i++) {
    const a = coords[i - 1];
    const b = coords[i];
    const seg = haversineM(a[1], a[0], b[1], b[0]);
    const next = walked + seg;
    if (next > lo && walked < hi) {
      if (walked >= lo && next <= hi) out.push(b);
    }
    walked = next;
  }
  const last = out[out.length - 1];
  if (!last || haversineM(last[1], last[0], end[1], end[0]) > 2) {
    out.push(end);
  }
  return out.length >= 2 ? out : [start, end];
}

export type TrailLastMile = {
  coords: [number, number][];
  join: [number, number];
  dest: [number, number];
  lastMileM: number;
  destOffM: number;
};

/** Join → tap on the trail. Never past dest, never the whole S-grade line. */
export function clipTrailLastMile(opts: {
  coords: [number, number][];
  from: [number, number];
  to: [number, number];
  maxDestOffM?: number;
  maxLastMileM?: number;
}): TrailLastMile | null {
  const coords = opts.coords;
  if (coords.length < 2) return null;
  const maxOff = opts.maxDestOffM ?? DEST_ON_TRAIL_M;
  const maxMile = opts.maxLastMileM ?? LAST_MILE_MAX_M;
  const destP = projectOntoRoute(coords, opts.to[1], opts.to[0]);
  if (destP.crossTrackM > maxOff) return null;
  const len = lineLengthM(coords);
  const destAlong = Math.max(0, Math.min(len, destP.distanceAlongM));
  const fromP = projectOntoRoute(coords, opts.from[1], opts.from[0]);
  const dStart = haversineM(
    opts.from[1],
    opts.from[0],
    coords[0][1],
    coords[0][0],
  );
  const last = coords[coords.length - 1];
  const dEnd = haversineM(opts.from[1], opts.from[0], last[1], last[0]);
  const fromStartSide =
    fromP.crossTrackM < 120
      ? fromP.distanceAlongM <= destAlong
      : dStart <= dEnd;

  let joinAlong: number;
  let endAlong: number;
  if (fromStartSide) {
    endAlong = destAlong;
    joinAlong = Math.max(0, destAlong - maxMile);
    if (
      fromP.crossTrackM < 250 &&
      fromP.distanceAlongM >= joinAlong &&
      fromP.distanceAlongM <= destAlong
    ) {
      joinAlong = fromP.distanceAlongM;
    } else {
      joinAlong = closestAlongInWindow(
        coords,
        opts.from[1],
        opts.from[0],
        joinAlong,
        destAlong,
      );
    }
  } else {
    joinAlong = destAlong;
    endAlong = Math.min(len, destAlong + maxMile);
    if (
      fromP.crossTrackM < 250 &&
      fromP.distanceAlongM >= destAlong &&
      fromP.distanceAlongM <= endAlong
    ) {
      endAlong = fromP.distanceAlongM;
    } else {
      endAlong = closestAlongInWindow(
        coords,
        opts.from[1],
        opts.from[0],
        destAlong,
        endAlong,
      );
    }
  }

  let geom = sliceBetween(coords, joinAlong, endAlong);
  if (joinAlong > endAlong) geom = [...geom].reverse();
  if (geom.length < 2) {
    const dest = pointAlongRoute(coords, destAlong);
    geom = [dest, dest];
  }
  return {
    coords: geom,
    join: geom[0],
    dest: geom[geom.length - 1],
    lastMileM: lineLengthM(geom),
    destOffM: destP.crossTrackM,
  };
}

export function pickTrailAlongRoute(opts: {
  profile: RoutingProfile;
  from: [number, number];
  to: [number, number];
  route: ClientRouteResult;
  trails: TrailSegment[];
}): TrailSegment | null {
  if (!profileWantsCorridorTrails(opts.profile)) return null;
  const routeCoords = (opts.route.geometry?.coordinates ?? []) as [
    number,
    number,
  ][];
  if (routeCoords.length < 2) return null;
  const routeM = Math.max(opts.route.distanceM, lineLengthM(routeCoords));
  if (routeM < 400) return null;

  const destHits = opts.trails.filter(
    (t) => destLiesOnTrail(t, opts.to, DEST_ON_TRAIL_M) && trailIsCorridorEligible(t),
  );
  // Pin in a field: do not fish S-trails along the A–B (that cuts through
  // meadows). Last-mile only when the rider’s dest sits on the trail.
  if (!destHits.length) return null;
  const pool = destHits;

  let best: { trail: TrailSegment; score: number } | null = null;

  for (const raw of pool) {
    const rawCoords = (raw.geometry?.coordinates ?? []) as [number, number][];
    if (rawCoords.length < 2) continue;
    if (!trailFitsProfile(opts.profile, raw)) continue;
    if (!trailIsCorridorEligible(raw)) continue;

    const onDest = destHits.length > 0;
    let coords = orientTowardFrom(rawCoords, opts.from);
    if (onDest) {
      const mile = clipTrailLastMile({
        coords: rawCoords,
        from: opts.from,
        to: opts.to,
      });
      if (!mile || mile.coords.length < 2) continue;
      coords = mile.coords;
    }

    const trailM = lineLengthM(coords);
    if (!onDest && trailM < MIN_TRAIL_M) continue;
    if (onDest && trailM < 40) continue;

    const entry = coords[0];
    const exit = coords[coords.length - 1];
    const entryP = projectOntoRoute(routeCoords, entry[1], entry[0]);
    const exitP = projectOntoRoute(routeCoords, exit[1], exit[0]);
    if (
      entryP.crossTrackM > MAX_ENDPOINT_OFF_M ||
      exitP.crossTrackM > MAX_ENDPOINT_OFF_M
    ) {
      continue;
    }
    if (medianCrossTrackM(coords, routeCoords) < ALREADY_ON_ROUTE_M) {
      continue;
    }
    const span = exitP.distanceAlongM - entryP.distanceAlongM;
    if (span < (onDest ? 40 : 180)) continue;

    const viaM =
      haversineM(opts.from[1], opts.from[0], entry[1], entry[0]) +
      trailM +
      haversineM(exit[1], exit[0], opts.to[1], opts.to[0]);
    if (viaM > routeM * MAX_DETOUR + 400) continue;

    if (!onDest) {
      const pastDestM = haversineM(exit[1], exit[0], opts.to[1], opts.to[0]);
      if (pastDestM > 800 && trailM > 1500) continue;
    }

    const score =
      trailM + span * 0.6 - (entryP.crossTrackM + exitP.crossTrackM) * 0.4;
    if (!best || score > best.score) {
      best = {
        trail: {
          ...raw,
          geometry: { type: "LineString", coordinates: coords },
        },
        score,
      };
    }
  }

  return best?.trail ?? null;
}

export function profileWantsCorridorCycleways(
  profile: RoutingProfile,
): boolean {
  return profile === "urban" || profile === "ebike";
}

type CyclewayCandidate = {
  trail: TrailSegment;
  entryAlong: number;
  exitAlong: number;
  score: number;
};

/**
 * Separate `highway=cycleway` slices GraphHopper left on the carriageway.
 * Never splices `cycleway=lane` (no second geometry).
 */
export function pickCyclewaysAlongRoute(opts: {
  profile: RoutingProfile;
  from: [number, number];
  to: [number, number];
  route: ClientRouteResult;
  trails: TrailSegment[];
}): TrailSegment[] {
  if (!profileWantsCorridorCycleways(opts.profile)) return [];
  const routeCoords = (opts.route.geometry?.coordinates ?? []) as [
    number,
    number,
  ][];
  if (routeCoords.length < 2) return [];
  const routeM = Math.max(opts.route.distanceM, lineLengthM(routeCoords));
  if (routeM < CITY_MIN_ROUTE_M) return [];

  const candidates: CyclewayCandidate[] = [];

  for (const raw of opts.trails) {
    const hw = (raw.highway ?? "").toLowerCase();
    if (hw !== "cycleway") continue;
    const rawCoords = (raw.geometry?.coordinates ?? []) as [number, number][];
    if (rawCoords.length < 2) continue;

    const coords = orientTowardFrom(rawCoords, opts.from);
    const trailM = lineLengthM(coords);
    if (trailM < CITY_MIN_M) continue;

    const entry = coords[0];
    const exit = coords[coords.length - 1];
    const entryP = projectOntoRoute(routeCoords, entry[1], entry[0]);
    const exitP = projectOntoRoute(routeCoords, exit[1], exit[0]);
    if (
      entryP.crossTrackM > CITY_MAX_ENDPOINT_OFF_M ||
      exitP.crossTrackM > CITY_MAX_ENDPOINT_OFF_M
    ) {
      continue;
    }
    if (medianCrossTrackM(coords, routeCoords) < CITY_ALREADY_ON_ROUTE_M) {
      continue;
    }
    const span = exitP.distanceAlongM - entryP.distanceAlongM;
    if (span < CITY_MIN_SPAN_M) continue;

    const viaM =
      haversineM(opts.from[1], opts.from[0], entry[1], entry[0]) +
      trailM +
      haversineM(exit[1], exit[0], opts.to[1], opts.to[0]);
    if (viaM > routeM * CITY_MAX_DETOUR + 80) continue;

    candidates.push({
      trail: {
        ...raw,
        geometry: { type: "LineString", coordinates: coords },
      },
      entryAlong: entryP.distanceAlongM,
      exitAlong: exitP.distanceAlongM,
      score:
        trailM + span * 0.6 - (entryP.crossTrackM + exitP.crossTrackM) * 0.8,
    });
  }

  candidates.sort((a, b) => b.score - a.score);
  const kept: CyclewayCandidate[] = [];
  for (const c of candidates) {
    const overlaps = kept.some(
      (k) =>
        !(
          c.exitAlong <= k.entryAlong + CITY_OVERLAP_PAD_M ||
          c.entryAlong >= k.exitAlong - CITY_OVERLAP_PAD_M
        ),
    );
    if (!overlaps) kept.push(c);
  }
  kept.sort((a, b) => b.entryAlong - a.entryAlong);
  return kept.map((k) => k.trail);
}

export type CorridorRouteShape = {
  distanceM: number;
  durationS: number;
  geometry: GeoJSON.LineString;
  warnings?: string[];
  steps?: NavStep[];
};

function dropStaleRoadWarnings(w: string): boolean {
  return !/überwiegend Straßen|Wenig Track|Wenig eigener Radweg/i.test(w);
}

function closeEnough(
  a: [number, number],
  b: [number, number],
  maxM = 12,
): boolean {
  return haversineM(a[1], a[0], b[1], b[0]) < maxM;
}

export type CorridorKind = "trail" | "cycleway";

const GENERIC_CORRIDOR_NAMES = new Set([
  "pfad",
  "path",
  "trail",
  "footway",
  "track",
  "radweg",
  "cycleway",
  "weg",
]);

export function isGenericCorridorName(name: string): boolean {
  return GENERIC_CORRIDOR_NAMES.has(name.trim().toLowerCase());
}

function corridorAnnounce(trail: TrailSegment, kind: CorridorKind) {
  if (kind === "cycleway") {
    const name = trail.name.trim() || "Radweg";
    const spoken = /^radweg\b/i.test(name) ? name : `Radweg ${name}`;
    return {
      warning: isGenericCorridorName(name)
        ? undefined
        : `Radweg „${name}“ in die Navi übernommen.`,
      enter: spoken,
      leave: `Ende ${name}`,
      enterEn: spoken,
      leaveEn: `End ${name}`,
    };
  }
  const name = trail.name.trim() || "Trail";
  return {
    warning: isGenericCorridorName(name)
      ? undefined
      : `Trail „${name}“ in die Navi übernommen.`,
    enter: `Trail ${name}`,
    leave: `Ende ${name}`,
    enterEn: `Trail ${name}`,
    leaveEn: `End ${name}`,
  };
}

function asClientRoute(
  profile: RoutingProfile,
  route: CorridorRouteShape,
): ClientRouteResult {
  return {
    distanceM: route.distanceM,
    durationS: route.durationS,
    geometry: route.geometry,
    engine: "graphhopper",
    profile,
    warnings: route.warnings,
  };
}

/**
 * Replace the engine slice between trail entry/exit with OSM geometry.
 * Fail-open: returns null when the trail does not span a real corridor.
 */
export function spliceTrailIntoRoute<T extends CorridorRouteShape>(
  route: T,
  trail: TrailSegment,
  opts?: { kind?: CorridorKind; announce?: boolean },
): T | null {
  const kind = opts?.kind ?? "trail";
  const announce = opts?.announce !== false;
  const minSpan = kind === "cycleway" ? 50 : 80;
  const routeCoords = (route.geometry?.coordinates ?? []) as [number, number][];
  const trailCoords = (trail.geometry?.coordinates ?? []) as [number, number][];
  if (routeCoords.length < 2 || trailCoords.length < 2) return null;

  const entry = trailCoords[0];
  const exit = trailCoords[trailCoords.length - 1];
  if (!entry || !exit) return null;
  const entryP = projectOntoRoute(routeCoords, entry[1], entry[0]);
  const exitP = projectOntoRoute(routeCoords, exit[1], exit[0]);
  if (exitP.distanceAlongM <= entryP.distanceAlongM + minSpan) return null;

  const iEntry = entryP.segmentIndex;
  let iExit = Math.min(routeCoords.length - 1, exitP.segmentIndex + 1);
  if (iExit <= iEntry) {
    iExit = Math.min(routeCoords.length - 1, iEntry + 1);
  }
  if (iExit <= iEntry) return null;
  const head = routeCoords.slice(0, iEntry + 1);
  const tail = routeCoords.slice(iExit);

  let mid = trailCoords;
  const headLast = head[head.length - 1];
  const midFirst = mid[0];
  if (headLast && midFirst && closeEnough(headLast, midFirst)) {
    mid = mid.slice(1);
  }
  const midLast = mid[mid.length - 1];
  const tailFirst = tail[0];
  if (tailFirst && midLast && closeEnough(midLast, tailFirst)) {
    mid = mid.slice(0, -1);
  }
  const coords = [...head, ...mid, ...tail];
  if (coords.length < 2) return null;

  const distanceM = Math.max(1, Math.round(lineLengthM(coords)));
  const durationS = Math.max(
    1,
    Math.round(route.durationS * (distanceM / Math.max(1, route.distanceM))),
  );
  const labels = corridorAnnounce(trail, kind);
  const trailStartM = Math.round(lineLengthM(head));
  const trailJoin: [number, number][] = [];
  if (headLast) trailJoin.push(headLast);
  trailJoin.push(...mid);
  const trailGeomM = Math.round(
    lineLengthM(trailJoin.length ? trailJoin : mid),
  );
  const trailEndM = trailStartM + Math.max(1, trailGeomM);
  const slug = trail.id.replace(/[^\w-]+/g, "").slice(0, 24) || "seg";

  const trailSteps: NavStep[] = [
    {
      id: `osm-${kind}-in-${slug}`,
      type: "fork",
      instruction: labels.enter,
      instructionEn: labels.enterEn,
      distanceAlongM: trailStartM,
      lengthM: Math.max(1, trailEndM - trailStartM),
      coordinate: { lng: entry[0], lat: entry[1] },
      streetName: trail.name.trim() || labels.enter,
    },
    {
      id: `osm-${kind}-out-${slug}`,
      type: "merge",
      instruction: labels.leave,
      instructionEn: labels.leaveEn,
      distanceAlongM: trailEndM,
      lengthM: 0,
      coordinate: { lng: exit[0], lat: exit[1] },
    },
  ];

  const orig = route.steps ?? [];
  const before = orig.filter((s) => s.distanceAlongM < trailStartM - 20);
  const scale = distanceM / Math.max(1, route.distanceM);
  const after = orig
    .filter((s) => s.distanceAlongM > trailEndM + 20 && s.type !== "arrive")
    .map((s) => ({
      ...s,
      distanceAlongM: Math.round(s.distanceAlongM * scale),
    }));
  const last = coords[coords.length - 1];
  if (!last) return null;
  const arrive: NavStep = {
    id: "osm-trail-arrive",
    type: "arrive",
    instruction: "Ziel erreicht",
    instructionEn: "You have arrived",
    distanceAlongM: distanceM,
    lengthM: 0,
    coordinate: { lng: last[0], lat: last[1] },
  };

  const warnings = announce
    ? [
        ...(labels.warning ? [labels.warning] : []),
        ...(route.warnings ?? []).filter(dropStaleRoadWarnings),
      ]
    : [...(route.warnings ?? []).filter(dropStaleRoadWarnings)];

  return {
    ...route,
    distanceM,
    durationS,
    geometry: { type: "LineString", coordinates: coords },
    warnings,
    steps: [...before, ...trailSteps, ...after, arrive],
  };
}

export function applyCorridorTrailSnap<T extends CorridorRouteShape>(opts: {
  profile: RoutingProfile;
  from: [number, number];
  to: [number, number];
  route: T;
  trails: TrailSegment[];
}): T {
  const destHits = opts.trails.filter(
    (t) => destLiesOnTrail(t, opts.to, DEST_ON_TRAIL_M) && trailIsCorridorEligible(t),
  );
  if (destHits.length) {
    let best: { trail: TrailSegment; joinOff: number } | null = null;
    for (const raw of destHits) {
      const rawCoords = (raw.geometry?.coordinates ?? []) as [number, number][];
      const mile = clipTrailLastMile({
        coords: rawCoords,
        from: opts.from,
        to: opts.to,
      });
      if (!mile || mile.coords.length < 2) continue;
      const routeCoords = (opts.route.geometry?.coordinates ?? []) as [
        number,
        number,
      ][];
      if (routeCoords.length < 2) continue;
      const joinP = projectOntoRoute(routeCoords, mile.join[1], mile.join[0]);
      // Engine already near the join → splice last mile. Otherwise leave GH
      // (client plans an efficient approach + last mile).
      if (joinP.crossTrackM > DEST_ON_TRAIL_M) continue;
      if (!best || joinP.crossTrackM < best.joinOff) {
        best = {
          trail: {
            ...raw,
            geometry: { type: "LineString", coordinates: mile.coords },
          },
          joinOff: joinP.crossTrackM,
        };
      }
    }
    if (!best) return opts.route;
    return spliceTrailIntoRoute(opts.route, best.trail) ?? opts.route;
  }

  const picked = pickTrailAlongRoute({
    profile: opts.profile,
    from: opts.from,
    to: opts.to,
    route: asClientRoute(opts.profile, opts.route),
    trails: opts.trails,
  });
  if (!picked) return opts.route;
  return spliceTrailIntoRoute(opts.route, picked) ?? opts.route;
}

export function applyCorridorCyclewaySnap<T extends CorridorRouteShape>(opts: {
  profile: RoutingProfile;
  from: [number, number];
  to: [number, number];
  route: T;
  trails: TrailSegment[];
}): T {
  const picked = pickCyclewaysAlongRoute({
    profile: opts.profile,
    from: opts.from,
    to: opts.to,
    route: asClientRoute(opts.profile, opts.route),
    trails: opts.trails,
  });
  if (!picked.length) return opts.route;

  let next: T = opts.route;
  const spliced: TrailSegment[] = [];
  for (const slice of picked) {
    const attempt = spliceTrailIntoRoute(next, slice, {
      kind: "cycleway",
      announce: false,
    });
    if (attempt) {
      next = attempt;
      spliced.push(slice);
    }
  }
  if (!spliced.length) return opts.route;

  const summary =
    spliced.length === 1
      ? `Radweg „${spliced[0].name.trim() || "Radweg"}“ in die Navi übernommen.`
      : `${spliced.length} Radweg-Abschnitte in die Navi übernommen.`;
  return {
    ...next,
    warnings: [summary, ...(next.warnings ?? []).filter(dropStaleRoadWarnings)],
  };
}

/** Named Ort/Photon stays put. Unlabeled map via may snap onto a trail. */
export function viaMaySnapOntoTrail(label?: string | null): boolean {
  const t = (label ?? "").trim();
  if (!t) return true;
  if (/^-?\d+[.,]\d+/.test(t)) return true;
  return false;
}

/** Vias may snap onto a path / tagged trail — never an untagged farm track. */
export function trailsForViaSnap(
  trails: TrailSegment[],
): [number, number][][] {
  return trails
    .filter((t) => trailIsCorridorEligible(t))
    .map((t) => (t.geometry?.coordinates ?? []) as [number, number][])
    .filter((coords) => coords.length >= 2);
}

/** Snap a via/place onto the nearest trail. Unchanged if none within maxOffM. */
export function snapPointOntoTrails(
  point: [number, number],
  trails: [number, number][][],
  maxOffM = DEST_ON_TRAIL_M
): [number, number] {
  let bestOff = maxOffM + 1;
  let best: [number, number] | null = null;
  for (const coords of trails) {
    if (coords.length < 2) continue;
    const p = projectOntoRoute(coords, point[1], point[0]);
    if (p.crossTrackM > maxOffM || p.crossTrackM >= bestOff) continue;
    bestOff = p.crossTrackM;
    best = pointAlongRoute(coords, p.distanceAlongM);
  }
  return best ?? point;
}
