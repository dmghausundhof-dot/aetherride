import { NextResponse } from "next/server";
import { createSupabaseServerClient } from "@/lib/supabase/server";
import { isSupabaseConfigured } from "@/lib/supabase/config";
import { authUserFromSupabase } from "@/lib/auth/supabaseUser";
import { upsertProfileFromAuth } from "@/lib/auth/profileStore";

/**
 * OAuth / Magic-Link Callback — code → Session-Cookies + Profile-Upsert
 */
export async function GET(request: Request) {
  const { searchParams, origin } = new URL(request.url);
  const code = searchParams.get("code");
  const nextRaw = searchParams.get("next") ?? "/";
  const next = nextRaw.startsWith("/") ? nextRaw : "/";

  if (!isSupabaseConfigured()) {
    return NextResponse.redirect(`${origin}/login?error=supabase_missing`);
  }

  if (!code) {
    return NextResponse.redirect(`${origin}/login?error=auth_callback`);
  }

  try {
    const supabase = await createSupabaseServerClient();
    const { data, error } = await supabase.auth.exchangeCodeForSession(code);
    if (error || !data.user) {
      console.error("[auth/callback]", error?.message);
      return NextResponse.redirect(
        `${origin}/login?error=auth_callback&detail=${encodeURIComponent(error?.message ?? "exchange")}`
      );
    }

    const mapped = authUserFromSupabase(data.user);
    await upsertProfileFromAuth({
      id: mapped.id,
      email: mapped.email,
      displayName: mapped.displayName,
    });

    // Client-Hydrator lädt Session; optional Zwischenseite
    const complete = `/auth/complete?next=${encodeURIComponent(next)}`;
    return NextResponse.redirect(`${origin}${complete}`);
  } catch (e) {
    console.error("[auth/callback]", e);
    return NextResponse.redirect(`${origin}/login?error=auth_callback`);
  }
}
