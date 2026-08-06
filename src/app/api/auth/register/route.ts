import { NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";

export async function POST(req: Request) {
  try {
    const supabase = await createClient();
    const body = await req.json();
    const email = String(body.email || "").trim();
    const password = String(body.password || "");
    const displayName = String(body.displayName || "").trim();

    if (!email || password.length < 8) {
      return NextResponse.json(
        { error: "E-Mail und Passwort (min. 8 Zeichen) erforderlich" },
        { status: 400 }
      );
    }

    const { data, error } = await supabase.auth.signUp({
      email,
      password,
      options: {
        data: { display_name: displayName || undefined },
      },
    });

    if (error) {
      return NextResponse.json({ error: error.message }, { status: 400 });
    }

    return NextResponse.json({
      user: data.user ? { id: data.user.id, email: data.user.email } : null,
      session: data.session ? true : false,
      needsConfirmation: !data.session,
    });
  } catch (e) {
    return NextResponse.json(
      { error: e instanceof Error ? e.message : "register failed" },
      { status: 500 }
    );
  }
}
