/**
 * F-ACC-001 / 002 / 004 — Konto, lokale Nutzung, Kontolöschung
 *
 * Web-Demo: lokaler Mock (kein echter IdP).
 * Produktion: Apple/Google Sign-in + E-Mail, Backend-Session.
 */

export type AuthProvider = "email" | "apple" | "google" | "local_anonymous";

export interface AuthUser {
  id: string;
  email: string | null;
  displayName: string;
  provider: AuthProvider;
  createdAt: string;
}

export interface AuthSession {
  user: AuthUser | null;
  /** Sync erfordert Konto (F-ACC-002) */
  syncEnabled: boolean;
}

export interface AccountDeletionRequest {
  requestedAt: string;
  /** Wirkung ≤ 30 Tage (DSGVO Art. 17) */
  effectiveBy: string;
  confirmationEmailSent: boolean;
  status: "pending" | "confirmed" | "cancelled" | "completed";
}

const STORAGE_KEY = "aetherride.auth.v1";

export function loadSession(): AuthSession {
  if (typeof window === "undefined") {
    return { user: null, syncEnabled: false };
  }
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) return { user: null, syncEnabled: false };
    return JSON.parse(raw) as AuthSession;
  } catch {
    return { user: null, syncEnabled: false };
  }
}

function saveSession(s: AuthSession) {
  if (typeof window === "undefined") return;
  localStorage.setItem(STORAGE_KEY, JSON.stringify(s));
}

export function signInLocal(input: {
  provider: AuthProvider;
  email?: string;
  displayName?: string;
}): AuthSession {
  const user: AuthUser = {
    id: `usr_${Math.random().toString(36).slice(2, 10)}`,
    email: input.email ?? null,
    displayName:
      input.displayName ??
      (input.provider === "apple"
        ? "Apple Nutzer"
        : input.provider === "google"
          ? "Google Nutzer"
          : input.email?.split("@")[0] || "Fahrer"),
    provider: input.provider,
    createdAt: new Date().toISOString(),
  };
  const session: AuthSession = {
    user,
    syncEnabled: input.provider !== "local_anonymous",
  };
  saveSession(session);
  return session;
}

export function signOut(): AuthSession {
  const s: AuthSession = { user: null, syncEnabled: false };
  saveSession(s);
  return s;
}

/** Lokale Nutzung ohne Konto — Tracking & Garage OK, Sync aus */
export function continueWithoutAccount(): AuthSession {
  return signInLocal({
    provider: "local_anonymous",
    displayName: "Lokal",
  });
}

export function requestAccountDeletion(user: AuthUser): AccountDeletionRequest {
  const requestedAt = new Date();
  const effective = new Date(requestedAt);
  effective.setDate(effective.getDate() + 30);
  const req: AccountDeletionRequest = {
    requestedAt: requestedAt.toISOString(),
    effectiveBy: effective.toISOString(),
    confirmationEmailSent: !!user.email,
    status: "pending",
  };
  if (typeof window !== "undefined") {
    localStorage.setItem(
      "aetherride.accountDeletion",
      JSON.stringify(req)
    );
  }
  return req;
}

export function getPendingDeletion(): AccountDeletionRequest | null {
  if (typeof window === "undefined") return null;
  try {
    const raw = localStorage.getItem("aetherride.accountDeletion");
    return raw ? (JSON.parse(raw) as AccountDeletionRequest) : null;
  } catch {
    return null;
  }
}

function saveDeletion(req: AccountDeletionRequest | null) {
  if (typeof window === "undefined") return;
  if (!req) {
    localStorage.removeItem("aetherride.accountDeletion");
    return;
  }
  localStorage.setItem("aetherride.accountDeletion", JSON.stringify(req));
}

/** Lokaler Statuswechsel — kein Server, E-Mails nur als Flag */
export function updateDeletionStatus(
  status: AccountDeletionRequest["status"]
): AccountDeletionRequest | null {
  const cur = getPendingDeletion();
  if (!cur) return null;
  const next: AccountDeletionRequest = {
    ...cur,
    status,
    confirmationEmailSent:
      status === "confirmed" ? cur.confirmationEmailSent : cur.confirmationEmailSent,
  };
  saveDeletion(next);
  return next;
}

export function cancelAccountDeletion(): AccountDeletionRequest | null {
  return updateDeletionStatus("cancelled");
}

export function confirmAccountDeletionLocally(): AccountDeletionRequest | null {
  const cur = getPendingDeletion();
  if (!cur) return null;
  const next: AccountDeletionRequest = {
    ...cur,
    status: "confirmed",
    confirmationEmailSent: cur.confirmationEmailSent,
  };
  saveDeletion(next);
  return next;
}

/** E-Mail-Format-Check für Demo-Login (kein IdP) */
export function isPlausibleEmail(email: string): boolean {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email.trim());
}

export const AUTH_DEMO_BANNER =
  "Web-Demo: kein echter IdP (Apple/Google/E-Mail). Session nur lokal — Produktion: OAuth + Backend.";

