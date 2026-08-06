/**
 * OAuth Google/Apple — Unit-Tests
 * Ausführen: npx tsx src/lib/auth/oauthPrep.test.ts
 */
import {
  anyOAuthReady,
  getOAuthCallbackUrl,
  getOAuthPublicStatus,
  isOAuthFeatureEnabled,
  isOAuthReady,
  listOAuthProvidersPrep,
  oauthPrepSummaryDe,
  renderOAuthSetupMarkdown,
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
  assert(isSupabaseConfigured() === false, "no supabase in test env");
  assert(getAuthBackend() === "local_file", "fallback backend");
  assert(authBackendLabelDe().includes("Fallback"), "label");

  assert(isOAuthFeatureEnabled() === false, "oauth flag default off");
  assert(!isOAuthReady("google"), "google not ready");
  assert(!isOAuthReady("apple"), "apple not ready");
  assert(!anyOAuthReady(), "none ready");

  const providers = listOAuthProvidersPrep();
  assert(providers.length === 2, "two providers");
  assert(providers.every((p) => !p.enabled), "both disabled");
  assert(getOAuthCallbackUrl().includes("/auth/callback"), "callback path");

  const status = getOAuthPublicStatus();
  assert(status.setupStepsDe.length >= 4, "setup steps");
  assert(status.featureEnabled === false, "status flag");
  assert(oauthPrepSummaryDe().length > 10, "summary");

  const md = renderOAuthSetupMarkdown();
  assert(md.includes("Google"), "md google");
  assert(md.includes("Apple"), "md apple");
  assert(md.includes("NEXT_PUBLIC_OAUTH_ENABLED"), "md flag");

  console.log("oauthPrep.test OK", {
    backend: getAuthBackend(),
    summary: oauthPrepSummaryDe(),
  });
}

main();
