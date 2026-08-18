import type { BikeCategory } from "@/types";

export const TOUR_LINE_COLOR = "#FF6A00";

export const SPORT_PIN_COLOR: Record<string, string> = {
  road: "#3D8BFF",
  gravel: "#C4A574",
  urban: "#2BB0A6",
  etrekking: "#5AA36A",
  emtb: "#7CB342",
  mtb_trail: "#FF8A3D",
  mtb_am: "#FF6A00",
  mtb_enduro: "#E23B2E",
  dh: "#B71C1C",
  hiking: "#8D6E63",
};

export function sportPinColor(category: BikeCategory | string): string {
  return SPORT_PIN_COLOR[category] ?? TOUR_LINE_COLOR;
}

export function pointsAreClose(
  a: [number, number],
  b: [number, number],
  eps = 0.00035,
): boolean {
  return Math.hypot(a[0] - b[0], a[1] - b[1]) <= eps;
}

export function lineEndpoints(
  coords: [number, number][],
  loopHint?: boolean,
): {
  start: [number, number] | null;
  end: [number, number] | null;
  loop: boolean;
} {
  if (coords.length < 2) {
    return { start: coords[0] ?? null, end: null, loop: Boolean(loopHint) };
  }
  const start = coords[0];
  const end = coords[coords.length - 1];
  const loop = loopHint === true || pointsAreClose(start, end);
  return { start, end: loop ? null : end, loop };
}

export function sportKeysOnTours(
  tours: Array<{ primaryCategory: string }>,
): string[] {
  const seen = new Set<string>();
  const out: string[] = [];
  for (const tour of tours) {
    const key = tour.primaryCategory;
    if (seen.has(key)) continue;
    seen.add(key);
    out.push(key);
  }
  return out;
}
