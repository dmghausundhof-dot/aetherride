/**
 * Host löst die Gruppe auf (RLS: nur host_user_id = auth.uid()).
 */
import { NextResponse } from "next/server";
import { createAuthedClient } from "@/lib/supabase/authed";
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
    const { data, error } = await supabase
      .from("ride_groups")
      .update({ status: "closed" })
      .eq("id", id)
      .eq("host_user_id", user.id)
      .select("id")
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
    return NextResponse.json({ ok: true, id, stub: false });
  } catch {
    return NextResponse.json({ error: "unauthorized" }, { status: 401 });
  }
}
