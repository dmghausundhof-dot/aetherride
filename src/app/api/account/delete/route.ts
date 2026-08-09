import { NextResponse } from "next/server";
import { createClient } from "@supabase/supabase-js";
import { createAuthedClient } from "@/lib/supabase/authed";

function adminClient() {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const key = process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (!url || !key) return null;
  return createClient(url, key, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
}

/**
 * POST /api/account/delete
 * Auth: Cookie oder Bearer. Löscht Auth-User (+ Cascade Profile falls FK).
 * Body optional: { confirm: "DELETE" }
 */
export async function POST(req: Request) {
  try {
    const supabase = await createAuthedClient(req);
    const {
      data: { user },
      error: userErr,
    } = await supabase.auth.getUser();
    if (userErr || !user) {
      return NextResponse.json({ error: "unauthorized" }, { status: 401 });
    }

    let confirm = "";
    try {
      const body = (await req.json()) as { confirm?: string };
      confirm = (body.confirm || "").trim();
    } catch {
      /* empty body ok if session present */
    }
    if (confirm && confirm !== "DELETE") {
      return NextResponse.json(
        { error: 'confirm must be "DELETE"' },
        { status: 400 }
      );
    }

    const admin = adminClient();
    if (!admin) {
      return NextResponse.json(
        {
          error:
            "account_delete_unavailable",
          message:
            "SUPABASE_SERVICE_ROLE_KEY fehlt — Remote-Löschung nicht möglich.",
        },
        { status: 503 }
      );
    }

    // Best-effort: Sync-/Profil-Daten vor Auth-Delete entfernen
    await admin.from("sync_snapshots").delete().eq("user_id", user.id);
    await admin.from("profiles").delete().eq("id", user.id);

    const { error: delErr } = await admin.auth.admin.deleteUser(user.id);
    if (delErr) {
      return NextResponse.json(
        { error: delErr.message },
        { status: 500 }
      );
    }

    return NextResponse.json({ ok: true, deletedUserId: user.id });
  } catch (e) {
    return NextResponse.json(
      { error: e instanceof Error ? e.message : "delete failed" },
      { status: 500 }
    );
  }
}
