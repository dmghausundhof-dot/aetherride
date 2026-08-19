/**
 * Host setzt Sichtbarkeit: private | public.
 */
import { NextResponse } from "next/server";
import { createAuthedClient } from "@/lib/supabase/authed";
import { createAdminClient } from "@/lib/supabase/admin";
import { parseGroupListing } from "@/lib/community/rideGroup";
import { isSessionRouteId } from "@/lib/community/rideTogether";
import {
  isMissingRideGroupTable,
  isRideGroupId,
  rowToRideGroup,
  RIDE_GROUP_SELECT,
  type RideGroupSqlRow,
} from "@/lib/community/rideGroupServer";

export const dynamic = "force-dynamic";

export async function POST(req: Request) {
  try {
    const supabase = await createAuthedClient(req);
    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (!user) {
      return NextResponse.json({ error: "unauthorized" }, { status: 401 });
    }
    const body = (await req.json()) as { id?: string; visibility?: string };
    const id = String(body.id || "").trim();
    if (!isRideGroupId(id)) {
      return NextResponse.json({ error: "invalid_body" }, { status: 400 });
    }
    const visibility = parseGroupListing(body.visibility);

    let admin;
    try {
      admin = createAdminClient();
    } catch {
      return NextResponse.json(
        { error: "not_implemented", stub: true, note: "Service-Role fehlt." },
        { status: 501 }
      );
    }

    const { data: existing } = await admin
      .from("ride_groups")
      .select("saved_route_id")
      .eq("id", id)
      .maybeSingle();
    if (existing && isSessionRouteId(String(existing.saved_route_id))) {
      return NextResponse.json(
        {
          error: "session_private",
          note: "Freeride-Session bleibt geschlossen.",
        },
        { status: 400 }
      );
    }

    const { data, error } = await admin
      .from("ride_groups")
      .update({ visibility })
      .eq("id", id)
      .eq("host_user_id", user.id)
      .neq("status", "closed")
      .neq("saved_route_id", "freeride")
      .select(RIDE_GROUP_SELECT)
      .maybeSingle();
    if (error) {
      if (isMissingRideGroupTable(error)) {
        return NextResponse.json(
          { error: "not_implemented", stub: true, note: "Server-Tabelle fehlt." },
          { status: 501 }
        );
      }
      return NextResponse.json(
        { error: "update_failed", note: error.message },
        { status: 501 }
      );
    }
    if (!data) {
      return NextResponse.json({ error: "forbidden" }, { status: 403 });
    }
    return NextResponse.json({
      me: user.id,
      group: rowToRideGroup(data as RideGroupSqlRow),
      stub: false,
    });
  } catch {
    return NextResponse.json({ error: "unauthorized" }, { status: 401 });
  }
}
