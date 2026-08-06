/**
 * Auth-User-Mapping aus Supabase User
 */

import type { User } from "@supabase/supabase-js";
import type { AuthProvider, AuthUser } from "./session";

export function authUserFromSupabase(user: User): AuthUser {
  const meta = user.user_metadata ?? {};
  const providerRaw =
    (user.app_metadata?.provider as string | undefined) ||
    user.identities?.[0]?.provider ||
    "email";

  let provider: AuthProvider = "email";
  if (providerRaw === "google") provider = "google";
  else if (providerRaw === "apple") provider = "apple";
  else if (providerRaw === "email") provider = "email";

  const displayName =
    (typeof meta.display_name === "string" && meta.display_name) ||
    (typeof meta.full_name === "string" && meta.full_name) ||
    (typeof meta.name === "string" && meta.name) ||
    user.email?.split("@")[0] ||
    "Fahrer";

  return {
    id: user.id,
    email: user.email ?? null,
    displayName,
    provider,
    createdAt: user.created_at ?? new Date().toISOString(),
  };
}
