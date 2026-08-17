/**
 * „Zusammen raus“ — Gruppe vor dem Tor.
 *
 * Policy only. No live GPS, no demo riders, no Explore listing.
 * HUD docking: mobile ride_screen `_drawRideMap` (addSymbol after route lines).
 * Web remains a bridge — roster + join code, never live pins.
 */

import { catalogTourIdOf } from "@/lib/tours/tourAkte";
import { isShared } from "@/lib/tours/routeVisibility";
import type { PrivacyZone } from "@/lib/privacy/consents";
import type {
  RideGroupListing,
  RideGroupPresenceVisibility,
  RideGroupStatus,
} from "@/lib/community/types";

export const RIDE_GROUP_JOIN_CODE_LEN = 6;
export const RIDE_GROUP_STALE_AFTER_MS = 90_000;
export const RIDE_GROUP_DROP_AFTER_MS = 5 * 60_000;
/** ~55 m — grober als Roh-GPS, feiner als Heatmap-Zelle (~110 m). */
export const RIDE_GROUP_QUANTIZE_DEG = 0.0005;

const JOIN_ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";

export function isRideGroupId(raw: string): boolean {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(
    raw.trim()
  );
}

export function parseGroupListing(raw: unknown): RideGroupListing {
  return raw === "public" ? "public" : "private";
}

/** Privat: nur Token-Link. Öffentlich: Link oder Listen-Join (eingeloggt). */
export function canJoinWithoutInviteToken(listing: RideGroupListing): boolean {
  return listing === "public";
}

export function generateJoinCode(rng: () => number = Math.random): string {
  let code = "";
  for (let i = 0; i < RIDE_GROUP_JOIN_CODE_LEN; i++) {
    const idx = Math.floor(rng() * JOIN_ALPHABET.length) % JOIN_ALPHABET.length;
    code += JOIN_ALPHABET[idx];
  }
  return code;
}

/** Private GPX bleibt privat. Katalog ist schon öffentlich. Freigabe ist Opt-in. */
export function canAttachCourse(route: {
  id: string;
  catalogTourId?: string;
  visibility?: string | null;
}): boolean {
  return isShared(route) || Boolean(catalogTourIdOf(route));
}

export function groupListedOnExplore(): false {
  return false;
}

export function isEventWindowOpen(
  nowIso: string,
  startIso: string,
  endIso: string,
  status: RideGroupStatus
): boolean {
  if (status === "closed") return false;
  const now = Date.parse(nowIso);
  const start = Date.parse(startIso);
  const end = Date.parse(endIso);
  if (!Number.isFinite(now) || !Number.isFinite(start) || !Number.isFinite(end)) {
    return false;
  }
  return now >= start && now <= end;
}

/** Join bis Fensterende. Vor dem Start erlaubt — Presence erst im Fenster. */
export function canJoinRideGroup(
  nowIso: string,
  endIso: string,
  status: RideGroupStatus
): boolean {
  if (status === "closed") return false;
  const now = Date.parse(nowIso);
  const end = Date.parse(endIso);
  if (!Number.isFinite(now) || !Number.isFinite(end)) return false;
  return now <= end;
}

/** Nächstes offenes Treffen — geschlossen oder abgelaufen fällt weg. */
export function nextActiveMeeting<T extends {
  status: RideGroupStatus;
  startWindowStart: string;
  startWindowEnd: string;
}>(groups: T[], now = new Date()): T | null {
  const open = groups.filter((g) => {
    if (g.status === "closed") return false;
    const end = Date.parse(g.startWindowEnd);
    return Number.isFinite(end) && now.getTime() <= end;
  });
  if (open.length === 0) return null;
  open.sort(
    (a, b) =>
      Date.parse(a.startWindowStart) - Date.parse(b.startWindowStart),
  );
  return open[0] ?? null;
}

export function parseRideGroupWindow(input: {
  startsAt?: unknown;
  duration?: unknown;
  durationHours?: unknown;
  now?: Date;
}):
  | {
      start: Date;
      end: Date;
      durationHours: number;
      status: RideGroupStatus;
    }
  | { error: string } {
  const now = input.now ?? new Date();
  let start = now;
  const rawStart = input.startsAt;
  if (rawStart != null && String(rawStart).trim()) {
    const parsed = new Date(String(rawStart));
    if (!Number.isFinite(parsed.getTime())) return { error: "invalid_startsAt" };
    start = parsed;
  }
  const rawDur = input.durationHours ?? input.duration;
  let hours = 3;
  if (rawDur != null && String(rawDur).trim() !== "") {
    hours = Number(rawDur);
  }
  if (!Number.isFinite(hours) || hours < 1 || hours > 12) {
    return { error: "invalid_duration" };
  }
  hours = Math.round(hours);
  const end = new Date(start.getTime() + hours * 60 * 60 * 1000);
  if (end.getTime() <= start.getTime()) return { error: "invalid_window" };
  if (start.getTime() - now.getTime() > 14 * 24 * 60 * 60 * 1000) {
    return { error: "startsAt_too_far" };
  }
  const status: RideGroupStatus =
    start.getTime() > now.getTime() + 60_000 ? "scheduled" : "open";
  return { start, end, durationHours: hours, status };
}

