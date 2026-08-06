/**
 * Profile-Persistenz (Supabase profiles) — ergänzt auth.users
 */

import { isSupabaseConfigured } from "@/lib/supabase/config";

export async function upsertProfileFromAuth(input: {
  id: string;
  email?: string | null;
  displayName?: string | null;
}): Promise<{ ok: boolean; error?: string }> {
  if (!isSupabaseConfigured()) {
    return { ok: false, error: "supabase_missing" };
  }
  try {
    const { createSupabaseServerClient } = await import(
      "@/lib/supabase/server"
    );
    const supabase = await createSupabaseServerClient();
    const { error } = await supabase.from("profiles").upsert(
      {
        id: input.id,
        email: input.email ?? null,
        display_name: input.displayName?.trim() || "Fahrer",
        updated_at: new Date().toISOString(),
      },
      { onConflict: "id" }
    );
    if (error) return { ok: false, error: error.message };
    return { ok: true };
  } catch (e) {
    return {
      ok: false,
      error: e instanceof Error ? e.message : "profile_upsert_failed",
    };
  }
}
