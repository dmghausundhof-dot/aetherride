/**
 * Browser/mobile-facing ride-groups API client.
 * Kein Fake-Roster. Ohne Session: nicht aufrufen.
 */

import { createClient, isSupabaseConfigured } from "@/lib/supabase/client";
import type {
  RideGroup,
  RideGroupMember,
  RideGroupPresence,
} from "@/lib/community/types";

export type RideGroupCloudBundle = {
  me: string;
  groups: RideGroup[];
  members: RideGroupMember[];
  stub?: boolean;
};

export type RideGroupCloudOne = {
  me: string;
  group: RideGroup;
  members: RideGroupMember[];
  already?: boolean;
  stub?: boolean;
};

export type RideGroupCloudFail = {
  status: number;
  error: string;
  stub?: boolean;
  note?: string;
};

async function authHeaders(): Promise<HeadersInit> {
  const headers: Record<string, string> = {
    Accept: "application/json",
    "Content-Type": "application/json",
  };
  if (!isSupabaseConfigured()) return headers;
  try {
    const sb = createClient();
    const { data } = await sb.auth.getSession();
    const token = data.session?.access_token;
    if (token) headers.Authorization = `Bearer ${token}`;
  } catch {
    /* Cookie-Session reicht auf dem Web. */
  }
  return headers;
}

export async function rideGroupHasSession(): Promise<boolean> {
  if (!isSupabaseConfigured()) return false;
  try {
    const sb = createClient();
    const { data } = await sb.auth.getSession();
    return Boolean(data.session?.access_token);
  } catch {
    return false;
  }
}

async function readJson(res: Response): Promise<Record<string, unknown>> {
  try {
    const data = await res.json();
    return data && typeof data === "object"
      ? (data as Record<string, unknown>)
      : {};
  } catch {
    return {};
  }
}

function failOf(res: Response, body: Record<string, unknown>): RideGroupCloudFail {
  return {
    status: res.status,
    error: String(body.error || "failed"),
    stub: body.stub === true,
    note: body.note ? String(body.note) : undefined,
  };
}

export async function fetchPublicRideGroups(): Promise<
  RideGroupCloudBundle | RideGroupCloudFail
> {
  const res = await fetch("/api/ride-groups?scope=public", {
    method: "GET",
    headers: await authHeaders(),
    credentials: "include",
  });
  const body = await readJson(res);
  if (!res.ok) return failOf(res, body);
  return {
    me: String(body.me || ""),
    groups: Array.isArray(body.groups) ? (body.groups as RideGroup[]) : [],
    members: [],
    stub: body.stub === true,
  };
}

export async function fetchRideGroups(): Promise<
  RideGroupCloudBundle | RideGroupCloudFail
> {
  const res = await fetch("/api/ride-groups", {
    method: "GET",
    headers: await authHeaders(),
    credentials: "include",
  });
  const body = await readJson(res);
  if (!res.ok) return failOf(res, body);
  return {
    me: String(body.me || ""),
    groups: Array.isArray(body.groups) ? (body.groups as RideGroup[]) : [],
    members: Array.isArray(body.members)
      ? (body.members as RideGroupMember[])
      : [],
    stub: body.stub === true,
  };
}

export async function createRideGroupCloud(input: {
  savedRouteId: string;
  catalogTourId?: string;
  title: string;
  visibility?: "public" | "private";
  startsAt?: string;
  durationHours?: number;
  meetingPoint?: string;
}): Promise<RideGroupCloudOne | RideGroupCloudFail> {
  const res = await fetch("/api/ride-groups", {
    method: "POST",
    headers: await authHeaders(),
    credentials: "include",
    body: JSON.stringify(input),
  });
  const body = await readJson(res);
  if (!res.ok) return failOf(res, body);
  return {
    me: String(body.me || ""),
    group: body.group as RideGroup,
    members: Array.isArray(body.members)
      ? (body.members as RideGroupMember[])
      : [],
    stub: body.stub === true,
  };
}

