/**
 * Ein Freeride endet: dieses Mitglied steigt aus.
 * Die anderen bleiben. Zu nur, wenn niemand übrig ist.
 */
import { NextResponse } from "next/server";
import { togetherAuthed, togetherStub } from "@/lib/community/rideTogetherRoute";
import { isSessionRouteId } from "@/lib/community/rideTogether";
import { leaveSession } from "@/lib/community/rideTogetherServer";
import { isMissingRideGroupTable } from "@/lib/community/rideGroupServer";

export const dynamic = "force-dynamic";

export async function POST(req: Request) {
  try {
    const auth = await togetherAuthed(req);
    if ("error" in auth) return auth.error;
    const { user, admin } = auth;
    const body = (await req.json()) as { groupId?: string };
    const groupId = String(body.groupId || "").trim();
    if (!groupId) {
      return NextResponse.json({ error: "invalid_body" }, { status: 400 });
    }

    const { data: group, error } = await admin
      .from("ride_groups")
      .select("id, saved_route_id, status")
      .eq("id", groupId)
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
    if (!group || !isSessionRouteId(String(group.saved_route_id))) {
      return NextResponse.json({ error: "unknown" }, { status: 404 });
    }

    const { data: member } = await admin
      .from("ride_group_members")
      .select("user_id")
      .eq("group_id", groupId)
      .eq("user_id", user.id)
      .maybeSingle();
    if (!member) {
      return NextResponse.json({ error: "forbidden" }, { status: 403 });
    }

    const out = await leaveSession(admin, groupId, user.id);
    return NextResponse.json({
      ok: true,
      id: groupId,
      closed: out.closed,
      remaining: out.remaining,
      stub: false,
    });
  } catch {
    return togetherStub("Zusammen braucht Login.");
  }
}
