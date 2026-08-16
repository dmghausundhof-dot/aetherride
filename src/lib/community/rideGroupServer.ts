/**
 * Ride-groups API helpers — mapping only. No fake roster.
 * Labels: Public Profile opt-in, sonst leer. Keine erfundenen Namen.
 */

import {
  generateJoinCode,
  isEventWindowOpen,
  parseGroupListing,
} from "@/lib/community/rideGroup";
import type {
  RideGroup,
  RideGroupMember,
  RideGroupPresence,
  RideGroupPresenceVisibility,
  RideGroupStatus,
} from "@/lib/community/types";

export { generateJoinCode, isEventWindowOpen, parseGroupListing };

export const RIDE_GROUP_SELECT =
  "id, host_user_id, saved_route_id, catalog_tour_id, title, start_window_start, start_window_end, join_code, status, live_pins_allowed, visibility, meeting_point, created_at";

export type RideGroupSqlRow = Record<string, unknown>;

export type PublicProfileLabelRow = {
  user_id?: string;
  enabled?: boolean;
  display_name?: string | null;
  handle?: string | null;
};

export function isMissingRideGroupTable(
  err: { code?: string; message?: string } | null | undefined
): boolean {
  if (!err) return false;
  return err.code === "42P01" || /ride_groups/i.test(err.message ?? "");
}

/** Nur enabled + Name oder @handle. Sonst leer — nie „Rider“ / Demo. */
export function profileDisplayLabel(
  row: PublicProfileLabelRow | null | undefined
): string {
  if (!row?.enabled) return "";
  const name = String(row.display_name || "").trim();
  if (name) return name.slice(0, 80);
  const handle = String(row.handle || "").trim();
  if (handle) return `@${handle}`;
  return "";
}

export function rowToRideGroup(row: RideGroupSqlRow): RideGroup {
  const status = String(row.status || "open") as RideGroupStatus;
  return {
    id: String(row.id),
    hostUserId: String(row.host_user_id),
    savedRouteId: String(row.saved_route_id),
    catalogTourId: row.catalog_tour_id
      ? String(row.catalog_tour_id)
      : undefined,
    title: String(row.title ?? ""),
    startWindowStart: String(row.start_window_start),
    startWindowEnd: String(row.start_window_end),
    meetingPoint: row.meeting_point
      ? String(row.meeting_point).trim() || undefined
      : undefined,
    joinCode: String(row.join_code),
    status:
      status === "scheduled" ||
      status === "open" ||
      status === "riding" ||
      status === "closed"
        ? status
        : "open",
    livePinsAllowed: row.live_pins_allowed === true,
    visibility: parseGroupListing(row.visibility),
    createdAt: String(row.created_at),
    onServer: true,
  };
}

export function rowToMember(
  row: RideGroupSqlRow,
  label: string
): RideGroupMember {
  return {
    groupId: String(row.group_id),
    userId: String(row.user_id),
    displayLabel: label,
    joinedAt: String(row.joined_at ?? new Date().toISOString()),
    liveOptIn: row.live_opt_in === true,
  };
}

export function labelsByUserId(
  rows: PublicProfileLabelRow[] | null | undefined
): Map<string, string> {
  const out = new Map<string, string>();
  for (const row of rows ?? []) {
    const id = String(row.user_id || "");
    if (!id) continue;
    out.set(id, profileDisplayLabel(row));
  }
  return out;
}

const PRESENCE_VIS: RideGroupPresenceVisibility[] = [
  "live",
  "stale",
  "hidden_zone",
  "hidden_offline",
  "hidden_opt_out",
  "hidden_window",
  "hidden_not_member",
];

export function parsePresenceVisibility(
  raw: unknown
): RideGroupPresenceVisibility {
  const s = String(raw || "");
  if ((PRESENCE_VIS as string[]).includes(s)) {
    return s as RideGroupPresenceVisibility;
  }
  return "hidden_offline";
}

export function rowToPresence(row: RideGroupSqlRow): RideGroupPresence {
  const vis = parsePresenceVisibility(row.visibility);
  const lat = typeof row.lat === "number" ? row.lat : undefined;
  const lng = typeof row.lng === "number" ? row.lng : undefined;
  const pin = vis === "live" || vis === "stale";
  return {
    groupId: String(row.group_id),
    userId: String(row.user_id),
    updatedAt: String(row.updated_at ?? new Date().toISOString()),
    visibility: vis,
    ...(pin && lat != null && lng != null ? { lat, lng } : {}),
  };
}

export function isRideGroupId(raw: string): boolean {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(
    raw
  );
}
