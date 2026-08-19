/**
 * Teilbarer Einladungslink für „Zusammen raus“.
 * HTTPS: /library?group=<id>&g=<token>
 * App: aetherride://platz?group=<id>&g=<token>
 * Alte Links mit 6-Zeichen-Code bleiben gültig.
 * Code zum Abtippen nur bei öffentlichen / Platz-Gruppen.
 */

import { siteOrigin, appDeepLink } from "@/lib/web/appLinks";
import type { RideGroup } from "@/lib/community/types";
import {
  isRideGroupId,
  isTypedJoinCode,
  normalizeJoinCode,
  RIDE_GROUP_JOIN_CODE_LEN,
} from "@/lib/community/rideGroup";
import { parseTourShareMap } from "@/lib/community/shareCodec";
import type { SharedTourPayload } from "@/lib/community/shareTypes";

export type RideGroupInvitePayload = {
  v: 1;
  kind: "group";
  id: string;
  code: string;
  title: string;
  savedRouteId: string;
  catalogTourId?: string;
  hostUserId?: string;
  start: string;
  end: string;
  tour?: SharedTourPayload;
};

function toBase64Url(json: string): string {
  if (typeof btoa === "function") {
    const b64 = btoa(unescape(encodeURIComponent(json)));
    return b64.replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
  }
  return Buffer.from(json, "utf8")
    .toString("base64")
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/, "");
}

function fromBase64Url(token: string): string {
  const b64 = token.replace(/-/g, "+").replace(/_/g, "/");
  const pad = b64.length % 4 === 0 ? "" : "=".repeat(4 - (b64.length % 4));
  const full = b64 + pad;
  if (typeof atob === "function") {
    return decodeURIComponent(escape(atob(full)));
  }
  return Buffer.from(full, "base64").toString("utf8");
}

export function encodeGroupInvite(
  group: RideGroup,
  tour?: SharedTourPayload
): string {
  const base: RideGroupInvitePayload = {
    v: 1,
    kind: "group",
    id: group.id,
    code: group.joinCode.trim().toUpperCase(),
    title: group.title,
    savedRouteId: group.savedRouteId,
    catalogTourId: group.catalogTourId,
    hostUserId: group.hostUserId,
    start: group.startWindowStart,
    end: group.startWindowEnd,
  };
  let payload: RideGroupInvitePayload = tour ? { ...base, tour } : base;
  let token = toBase64Url(JSON.stringify(payload));
  if (token.length > 2400 && payload.tour?.track) {
    payload = {
      ...payload,
      tour: { ...payload.tour, includeTrack: false, track: undefined },
    };
    token = toBase64Url(JSON.stringify(payload));
  }
  if (token.length > 2400) {
    token = toBase64Url(JSON.stringify(base));
  }
  return token;
}

export function decodeGroupInvite(
  token: string
): RideGroupInvitePayload | null {
  try {
    const data = JSON.parse(fromBase64Url(token)) as RideGroupInvitePayload;
    if (data?.v !== 1 || data.kind !== "group") return null;
    const code = String(data.code || "")
      .trim()
      .toUpperCase();
    if (code.length !== 6 || !data.id || !data.title || !data.savedRouteId) {
      return null;
    }
    if (!data.start || !data.end) return null;
    const tour = parseTourShareMap(data.tour) ?? undefined;
    return { ...data, code, tour };
  } catch {
    return null;
  }
}

export function groupInviteRef(group: Pick<RideGroup, "id" | "joinCode">): string {
  const id = String(group.id || "").trim();
  if (id) return id;
  return String(group.joinCode || "").trim().toUpperCase();
}

export function groupInvitePath(groupRef: string, token?: string): string {
  const ref = groupRef.trim();
  const q = new URLSearchParams({ group: ref });
  if (token) q.set("g", token);
  return `/library?${q.toString()}`;
}

export function groupInviteHttps(groupRef: string, token?: string): string {
  const path = groupInvitePath(groupRef, token);
  const origin =
    siteOrigin() ||
    (typeof window !== "undefined" ? window.location.origin : "");
  return origin ? `${origin}${path}` : path;
}

export function groupInviteScheme(groupRef: string, token?: string): string {
  const ref = groupRef.trim();
  const q = new URLSearchParams({ group: ref });
  if (token) q.set("g", token);
  return appDeepLink(`platz?${q.toString()}`);
}

export type PastedGroupJoin = { ref: string; token?: string };

/** Paste from WhatsApp / Messages. Prefers the URL that carries `g=`. */
export function parsePastedGroupJoin(raw: string): PastedGroupJoin | null {
  const text = raw.trim();
  if (!text) return null;
  let withoutToken: PastedGroupJoin | null = null;
  const urlRe = /(?:https?:\/\/|aetherride:\/\/)[^\s]+/gi;
  let m: RegExpExecArray | null;
  while ((m = urlRe.exec(text)) !== null) {
    try {
      const uri = new URL(m[0]);
      const group = (uri.searchParams.get("group") || uri.searchParams.get("code") || "").trim();
      if (!group) continue;
      const token = uri.searchParams.get("g")?.trim() || undefined;
      const hit: PastedGroupJoin = { ref: group, token };
      if (hit.token) return hit;
      withoutToken ??= hit;
    } catch {
      /* not a URL */
    }
  }
  if (withoutToken) return withoutToken;
  const compact = text.replace(/\s+/g, "");
  if (isRideGroupId(compact)) return { ref: compact };
  if (isTypedJoinCode(text)) return { ref: normalizeJoinCode(text) };
  return null;
}

export function groupInviteShareText(input: {
  title: string;
  url: string;
  code?: string;
  profileUrl?: string;
  visibility?: "public" | "private";
  when?: string;
  meetingPoint?: string;
}): string {
  const lines = [`Zusammen raus: ${input.title}`, input.url];
  if (input.visibility === "public") {
    const typed = normalizeJoinCode(input.code ?? "");
    if (typed.length === RIDE_GROUP_JOIN_CODE_LEN) {
      lines.push(`Code: ${typed}`);
    }
  }
  if (input.when?.trim()) {
    lines.push(input.when.trim());
  }
  if (input.meetingPoint?.trim()) {
    lines.push(`Treffpunkt: ${input.meetingPoint.trim()}`);
  }
  if (input.profileUrl?.trim()) {
    lines.push("", `Mein Profil: ${input.profileUrl.trim()}`);
  }
  const vis =
    input.visibility === "public"
      ? "Freigegeben: Link oder Code reicht. Die Gruppe steht auf dem Platz und als Treffen-Pin auf der Karte."
      : "Privat: nur wer diesen Link hat, kann beitreten. Nicht gelistet.";
  lines.push("", vis);
  return lines.join("\n");
}

export function publicProfileShareUrl(handle: string, origin?: string): string | undefined {
  const h = handle.trim().toLowerCase().replace(/[^a-z0-9_]/g, "");
  if (!h) return undefined;
  const base = (origin || siteOrigin() ||
    (typeof window !== "undefined" ? window.location.origin : "")
  ).replace(/\/$/, "");
  if (!base) return `/u/${h}`;
  return `${base}/u/${h}`;
}

export function inviteWindowOpen(
  payload: RideGroupInvitePayload,
  now = new Date()
): boolean {
  const start = new Date(payload.start);
  const end = new Date(payload.end);
  return now.getTime() <= end.getTime();
}
