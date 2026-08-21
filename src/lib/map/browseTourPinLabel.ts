/** Browse-Karte: Minuten, keine Sport-Kürzel. Keep in sync with TourFilters. */

const NAME_MAX = 16;

export function browseTourTimeLabel(durationMin: number): string {
  if (durationMin <= 0) return "";
  return `${durationMin}′`;
}

export function browseTourShowsTime(zoom: number): boolean {
  return zoom >= 11;
}

/** Ungewählt: nur Dauer. Gewählt ab Zoom 13: Dauer · Kurzname. */
export function browseTourPinText(opts: {
  durationMin: number;
  selected: boolean;
  zoom: number;
  name?: string;
}): string {
  if (!browseTourShowsTime(opts.zoom)) return "";
  const time = browseTourTimeLabel(opts.durationMin);
  if (!opts.selected || opts.zoom < 13) return time;
  const n = (opts.name ?? "").trim();
  if (!n) return time;
  const short = n.length <= NAME_MAX ? n : `${n.slice(0, NAME_MAX - 1)}…`;
  return time ? `${time} · ${short}` : short;
}
