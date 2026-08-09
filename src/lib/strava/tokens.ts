import { createClient, type SupabaseClient } from "@supabase/supabase-js";

export type StravaConnectionRow = {
  user_id: string;
  athlete_id: number | null;
  access_token: string;
  refresh_token: string | null;
  expires_at: string | null;
};

export function stravaAdminClient(): SupabaseClient | null {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL?.trim();
  const key = process.env.SUPABASE_SERVICE_ROLE_KEY?.trim();
  if (!url || !key) return null;
  return createClient(url, key, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
}

export function stravaConfigured(): boolean {
  return Boolean(
    process.env.STRAVA_CLIENT_ID?.trim() &&
      process.env.STRAVA_CLIENT_SECRET?.trim()
  );
}

/** Refresh if expired; returns access_token or null. */
export async function getValidStravaAccessToken(
  userId: string
): Promise<string | null> {
  const sb = stravaAdminClient();
  if (!sb) return null;
  const { data, error } = await sb
    .from("strava_connections")
    .select("access_token, refresh_token, expires_at")
    .eq("user_id", userId)
    .maybeSingle();
  if (error || !data?.access_token) return null;

  const expiresAt = data.expires_at ? Date.parse(data.expires_at) : 0;
  const stillValid = !expiresAt || expiresAt > Date.now() + 60_000;
  if (stillValid) return data.access_token as string;

  const refresh = data.refresh_token as string | null;
  if (!refresh) return null;

  const clientId = process.env.STRAVA_CLIENT_ID!.trim();
  const clientSecret = process.env.STRAVA_CLIENT_SECRET!.trim();
  const tokenRes = await fetch("https://www.strava.com/oauth/token", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      client_id: clientId,
      client_secret: clientSecret,
      grant_type: "refresh_token",
      refresh_token: refresh,
    }),
  });
  if (!tokenRes.ok) return null;
  const token = (await tokenRes.json()) as {
    access_token?: string;
    refresh_token?: string;
    expires_at?: number;
  };
  if (!token.access_token) return null;

  await sb.from("strava_connections").upsert(
    {
      user_id: userId,
      access_token: token.access_token,
      refresh_token: token.refresh_token ?? refresh,
      expires_at: token.expires_at
        ? new Date(token.expires_at * 1000).toISOString()
        : null,
      updated_at: new Date().toISOString(),
    },
    { onConflict: "user_id" }
  );
  return token.access_token;
}
