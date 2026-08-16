/**
 * Last-point Presence — kein Track, kein Explore, keine Demo-Pins.
 * GET ?groupId=  Mitglieder sehen live/stale. Älter als 5 min: weg.
 * POST { groupId, lat?, lng?, inPrivacyZone?, liveOptIn? }
 */
import { NextResponse } from "next/server";
import { createAuthedClient } from "@/lib/supabase/authed";
import { createAdminClient } from "@/lib/supabase/admin";
import {
  RIDE_GROUP_DROP_AFTER_MS,
  isEventWindowOpen,
  quantizeGroupCoord,
  resolvePresenceVisibility,
} from "@/lib/community/rideGroup";
import {
  isMissingRideGroupTable,
  isRideGroupId,
  rowToMember,
  rowToPresence,
  rowToRideGroup,
  type RideGroupSqlRow,
} from "@/lib/community/rideGroupServer";
import type { RideGroupPresenceVisibility } from "@/lib/community/types";

export const dynamic = "force-dynamic";

function unauthorized() {
  return NextResponse.json({ error: "unauthorized" }, { status: 401 });
}

function stub(note: string) {
  return NextResponse.json(
    { error: "not_implemented", stub: true, note },
    { status: 501 }
  );
}

async function tryAdmin() {
  try {
    return createAdminClient();
  } catch {
    return null;
  }
}

async function loadGroup(
  admin: ReturnType<typeof createAdminClient>,
  groupId: string
) {
  const { data, error } = await admin
    .from("ride_groups")
    .select(
      "id, host_user_id, saved_route_id, catalog_tour_id, title, start_window_start, start_window_end, join_code, status, live_pins_allowed, created_at"
    )
    .eq("id", groupId)
    .maybeSingle();
  if (error) {
    if (isMissingRideGroupTable(error)) {
      return { error: stub("Server-Tabelle fehlt — Presence bleibt lokal.") };
    }
    return {
      error: NextResponse.json(
        { error: "query_failed", note: error.message },
        { status: 501 }
      ),
    };
  }
  if (!data) {
    return {
      error: NextResponse.json({ error: "unknown" }, { status: 404 }),
    };
  }
  return { row: data as RideGroupSqlRow };
}

async function isMember(
  admin: ReturnType<typeof createAdminClient>,
  groupId: string,
  userId: string
): Promise<boolean> {
  const { data } = await admin
    .from("ride_group_members")
    .select("user_id")
    .eq("group_id", groupId)
    .eq("user_id", userId)
    .maybeSingle();
  return Boolean(data);
}

function ageMsOf(updatedAt: string, nowIso: string): number {
  const a = Date.parse(updatedAt);
  const n = Date.parse(nowIso);
  if (!Number.isFinite(a) || !Number.isFinite(n)) return RIDE_GROUP_DROP_AFTER_MS + 1;
  return Math.max(0, n - a);
}

async function visibleBundle(
  admin: ReturnType<typeof createAdminClient>,
  groupRow: RideGroupSqlRow,
  nowIso: string
) {
  const group = rowToRideGroup(groupRow);
  const groupId = group.id;
  const { data: memRows, error: memErr } = await admin
    .from("ride_group_members")
    .select("group_id, user_id, display_label, joined_at, live_opt_in")
    .eq("group_id", groupId);
  if (memErr) throw memErr;
  const members = (memRows ?? []).map((row) =>
    rowToMember(row as RideGroupSqlRow, "")
  );
  const opt = new Set(
    members.filter((m) => m.liveOptIn).map((m) => m.userId)
  );
  const inWindow = isEventWindowOpen(
    nowIso,
    group.startWindowStart,
    group.startWindowEnd,
    group.status
  );

  const { data: presRows, error: pErr } = await admin
    .from("ride_group_presence")
    .select("group_id, user_id, lng, lat, updated_at, visibility")
    .eq("group_id", groupId);
  if (pErr) throw pErr;

  const staleIds: string[] = [];
  const presence = [];
  for (const raw of presRows ?? []) {
    const row = raw as RideGroupSqlRow;
    const userId = String(row.user_id);
    const updatedAt = String(row.updated_at ?? nowIso);
    const age = ageMsOf(updatedAt, nowIso);
    if (age > RIDE_GROUP_DROP_AFTER_MS) {
      staleIds.push(userId);
      continue;
    }
    const vis = resolvePresenceVisibility({
      isMember: members.some((m) => m.userId === userId),
      livePinsAllowed: group.livePinsAllowed,
      liveOptIn: opt.has(userId),
      inEventWindow: inWindow,
      inPrivacyZone: String(row.visibility) === "hidden_zone",
      hasFix: typeof row.lat === "number" && typeof row.lng === "number",
      ageMs: age,
    });
    presence.push(
      rowToPresence({
        ...row,
        visibility: vis,
        lat: vis === "live" || vis === "stale" ? row.lat : null,
        lng: vis === "live" || vis === "stale" ? row.lng : null,
      })
    );
  }
  if (staleIds.length > 0) {
    await admin
      .from("ride_group_presence")
      .delete()
      .eq("group_id", groupId)
      .in("user_id", staleIds);
  }
  return { group, members, presence };
}

