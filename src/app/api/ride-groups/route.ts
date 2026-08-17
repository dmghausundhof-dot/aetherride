/**
 * Zusammen raus — Gruppen auf dem Server.
 * GET: meine Gruppen (RLS). POST: anlegen + Host-Mitglied (service role).
 * Join: POST /api/ride-groups/join (Token oder öffentliche Id). Kein Code-Feld.
 */
import { NextResponse } from "next/server";
import { createAuthedClient } from "@/lib/supabase/authed";
import { createAdminClient } from "@/lib/supabase/admin";
import {
  parseGroupListing,
  parseMeetingPoint,
  parseRideGroupWindow,
} from "@/lib/community/rideGroup";
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

export const dynamic = "force-dynamic";

function unauthorized() {
  return NextResponse.json({ error: "unauthorized" }, { status: 401 });
}

function stub(status: number, note: string) {
  return NextResponse.json(
    { error: "not_implemented", stub: true, note },
    { status }
  );
}

async function tryAdmin() {
  try {
    return createAdminClient();
  } catch {
    return null;
  }
}

async function memberBundle(
  client: ReturnType<typeof createAdminClient>,
  groupIds: string[]
) {
  if (groupIds.length === 0) {
    return { members: [] as ReturnType<typeof rowToMember>[] };
  }
  const { data: rows, error } = await client
    .from("ride_group_members")
    .select("group_id, user_id, display_label, joined_at, live_opt_in")
    .in("group_id", groupIds);
  if (error) throw error;
  const userIds = [
    ...new Set((rows ?? []).map((r) => String((r as RideGroupSqlRow).user_id))),
  ];
  let profiles: PublicProfileLabelRow[] = [];
  if (userIds.length > 0) {
    const { data: prof } = await client
      .from("public_profiles")
      .select("user_id, enabled, display_name, handle")
      .in("user_id", userIds);
    profiles = (prof ?? []) as PublicProfileLabelRow[];
  }
  const labels = labelsByUserId(profiles);
  return {
    members: (rows ?? []).map((row) => {
      const r = row as RideGroupSqlRow;
      return rowToMember(r, labels.get(String(r.user_id)) ?? "");
    }),
  };
}

export async function GET(req: Request) {
  try {
    const supabase = await createAuthedClient(req);
    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (!user) return unauthorized();

    const admin = await tryAdmin();
    const roster = admin ?? supabase;

    const url = new URL(req.url);
    if (url.searchParams.get("scope") === "public") {
      const { data: rows, error: pubErr } = await roster
        .from("ride_groups")
        .select(RIDE_GROUP_SELECT)
        .eq("visibility", "public")
        .neq("status", "closed")
        .order("created_at", { ascending: false })
        .limit(40);
      if (pubErr) {
        if (isMissingRideGroupTable(pubErr)) {
          return stub(501, "Server-Tabelle fehlt — nur lokal.");
        }
        return NextResponse.json(
          { error: "query_failed", note: pubErr.message },
          { status: 501 }
        );
      }
      const mapped = (rows ?? []).map((g) =>
        rowToRideGroup(g as RideGroupSqlRow)
      );
      const ids = mapped.map((g) => g.id);
      const counts: Record<string, number> = {};
      if (ids.length > 0) {
        const { data: mems } = await roster
          .from("ride_group_members")
          .select("group_id")
          .in("group_id", ids);
        for (const row of mems ?? []) {
          const id = String((row as { group_id?: string }).group_id || "");
          if (!id) continue;
          counts[id] = (counts[id] ?? 0) + 1;
        }
      }
      return NextResponse.json({
        me: user.id,
        groups: mapped,
        members: [],
        memberCounts: counts,
        stub: false,
      });
    }

    const { data: groups, error } = await supabase
      .from("ride_groups")
      .select(RIDE_GROUP_SELECT)
      .neq("status", "closed")
      .order("created_at", { ascending: false });
    if (error) {
      if (isMissingRideGroupTable(error)) {
        return stub(501, "Server-Tabelle fehlt — nur lokal.");
      }
      return NextResponse.json(
        { error: "query_failed", note: error.message },
        { status: 501 }
      );
    }
    const mapped = (groups ?? []).map((g) => rowToRideGroup(g as RideGroupSqlRow));
    const { members } = await memberBundle(
      roster,
      mapped.map((g) => g.id)
    );
    return NextResponse.json({
      me: user.id,
      groups: mapped,
      members,
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
      savedRouteId?: string;
      catalogTourId?: string;
      title?: string;
      visibility?: string;
      startsAt?: string;
      duration?: number;
      durationHours?: number;
      meetingPoint?: string;
    };
    const savedRouteId = String(body.savedRouteId || "").trim();
    const title = String(body.title || "").trim() || "Gruppe";
    if (!savedRouteId) {
      return NextResponse.json({ error: "invalid_body" }, { status: 400 });
    }

    const admin = await tryAdmin();
    const writer = admin ?? supabase;

    const window = parseRideGroupWindow({
      startsAt: body.startsAt,
      duration: body.duration,
      durationHours: body.durationHours,
    });
    if ("error" in window) {
      return NextResponse.json(
        { error: window.error, note: "Startzeit und Dauer (1–12 h) nötig." },
        { status: 400 }
      );
    }
    const meetingPoint = parseMeetingPoint(body.meetingPoint) ?? null;
    let inserted: RideGroupSqlRow | null = null;
    let lastError: { code?: string; message?: string } | null = null;
    for (let i = 0; i < 4; i++) {
      const { data, error } = await writer
        .from("ride_groups")
        .insert({
          host_user_id: user.id,
          saved_route_id: savedRouteId.slice(0, 200),
          catalog_tour_id: body.catalogTourId
            ? String(body.catalogTourId).slice(0, 200)
            : null,
          title: title.slice(0, 120),
          start_window_start: window.start.toISOString(),
          start_window_end: window.end.toISOString(),
          join_code: generateJoinCode(),
          status: window.status,
          live_pins_allowed: true,
          visibility: parseGroupListing(body.visibility),
          meeting_point: meetingPoint,
        })
        .select(RIDE_GROUP_SELECT)
        .maybeSingle();
      if (!error && data) {
        inserted = data as RideGroupSqlRow;
        break;
      }
      lastError = error;
      if (error && isMissingRideGroupTable(error)) {
        return stub(501, "Server-Tabelle fehlt — nur lokal.");
      }
      if (error?.code !== "23505") {
        return NextResponse.json(
          { error: "insert_failed", note: error?.message, stub: true },
          { status: 501 }
        );
      }
    }
    if (!inserted) {
      return NextResponse.json(
        { error: "insert_failed", note: lastError?.message, stub: true },
        { status: 501 }
      );
    }

    const { data: profile } = await writer
      .from("public_profiles")
      .select("user_id, enabled, display_name, handle")
      .eq("user_id", user.id)
      .maybeSingle();
    const label = profileDisplayLabel(profile as PublicProfileLabelRow | null);

    const { error: memErr } = await writer.from("ride_group_members").insert({
      group_id: inserted.id,
      user_id: user.id,
      display_label: label,
      live_opt_in: false,
    });
    if (memErr && memErr.code !== "23505") {
      return NextResponse.json(
        { error: "member_insert_failed", note: memErr.message, stub: true },
        { status: 501 }
      );
    }

    const { members } = await memberBundle(writer, [String(inserted.id)]);
    return NextResponse.json({
      me: user.id,
      group: rowToRideGroup(inserted),
      members,
      stub: false,
    });
  } catch {
    return stub(501, "Cloud anlegen braucht Login + ride_groups.");
  }
}
