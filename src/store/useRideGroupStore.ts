"use client";

/**
 * RideGroup — lokal immer. API wenn eingeloggt. Kein Fake-Roster.
 */

import { create } from "zustand";
import { persist } from "zustand/middleware";
import { v4 as uuidv4 } from "uuid";
import type { RideGroup, RideGroupMember } from "@/lib/community/types";
import {
  canAttachCourse,
  generateJoinCode,
  isRideGroupId,
  keepLocalRideGroupAfterCloud,
  parseGroupListing,
} from "@/lib/community/rideGroup";
import {
  decodeGroupInvite,
  inviteWindowOpen,
} from "@/lib/community/rideGroupInvite";
import {
  closeRideGroupCloud,
  createRideGroupCloud,
  fetchRideGroups,
  isCloudFail,
  joinRideGroupCloud,
  leaveRideGroupCloud,
  publishRideGroupPresence,
  rideGroupHasSession,
  setRideGroupVisibilityCloud,
} from "@/lib/community/rideGroupCloud";
import type { SavedRoute } from "@/types/route";

export const LOCAL_ONLY_NOTE =
  "Nicht eingeloggt — nur auf diesem Gerät. Join auf dem Server braucht Login.";
export const SERVER_TABLE_NOTE =
  "Server-Tabelle fehlt — nur lokal.";
export const ON_SERVER_NOTE = "Gruppe auf dem Server.";

type RideGroupState = {
  localUserId: string;
  cloudUserId: string | null;
  lastNote: string | null;
  groups: RideGroup[];
  members: RideGroupMember[];
  inboxSeen: number;
  createGroup: (input: {
    route: SavedRoute;
    title?: string;
    displayLabel?: string;
    visibility?: "public" | "private";
  }) => RideGroup | { error: string };
  createGroupAsync: (input: {
    route: SavedRoute;
    title?: string;
    displayLabel?: string;
    visibility?: "public" | "private";
    startsAt?: string;
    durationHours?: number;
    meetingPoint?: string;
  }) => Promise<RideGroup | { error: string }>;
  setVisibilityAsync: (
    id: string,
    visibility: "public" | "private"
  ) => Promise<void>;
  joinByCode: (code: string) => RideGroup | { error: string };
  joinByCodeAsync: (
    code: string,
    token?: string | null
  ) => Promise<RideGroup | { error: string }>;
  joinFromInvite: (
    code: string,
    token?: string | null
  ) => RideGroup | { error: string };
  joinFromInviteAsync: (
    code: string,
    token?: string | null
  ) => Promise<RideGroup | { error: string }>;
  setLiveOptIn: (groupId: string, on: boolean) => void;
  leaveGroup: (groupId: string) => void;
  leaveGroupAsync: (groupId: string) => Promise<void>;
  pullCloud: () => Promise<void>;
  markInboxSeen: (n: number) => void;
};

function activeGroups(groups: RideGroup[]) {
  return groups.filter((g) => g.status !== "closed");
}

function isSelf(state: { localUserId: string; cloudUserId: string | null }, userId: string) {
  return userId === state.localUserId || Boolean(state.cloudUserId && userId === state.cloudUserId);
}

function mergeCloud(
  state: RideGroupState,
  input: { me: string; groups: RideGroup[]; members: RideGroupMember[] }
): Partial<RideGroupState> {
  const ids = new Set(input.groups.map((g) => g.id));
  const codes = new Set(input.groups.map((g) => g.joinCode));
  const cloudUserId = input.me || state.cloudUserId;
  const self = { localUserId: state.localUserId, cloudUserId };
  const keepLocal = state.groups.filter(
    (g) =>
      !ids.has(g.id) &&
      !codes.has(g.joinCode) &&
      keepLocalRideGroupAfterCloud({
        onServer: g.onServer,
        selfIsHost: isSelf(self, g.hostUserId),
      })
  );
  const keepIds = new Set(keepLocal.map((g) => g.id));
  return {
    cloudUserId,
    groups: [
      ...input.groups.map((g) => ({ ...g, onServer: true })),
      ...keepLocal,
    ],
    members: [
      ...input.members,
      ...state.members.filter(
        (m) => !ids.has(m.groupId) && keepIds.has(m.groupId)
      ),
    ],
  };
}

