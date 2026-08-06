"use client";

import { FormEvent, useEffect, useState } from "react";
import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";
import { Suspense } from "react";
import { useAppStore } from "@/store/useAppStore";
import {
  fetchServerSession,
  loginWithServer,
  registerWithServer,
  startOAuth,
  toAuthSession,
} from "@/lib/auth/clientAuth";
import { isPlausibleEmail } from "@/lib/auth/session";
import { PROFESSIONAL_ROADMAP_STEPS } from "@/lib/platform/professionalRoadmap";

function LoginForm() {
  const router = useRouter();
  const params = useSearchParams();
  const next = params.get("next") || "/";
  const modeParam = params.get("mode");
  const applyServerSession = useAppStore((s) => s.applyServerSession);
  const continueLocal = useAppStore((s) => s.continueLocal);
  const setOnboardingCompleted = useAppStore((s) => s.setOnboardingCompleted);

  const [mode, setMode] = useState<"login" | "register">(
    modeParam === "register" ? "register" : "login"
  );
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [displayName, setDisplayName] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);
  const [info, setInfo] = useState<string | null>(null);
  const [backendLabel, setBackendLabel] = useState<string | null>(null);

  useEffect(() => {
    const err = params.get("error");
    if (err === "auth_callback") {
      setError("Auth-Callback fehlgeschlagen — bitte erneut anmelden.");
    } else if (err === "supabase_missing") {
      setError("Supabase-Env fehlt — bitte NEXT_PUBLIC_SUPABASE_URL/ANON_KEY setzen.");
    }
    void fetchServerSession().then((s) => {
      if (s.authBackend === "supabase") {
        setBackendLabel("Supabase Auth · E-Mail/Passwort");
      } else if (s.authBackend === "local_file") {
        setBackendLabel(
          "Lokaler Fallback (Supabase-Env fehlt) · OAuth vorbereitet"
        );
      }
      if (s.oauthPrep) {
        setInfo(s.oauthPrep);
      }
    });
  }, [params]);

  const submit = async (e: FormEvent) => {
    e.preventDefault();
    setError(null);
    if (!isPlausibleEmail(email)) {
      setError("Bitte gültige E-Mail eingeben.");
      return;
    }
    if (password.length < 8) {
      setError("Passwort mindestens 8 Zeichen.");
      return;
    }
    setBusy(true);
    try {
      const res =
        mode === "register"
          ? await registerWithServer({
              email,
              password,
              displayName: displayName || undefined,
            })
          : await loginWithServer({ email, password });
      if (res.error || !res.user) {
        setError(res.error || "Anmeldung fehlgeschlagen.");
        return;
      }
      if (res.pendingEmailConfirmation) {
        setInfo(
          res.note ||
            "Konto angelegt — bitte E-Mail bestätigen, dann anmelden."
        );
        setMode("login");
        return;
      }
      applyServerSession(toAuthSession(res));
      if (res.authBackend === "local_file") {
        setInfo(
          "Hinweis: Supabase-Env fehlt — lokaler File-Store aktiv. Für Produktion URL + Anon-Key setzen."
        );
      }
      setOnboardingCompleted(true);
      router.push(next.startsWith("/") ? next : "/");
    } catch {
      setError("Netzwerkfehler — Server erreichbar?");
    } finally {
      setBusy(false);
    }
  };

  const tryOAuth = async (provider: "google" | "apple") => {
    setError(null);
    setBusy(true);
    try {
      const r = await startOAuth(provider, next);
      if (r.url) {
        window.location.href = r.url;
        return;
      }
      setError(
        r.error ||
          "OAuth kommt zum Schluss — Flag NEXT_PUBLIC_OAUTH_ENABLED + Provider im Dashboard."
      );
    } catch {
      setError("OAuth-Start fehlgeschlagen.");
    } finally {
      setBusy(false);
    }
  };

  return (
    <div className="mx-auto flex w-full max-w-md flex-col gap-5 p-4 pt-10">
      <header>
        <p className="text-xs uppercase tracking-wide text-text-secondary">
          AetherRide · Auth
        </p>
        <h1 className="text-2xl font-bold">
          {mode === "login" ? "Anmelden" : "Konto erstellen"}
        </h1>
        <p className="text-sm text-text-secondary">
          {backendLabel ??
            "E-Mail/Passwort · Supabase (oder lokaler Fallback)"}
        </p>
      </header>

      <div className="flex gap-2 rounded-xl bg-surface-elevated p-1 text-sm">
        <button
          type="button"
          onClick={() => setMode("login")}
          className={`flex-1 rounded-lg py-2 ${
            mode === "login" ? "bg-accent text-white" : ""
          }`}
        >
          Login
        </button>
        <button
          type="button"
          onClick={() => setMode("register")}
          className={`flex-1 rounded-lg py-2 ${
            mode === "register" ? "bg-accent text-white" : ""
          }`}
        >
          Registrieren
        </button>
      </div>

      <form
        onSubmit={submit}
        className="flex flex-col gap-3 rounded-2xl border border-border bg-surface p-4"
      >
        {mode === "register" && (
          <label className="text-sm">
            Anzeigename
            <input
              value={displayName}
              onChange={(e) => setDisplayName(e.target.value)}
              className="mt-1 w-full rounded-xl border border-border bg-surface-elevated px-3 py-2"
              autoComplete="nickname"
            />
          </label>
        )}
        <label className="text-sm">
          E-Mail
          <input
            type="email"
            required
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            className="mt-1 w-full rounded-xl border border-border bg-surface-elevated px-3 py-2"
            autoComplete="email"
          />
        </label>
        <label className="text-sm">
          Passwort
          <input
            type="password"
            required
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            className="mt-1 w-full rounded-xl border border-border bg-surface-elevated px-3 py-2"
            autoComplete={
              mode === "register" ? "new-password" : "current-password"
            }
          />
        </label>
        {error && <p className="text-xs text-error">{error}</p>}
        {info && <p className="text-xs text-text-secondary">{info}</p>}
        <button
          type="submit"
          disabled={busy}
          className="rounded-xl bg-accent py-2.5 text-sm font-semibold text-white disabled:opacity-50"
        >
          {busy
            ? "…"
            : mode === "login"
              ? "Anmelden"
              : "Registrieren & starten"}
        </button>
      </form>

      <div className="space-y-2 text-sm">
        <p className="text-[11px] text-text-secondary">
          OAuth vorbereitet — Aktivierung zum Schluss (Dashboard + Flag).
        </p>
        <button
          type="button"
          disabled={busy}
          onClick={() => void tryOAuth("apple")}
          className="w-full rounded-xl bg-foreground/80 py-2.5 text-background opacity-70"
          title="Vorbereitet — Feature-Flag aus"
        >
          Apple — vorbereitet (zum Schluss)
        </button>
        <button
          type="button"
          disabled={busy}
          onClick={() => void tryOAuth("google")}
          className="w-full rounded-xl border border-border py-2.5 opacity-70"
          title="Vorbereitet — Feature-Flag aus"
        >
          Google — vorbereitet (zum Schluss)
        </button>
      </div>

      <button
        type="button"
        onClick={() => {
          continueLocal();
          setOnboardingCompleted(true);
          router.push(next.startsWith("/") ? next : "/");
        }}
        className="text-center text-xs text-text-secondary underline"
      >
        Ohne Konto lokal weiter (kein Sync)
      </button>

      <section className="rounded-xl border border-border bg-surface p-3 text-[11px] text-text-secondary">
        <p className="font-medium text-foreground">Roadmap</p>
        <ol className="mt-1 list-decimal space-y-0.5 pl-4">
          {PROFESSIONAL_ROADMAP_STEPS.filter((s) =>
            [3, 4, 9].includes(s.id)
          ).map((s) => (
            <li key={s.id}>
              {s.id}. {s.titleDe}
              {s.status === "in_progress" ? " ← jetzt" : ""}
              {s.status === "done" ? " ✓" : ""}
            </li>
          ))}
        </ol>
      </section>

      <Link href="/onboarding" className="text-center text-xs text-accent">
        Zum Onboarding
      </Link>
    </div>
  );
}

export default function LoginPage() {
  return (
    <Suspense fallback={<div className="p-6 text-center">Lade…</div>}>
      <LoginForm />
    </Suspense>
  );
}
