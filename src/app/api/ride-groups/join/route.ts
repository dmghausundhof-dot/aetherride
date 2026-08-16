/**
 * Join per Einladungslink (Token) oder — nur öffentlich — per Listen-Id.
 * Code allein reicht bei privaten Gruppen nicht mehr.
 * Alte Links ?group=CODE&g=token bleiben gültig.
 */
import { NextResponse } from "next/server";
import { createAuthedClient } from "@/lib/supabase/authed";
import { createAdminClient } from "@/lib/supabase/admin";
import { decodeGroupInvite } from "@/lib/community/rideGroupInvite";
import {
  canJoinRideGroup,
  canJoinWithoutInviteToken,
  formatGroupWhen,
  parseGroupListing,
} from "@/lib/community/rideGroup";
import {
  isMissingRideGroupTable,
  isRideGroupId,
  labelsByUserId,
  profileDisplayLabel,
  rowToMember,
  rowToRideGroup,
  RIDE_GROUP_SELECT,
  type PublicProfileLabelRow,
  type RideGroupSqlRow,
} from "@/lib/community/rideGroupServer";
import { RIDE_GROUP_JOIN_CODE_LEN } from "@/lib/community/rideGroup";

export const dynamic = "force-dynamic";

function stub(note: string) {
  return NextResponse.json(
    { error: "not_implemented", stub: true, note },
    { status: 501 }
  );
}

export async function POST(req: Request) {
  try {
    const supabase = await createAuthedClient(req);
    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (!user) {
      return NextResponse.json({ error: "unauthorized" }, { status: 401 });
    }

    const body = (await req.json()) as {
      code?: string;
      token?: string;
      groupId?: string;
    };
    const token = String(body.token || "").trim();
    const rawId = String(body.groupId || "").trim();
    const rawCode = String(body.code || "")
      .trim()
      .toUpperCase();
    const groupId = isRideGroupId(rawId)
      ? rawId
      : isRideGroupId(rawCode)
        ? rawCode
        : "";
    const shortCode =
      rawCode.length === RIDE_GROUP_JOIN_CODE_LEN && !isRideGroupId(rawCode)
        ? rawCode
        : "";

    let payload: ReturnType<typeof decodeGroupInvite> = null;
    if (token) {
      payload = decodeGroupInvite(token);
      if (!payload) {
        return NextResponse.json({ error: "invalid_token" }, { status: 400 });
      }
    }

    if (!token && !groupId && !shortCode) {
      return NextResponse.json(
        {
          error: "need_link",
          note: "Beitritt nur über den Einladungslink.",
        },
        { status: 400 }
      );
    }

    let admin;
    try {
      admin = createAdminClient();
    } catch {
      return stub("Service-Role fehlt — Join bleibt lokal.");
    }

    let row: RideGroupSqlRow | null = null;
    const lookupId = payload?.id && isRideGroupId(payload.id) ? payload.id : groupId;
    if (lookupId) {
      const { data, error } = await admin
        .from("ride_groups")
        .select(RIDE_GROUP_SELECT)
        .eq("id", lookupId)
        .neq("status", "closed")
        .maybeSingle();
      if (error) {
        if (isMissingRideGroupTable(error)) {
          return stub("Server-Tabelle fehlt — nur lokal.");
        }
        return NextResponse.json(
          { error: "query_failed", note: error.message },
          { status: 501 }
        );
      }
      row = (data as RideGroupSqlRow) ?? null;
    }
    const codeForLookup = payload?.code || shortCode;
    if (!row && codeForLookup) {
      const { data, error } = await admin
        .from("ride_groups")
        .select(RIDE_GROUP_SELECT)
        .eq("join_code", codeForLookup)
        .neq("status", "closed")
        .maybeSingle();
      if (error) {
        if (isMissingRideGroupTable(error)) {
          return stub("Server-Tabelle fehlt — nur lokal.");
        }
        return NextResponse.json(
          { error: "query_failed", note: error.message },
          { status: 501 }
        );
      }
      row = (data as RideGroupSqlRow) ?? null;
    }

    if (!row) {
      return NextResponse.json(
        {
          error: "unknown",
          note: "Kein offener Link auf dem Server. Privat braucht den Einladungslink.",
        },
        { status: 404 }
      );
    }

    if (payload) {
      const matchesId = payload.id && String(row.id) === payload.id;
      const matchesCode =
        payload.code && String(row.join_code).toUpperCase() === payload.code;
      if (!matchesId && !matchesCode) {
        return NextResponse.json({ error: "invalid_token" }, { status: 400 });
      }
    }

    const listing = parseGroupListing(row.visibility);
    if (!token && !canJoinWithoutInviteToken(listing)) {
      return NextResponse.json(
        {
          error: "need_link",
          note: "Privat — nur mit Einladungslink. Kein Code zum Abtippen.",
        },
        { status: 403 }
      );
    }

    const group = rowToRideGroup(row);
    if (group.status === "closed") {
      return NextResponse.json({ error: "closed" }, { status: 409 });
    }
    if (
      !canJoinRideGroup(
        new Date().toISOString(),
        group.startWindowEnd,
        group.status
      )
    ) {
      return NextResponse.json(
        {
          error: "expired",
          note: (() => {
            const when = formatGroupWhen(
              group.startWindowStart,
              group.startWindowEnd
            );
            return when.startsWith("zu")
              ? `Fenster ${when}.`
              : `Fenster zu — ${when}.`;
          })(),
        },
        { status: 410 }
      );
    }

    const { data: existing } = await admin
      .from("ride_group_members")
      .select("group_id, user_id, display_label, joined_at, live_opt_in")
      .eq("group_id", group.id)
      .eq("user_id", user.id)
      .maybeSingle();

    if (!existing) {
      const { data: profile } = await admin
        .from("public_profiles")
        .select("user_id, enabled, display_name, handle")
        .eq("user_id", user.id)
        .maybeSingle();
      const { error: insErr } = await admin.from("ride_group_members").insert({
        group_id: group.id,
        user_id: user.id,
        display_label: profileDisplayLabel(
          profile as PublicProfileLabelRow | null
        ),
        live_opt_in: false,
      });
      if (insErr && insErr.code !== "23505") {
        return NextResponse.json(
          { error: "member_insert_failed", note: insErr.message, stub: true },
          { status: 501 }
        );
      }
    }

    const { data: memRows, error: memErr } = await admin
      .from("ride_group_members")
      .select("group_id, user_id, display_label, joined_at, live_opt_in")
      .eq("group_id", group.id);
    if (memErr) {
      return NextResponse.json(
        { error: "query_failed", note: memErr.message },
        { status: 501 }
      );
    }
    const userIds = [
      ...new Set(
        (memRows ?? []).map((r) => String((r as RideGroupSqlRow).user_id))
      ),
    ];
    const { data: profiles } = userIds.length
      ? await admin
          .from("public_profiles")
          .select("user_id, enabled, display_name, handle")
          .in("user_id", userIds)
      : { data: [] as PublicProfileLabelRow[] };
    const labels = labelsByUserId(profiles as PublicProfileLabelRow[]);
    const members = (memRows ?? []).map((r) => {
      const mem = r as RideGroupSqlRow;
      return rowToMember(mem, labels.get(String(mem.user_id)) ?? "");
    });

    return NextResponse.json({
      me: user.id,
      group,
      members,
      already: Boolean(existing),
      stub: false,
    });
  } catch {
    return stub("Join auf dem Server braucht Login + ride_groups.");
  }
}
