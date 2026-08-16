/**
 * Teilbarer Einladungslink für „Zusammen raus“.
 * HTTPS: /library?group=<id>&g=<token>
 * App: aetherride://platz?group=<id>&g=<token>
 * Alte Links mit 6-Zeichen-Code bleiben gültig. Code nicht in der UI.
 */

import { siteOrigin, appDeepLink } from "@/lib/web/appLinks";
import type { RideGroup } from "@/lib/community/types";

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

export function encodeGroupInvite(group: RideGroup): string {
  const payload: RideGroupInvitePayload = {
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
  return toBase64Url(JSON.stringify(payload));
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
    return { ...data, code };
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
  if (input.when?.trim()) {
    lines.push(input.when.trim());
  }
  if (input.meetingPoint?.trim()) {
    lines.push(`Treffpunkt: ${input.meetingPoint.trim()}`);
  }
  if (input.profileUrl?.trim()) {
    lines.push("", `Mein Platz-Profil: ${input.profileUrl.trim()}`);
  }
  const vis =
    input.visibility === "public"
      ? "Öffentlich: wer den Link hat, kann beitreten. Die Gruppe kann auf dem Platz unter Öffentlich stehen."
      : "Privat: nur wer diesen Link hat, kann beitreten. Kein öffentliches Roster.";
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