function localCreate(
  get: () => RideGroupState,
  input: {
    route: SavedRoute;
    title?: string;
    displayLabel?: string;
    visibility?: "public" | "private";
  }
): RideGroup | { error: string } {
  if (!canAttachCourse(input.route)) {
    return {
      error:
        "Gruppe nur an freigegebener oder Katalog-Tour. Private GPX bleibt privat.",
    };
  }
  const now = new Date();
  const end = new Date(now.getTime() + 4 * 60 * 60 * 1000);
  const group: RideGroup = {
    id: `rg-${uuidv4()}`,
    hostUserId: get().localUserId,
    savedRouteId: input.route.id,
    catalogTourId: input.route.catalogTourId,
    title: (input.title ?? input.route.name).trim() || "Gruppe",
    startWindowStart: now.toISOString(),
    startWindowEnd: end.toISOString(),
    joinCode: generateJoinCode(),
    status: "open",
    livePinsAllowed: true,
    visibility: parseGroupListing(input.visibility),
    createdAt: now.toISOString(),
    onServer: false,
  };
  const host: RideGroupMember = {
    groupId: group.id,
    userId: get().localUserId,
    displayLabel: (input.displayLabel ?? "Du").trim() || "Du",
    joinedAt: now.toISOString(),
    liveOptIn: false,
  };
  useRideGroupStore.setState((s) => ({
    groups: [group, ...s.groups],
    members: [host, ...s.members],
  }));
  return group;
}

