/**
 * OAuth Google / Apple (Supabase Auth) — Roadmap 9 Final
 *
 * Aktivierung:
 * 1) Supabase Dashboard → Authentication → Providers → Google/Apple
 * 2) Redirect URL: {NEXT_PUBLIC_SITE_URL}/auth/callback
 * 3) NEXT_PUBLIC_OAUTH_ENABLED=true
 * 4) Optional pro Provider: NEXT_PUBLIC_OAUTH_GOOGLE=true / APPLE=true (Default: an wenn Master-Flag)
 *
 * Secrets liegen im Supabase Dashboard, nicht zwingend in .env.
 */

import { isSupabaseConfigured } from "@/lib/supabase/config";

export type OAuthProviderId = "google" | "apple";

export interface OAuthProviderStatus {
  id: OAuthProviderId;
  titleDe: string;
  supabaseProvider: "google" | "apple";
  envHints: string[];
  enabled: boolean;
  blockedReasonDe: string | null;
}

function siteUrl(): string | null {
  return (
    process.env.NEXT_PUBLIC_SITE_URL?.trim() ||
    process.env.SITE_URL?.trim() ||
    null
  );
}

export function isOAuthFeatureEnabled(): boolean {
  return process.env.NEXT_PUBLIC_OAUTH_ENABLED === "true";
}

function providerFlag(id: OAuthProviderId): boolean {
  const key =
    id === "google"
      ? process.env.NEXT_PUBLIC_OAUTH_GOOGLE
      : process.env.NEXT_PUBLIC_OAUTH_APPLE;
  if (key === "false") return false;
  if (key === "true") return true;
  // Default: beide an, wenn Master-Flag an
  return true;
}

export function getOAuthCallbackUrl(): string {
  const base = siteUrl() || "http://localhost:3000";
  return `${base.replace(/\/$/, "")}/auth/callback`;
}

export function listOAuthProvidersPrep(): OAuthProviderStatus[] {
  const feature = isOAuthFeatureEnabled();
  const supabase = isSupabaseConfigured();
  const hasSite = Boolean(siteUrl());

  const commonBlock = !feature
    ? "NEXT_PUBLIC_OAUTH_ENABLED=true setzen + Provider im Supabase-Dashboard"
    : !supabase
      ? "Supabase-Env fehlt (URL + Anon-Key)"
      : !hasSite
        ? "NEXT_PUBLIC_SITE_URL fehlt (Redirect-URL)"
        : null;

  return (["google", "apple"] as const).map((id) => {
    const providerOn = providerFlag(id);
    const blocked =
      commonBlock ??
      (!providerOn
        ? `NEXT_PUBLIC_OAUTH_${id.toUpperCase()}=false — Provider aus`
        : null);
    return {
      id,
      titleDe: id === "google" ? "Mit Google fortfahren" : "Mit Apple fortfahren",
      supabaseProvider: id,
      envHints: [
        `Supabase Dashboard → ${id === "google" ? "Google" : "Apple"} Provider`,
        id === "google"
          ? "Google Cloud OAuth Client ID/Secret"
          : "Apple Services ID + Key",
        `Redirect: ${getOAuthCallbackUrl()}`,
      ],
      enabled: !blocked,
      blockedReasonDe: blocked,
    };
  });
}

export function isOAuthReady(provider: OAuthProviderId): boolean {
  return listOAuthProvidersPrep().some((p) => p.id === provider && p.enabled);
}

export function anyOAuthReady(): boolean {
  return listOAuthProvidersPrep().some((p) => p.enabled);
}

export function oauthPrepSummaryDe(): string {
  const list = listOAuthProvidersPrep();
  const ready = list.filter((p) => p.enabled).map((p) => p.id);
  if (ready.length === list.length) {
    return "OAuth Google/Apple bereit (Flag + Supabase + Site-URL).";
  }
  if (ready.length > 0) {
    return `OAuth teilweise bereit: ${ready.join(", ")}.`;
  }
  return `OAuth nicht aktiv (${list[0]?.blockedReasonDe ?? "Konfiguration fehlt"}).`;
}

export function getOAuthPublicStatus() {
  return {
    featureEnabled: isOAuthFeatureEnabled(),
    supabaseConfigured: isSupabaseConfigured(),
    siteUrl: siteUrl(),
    callbackUrl: getOAuthCallbackUrl(),
    anyReady: anyOAuthReady(),
    providers: listOAuthProvidersPrep(),
    summaryDe: oauthPrepSummaryDe(),
    setupStepsDe: [
      "Supabase: Google/Apple Provider einschalten",
      `Redirect-URL eintragen: ${getOAuthCallbackUrl()}`,
      "NEXT_PUBLIC_SUPABASE_URL + NEXT_PUBLIC_SUPABASE_ANON_KEY",
      "NEXT_PUBLIC_SITE_URL setzen",
      "NEXT_PUBLIC_OAUTH_ENABLED=true",
    ],
  };
}

export function renderOAuthSetupMarkdown(): string {
  const s = getOAuthPublicStatus();
  return [
    "# AetherRide — OAuth Google/Apple Setup",
    "",
    `Status: ${s.summaryDe}`,
    "",
    "## Schritte",
    ...s.setupStepsDe.map((x, i) => `${i + 1}. ${x}`),
    "",
    "## Provider",
    ...s.providers.flatMap((p) => [
      `### ${p.titleDe}`,
      `- enabled: ${p.enabled}`,
      `- blocked: ${p.blockedReasonDe ?? "—"}`,
      ...p.envHints.map((h) => `- ${h}`),
      "",
    ]),
    "## Hinweis",
    "Client-Secrets gehören ins Supabase Dashboard. Kein Fake-Login ohne Provider.",
    "",
  ].join("\n");
}
