"use client";

import { useCallback, useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { isSupabaseConfigured } from "@/lib/supabase/client";
import { HOF_COPY } from "@/lib/home/hofCopy";

type AuthUser = {
  id: string;
  email: string | null;
};

export function AuthCard({
  redirectTo = "/home",
  onAuthed,
  variant = "page",
}: {
  redirectTo?: string;
  onAuthed?: () => void | Promise<void>;
  variant?: "page" | "embedded";
}) {
  const router = useRouter();
  const configured = isSupabaseConfigured();
  const [authUser, setAuthUser] = useState<AuthUser | null>(null);
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [authMsg, setAuthMsg] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  const refreshMe = useCallback(async () => {
    try {
      const res = await fetch("/api/auth/me");
      const data = (await res.json()) as { user?: AuthUser | null };
      setAuthUser(data.user ?? null);
      return data.user ?? null;
    } catch {
      setAuthUser(null);
      return null;
    }
  }, []);

  useEffect(() => {
    if (!configured) return;
    void refreshMe();
  }, [configured, refreshMe]);

  const afterAuth = async () => {
    await refreshMe();
    await onAuthed?.();
    if (variant !== "embedded") {
      router.push(redirectTo);
    }
  };

  const login = async () => {
    setBusy(true);
    setAuthMsg(null);
    try {
      const res = await fetch("/api/auth/login", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email, password }),
      });
      const data = (await res.json()) as { error?: string };
      if (!res.ok) throw new Error(data.error || "Login fehlgeschlagen");
      await afterAuth();
    } catch (e) {
      setAuthMsg(e instanceof Error ? e.message : "Fehler");
    } finally {
      setBusy(false);
    }
  };

  const register = async () => {
    setBusy(true);
    setAuthMsg(null);
    try {
      const res = await fetch("/api/auth/register", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email, password }),
      });
      const data = (await res.json()) as {
        error?: string;
        needsConfirmation?: boolean;
      };
      if (!res.ok) throw new Error(data.error || "Registrierung fehlgeschlagen");
      if (data.needsConfirmation) {
        setAuthMsg("Bitte E-Mail bestätigen, dann anmelden.");
        return;
      }
      await afterAuth();
    } catch (e) {
      setAuthMsg(e instanceof Error ? e.message : "Fehler");
    } finally {
      setBusy(false);
    }
  };

  const oauth = async (provider: "google" | "apple") => {
    setBusy(true);
    setAuthMsg(null);
    try {
      const res = await fetch("/api/auth/oauth/start", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ provider }),
      });
      const data = (await res.json()) as { error?: string; url?: string };
      if (!res.ok) throw new Error(data.error || "OAuth nicht verfügbar");
      if (data.url) window.location.href = data.url;
    } catch (e) {
      setAuthMsg(
        e instanceof Error
          ? e.message
          : "OAuth: Provider in Supabase aktivieren"
      );
      setBusy(false);
    }
  };

  if (!configured) {
    return (
      <p className="text-sm text-text-secondary">{HOF_COPY.profileLocalOnly}</p>
    );
  }

  if (authUser) {
    if (variant === "embedded") return null;
    return (
      <div className="space-y-3 text-sm">
        <p>
          {authUser.email ?? "Angemeldet"} · {HOF_COPY.profileWelcome}
        </p>
        <div className="flex flex-wrap gap-2">
          <Link
            href={redirectTo}
            className="inline-flex h-11 items-center justify-center rounded-xl bg-chrome px-4 text-sm font-semibold text-background"
          >
            Zum Hof
          </Link>
          <Link
            href="/profile"
            className="inline-flex h-11 items-center justify-center rounded-xl border border-border px-4 text-sm font-medium"
          >
            {HOF_COPY.profile}
          </Link>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-2">
      <input
        type="email"
        placeholder="E-Mail"
        value={email}
        autoComplete="email"
        onChange={(e) => setEmail(e.target.value)}
        className="w-full rounded-xl border border-border bg-surface-elevated px-3 py-2.5 text-sm"
      />
      <input
        type="password"
        placeholder="Passwort (min. 8)"
        value={password}
        autoComplete="current-password"
        onChange={(e) => setPassword(e.target.value)}
        className="w-full rounded-xl border border-border bg-surface-elevated px-3 py-2.5 text-sm"
      />
      <div className="grid grid-cols-2 gap-2">
        <button
          type="button"
          disabled={busy}
          onClick={() => void login()}
          className="rounded-xl bg-chrome py-2.5 text-sm font-medium text-background disabled:opacity-50"
        >
          Anmelden
        </button>
        <button
          type="button"
          disabled={busy}
          onClick={() => void register()}
          className="rounded-xl bg-surface-elevated py-2.5 text-sm font-medium disabled:opacity-50"
        >
          Registrieren
        </button>
      </div>
      <div className="grid grid-cols-2 gap-2">
        <button
          type="button"
          disabled={busy}
          onClick={() => void oauth("google")}
          className="rounded-xl border border-border py-2 text-xs disabled:opacity-50"
        >
          Google
        </button>
        <button
          type="button"
          disabled={busy}
          onClick={() => void oauth("apple")}
          className="rounded-xl border border-border py-2 text-xs disabled:opacity-50"
        >
          Apple
        </button>
      </div>
      {authMsg ? (
        <p className="text-xs text-text-secondary">{authMsg}</p>
      ) : null}
    </div>
  );
}
