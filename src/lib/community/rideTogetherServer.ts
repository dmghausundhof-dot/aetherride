/**
 * Freeride-Zusammen — Server-Helfer. Kein Fake-Roster, keine Koordinaten raus.
 */
import { createAdminClient } from "@/lib/supabase/admin";
import {
  generateJoinCode,
  isMissingRideGroupTable,
  labelsByUserId,
  profileDisplayLabel,
  rowToMember,
  rowToRideGroup,
  RIDE_GROUP_SELECT,
  type PublicProfileLabelRow,
  type RideGroupSqlRow,
} from "@/lib/community/rideGroupServer";
import {
  RIDE_TOGETHER_LOOK_MS,
  RIDE_TOGETHER_REQUEST_MS,
  RIDE_TOGETHER_ROUTE_ID,
  RIDE_TOGETHER_TITLE,
  canAddSessionMember,
  isSessionRouteId,
  matePair,
  nearbyFromLooks,
  sessionLeaveClosesGroup,
  sanitizeTogetherLabel,
  sessionWindow,
  togetherBounds,
} from "@/lib/community/rideTogether";
import { quantizeGroupCoord } from "@/lib/community/rideGroup";
import type { RideGroup, RideGroupMember } from "@/lib/community/types";

export { isMissingRideGroupTable };

export type AdminClient = ReturnType<typeof createAdminClient>;

export function isMissingTogetherTable(
  err: { code?: string; message?: string } | null | undefined
): boolean {
  if (!err) return false;
  if (err.code === "42P01") return true;
  return /ride_together_|ride_mates/i.test(err.message ?? "");
}

export function resolveTogetherLabel(
  profile: PublicProfileLabelRow | null | undefined,
  clientLabel?: unknown
): string {
  return profileDisplayLabel(profile) || sanitizeTogetherLabel(clientLabel);
}

export async function expireStaleTogether(
  admin: AdminClient,
  now = new Date()
): Promise<void> {
  const iso = now.toISOString();
  await admin
    .from("ride_together_looks")
    .delete()
    .lt("looking_until", iso);
  await admin
    .from("ride_together_requests")
    .update({ status: "expired" })
    .eq("status", "pending")
    .lt("expires_at", iso);
}

export async function loadLabels(
  admin: AdminClient,
  userIds: string[]
): Promise<Map<string, string>> {
  const ids = [...new Set(userIds.filter(Boolean))];
  if (ids.length === 0) return new Map();
  const { data } = await admin
    .from("public_profiles")
    .select("user_id, enabled, display_name, handle")
    .in("user_id", ids);
  return labelsByUserId((data ?? []) as PublicProfileLabelRow[]);
}

export async function memberBundle(
  admin: AdminClient,
  groupId: string
): Promise<RideGroupMember[]> {
  const { data: rows, error } = await admin
    .from("ride_group_members")
    .select("group_id, user_id, display_label, joined_at, live_opt_in")
    .eq("group_id", groupId);
  if (error) throw error;
  const userIds = (rows ?? []).map((r: RideGroupSqlRow) => String(r.user_id));
  const labels = await loadLabels(admin, userIds);
  return (rows ?? []).map((row: RideGroupSqlRow) =>
    rowToMember(row, labels.get(String(row.user_id)) ?? "")
  );
}

export async function sessionMemberCount(
  admin: AdminClient,
  groupId: string
): Promise<number> {
  const { count } = await admin
    .from("ride_group_members")
    .select("user_id", { count: "exact", head: true })
    .eq("group_id", groupId);
  return count ?? 0;
}

export async function findOpenSessionForUser(
  admin: AdminClient,
  userId: string
): Promise<RideGroup | null> {
  const { data: mems } = await admin
    .from("ride_group_members")
    .select("group_id")
    .eq("user_id", userId);
  const ids = [
    ...new Set(
      (mems ?? [])
        .map((r: { group_id?: string }) => String(r.group_id || ""))
        .filter(Boolean)
    ),
  ];
  if (ids.length === 0) return null;
  const { data: rows } = await admin
    .from("ride_groups")
    .select(RIDE_GROUP_SELECT)
    .in("id", ids)
    .eq("saved_route_id", RIDE_TOGETHER_ROUTE_ID)
    .neq("status", "closed")
    .order("created_at", { ascending: false })
    .limit(1);
  const hit = Array.isArray(rows) ? rows[0] : rows;
  return hit ? rowToRideGroup(hit as RideGroupSqlRow) : null;
}