export async function GET(req: Request) {
  try {
    const supabase = await createAuthedClient(req);
    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (!user) return unauthorized();

    const groupId = new URL(req.url).searchParams.get("groupId")?.trim() ?? "";
    if (!isRideGroupId(groupId)) {
      return NextResponse.json({ error: "invalid_body" }, { status: 400 });
    }

    const admin = await tryAdmin();
    if (!admin) return stub("Service-Role fehlt — Presence bleibt lokal.");

    const loaded = await loadGroup(admin, groupId);
    if (loaded.error) return loaded.error;
    if (!(await isMember(admin, groupId, user.id))) {
      return NextResponse.json({ error: "unknown" }, { status: 404 });
    }

    const nowIso = new Date().toISOString();
    const bundle = await visibleBundle(admin, loaded.row, nowIso);
    return NextResponse.json({
      me: user.id,
      groupId,
      presence: bundle.presence,
      members: bundle.members,
      stub: false,
    });
  } catch {
    return unauthorized();
  }
}

export async function POST(req: Request) {
  try {
    const supabase = await createAuthedClient(req);
    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (!user) return unauthorized();

    const body = (await req.json()) as {
      groupId?: string;
      lat?: number;
      lng?: number;
      inPrivacyZone?: boolean;
      liveOptIn?: boolean;
    };
    const groupId = String(body.groupId || "").trim();
    if (!isRideGroupId(groupId)) {
      return NextResponse.json({ error: "invalid_body" }, { status: 400 });
    }

    const admin = await tryAdmin();
    if (!admin) return stub("Service-Role fehlt — Presence bleibt lokal.");

    const loaded = await loadGroup(admin, groupId);
    if (loaded.error) return loaded.error;
    if (!(await isMember(admin, groupId, user.id))) {
      return NextResponse.json({ error: "unknown" }, { status: 404 });
    }

    if (typeof body.liveOptIn === "boolean") {
      const { error } = await admin
        .from("ride_group_members")
        .update({ live_opt_in: body.liveOptIn })
        .eq("group_id", groupId)
        .eq("user_id", user.id);
      if (error) {
        return NextResponse.json(
          { error: "opt_in_failed", note: error.message },
          { status: 501 }
        );
      }
    }

    const { data: mem } = await admin
      .from("ride_group_members")
      .select("live_opt_in")
      .eq("group_id", groupId)
      .eq("user_id", user.id)
      .maybeSingle();
    const group = rowToRideGroup(loaded.row);
    const now = new Date();
    const nowIso = now.toISOString();
    const hasFix =
      typeof body.lat === "number" &&
      Number.isFinite(body.lat) &&
      typeof body.lng === "number" &&
      Number.isFinite(body.lng);
    const q = hasFix
      ? quantizeGroupCoord(body.lat as number, body.lng as number)
      : null;
    const vis: RideGroupPresenceVisibility = resolvePresenceVisibility({
      isMember: true,
      livePinsAllowed: group.livePinsAllowed,
      liveOptIn: mem?.live_opt_in === true,
      inEventWindow: isEventWindowOpen(
        nowIso,
        group.startWindowStart,
        group.startWindowEnd,
        group.status
      ),
      inPrivacyZone: body.inPrivacyZone === true,
      hasFix: Boolean(q),
      ageMs: q ? 0 : null,
    });
    const pin = vis === "live" || vis === "stale";

    const { error: upErr } = await admin.from("ride_group_presence").upsert(
      {
        group_id: groupId,
        user_id: user.id,
        lat: pin && q ? q.lat : null,
        lng: pin && q ? q.lng : null,
        updated_at: nowIso,
        visibility: vis,
      },
      { onConflict: "group_id,user_id" }
    );
    if (upErr) {
      if (isMissingRideGroupTable(upErr)) {
        return stub("Presence-Tabelle fehlt — lokal bleiben.");
      }
      return NextResponse.json(
        { error: "upsert_failed", note: upErr.message },
        { status: 501 }
      );
    }

    const bundle = await visibleBundle(admin, loaded.row, nowIso);
    return NextResponse.json({
      me: user.id,
      groupId,
      presence: bundle.presence,
      members: bundle.members,
      stub: false,
    });
  } catch {
    return unauthorized();
  }
}
