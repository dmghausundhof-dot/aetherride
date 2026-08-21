"use client";

import { useCallback, useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { isSupabaseConfigured } from "@/lib/supabase/client";
import { useHofCopy } from "@/hooks/useHofCopy";
import { useChromeLang } from "@/hooks/useChromeLang";
import { webChrome } from "@/lib/i18n/webChrome";
import { authCopy, presentAuthError } from "@/lib/i18n/authCopy";

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
  const copy = useHofCopy();
  const lang = useChromeLang();
  const chrome = webChrome(lang);
  const a = authCopy(lang);

  const router = useRouter();
  const configured = isSupabaseConfigured();
  const [authUser, setAuthUser] = useState<AuthUser | null>(null);
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [authMsg, setAuthMsg] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);
  const [showPassword, setShowPassword] = useState(false);

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

  const failMsg = (e: unknown, fallback: string) => {
    if (!(e instanceof Error)) return fallback;
    return presentAuthError(e.message, lang);
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
      if (!res.ok) throw new Error(data.error || a.loginFailed);
      await afterAuth();
    } catch (e) {
      setAuthMsg(failMsg(e, a.error));
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
      if (!res.ok) throw new Error(data.error || a.registerFailed);
      if (data.needsConfirmation) {
        setAuthMsg(a.confirmEmail);
        return;
      }
      await afterAuth();
    } catch (e) {
      setAuthMsg(failMsg(e, a.error));
    } finally {
      setBusy(false);
    }
  };

  const resetPassword = async () => {
    setBusy(true);
    setAuthMsg(null);
    try {
      if (!email.trim()) {
        setAuthMsg(a.needEmail);
        return;
      }
      const res = await fetch("/api/auth/reset", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email }),
      });
      const data = (await res.json()) as { error?: string };
      if (!res.ok) throw new Error(data.error || a.resetFailed);
      setAuthMsg(a.resetSent);
    } catch (e) {
      setAuthMsg(failMsg(e, a.error));
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
      if (!res.ok) throw new Error(data.error || a.oauthUnavailable);
      if (data.url) window.location.href = data.url;
    } catch (e) {
      setAuthMsg(failMsg(e, a.oauthEnable));
      setBusy(false);
    }
  };

  if (!configured) {
    return (
      <p className="text-sm text-text-secondary">{copy.profileLocalOnly}</p>
    );
  }

  if (authUser) {
    if (variant === "embedded") return null;
    return (
      <div className="space-y-3 text-sm">
        <p>
          {authUser.email ?? copy.signedIn} · {copy.profileWelcome}
        </p>
        <div className="flex flex-wrap gap-2">
          <Link
            href={redirectTo}
            className="inline-flex h-11 items-center justify-center rounded-xl bg-chrome px-4 text-sm font-semibold text-on-accent"
          >
            {chrome.toHof}
          </Link>
          <Link
            href="/profile"
            className="inline-flex h-11 items-center justify-center rounded-xl border border-border px-4 text-sm font-medium"
          >
            {copy.profile}
          </Link>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-2">
      <input
        type="email"
        placeholder={a.email}
        value={email}
        autoComplete="email"
        onChange={(e) => setEmail(e.target.value)}
        className="w-full rounded-xl border border-border bg-surface-elevated px-3 py-2.5 text-sm"
      />
      <div className="relative">
        <input
          type={showPassword ? "text" : "password"}
          placeholder={a.passwordPh}
          value={password}
          autoComplete="current-password"
          onChange={(e) => setPassword(e.target.value)}
          className="w-full rounded-xl border border-border bg-surface-elevated px-3 py-2.5 pr-16 text-sm"
        />
        <button
          type="button"
          onClick={() => setShowPassword((v) => !v)}
          className="absolute inset-y-0 right-2 text-xs font-semibold text-text-secondary"
        >
          {showPassword ? a.hide : a.show}
        </button>
      </div>
      <div className="grid grid-cols-2 gap-2">
        <button
          type="button"
          disabled={busy}
          onClick={() => void login()}
          className="rounded-xl bg-chrome py-2.5 text-sm font-medium text-on-accent disabled:opacity-50"
        >
          {a.signIn}
        </button>
        <button
          type="button"
          disabled={busy}
          onClick={() => void register()}
          className="rounded-xl bg-surface-elevated py-2.5 text-sm font-medium disabled:opacity-50"
        >
          {a.register}
        </button>
      </div>
      <button
        type="button"
        disabled={busy}
        onClick={() => void resetPassword()}
        className="text-left text-xs font-medium text-text-secondary underline-offset-2 hover:underline"
      >
        {a.forgot}
      </button>
      <div className="grid grid-cols-2 gap-2">
        <button
          type="button"
          disabled={busy}
          onClick={() => void oauth("google")}
          className="rounded-xl border border-border py-2 text-xs disabled:opacity-50"
        >
          {a.google}
        </button>
        <button
          type="button"
          disabled={busy}
          onClick={() => void oauth("apple")}
          className="rounded-xl border border-border py-2 text-xs disabled:opacity-50"
        >
          {a.apple}
        </button>
      </div>
      {authMsg ? (
        <p className="text-xs text-text-secondary">{authMsg}</p>
      ) : null}
    </div>
  );
}
