/**
 * Freeride-Zusammen — Session ohne Tour.
 *
 * Straße: Zelle + Karte + Ja, Code als Fallback. Keine geplante Gruppe.
 * 5–20: dieselbe private Session. Nie Explore, nie Platz, nie Meeting-Pin.
 * Nearby = nur wer JETZT sucht, nicht das geschlossene Roster.
 * Ride-Stopp = aussteigen. Die anderen bleiben. Zu wenn der Letzte geht.
 */
import {
  RIDE_GROUP_QUANTIZE_DEG,
  quantizeGroupCoord,
} from "@/lib/community/rideGroup";
import type { RideGroup, RideGroupStatus } from "@/lib/community/types";

export const RIDE_TOGETHER_ROUTE_ID = "freeride";
export const RIDE_TOGETHER_TITLE = "Zusammen";
export const RIDE_TOGETHER_LOOK_MS = 90_000;
export const RIDE_TOGETHER_REQUEST_MS = 90_000;
export const RIDE_TOGETHER_SESSION_HOURS = 8;
/** 5×5 Zellen à ~55 m — Parkplatz, nicht die ganze Stadt. */
export const RIDE_TOGETHER_CELL_RING = 2;
/** Hartes Cap — Straße oder geschlossene 20, nicht mehr. */
export const RIDE_TOGETHER_MAX_MEMBERS = 20;

export type TogetherBucket = "beside" | "near";

export function isSessionRouteId(id: string | null | undefined): boolean {
  return String(id ?? "").trim() === RIDE_TOGETHER_ROUTE_ID;
}

export function isFreerideRide(routeId: string | null | undefined): boolean {
  return String(routeId ?? "").trim() === "";
}

export function canJoinSessionByCode(savedRouteId: string): boolean {
  return isSessionRouteId(savedRouteId);
}

/** Session nie auf Platz / Explore / als Treffen-Pin. */
export function sessionListedPublicly(): false {
  return false;
}

export function canAddSessionMember(currentCount: number): boolean {
  return (
    Number.isFinite(currentCount) &&
    currentCount >= 0 &&
    currentCount < RIDE_TOGETHER_MAX_MEMBERS
  );
}

/**
 * Wohin die Anfrage hängt.
 * Beide solo (Straße) → Session des Fragenden.
 * Eine Seite hat schon ≥2 → die geschlossene Gruppe, Suchender kommt dazu.
 * Zwei geschlossene Gruppen → nicht still mergen.
 */
export function pickRequestSession(
  fromCount: number,
  toCount: number
): "from" | "to" | "none" {
  const fromClosed = fromCount >= 2;
  const toClosed = toCount >= 2;
  if (fromClosed && toClosed) return "none";
  if (toClosed) return "to";
  return "from";
}

/**
 * Stopp = Leave. Host mit Rest steigt auch nur aus.
 * Schließen nur wenn nach dem Leave niemand mehr da ist.
 */
export function sessionLeaveClosesGroup(remainingAfterLeave: number): boolean {
  return remainingAfterLeave <= 0;
}

/** Sheet zu: Session bleibt. Suche aus schließt keine Paar-Session. */
export function stopLookClosesSession(): false {
  return false;
}

/** Suche aus + niemand dabei: Solo-Session zu, kein 8-h-Geistercode. */
export function stopLookClosesSoloSession(): true {
  return true;
}

export const sessionClosesAfterLeave = sessionLeaveClosesGroup;

export function sanitizeTogetherLabel(raw: unknown): string {
  return String(raw ?? "")
    .trim()
    .replace(/\s+/g, " ")
    .slice(0, 24);
}

export function matePair(
  a: string,
  b: string
): { lo: string; hi: string } | null {
  const left = String(a || "").trim();
  const right = String(b || "").trim();
  if (!left || !right || left === right) return null;
  return left < right ? { lo: left, hi: right } : { lo: right, hi: left };
}

export function chebyshevRing(
  lat: number,
  lng: number,
  otherLat: number,
  otherLng: number
): number {
  const a = quantizeGroupCoord(lat, lng);
  const b = quantizeGroupCoord(otherLat, otherLng);
  const step = RIDE_GROUP_QUANTIZE_DEG;
  const dy = Math.round((b.lat - a.lat) / step);
  const dx = Math.round((b.lng - a.lng) / step);
  return Math.max(Math.abs(dx), Math.abs(dy));
}

export function togetherBucket(
  selfLat: number,
  selfLng: number,
  otherLat: number,
  otherLng: number
): TogetherBucket | null {
  const ring = chebyshevRing(selfLat, selfLng, otherLat, otherLng);
  if (ring <= 1) return "beside";
  if (ring <= RIDE_TOGETHER_CELL_RING) return "near";
  return null;
}

