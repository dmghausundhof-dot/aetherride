/**
 * Gegenseitiges Ja — erst dann Session-Mitglieder + Pins.
 */
import { NextResponse } from "next/server";
import { togetherAuthed, togetherStub } from "@/lib/community/rideTogetherRoute";
import {
  addSessionMember,
  expireStaleTogether,
  isMissingTogetherTable,
  isSessionRouteId,
  leaveOtherSessions,
  loadLabels,
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
    const body = (await req.json()) as {
      requestId?: string;
      accept?: boolean;
      label?: string;
    };
    const requestId = String(body.requestId || "").trim();
    if (!requestId) {
      return NextResponse.json({ error: "invalid_body" }, { status: 400 });
    }

    await expireStaleTogether(admin);
    const { data: row, error } = await admin
      .from("ride_together_requests")
      .select("id, from_user_id, to_user_id, group_id, status, expires_at")
      .eq("id", requestId)
      .maybeSingle();
    if (error) {
      if (isMissingTogetherTable(error)) {
        return togetherStub("Server-Tabelle fehlt — Zusammen nicht bereit.");
      }
      return NextResponse.json(
        { error: "query_failed", note: error.message },
        { status: 501 }
      );
    }
    if (!row || String(row.to_user_id) !== user.id) {
      return NextResponse.json({ error: "unknown" }, { status: 404 });
    }
    if (row.status !== "pending") {
      return NextResponse.json({ error: "closed" }, { status: 409 });
    }
    if (new Date(String(row.expires_at)).getTime() <= Date.now()) {
      await admin
        .from("ride_together_requests")
        .update({ status: "expired" })
        .eq("id", requestId);
      return NextResponse.json({ error: "expired" }, { status: 410 });
    }

    if (body.accept !== true) {
      await admin
        .from("ride_together_requests")
        .update({ status: "declined" })
        .eq("id", requestId);
      return NextResponse.json({
        me: user.id,
        declined: true,
        stub: false,
      });
    }

    const { data: groupRow, error: gErr } = await admin
      .from("ride_groups")
      .select(RIDE_GROUP_SELECT)
      .eq("id", row.group_id)
      .maybeSingle();
    if (gErr) {
      if (isMissingRideGroupTable(gErr)) {
        return togetherStub("Server-Tabelle fehlt.");
      }
      return NextResponse.json(
        { error: "query_failed", note: gErr.message },
        { status: 501 }
      );
    }
    if (!groupRow || !isSessionRouteId(String(groupRow.saved_route_id))) {
      return NextResponse.json({ error: "unknown" }, { status: 404 });
    }
    const group = rowToRideGroup(groupRow as RideGroupSqlRow);
    if (group.status === "closed") {
      return NextResponse.json({ error: "closed" }, { status: 409 });
    }

    const { data: profile } = await admin
      .from("public_profiles")
      .select("user_id, enabled, display_name, handle")
      .eq("user_id", user.id)
      .maybeSingle();
    const label = resolveTogetherLabel(profile, body.label);
    const fromId = String(row.from_user_id);
    const before = await memberBundle(admin, group.id);
    const beforeIds = new Set(before.map((m) => m.userId));
    const fromLabels = await loadLabels(admin, [fromId]);
    try {
      await addSessionMember(
        admin,
        group.id,
        fromId,
        fromLabels.get(fromId) || ""
      );
      await addSessionMember(admin, group.id, user.id, label);
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
    await upsertMate(admin, fromId, user.id);
    await admin
      .from("ride_together_requests")
      .update({ status: "accepted" })
      .eq("id", requestId);
    const joined = [fromId, user.id].filter((id) => !beforeIds.has(id));
    if (joined.length > 0) {
      await admin.from("ride_together_looks").delete().in("user_id", joined);
    }
    await leaveOtherSessions(admin, fromId, group.id);
    await leaveOtherSessions(admin, user.id, group.id);
    const members = await memberBundle(admin, group.id);
    return NextResponse.json({
      me: user.id,
      group,
      members,
      stub: false,
    });
  } catch {
    return togetherStub("Zusammen braucht Login.");
  }
}
