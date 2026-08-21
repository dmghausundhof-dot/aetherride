import { NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";

export async function POST(req: Request) {
  try {
    const supabase = await createClient();
    const body = await req.json();
    const email = String(body.email || "").trim();
    if (!email) {
      return NextResponse.json(
        { error: "E-Mail erforderlich" },
        { status: 400 },
      );
    }

    const origin = new URL(req.url).origin;
    const { error } = await supabase.auth.resetPasswordForEmail(email, {
      redirectTo: `${origin}/anmelden`,
    });
    if (error) {
      return NextResponse.json({ error: error.message }, { status: 400 });
    }
    return NextResponse.json({ ok: true });
  } catch (e) {
    return NextResponse.json(
      { error: e instanceof Error ? e.message : "reset failed" },
      { status: 500 },
    );
  }
}
