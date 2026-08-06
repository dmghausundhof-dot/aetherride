/**
 * Client-Auth gegen Server-API (F-ACC-001)
 * Backend: Supabase (wenn Env gesetzt) oder lokaler File-Fallback.
 */

import type { AuthSession, AuthUser } from "./session";

export interface ServerAuthResponse {
  user: AuthUser | null;
  syncEnabled: boolean;
  authSecretHardened?: boolean;
  authBackend?: "supabase" | "local_file";
  authBackendLabel?: string;
  pendingEmailConfirmation?: boolean;
  oauthPrep?: string;
  note?: string;
  error?: string;
}

async function parseJson(res: Response): Promise<ServerAuthResponse> {
  const data = (await res.json()) as ServerAuthResponse & { error?: string };
  if (!res.ok) {
    return {
      user: null,
      syncEnabled: false,
      error: data.error || `HTTP ${res.status}`,
      authBackend: data.authBackend,
      note: data.note,
    };
  }
  return data;
}

export async function registerWithServer(input: {
  email: string;
  password: string;
  displayName?: string;
}): Promise<ServerAuthResponse> {
  const res = await fetch("/api/auth/register", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(input),
    credentials: "same-origin",
  });
  return parseJson(res);
}

export async function loginWithServer(input: {
  email: string;
  password: string;
}): Promise<ServerAuthResponse> {
  const res = await fetch("/api/auth/login", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(input),
    credentials: "same-origin",
  });
  return parseJson(res);
}

export async function logoutFromServer(): Promise<void> {
  await fetch("/api/auth/logout", {
    method: "POST",
    credentials: "same-origin",
  });
}

export async function fetchServerSession(): Promise<
  AuthSession & {
    authSecretHardened?: boolean;
    authBackend?: "supabase" | "local_file";
    oauthPrep?: string;
    error?: string;
  }
> {
  const res = await fetch("/api/auth/me", {
    credentials: "same-origin",
    cache: "no-store",
  });
  const data = await parseJson(res);
  return {
    user: data.user,
    syncEnabled: !!data.user && data.syncEnabled,
    authSecretHardened: data.authSecretHardened,
    authBackend: data.authBackend,
    oauthPrep: data.oauthPrep,
    error: data.error,
  };
}

/** OAuth-Start — erwartet 503 solange Flag aus */
export async function startOAuth(
  provider: "google" | "apple",
  next = "/"
): Promise<{ url?: string; error?: string; code?: string }> {
  const res = await fetch("/api/auth/oauth/start", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    credentials: "same-origin",
    body: JSON.stringify({ provider, next }),
  });
  const data = (await res.json()) as {
    url?: string;
    error?: string;
    code?: string;
  };
  if (!res.ok) {
    return { error: data.error || `HTTP ${res.status}`, code: data.code };
  }
  return data;
}

export function toAuthSession(r: ServerAuthResponse): AuthSession {
  return {
    user: r.user,
    syncEnabled: !!r.user && r.syncEnabled,
  };
}
