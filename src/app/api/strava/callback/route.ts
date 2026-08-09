import { cookies } from "next/headers";
import { NextResponse } from "next/server";
import { verifyStravaOAuthState } from "@/lib/strava/oauthState";
import { stravaAdminClient } from "@/lib/strava/tokens";

/**
 * Strava OAuth callback: code → token, CSRF/state, store by user_id when signed.
 */
export async function GET(req: Request) {
  const clientId = process.env.STRAVA_CLIENT_ID?.trim();
  const clientSecret = process.env.STRAVA_CLIENT_SECRET?.trim();
  const url = new URL(req.url);
  const origin =
    process.env.NEXT_PUBLIC_APP_URL?.replace(/\/$/, "") ||
    `${url.protocol}//${url.host}`;

  const finish = (query: string, mobile: boolean) => {
    if (mobile) {
      return NextResponse.redirect(
        `io.aetherride.app://strava-callback?${query}`
      );
    }
    return NextResponse.redirect(`${origin}/privacy?${query}`);
  };

  if (!clientId || !clientSecret) {
    return finish("strava=not_configured", false);
  }

  const code = url.searchParams.get("code");
  const state = url.searchParams.get("state");
  const error = url.searchParams.get("error");

  const signed = state ? verifyStravaOAuthState(state) : null;
  const mobile = signed?.mobile === true;

  if (error) {
    return finish(
      `strava=error&reason=${encodeURIComponent(error)}`,
      mobile
    );
  }

  if (!code) {
    return finish("strava=missing_code", mobile);
  }

  const jar = await cookies();
  const expected = jar.get("strava_oauth_state")?.value;
  const cookieOk = Boolean(expected && state && expected === state);
  const stateOk = Boolean(signed) || cookieOk;
  if (!stateOk) {
    return finish("strava=csrf", mobile);
  }

  const tokenRes = await fetch("https://www.strava.com/oauth/token", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      client_id: clientId,
      client_secret: clientSecret,
      code,
      grant_type: "authorization_code",
    }),
  });

  if (!tokenRes.ok) {
    return finish("strava=token_failed", mobile);
  }

  const token = (await tokenRes.json()) as {
    access_token?: string;
    refresh_token?: string;
    expires_at?: number;
    athlete?: { id?: number };
  };

  if (!token.access_token) {
    return finish("strava=token_failed", mobile);
  }

  const userId = signed?.userId;
  const athleteId = token.athlete?.id;
  const sb = stravaAdminClient();

  if (sb && userId) {
    try {
      await sb.from("strava_connections").upsert(
        {
          user_id: userId,
          athlete_id: athleteId ?? null,
          access_token: token.access_token,
          refresh_token: token.refresh_token ?? null,
          expires_at: token.expires_at
            ? new Date(token.expires_at * 1000).toISOString()
            : null,
          updated_at: new Date().toISOString(),
        },
        { onConflict: "user_id" }
      );
    } catch {
      // Token ok — UI shows connected via cookie/deep-link
    }
  }

  const res = finish("strava=connected", mobile);
  res.cookies.set("strava_connected", "1", {
    httpOnly: false,
    sameSite: "lax",
    path: "/",
    maxAge: 60 * 60 * 24 * 30,
  });
  res.cookies.delete("strava_oauth_state");
  return res;
}
