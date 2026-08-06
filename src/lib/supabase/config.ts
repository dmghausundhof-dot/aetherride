/**
 * Supabase-Konfiguration (E-Mail/Passwort jetzt, OAuth später)
 */

export function getSupabaseUrl(): string | null {
  const url =
    process.env.NEXT_PUBLIC_SUPABASE_URL?.trim() ||
    process.env.SUPABASE_URL?.trim();
  return url || null;
}

export function getSupabaseAnonKey(): string | null {
  const key =
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY?.trim() ||
    process.env.SUPABASE_ANON_KEY?.trim();
  return key || null;
}

/** Service Role nur Server — optional für Admin-Ops */
export function getSupabaseServiceRoleKey(): string | null {
  return process.env.SUPABASE_SERVICE_ROLE_KEY?.trim() || null;
}

export function isSupabaseConfigured(): boolean {
  return Boolean(getSupabaseUrl() && getSupabaseAnonKey());
}

export type AuthBackend = "supabase" | "local_file";

export function getAuthBackend(): AuthBackend {
  return isSupabaseConfigured() ? "supabase" : "local_file";
}

export function authBackendLabelDe(backend: AuthBackend = getAuthBackend()): string {
  return backend === "supabase"
    ? "Supabase Auth (E-Mail/Passwort)"
    : "Lokaler File-Store (Fallback — Supabase-Env fehlt)";
}
