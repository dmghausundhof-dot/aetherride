/**
 * „Zusammen raus“ — Gruppe vor dem Tor.
 *
 * Policy only. No live GPS, no demo riders, no Explore listing.
 * HUD docking: mobile ride_screen `_drawRideMap` (addSymbol after route lines).
 * Web remains a bridge — roster + join code, never live pins.
 */

import type { PrivacyZone } from "@/lib/privacy/consents";
import type {
  RideGroupListing,
  RideGroupPresenceVisibility,
  RideGroupStatus,
} from "@/lib/community/types";

export const RIDE_GROUP_JOIN_CODE_LEN = 6;
export const RIDE_GROUP_JOIN_ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
export const RIDE_GROUP_STALE_AFTER_MS = 90_000;
export const RIDE_GROUP_DROP_AFTER_MS = 5 * 60_000;
/** ~55 m — grober als Roh-GPS, feiner als Heatmap-Zelle (~110 m). */
export const RIDE_GROUP_QUANTIZE_DEG = 0.0005;
/** Create + extend: 15 Min bis 12 h. */
export const RIDE_GROUP_MIN_DURATION_HOURS = 0.25;
export const RIDE_GROUP_MAX_DURATION_HOURS = 12;
/** Verlängerung: Ende nie später als jetzt + 12 h. */
export const RIDE_GROUP_EXTEND_CAP_HOURS = 12;
export const RIDE_GROUP_STARTS_AT_MAX_DAYS = 14;

export function isRideGroupId(raw: string): boolean {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(
    raw.trim()
  );
}

export function parseGroupListing(raw: unknown): RideGroupListing {
  return raw === "public" ? "public" : "private";
}

/**
 * Privat: nur Token-Link. Der 6-Zeichen-Code ist zum Abtippen gedacht,
 * nicht als Geheimnis — Code- oder Listen-Join nur für öffentliche /
 * auf dem Platz gelistete Gruppen. Private Gruppen bleiben Link-only.
 */
export function canJoinWithoutInviteToken(listing: RideGroupListing): boolean {
  return listing === "public";
}

/** Host allein und Fenster noch zu → Einladen. Sonst Losfahren. */
export function platzGroupPrimaryIsInvite(
  selfIsHost: boolean,
  otherMemberCount: number,
  windowOpen = false
): boolean {
  return selfIsHost && otherMemberCount <= 0 && !windowOpen;
}

/** Code eintippen — dasselbe Tor wie Listen-Join ohne Token. */
export function canJoinByTypedCode(listing: RideGroupListing): boolean {
  return canJoinWithoutInviteToken(listing);
}

export function isTypedJoinCode(raw: string): boolean {
  const t = String(raw ?? "").trim();
  if (!t || isRideGroupId(t)) return false;
  return normalizeJoinCode(t).length === RIDE_GROUP_JOIN_CODE_LEN;
}

export function generateJoinCode(rng: () => number = Math.random): string {
  let code = "";
  for (let i = 0; i < RIDE_GROUP_JOIN_CODE_LEN; i++) {
    const idx =
      Math.floor(rng() * RIDE_GROUP_JOIN_ALPHABET.length) %
      RIDE_GROUP_JOIN_ALPHABET.length;
    code += RIDE_GROUP_JOIN_ALPHABET[idx];
  }
  return code;
}

/** Leerzeichen, Bindestriche, I/O/0/1 — nur das Alphabet bleibt. */
export function normalizeJoinCode(raw: unknown): string {
  const upper = String(raw ?? "")
    .trim()
    .toUpperCase();
  let out = "";
  for (const ch of upper) {
    if (RIDE_GROUP_JOIN_ALPHABET.includes(ch)) out += ch;
  }
  return out;
}

/**
 * Gruppe darf an jede gespeicherte/Katalog-Tour — inkl. privater GPX des Hosts.
 * Freies Fahren / RideTogether-Session ist keine Gruppen-Route.
 * Tour-Visibility bleibt getrennt: Anlegen macht die Tour nicht öffentlich.
 * Private Host-GPX braucht eine Mitglieds-Kopie — Katalog nicht.
 */
