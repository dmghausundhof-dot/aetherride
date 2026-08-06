import { NextResponse } from "next/server";
import { clearSessionCookie } from "@/lib/auth/serverSession";
import { getAuthBackend } from "@/lib/supabase/config";

export async function POST() {
  if (getAuthBackend() === "supabase") {
    try {
      const { createSupabaseServerClient } = await import(
        "@/lib/supabase/server"
      );
      const supabase = await createSupabaseServerClient();
      await supabase.auth.signOut();
    } catch (e) {
      console.error("[auth/logout] supabase", e);
    }
  }
  await clearSessionCookie();
  return NextResponse.json({
    ok: true,
    syncEnabled: false,
    authBackend: getAuthBackend(),
  });
}