export async function openSessionForUser(
  admin: AdminClient,
  userId: string,
  label: string
): Promise<RideGroup> {
  const found = await findOpenSessionForUser(admin, userId);
  if (found) {
    await admin.from("ride_group_members").upsert(
      {
        group_id: found.id,
        user_id: userId,
        display_label: label,
        live_opt_in: true,
      },
      { onConflict: "group_id,user_id" }
    );
    return found;
  }
  return ensureSessionGroup(admin, userId, label);
}

/** Eine Freeride-Session pro Person. Beitritt lässt die alte Solo-/Session hinter sich. */
export async function leaveOtherSessions(
  admin: AdminClient,
  userId: string,
  keepGroupId: string
): Promise<void> {
  const { data: mems } = await admin
    .from("ride_group_members")
    .select("group_id")
    .eq("user_id", userId);
  const ids = [
    ...new Set(
      (mems ?? [])
        .map((r: { group_id?: string }) => String(r.group_id || ""))
        .filter((id) => id && id !== keepGroupId)
    ),
  ];
  if (ids.length === 0) return;
  const { data: rows } = await admin
    .from("ride_groups")
    .select("id")
    .in("id", ids)
    .eq("saved_route_id", RIDE_TOGETHER_ROUTE_ID)
    .neq("status", "closed");
  for (const row of rows ?? []) {
    const id = String((row as { id?: string }).id || "");
    if (!id || id === keepGroupId) continue;
    await leaveSession(admin, id, userId);
  }
}

export async function ensureSessionGroup(
  admin: AdminClient,
  userId: string,
  label: string
): Promise<RideGroup> {
  const { data: existing } = await admin
    .from("ride_groups")
    .select(RIDE_GROUP_SELECT)
    .eq("host_user_id", userId)
    .eq("saved_route_id", RIDE_TOGETHER_ROUTE_ID)
    .neq("status", "closed")
    .order("created_at", { ascending: false })
    .limit(1)
    .maybeSingle();
  if (existing) {
    const group = rowToRideGroup(existing as RideGroupSqlRow);
    await admin.from("ride_group_members").upsert(
      {
        group_id: group.id,
        user_id: userId,
        display_label: label,
        live_opt_in: true,
      },
      { onConflict: "group_id,user_id" }
    );
    return group;
  }

  const window = sessionWindow();
  let inserted: RideGroupSqlRow | null = null;
  let lastError: { code?: string; message?: string } | null = null;
  for (let i = 0; i < 4; i++) {
    const { data, error } = await admin
      .from("ride_groups")
      .insert({
        host_user_id: userId,
        saved_route_id: RIDE_TOGETHER_ROUTE_ID,
        catalog_tour_id: null,
        title: RIDE_TOGETHER_TITLE,
        start_window_start: window.start.toISOString(),
        start_window_end: window.end.toISOString(),
        join_code: generateJoinCode(),
        status: window.status,
        live_pins_allowed: true,
        visibility: "private",
        meeting_point: null,
      })
      .select(RIDE_GROUP_SELECT)
      .maybeSingle();
    if (!error && data) {
      inserted = data as RideGroupSqlRow;
      break;
    }
    lastError = error;
    if (error && isMissingRideGroupTable(error)) throw error;
    if (error?.code !== "23505") throw error ?? new Error("insert_failed");
  }
  if (!inserted) {
    throw lastError ?? new Error("insert_failed");
  }
  const group = rowToRideGroup(inserted);
  await admin.from("ride_group_members").insert({
    group_id: group.id,
    user_id: userId,
    display_label: label,
    live_opt_in: true,
  });
  return group;
}

export async function closeSoloSession(
  admin: AdminClient,
  userId: string,
  exceptGroupId?: string
): Promise<void> {
  const { data: rows } = await admin
    .from("ride_groups")
    .select("id")
    .eq("host_user_id", userId)
    .eq("saved_route_id", RIDE_TOGETHER_ROUTE_ID)
    .neq("status", "closed");
  for (const row of rows ?? []) {
    const id = String((row as { id?: string }).id || "");
    if (!id || id === exceptGroupId) continue;
    const { count } = await admin
      .from("ride_group_members")
      .select("user_id", { count: "exact", head: true })
      .eq("group_id", id);
    if ((count ?? 0) <= 1) {
      await admin.from("ride_groups").update({ status: "closed" }).eq("id", id);
    }
  }
}