const WEEKDAYS_DE = ["So", "Mo", "Di", "Mi", "Do", "Fr", "Sa"];

export function formatGroupWhen(
  startIso: string,
  endIso: string,
  now = new Date(),
  timeZone = "Europe/Berlin"
): string {
  const start = new Date(startIso);
  const end = new Date(endIso);
  if (!Number.isFinite(start.getTime()) || !Number.isFinite(end.getTime())) {
    return "";
  }
  const hours = Math.round((end.getTime() - start.getTime()) / 3_600_000);
  const dur = `${Math.max(1, hours)} h`;
  const fmt = new Intl.DateTimeFormat("de-DE", {
    timeZone,
    weekday: "short",
    day: "2-digit",
    month: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
    hour12: false,
  });
  const parts = Object.fromEntries(
    fmt.formatToParts(start).map((p) => [p.type, p.value])
  );
  const wdRaw = (parts.weekday || "").replace(".", "");
  const wdMap: Record<string, string> = {
    So: "So",
    Mo: "Mo",
    Di: "Di",
    Mi: "Mi",
    Do: "Do",
    Fr: "Fr",
    Sa: "Sa",
    Sun: "So",
    Mon: "Mo",
    Tue: "Di",
    Wed: "Mi",
    Thu: "Do",
    Fri: "Fr",
    Sat: "Sa",
  };
  const wd = wdMap[wdRaw] || WEEKDAYS_DE[start.getUTCDay()] || wdRaw;
  const hm = `${parts.hour || "00"}:${parts.minute || "00"}`;
  if (now.getTime() > end.getTime()) return `zu — ${wd} ${hm}`;
  const nowDay = new Intl.DateTimeFormat("en-CA", {
    timeZone,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).format(now);
  const startDay = new Intl.DateTimeFormat("en-CA", {
    timeZone,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).format(start);
  const tomorrow = new Date(now.getTime() + 24 * 60 * 60 * 1000);
  const tomorrowDay = new Intl.DateTimeFormat("en-CA", {
    timeZone,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).format(tomorrow);
  if (startDay === nowDay) return `heute ${hm} · ${dur}`;
  if (startDay === tomorrowDay) return `morgen ${hm} · ${dur}`;
  return `${wd} ${hm} · ${dur}`;
}

export function parseMeetingPoint(raw: unknown): string | undefined {
  const t = String(raw ?? "").trim().slice(0, 80);
  return t || undefined;
}

export function quantizeGroupCoord(
  lat: number,
  lng: number
): { lat: number; lng: number } {
  const q = RIDE_GROUP_QUANTIZE_DEG;
  return {
    lat: Math.round(lat / q) * q,
    lng: Math.round(lng / q) * q,
  };
}

export function pointInPrivacyZones(
  lat: number,
  lng: number,
  zones: Pick<PrivacyZone, "lat" | "lng" | "radiusM">[]
): boolean {
  for (const z of zones) {
    if (distM(lng, lat, z.lng, z.lat) < z.radiusM) return true;
  }
  return false;
}

export function resolvePresenceVisibility(input: {
  isMember: boolean;
  livePinsAllowed: boolean;
  liveOptIn: boolean;
  inEventWindow: boolean;
  inPrivacyZone: boolean;
  hasFix: boolean;
  ageMs: number | null;
}): RideGroupPresenceVisibility {
  if (!input.isMember) return "hidden_not_member";
  if (!input.livePinsAllowed || !input.liveOptIn) return "hidden_opt_out";
  if (!input.inEventWindow) return "hidden_window";
  if (input.inPrivacyZone) return "hidden_zone";
  if (!input.hasFix || input.ageMs == null) return "hidden_offline";
  if (input.ageMs > RIDE_GROUP_DROP_AFTER_MS) return "hidden_offline";
  if (input.ageMs > RIDE_GROUP_STALE_AFTER_MS) return "stale";
  return "live";
}

/** Nach erfolgreichem Cloud-GET: lokale Karte behalten? Host offline ja. */
export function keepLocalRideGroupAfterCloud(input: {
  onServer?: boolean;
  selfIsHost: boolean;
}): boolean {
  if (input.onServer) return false;
  return input.selfIsHost;
}

function distM(lng1: number, lat1: number, lng2: number, lat2: number): number {
  const r = 6371000;
  const la1 = (lat1 * Math.PI) / 180;
  const la2 = (lat2 * Math.PI) / 180;
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLng = ((lng2 - lng1) * Math.PI) / 180;
  const h =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(la1) * Math.cos(la2) * Math.sin(dLng / 2) ** 2;
  return 2 * r * Math.asin(Math.sqrt(h));
}
