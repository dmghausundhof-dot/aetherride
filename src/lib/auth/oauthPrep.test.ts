/**
 * OAuth-Vorbereitung + Supabase-Config — Unit-Tests
 * Ausführen: npx tsx src/lib/auth/oauthPrep.test.ts
 */
import {
  getOAuthCallbackUrl,
  isOAuthFeatureEnabled,
  isOAuthReady,
  listOAuthProvidersPrep,
  oauthPrepSummaryDe,
} from "./oauthPrep";
import {
  authBackendLabelDe,
  getAuthBackend,
  isSupabaseConfigured,
} from "@/lib/supabase/config";

function assert(c: boolean, m: string) {
  if (!c) throw new Error(m);
}

function main() {
  // Ohne Env: kein Supabase, OAuth aus
  assert(isSupabaseConfigured() === false, "no supabase in test env");
  assert(getAuthBackend() === "local_file", "fallback backend");
  assert(authBackendLabelDe().includes("Fallback"), "label");

  assert(isOAuthFeatureEnabled() === false, "oauth flag default off");
  assert(!isOAuthReady("google"), "google not ready");
  assert(!isOAuthReady("apple"), "apple not ready");

  const providers = listOAuthProvidersPrep();
  assert(providers.length === 2, "two providers");
  assert(providers.every((p) => !p.enabled), "both disabled");
  assert(
    providers.every((p) => p.envHints.length >= 2),
    "hints present"
  );
  assert(getOAuthCallbackUrl().includes("/auth/callback"), "callback path");
  assert(oauthPrepSummaryDe().includes("deaktiviert"), "summary de");

  console.log("oauthPrep.test OK", {
    backend: getAuthBackend(),
    summary: oauthPrepSummaryDe(),
  });
}

main();
