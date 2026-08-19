/**
 * Session-Code — Ausnahme zur geplanten Gruppe (die braucht den Link).
 */
import { NextResponse } from "next/server";
import {
  RIDE_GROUP_JOIN_CODE_LEN,
  normalizeJoinCode,
} from "@/lib/community/rideGroup";
import { togetherAuthed, togetherStub } from "@/lib/community/rideTogetherRoute";
import {
  addSessionMember,
  expireStaleTogether,
  isSessionRouteId,
  leaveOtherSessions,
  memberBundle,
  resolveTogetherLabel,
  upsertMate,
} from "@/lib/community/rideTogetherServer";
import {
  isMissingRideGroupTable,
  rowToRideGroup,
  RIDE_GROUP_SELECT,
  type RideGroupSqlRow,
} from "@/lib/community/rideGroupServer";

export const dynamic = "force-dynamic";

export async function POST(req: Request) {
  try {
    const auth = await togetherAuthed(req);
    if ("error" in auth) return auth.error;
    const { user, admin } = auth;
    const body = (await req.json()) as { code?: string; label?: string };
    const code = normalizeJoinCode(body.code);
    if (code.length !== RIDE_GROUP_JOIN_CODE_LEN) {
      return NextResponse.json({ error: "invalid_body" }, { status: 400 });
    }

    await expireStaleTogether(admin);
    const { data: row, error } = await admin
      .from("ride_groups")
      .select(RIDE_GROUP_SELECT)
      .eq("join_code", code)
      .eq("saved_route_id", "freeride")
      .neq("status", "closed")
      .maybeSingle();
    if (error) {
      if (isMissingRideGroupTable(error)) {
        return togetherStub("Server-Tabelle fehlt.");
      }
      return NextResponse.json(
        { error: "query_failed", note: error.message },
        { status: 501 }
      );
    }
    if (!row || !isSessionRouteId(String(row.saved_route_id))) {
      return NextResponse.json(
        { error: "unknown", note: "Kein offener Zusammen-Code." },
        { status: 404 }
      );
    }
    const group = rowToRideGroup(row as RideGroupSqlRow);
    const { data: profile } = await admin
      .from("public_profiles")
      .select("user_id, enabled, display_name, handle")
      .eq("user_id", user.id)
      .maybeSingle();
    const label = resolveTogetherLabel(profile, body.label);
    let already = false;
    try {
      already = await addSessionMember(admin, group.id, user.id, label);
    } catch (err) {
      const e = err as { code?: string };
      if (e.code === "together_full") {
        return NextResponse.json(
          { error: "full", note: "Gruppe ist voll (20)." },
          { status: 409 }
        );
      }
      throw err;
    }
    if (!already) {
      await upsertMate(admin, group.hostUserId, user.id);
    }
    await admin.from("ride_together_looks").delete().eq("user_id", user.id);
    await leaveOtherSessions(admin, user.id, group.id);
    const members = await memberBundle(admin, group.id);
    return NextResponse.json({
      me: user.id,
      group,
      members,
      already,
      stub: false,
    });
  } catch {
    return togetherStub("Zusammen braucht Login.");
  }
}