export function togetherBounds(lat: number, lng: number): {
  minLat: number;
  maxLat: number;
  minLng: number;
  maxLng: number;
} {
  const q = quantizeGroupCoord(lat, lng);
  const span = RIDE_GROUP_QUANTIZE_DEG * RIDE_TOGETHER_CELL_RING;
  return {
    minLat: q.lat - span,
    maxLat: q.lat + span,
    minLng: q.lng - span,
    maxLng: q.lng + span,
  };
}

export function pickGroupForRide<T extends {
  savedRouteId: string;
  catalogTourId?: string;
  createdAt: string;
  onServer?: boolean;
}>(input: {
  rideRouteId: string | null | undefined;
  catalogTourId?: string | null;
  groups: T[];
  memberCounts: Record<string, number>;
  idOf: (g: T) => string;
}): T | null {
  const freeride = isFreerideRide(input.rideRouteId);
  let newestSession: T | null = null;
  let routeHit: T | null = null;
  const rideId = String(input.rideRouteId ?? "").trim();
  const catalogId = String(input.catalogTourId ?? "").trim();
  const ids = new Set<string>();
  if (rideId) ids.add(rideId);
  if (catalogId) ids.add(catalogId);

  for (const g of input.groups) {
    if (isSessionRouteId(g.savedRouteId)) {
      const n = input.memberCounts[input.idOf(g)] ?? 0;
      if (n < 2) continue;
      if (
        !newestSession ||
        Date.parse(g.createdAt) > Date.parse(newestSession.createdAt)
      ) {
        newestSession = g;
      }
      continue;
    }
    if (freeride) continue;
    const match =
      ids.size > 0 &&
      (ids.has(g.savedRouteId) ||
        Boolean(g.catalogTourId && ids.has(g.catalogTourId)));
    if (match && !routeHit) routeHit = g;
  }
  if (freeride) return newestSession;
  return routeHit;
}

export function sessionWindow(now = new Date()): {
  start: Date;
  end: Date;
  status: RideGroupStatus;
} {
  const start = now;
  const end = new Date(
    start.getTime() + RIDE_TOGETHER_SESSION_HOURS * 60 * 60 * 1000
  );
  return { start, end, status: "riding" };
}

export function isLookingOpen(untilIso: string, now = new Date()): boolean {
  const t = Date.parse(untilIso);
  return Number.isFinite(t) && t > now.getTime();
}

export function listedPlannedGroups<T extends { savedRouteId?: string }>(
  groups: T[]
): T[] {
  return groups.filter((g) => !isSessionRouteId(g.savedRouteId));
}

export function plannedMeetingOnly<T extends {
  status: RideGroupStatus;
  startWindowStart: string;
  startWindowEnd: string;
  savedRouteId?: string;
}>(groups: T[], now = new Date()): T | null {
  const open = groups.filter((g) => {
    if (isSessionRouteId(g.savedRouteId)) return false;
    if (g.status === "closed") return false;
    const end = Date.parse(g.startWindowEnd);
    return Number.isFinite(end) && now.getTime() <= end;
  });
  if (open.length === 0) return null;
  open.sort(
    (a, b) =>
      Date.parse(a.startWindowStart) - Date.parse(b.startWindowStart)
  );
  return open[0] ?? null;
}

export function assertSessionGroup(
  group: Pick<RideGroup, "savedRouteId"> | null | undefined
): boolean {
  return Boolean(group && isSessionRouteId(group.savedRouteId));
}

/** Nearby = nur wer JETZT sucht. Roster-IDs raus, keine Koordinaten. */
export function nearbyFromLooks(input: {
  selfLat: number;
  selfLng: number;
  selfId: string;
  looks: Array<{
    user_id: string;
    lat: number;
    lng: number;
    display_label?: string;
  }>;
  labels: Map<string, string>;
  excludeUserIds?: Iterable<string>;
}): Array<{ userId: string; label: string; bucket: TogetherBucket }> {
  const skip = new Set(input.excludeUserIds ?? []);
  skip.add(input.selfId);
  const out: Array<{ userId: string; label: string; bucket: TogetherBucket }> =
    [];
  for (const look of input.looks) {
    const id = String(look.user_id);
    if (skip.has(id)) continue;
    const bucket = togetherBucket(
      input.selfLat,
      input.selfLng,
      look.lat,
      look.lng
    );
    if (!bucket) continue;
    const label =
      input.labels.get(id) || sanitizeTogetherLabel(look.display_label);
    out.push({ userId: id, label, bucket });
  }
  return out;
}