export async function upsertMate(admin: AdminClient, a: string, b: string) {
  const pair = matePair(a, b);
  if (!pair) return;
  const now = new Date().toISOString();
  const { data: existing } = await admin
    .from("ride_mates")
    .select("user_lo")
    .eq("user_lo", pair.lo)
    .eq("user_hi", pair.hi)
    .maybeSingle();
  if (existing) {
    await admin
      .from("ride_mates")
      .update({ last_paired_at: now })
      .eq("user_lo", pair.lo)
      .eq("user_hi", pair.hi);
    return;
  }
  await admin.from("ride_mates").insert({
    user_lo: pair.lo,
    user_hi: pair.hi,
    first_paired_at: now,
    last_paired_at: now,
  });
}

export async function addSessionMember(
  admin: AdminClient,
  groupId: string,
  userId: string,
  label: string
): Promise<boolean> {
  const { data: existing } = await admin
    .from("ride_group_members")
    .select("user_id")
    .eq("group_id", groupId)
    .eq("user_id", userId)
    .maybeSingle();
  if (existing) {
    await admin
      .from("ride_group_members")
      .update({ live_opt_in: true, display_label: label })
      .eq("group_id", groupId)
      .eq("user_id", userId);
    return true;
  }
  const n = await sessionMemberCount(admin, groupId);
  if (!canAddSessionMember(n)) {
    const err = new Error("full") as Error & { code?: string };
    err.code = "together_full";
    throw err;
  }
  const { error } = await admin.from("ride_group_members").insert({
    group_id: groupId,
    user_id: userId,
    display_label: label,
    live_opt_in: true,
  });
  if (error && error.code !== "23505") throw error;
  return false;
}

/**
 * Ein Mitglied steigt aus. Die anderen bleiben zusammen.
 * Host mit Rest gibt nur den Host weiter — schließt nicht.
 * Zu nur wenn nach dem Leave niemand mehr da ist (Letzter / allein).
 */
export async function leaveSession(
  admin: AdminClient,
  groupId: string,
  userId: string
): Promise<{ closed: boolean; remaining: number }> {
  const { data: roster } = await admin
    .from("ride_group_members")
    .select("user_id, joined_at")
    .eq("group_id", groupId);
  const members = (roster ?? []) as Array<{ user_id: string; joined_at?: string }>;
  const remaining = members.filter((m) => String(m.user_id) !== userId);
  await admin
    .from("ride_group_members")
    .delete()
    .eq("group_id", groupId)
    .eq("user_id", userId);
  await admin.from("ride_together_looks").delete().eq("user_id", userId);
  await admin
    .from("ride_together_requests")
    .update({ status: "expired" })
    .eq("status", "pending")
    .eq("from_user_id", userId);
  await admin
    .from("ride_together_requests")
    .update({ status: "expired" })
    .eq("status", "pending")
    .eq("to_user_id", userId);

  if (sessionLeaveClosesGroup(remaining.length)) {
    await admin.from("ride_groups").update({ status: "closed" }).eq("id", groupId);
    return { closed: true, remaining: 0 };
  }

  const { data: group } = await admin
    .from("ride_groups")
    .select("host_user_id")
    .eq("id", groupId)
    .maybeSingle();
  if (group && String(group.host_user_id) === userId) {
    remaining.sort((a, b) =>
      String(a.joined_at ?? "").localeCompare(String(b.joined_at ?? ""))
    );
    await admin
      .from("ride_groups")
      .update({ host_user_id: remaining[0].user_id })
      .eq("id", groupId);
  }
  return { closed: false, remaining: remaining.length };
}

export { nearbyFromLooks };

export function lookBox(lat: number, lng: number) {
  const q = quantizeGroupCoord(lat, lng);
  return { q, box: togetherBounds(q.lat, q.lng) };
}

export function lookingUntilIso(now = new Date()): string {
  return new Date(now.getTime() + RIDE_TOGETHER_LOOK_MS).toISOString();
}

export function requestExpiresIso(now = new Date()): string {
  return new Date(now.getTime() + RIDE_TOGETHER_REQUEST_MS).toISOString();
}

export { isSessionRouteId };
