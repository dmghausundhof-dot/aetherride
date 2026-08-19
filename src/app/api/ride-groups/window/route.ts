/**
 * Host verlängert das Event-Fenster (addHours 0,25–12 oder newEnd).
 * Deckel: jetzt+12 h. Abgelaufenes Fenster startet bei now.
 */
import { NextResponse } from "next/server";
import { createAuthedClient } from "@/lib/supabase/authed";
import { parseRideGroupExtend } from "@/lib/community/rideGroup";
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
    const body = (await req.json()) as {
      id?: string;
      addHours?: number;
      newEnd?: string;
    };
    const id = String(body.id || "").trim();
    if (!isRideGroupId(id)) {
      return NextResponse.json({ error: "invalid_body" }, { status: 400 });
    }
    const hasNewEnd = body.newEnd != null && String(body.newEnd).trim() !== "";

    const { data: row, error: loadErr } = await supabase
      .from("ride_groups")
      .select(RIDE_GROUP_SELECT)
      .eq("id", id)
      .eq("host_user_id", user.id)
      .maybeSingle();
    if (loadErr) {
      if (isMissingRideGroupTable(loadErr)) {
        return NextResponse.json(
          { error: "not_implemented", stub: true, note: "Server-Tabelle fehlt." },
          { status: 501 }
        );
      }
      return NextResponse.json(
        { error: "query_failed", note: loadErr.message },
        { status: 501 }
      );
    }
    if (!row) {
      return NextResponse.json({ error: "forbidden" }, { status: 403 });
    }
    const group = rowToRideGroup(row as RideGroupSqlRow);
    if (group.status === "closed") {
      return NextResponse.json({ error: "closed" }, { status: 409 });
    }
    const now = new Date();
    const resolved = parseRideGroupExtend({
      now,
      currentEnd: new Date(group.startWindowEnd),
      addHours: hasNewEnd ? undefined : (body.addHours ?? 1),
      newEnd: hasNewEnd ? body.newEnd : undefined,
    });
    if ("error" in resolved) {
      return NextResponse.json({ error: resolved.error }, { status: 400 });
    }
    const end = resolved.end;
    const { data, error } = await supabase
      .from("ride_groups")
      .update({ start_window_end: end.toISOString() })
      .eq("id", id)
      .eq("host_user_id", user.id)
      .select(RIDE_GROUP_SELECT)
      .maybeSingle();
    if (error || !data) {
      return NextResponse.json(
        { error: "update_failed", note: error?.message },
        { status: 501 }
      );
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