export function needsMemberTrack(input: {
  savedRouteId: string;
  catalogTourId?: string | null;
}): boolean {
  const catalog = String(input.catalogTourId ?? "").trim();
  if (catalog) return false;
  const id = String(input.savedRouteId ?? "").trim();
  if (!id || id === "freeride") return false;
  const privatePrefixes = [
    "saved-",
    "gpx-",
    "import-",
    "recorded-",
    "library-",
    "engine-",
  ];
  return privatePrefixes.some((p) => id.startsWith(p));
}

export function canAttachCourse(route: {
  id: string;
  catalogTourId?: string;
  visibility?: string | null;
}): boolean {
  const id = String(route.id ?? "").trim();
  if (!id || id === "freeride") return false;
  return true;
}

export function groupListedOnExplore(): false {
  return false;
}

/** Static meeting pin on Explore — never live member GPS. */
export function canShowMeetingOnExplore(input: {
  visibility?: RideGroupListing;
  status: RideGroupStatus;
  startWindowEnd: string;
  isMember: boolean;
  now?: Date;
  savedRouteId?: string;
}): boolean {
  if (String(input.savedRouteId ?? "").trim() === "freeride") return false;
  if (input.status === "closed") return false;
  const now = input.now ?? new Date();
  if (!canJoinRideGroup(now.toISOString(), input.startWindowEnd, input.status)) {
    return false;
  }
  if (parseGroupListing(input.visibility) === "public") return true;
  return input.isMember;
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

/** Öffentliche Liste: nicht meine, nicht geschlossen, Fenster noch offen. */
export function listedPublicJoinGroups<T extends {
  id: string;
  status: RideGroupStatus;
  startWindowEnd: string;
}>(groups: T[], mineIds: Iterable<string>, now = new Date()): T[] {
  const mine = mineIds instanceof Set ? mineIds : new Set(mineIds);
  const nowIso = now.toISOString();
  return groups.filter(
    (g) =>
      !mine.has(g.id) &&
      canJoinRideGroup(nowIso, g.startWindowEnd, g.status),
  );
}

/** Nächstes offenes Treffen — geschlossen oder abgelaufen fällt weg. */
export function nextActiveMeeting<T extends {
  status: RideGroupStatus;
  startWindowStart: string;
  startWindowEnd: string;
  savedRouteId?: string;
}>(groups: T[], now = new Date()): T | null {
  const open = groups.filter((g) => {
    if (String(g.savedRouteId ?? "").trim() === "freeride") return false;
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

export function snapDurationHours(hours: number): number {
  return Math.round(hours * 60) / 60;
}

export function isValidRideGroupDurationHours(hours: number): boolean {
  return (
    Number.isFinite(hours) &&
    hours >= RIDE_GROUP_MIN_DURATION_HOURS &&
    hours <= RIDE_GROUP_MAX_DURATION_HOURS
  );
}

export function formatRideGroupDurationHours(
  hours: number,
  decimal = "."
): string {
  if (!Number.isFinite(hours) || hours <= 0) return "0 h";
  const mins = Math.round(hours * 60);
  if (mins < 60) return `${mins} Min`;
  if (mins % 60 === 0) return `${mins / 60} h`;
  const value = mins / 60;
  const places = mins % 60 === 30 ? 1 : 2;
  return `${value.toFixed(places).replace(".", decimal)} h`;
}

export function parseRideGroupWindow(input: {
  startsAt?: unknown;
  endsAt?: unknown;
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
  let hours = 3;
  const rawEnd = input.endsAt;
  if (rawEnd != null && String(rawEnd).trim() !== "") {
    const parsedEnd = new Date(String(rawEnd));
    if (!Number.isFinite(parsedEnd.getTime())) return { error: "invalid_endsAt" };
    hours = (parsedEnd.getTime() - start.getTime()) / 3_600_000;
  } else {
    const rawDur = input.durationHours ?? input.duration;
    if (rawDur != null && String(rawDur).trim() !== "") {
      hours = Number(rawDur);
    }
  }
  if (!isValidRideGroupDurationHours(hours)) {
    return { error: "invalid_duration" };
  }
  hours = snapDurationHours(hours);
  const end = new Date(start.getTime() + hours * 60 * 60 * 1000);
  if (end.getTime() <= start.getTime()) return { error: "invalid_window" };
  if (
    start.getTime() - now.getTime() >
    RIDE_GROUP_STARTS_AT_MAX_DAYS * 24 * 60 * 60 * 1000
  ) {
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
  const hours = (end.getTime() - start.getTime()) / 3_600_000;
  const dur = formatRideGroupDurationHours(hours);
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

/** Fenster verlängern. addHours fractional (0,25–12). Deckel jetzt+12 h. */
export function extendRideGroupWindowEnd(
  now: Date,
  end: Date,
  hours = 1
): Date {
  const add = Math.max(
    RIDE_GROUP_MIN_DURATION_HOURS,
    Math.min(RIDE_GROUP_MAX_DURATION_HOURS, hours)
  );
  const out = parseRideGroupExtend({
    now,
    currentEnd: end,
    addHours: add,
  });
  if ("error" in out) {
    const cap = new Date(now.getTime() + RIDE_GROUP_EXTEND_CAP_HOURS * 3_600_000);
    return cap;
  }
  return out.end;
}

/** POST /api/ride-groups: Fenster statt Anlegen — ohne savedRouteId. */
export function isRideGroupExtendBody(body: {
  savedRouteId?: unknown;
  id?: unknown;
  addHours?: unknown;
  newEnd?: unknown;
}): boolean {
  if (String(body.savedRouteId ?? "").trim()) return false;
  if (!isRideGroupId(String(body.id ?? ""))) return false;
  const hasEnd = body.newEnd != null && String(body.newEnd).trim() !== "";
  const hasHours = body.addHours != null && String(body.addHours).trim() !== "";
  return hasEnd || hasHours;
}

/** Host: addHours (auch 0,5) oder newEnd. Abgelaufenes Fenster startet bei now. */
export function parseRideGroupExtend(input: {
  now: Date;
  currentEnd: Date;
  addHours?: unknown;
  newEnd?: unknown;
}): { end: Date } | { error: string } {
  const now = input.now;
  const cap = new Date(
    now.getTime() + RIDE_GROUP_EXTEND_CAP_HOURS * 60 * 60 * 1000
  );
  const base =
    input.currentEnd.getTime() > now.getTime() ? input.currentEnd : now;
  const rawNew = input.newEnd;
  if (rawNew != null && String(rawNew).trim() !== "") {
    const parsed = rawNew instanceof Date ? rawNew : new Date(String(rawNew));
    if (!Number.isFinite(parsed.getTime())) return { error: "invalid_end" };
    if (parsed.getTime() <= base.getTime()) return { error: "invalid_end" };
    return { end: parsed.getTime() > cap.getTime() ? cap : parsed };
  }
  let hours = 1;
  if (input.addHours != null && String(input.addHours).trim() !== "") {
    hours = Number(input.addHours);
  }
  if (!isValidRideGroupDurationHours(hours)) {
    return { error: "invalid_duration" };
  }
  hours = snapDurationHours(hours);
  const next = new Date(base.getTime() + hours * 60 * 60 * 1000);
  return { end: next.getTime() > cap.getTime() ? cap : next };
}

/** Leere Gäste, stabil nach userId. Self bleibt draußen. */
export function friendUnnamedNumbers(
  members: { userId: string; displayLabel: string }[],
  selfIds: Iterable<string>
): Record<string, number> {
  const self = new Set(selfIds);
  const unnamed = members
    .filter((m) => !self.has(m.userId) && !String(m.displayLabel || "").trim())
    .slice()
    .sort((a, b) => a.userId.localeCompare(b.userId));
  const out: Record<string, number> = {};
  unnamed.forEach((m, i) => {
    out[m.userId] = i + 1;
  });
  return out;
}

export function friendRosterName(input: {
  displayLabel: string;
  self: boolean;
  friendN?: number;
  fallbackSelf: string;
  fallbackOther: string;
  friendLabel: (n: number) => string;
}): string {
  const raw = String(input.displayLabel || "").trim();
  if (raw) return raw;
  if (input.self) return input.fallbackSelf;
  if (input.friendN != null) return input.friendLabel(input.friendN);
  return input.fallbackOther;
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
