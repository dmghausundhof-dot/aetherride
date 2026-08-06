/**
 * OAuth-Vorbereitung (Google / Apple) — aktiv erst zum Schluss
 *
 * Supabase Dashboard:
 * 1. Authentication → Providers → Google / Apple einschalten
 * 2. Redirect URLs: {SITE_URL}/auth/callback
 * 3. Env: NEXT_PUBLIC_SITE_URL (+ Provider-Secrets im Dashboard)
 *
 * Code-Pfad existiert; UI bleibt disabled bis isOAuthReady().
 */

export type OAuthProviderId = "google" | "apple";

export interface OAuthProviderPrep {
  id: OAuthProviderId;
  titleDe: string;
  supabaseProvider: "google" | "apple";
  /** Env-Hinweis (Client-IDs liegen i. d. R. im Supabase Dashboard) */
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

/** Explizites Opt-in — erst setzen wenn Provider im Dashboard fertig sind */
export function isOAuthFeatureEnabled(): boolean {
  return process.env.NEXT_PUBLIC_OAUTH_ENABLED === "true";
}

export function getOAuthCallbackUrl(): string {
  const base = siteUrl() || "http://localhost:3000";
  return `${base.replace(/\/$/, "")}/auth/callback`;
}

export function listOAuthProvidersPrep(): OAuthProviderPrep[] {
  const feature = isOAuthFeatureEnabled();
  const hasSite = Boolean(siteUrl());
  const commonBlock = !feature
    ? "OAuth bewusst zum Schluss — NEXT_PUBLIC_OAUTH_ENABLED=true setzen"
    : !hasSite
      ? "NEXT_PUBLIC_SITE_URL fehlt (Redirect-URL)"
      : null;

  return [
    {
      id: "google",
      titleDe: "Mit Google fortfahren",
      supabaseProvider: "google",
      envHints: [
        "Supabase Dashboard → Google Provider",
        "Google Cloud OAuth Client ID/Secret",
        `Redirect: ${getOAuthCallbackUrl()}`,
      ],
      enabled: feature && hasSite,
      blockedReasonDe: commonBlock,
    },
    {
      id: "apple",
      titleDe: "Mit Apple fortfahren",
      supabaseProvider: "apple",
      envHints: [
        "Supabase Dashboard → Apple Provider",
        "Apple Services ID + Key",
        `Redirect: ${getOAuthCallbackUrl()}`,
      ],
      enabled: feature && hasSite,
      blockedReasonDe: commonBlock,
    },
  ];
}

export function isOAuthReady(provider: OAuthProviderId): boolean {
  return listOAuthProvidersPrep().some((p) => p.id === provider && p.enabled);
}

export function oauthPrepSummaryDe(): string {
  const list = listOAuthProvidersPrep();
  const ready = list.filter((p) => p.enabled).map((p) => p.id);
  if (ready.length === list.length) {
    return "OAuth Google/Apple bereit (Feature-Flag an).";
  }
  return `OAuth vorbereitet, noch deaktiviert (${list[0]?.blockedReasonDe ?? "Flag aus"}).`;
}