export const useRideGroupStore = create<RideGroupState>()(
  persist(
    (set, get) => ({
      localUserId: `web-${uuidv4()}`,
      cloudUserId: null,
      lastNote: null,
      groups: [],
      members: [],
      inboxSeen: 0,

      createGroup: (input) => {
        const out = localCreate(get, input);
        if (!("error" in out)) {
          set({ lastNote: LOCAL_ONLY_NOTE });
        }
        return out;
      },

      createGroupAsync: async (input) => {
        if (!canAttachCourse(input.route)) {
          return {
            error:
              "Gruppe nur an freigegebener oder Katalog-Tour. Private GPX bleibt privat.",
          };
        }
        const loggedIn = await rideGroupHasSession();
        if (!loggedIn) {
          return {
            error:
              "Anmelden — sonst sieht der Freund die Gruppe nicht auf dem Server.",
          };
        }
        const cloud = await createRideGroupCloud({
          savedRouteId: input.route.id,
          catalogTourId: input.route.catalogTourId,
          title: (input.title ?? input.route.name).trim() || "Gruppe",
          visibility: parseGroupListing(input.visibility),
          startsAt: input.startsAt,
          durationHours: input.durationHours,
          meetingPoint: input.meetingPoint,
        });
        if (!isCloudFail(cloud) && cloud.group) {
          set((s) => ({
            lastNote: ON_SERVER_NOTE,
            ...mergeCloud(s as RideGroupState, {
              me: cloud.me,
              groups: [cloud.group],
              members: cloud.members,
            }),
          }));
          return { ...cloud.group, onServer: true };
        }
        return {
          error:
            isCloudFail(cloud) && cloud.status === 401
              ? "Anmelden — sonst sieht der Freund die Gruppe nicht auf dem Server."
              : isCloudFail(cloud)
                ? cloud.note || "Anlegen auf dem Server fehlgeschlagen."
                : "Anlegen auf dem Server fehlgeschlagen.",
        };
      },

      joinByCode: (code) => {
        const normalized = code.trim().toUpperCase();
        if (normalized.length !== 6) {
          return { error: "Code hat 6 Zeichen." };
        }
        const hit = get().groups.find(
          (g) => g.joinCode === normalized && g.status !== "closed"
        );
        if (!hit) {
          return {
            error:
              "Kein offener Link. Ohne Login gilt nur dieser Speicher; sonst den Einladungslink einfügen.",
          };
        }
        const now = new Date();
        if (now > new Date(hit.startWindowEnd)) {
          return { error: "Fenster zu — der Link gilt nicht mehr." };
        }
        const uid = get().localUserId;
        if (
          get().members.some((m) => m.groupId === hit.id && m.userId === uid)
        ) {
          return hit;
        }
        const member: RideGroupMember = {
          groupId: hit.id,
          userId: uid,
          displayLabel: "Du",
          joinedAt: new Date().toISOString(),
          liveOptIn: false,
        };
        set((s) => ({ members: [member, ...s.members] }));
        return hit;
      },

      setVisibilityAsync: async (id, visibility) => {
        const loggedIn = await rideGroupHasSession();
        if (loggedIn) {
          const cloud = await setRideGroupVisibilityCloud({ id, visibility });
          if (!isCloudFail(cloud) && cloud.group) {
            set((s) => ({
              lastNote:
                visibility === "public"
                  ? "Gruppe öffentlich — wer den Link hat, kann beitreten."
                  : "Gruppe privat — nur der Link.",
              groups: s.groups.map((g) =>
                g.id === id ? { ...g, ...cloud.group, visibility } : g
              ),
            }));
            return;
          }
        }
        set((s) => ({
          groups: s.groups.map((g) =>
            g.id === id ? { ...g, visibility } : g
          ),
        }));
      },

      joinByCodeAsync: async (code, token) => {
        const raw = code.trim();
        const asId = isRideGroupId(raw);
        const normalized = raw.toUpperCase();
        if (!asId && normalized.length !== 6 && !token) {
          return { error: "Beitritt nur über den Einladungslink." };
        }
        const loggedIn = await rideGroupHasSession();
        if (!loggedIn) {
          return { error: "Anmelden — sonst sieht der Host dich nicht." };
        }
        const cloud = await joinRideGroupCloud({
          code: asId ? undefined : normalized,
          groupId: asId ? raw : undefined,
          token,
        });
        if (!isCloudFail(cloud) && cloud.group) {
          set((s) => ({
            lastNote: ON_SERVER_NOTE,
            ...mergeCloud(s as RideGroupState, {
              me: cloud.me,
              groups: [cloud.group],
              members: cloud.members,
            }),
          }));
          return { ...cloud.group, onServer: true };
        }
        if (isCloudFail(cloud) && cloud.status === 403) {
          return {
            error:
              cloud.note ||
              "Privat — nur mit Einladungslink. Kein Code zum Abtippen.",
          };
        }
        if (isCloudFail(cloud) && cloud.status === 400) {
          return {
            error: cloud.note || "Beitritt nur über den Einladungslink.",
          };
        }
        if (isCloudFail(cloud) && cloud.status === 410) {
          return { error: cloud.note || "Fenster zu — der Link gilt nicht mehr." };
        }
        if (isCloudFail(cloud) && cloud.status === 409) {
          return { error: "Gruppe ist aufgelöst." };
        }
        if (isCloudFail(cloud) && cloud.status === 401) {
          return { error: "Anmelden — sonst sieht der Host dich nicht." };
        }
        return {
          error: isCloudFail(cloud)
            ? cloud.note || "Beitritt auf dem Server fehlgeschlagen."
            : "Beitritt auf dem Server fehlgeschlagen.",
        };
      },

      joinFromInvite: (code, token) => {
        const local = get().joinByCode(code);
        if (!("error" in local)) return local;
        if (!token) {
          return {
            error:
              "Kein offener Code. Link gilt nur, solange Fenster und Gruppe offen sind.",
          };
        }
        const payload = decodeGroupInvite(token);
        const raw = code.trim();
        const matchesCode = raw.toUpperCase() === payload?.code;
        const matchesId = raw.toLowerCase() === payload?.id.toLowerCase();
        if (!payload || (!matchesCode && !matchesId && raw.length > 0)) {
          return { error: "Einladungslink ungültig." };
        }
        if (!inviteWindowOpen(payload)) {
          return { error: "Fenster zu — Link gilt nicht mehr." };
        }
        const existing = get().groups.find((g) => g.id === payload.id);
        if (existing?.status === "closed") {
          return { error: "Gruppe ist aufgelöst." };
        }
        const now = new Date().toISOString();
        const group: RideGroup = existing ?? {
          id: payload.id,
          hostUserId: payload.hostUserId || "invite-host",
          savedRouteId: payload.savedRouteId,
          catalogTourId: payload.catalogTourId,
          title: payload.title,
          startWindowStart: payload.start,
          startWindowEnd: payload.end,
          joinCode: payload.code,
          status: "open",
          livePinsAllowed: true,
          createdAt: now,
          onServer: false,
        };
        const uid = get().localUserId;
        if (get().members.some((m) => m.groupId === group.id && m.userId === uid)) {
          return group;
        }
        const member: RideGroupMember = {
          groupId: group.id,
          userId: uid,
          displayLabel: "Du",
          joinedAt: now,
          liveOptIn: false,
        };
        set((s) => ({
          groups: existing ? s.groups : [group, ...s.groups],
          members: [member, ...s.members],
        }));
        return group;
      },

      joinFromInviteAsync: async (code, token) => {
        return get().joinByCodeAsync(code, token);
      },

      setLiveOptIn: (groupId, on) => {
        set((s) => ({
          members: s.members.map((m) =>
            m.groupId === groupId && isSelf(s, m.userId)
              ? { ...m, liveOptIn: on }
              : m
          ),
        }));
        const g = get().groups.find((x) => x.id === groupId);
        if (g?.onServer) {
          void publishRideGroupPresence({ groupId, liveOptIn: on });
        }
      },

      leaveGroup: (groupId) =>
        set((s) => {
          const host = s.groups.some(
            (g) => g.id === groupId && isSelf(s, g.hostUserId)
          );
          if (host) {
            return {
              groups: s.groups.map((g) =>
                g.id === groupId ? { ...g, status: "closed" as const } : g
              ),
            };
          }
          return {
            groups: s.groups.filter((g) => g.id !== groupId),
            members: s.members.filter((m) => m.groupId !== groupId),
          };
        }),

      leaveGroupAsync: async (groupId) => {
        const g = get().groups.find((x) => x.id === groupId);
        const host = g ? isSelf(get(), g.hostUserId) : false;
        if (g?.onServer && (await rideGroupHasSession())) {
          if (host) await closeRideGroupCloud(groupId);
          else await leaveRideGroupCloud(groupId);
        }
        get().leaveGroup(groupId);
        await get().pullCloud();
      },

      pullCloud: async () => {
        if (!(await rideGroupHasSession())) return;
        const cloud = await fetchRideGroups();
        if (isCloudFail(cloud)) {
          if (cloud.status === 501 || cloud.stub) {
            set({ lastNote: cloud.note || SERVER_TABLE_NOTE });
          }
          return;
        }
        set((s) => ({
          lastNote: cloud.groups.length ? ON_SERVER_NOTE : s.lastNote,
          ...mergeCloud(s as RideGroupState, cloud),
        }));
      },

      markInboxSeen: (n) => set({ inboxSeen: n }),
    }),
    {
      name: "aetherride-ride-groups-v1",
      partialize: (s) => ({
        localUserId: s.localUserId,
        cloudUserId: s.cloudUserId,
        groups: s.groups,
        members: s.members,
        inboxSeen: s.inboxSeen,
      }),
    }
  )
);

export function listedRideGroups(groups: RideGroup[]) {
  return activeGroups(groups);
}

export function isRideGroupSelf(
  state: { localUserId: string; cloudUserId: string | null },
  userId: string
) {
  return isSelf(state, userId);
}

export function memberRosterLine(input: {
  displayLabel: string;
  isHost: boolean;
  isSelf: boolean;
}): string {
  const name = input.displayLabel.trim();
  const role = input.isHost ? "Host" : "Gast";
  const self = input.isSelf ? " · du" : "";
  return name ? `${name} · ${role}${self}` : `${role}${self}`;
}