export async function joinRideGroupCloud(input: {
  code?: string;
  groupId?: string;
  token?: string | null;
}): Promise<RideGroupCloudOne | RideGroupCloudFail> {
  const res = await fetch("/api/ride-groups/join", {
    method: "POST",
    headers: await authHeaders(),
    credentials: "include",
    body: JSON.stringify({
      code: input.code || undefined,
      groupId: input.groupId || undefined,
      token: input.token || undefined,
    }),
  });
  const body = await readJson(res);
  if (!res.ok) return failOf(res, body);
  return {
    me: String(body.me || ""),
    group: body.group as RideGroup,
    members: Array.isArray(body.members)
      ? (body.members as RideGroupMember[])
      : [],
    already: body.already === true,
    stub: body.stub === true,
  };
}

export async function setRideGroupVisibilityCloud(input: {
  id: string;
  visibility: "public" | "private";
}): Promise<RideGroupCloudOne | RideGroupCloudFail> {
  const res = await fetch("/api/ride-groups/visibility", {
    method: "POST",
    headers: await authHeaders(),
    credentials: "include",
    body: JSON.stringify(input),
  });
  const body = await readJson(res);
  if (!res.ok) return failOf(res, body);
  return {
    me: String(body.me || ""),
    group: body.group as RideGroup,
    members: Array.isArray(body.members)
      ? (body.members as RideGroupMember[])
      : [],
    stub: body.stub === true,
  };
}

export async function closeRideGroupCloud(
  id: string
): Promise<{ ok: true } | RideGroupCloudFail> {
  const res = await fetch("/api/ride-groups/close", {
    method: "POST",
    headers: await authHeaders(),
    credentials: "include",
    body: JSON.stringify({ id }),
  });
  const body = await readJson(res);
  if (!res.ok) return failOf(res, body);
  return { ok: true };
}

export async function fetchRideGroupPresence(
  groupId: string
): Promise<
  | { me: string; groupId: string; presence: RideGroupPresence[]; members: RideGroupMember[] }
  | RideGroupCloudFail
> {
  const res = await fetch(
    `/api/ride-groups/presence?groupId=${encodeURIComponent(groupId)}`,
    {
      method: "GET",
      headers: await authHeaders(),
      credentials: "include",
    }
  );
  const body = await readJson(res);
  if (!res.ok) return failOf(res, body);
  return {
    me: String(body.me || ""),
    groupId: String(body.groupId || groupId),
    presence: Array.isArray(body.presence)
      ? (body.presence as RideGroupPresence[])
      : [],
    members: Array.isArray(body.members)
      ? (body.members as RideGroupMember[])
      : [],
  };
}

export async function publishRideGroupPresence(input: {
  groupId: string;
  lat?: number;
  lng?: number;
  inPrivacyZone?: boolean;
  liveOptIn?: boolean;
}): Promise<
  | { me: string; groupId: string; presence: RideGroupPresence[]; members: RideGroupMember[] }
  | RideGroupCloudFail
> {
  const res = await fetch("/api/ride-groups/presence", {
    method: "POST",
    headers: await authHeaders(),
    credentials: "include",
    body: JSON.stringify(input),
  });
  const body = await readJson(res);
  if (!res.ok) return failOf(res, body);
  return {
    me: String(body.me || ""),
    groupId: String(body.groupId || input.groupId),
    presence: Array.isArray(body.presence)
      ? (body.presence as RideGroupPresence[])
      : [],
    members: Array.isArray(body.members)
      ? (body.members as RideGroupMember[])
      : [],
  };
}

export async function leaveRideGroupCloud(
  id: string
): Promise<{ ok: true } | RideGroupCloudFail> {
  const res = await fetch("/api/ride-groups/leave", {
    method: "POST",
    headers: await authHeaders(),
    credentials: "include",
    body: JSON.stringify({ id }),
  });
  const body = await readJson(res);
  if (!res.ok) return failOf(res, body);
  return { ok: true };
}

export function isCloudFail(
  value: { error?: string } | object
): value is RideGroupCloudFail {
  return "error" in value && typeof (value as RideGroupCloudFail).error === "string";
}
