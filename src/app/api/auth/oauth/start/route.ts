import { NextResponse } from "next/server";
import { getAuthBackend, isSupabaseConfigured } from "@/lib/supabase/config";
import {
  getOAuthCallbackUrl,
  isOAuthFeatureEnabled,
  listOAuthProvidersPrep,
  oauthPrepSummaryDe,
} from "@/lib/auth/oauthPrep";

/**
 * OAuth starten (Google/Apple) — nur wenn Feature-Flag + Supabase.
 * Default: 503 mit Vorbereitungshinweis.
 */
export async function POST(req: Request) {
  if (!isSupabaseConfigured()) {
    return NextResponse.json(
      {
        error: "Supabase nicht konfiguriert.",
        code: "SUPABASE_MISSING",
      },
      { status: 503 }
    );
  }
  if (!isOAuthFeatureEnabled()) {
    return NextResponse.json(
      {
        error: oauthPrepSummaryDe(),
        code: "OAUTH_DEFERRED",
        providers: listOAuthProvidersPrep(),
        callbackUrl: getOAuthCallbackUrl(),
      },
      { status: 503 }
    );
  }

  const body = (await req.json().catch(() => ({}))) as {
    provider?: string;
    next?: string;
  };
  const provider = body.provider === "apple" ? "apple" : "google";
  const prep = listOAuthProvidersPrep().find((p) => p.id === provider);
  if (!prep?.enabled) {
    return NextResponse.json(
      { error: prep?.blockedReasonDe ?? "Provider nicht bereit", code: "OAUTH_BLOCKED" },
      { status: 503 }
    );
  }

  const { createSupabaseServerClient } = await import("@/lib/supabase/server");
  const supabase = await createSupabaseServerClient();
  const next = body.next?.startsWith("/") ? body.next : "/";
  const redirectTo = `${getOAuthCallbackUrl()}?next=${encodeURIComponent(next)}`;

  const { data, error } = await supabase.auth.signInWithOAuth({
    provider,
    options: { redirectTo },
  });
  if (error || !data.url) {
    return NextResponse.json(
      { error: error?.message ?? "OAuth-Start fehlgeschlagen" },
      { status: 400 }
    );
  }
  return NextResponse.json({
    url: data.url,
    provider,
    authBackend: getAuthBackend(),
  });
}
