/**
 * Gast verlässt die Gruppe. Kein client DELETE auf members — service role.
 * Host muss /close nutzen.
 */
import { NextResponse } from "next/server";
import { createAuthedClient } from "@/lib/supabase/authed";
import { createAdminClient } from "@/lib/supabase/admin";
import { isMissingRideGroupTable } from "@/lib/community/rideGroupServer";

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
    const body = (await req.json()) as { id?: string };
    const id = String(body.id || "").trim();
    if (!id) {
      return NextResponse.json({ error: "invalid_body" }, { status: 400 });
    }

    let admin;
    try {
      admin = createAdminClient();
    } catch {
      return NextResponse.json(
        {
          error: "not_implemented",
          stub: true,
          note: "Service-Role fehlt — Verlassen bleibt lokal.",
        },
        { status: 501 }
      );
    }

    const { data: group, error: gErr } = await admin
      .from("ride_groups")
      .select("id, host_user_id, status")
      .eq("id", id)
      .maybeSingle();
    if (gErr) {
      if (isMissingRideGroupTable(gErr)) {
        return NextResponse.json(
          { error: "not_implemented", stub: true, note: "Server-Tabelle fehlt." },
          { status: 501 }
        );
      }
      return NextResponse.json(
        { error: "query_failed", note: gErr.message },
        { status: 501 }
      );
    }
    if (!group) {
      return NextResponse.json({ error: "unknown" }, { status: 404 });
    }
    if (String(group.host_user_id) === user.id) {
      return NextResponse.json(
        { error: "host_must_close", note: "Host löst auf, Gast verlässt." },
        { status: 400 }
      );
    }

    const { error } = await admin
      .from("ride_group_members")
      .delete()
      .eq("group_id", id)
      .eq("user_id", user.id);
    if (error) {
      return NextResponse.json(
        { error: "delete_failed", note: error.message },
        { status: 501 }
      );
    }
    return NextResponse.json({ ok: true, id, stub: false });
  } catch {
    return NextResponse.json({ error: "unauthorized" }, { status: 401 });
  }
}
