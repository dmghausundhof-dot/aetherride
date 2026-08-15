import type { SavedRoute } from "@/types/route";

/** Ehrliches Mini-„Route hinzufügen“: Name + optionaler Start, kein Fake-Track. */
export function defaultRouteName(now = new Date()): string {
  return `Route ${now.getDate()}.${now.getMonth() + 1}.`;
}

export function simpleNamedRoute(opts: {
  name: string;
  /** [lng, lat] */
  start?: [number, number];
  now?: Date;
  id?: string;
}): SavedRoute {
  const now = opts.now ?? new Date();
  const label = opts.name.trim() || defaultRouteName(now);
  const start = opts.start;
  return {
    id: opts.id ?? `library-${now.getTime()}`,
    name: label,
    distanceKm: 0,
    elevationM: 0,
    durationMin: 0,
    savedAt: now.toISOString(),
    source: "suggestion",
    geometry: null,
    waypoints: start
      ? [{ role: "start", lngLat: start, label: "Start" }]
      : undefined,
  };
}
