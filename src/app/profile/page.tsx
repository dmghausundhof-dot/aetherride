"use client";

import { useCallback, useEffect, useState } from "react";
import { useAppStore } from "@/store/useAppStore";
import { User, Sparkles, Crown, LogIn, LogOut, Cloud, Trash2 } from "lucide-react";
import Link from "next/link";
import type { RiderProfile } from "@/types";
import { PublicProfilePanel } from "@/components/community/PublicProfilePanel";
import {
  isSupabaseConfigured,
} from "@/lib/supabase/client";
import { runWebSync } from "@/lib/sync/webSync";

type AuthUser = {
  id: string;
  email: string | null;
  displayName: string | null;
  subscriptionTier: "free" | "pro";
  subscriptionStatus: string;
  hasStripeCustomer: boolean;
};

export default function ProfilePage() {
  const profile = useAppStore((s) => s.riderProfile);
  const explanations = useAppStore((s) => s.profileExplanations);
  const updateRiderProfile = useAppStore((s) => s.updateRiderProfile);
  const subscriptionTier = useAppStore((s) => s.subscriptionTier);
  const setSubscriptionTier = useAppStore((s) => s.setSubscriptionTier);
  const rides = useAppStore((s) => s.rides);
  const bikes = useAppStore((s) => s.bikes);
  const rangeCalibration = useAppStore((s) => s.rangeCalibration);
  const [advanced, setAdvanced] = useState(false);
  const store = useAppStore();

  const [authUser, setAuthUser] = useState<AuthUser | null>(null);
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [authMsg, setAuthMsg] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);
  const configured = isSupabaseConfigured();

  const refreshMe = useCallback(async () => {
    try {
      const res = await fetch("/api/auth/me");
      const data = await res.json();
      if (data.user) {
        setAuthUser(data.user);
        if (data.user.subscriptionTier === "pro") {
          setSubscriptionTier("pro");
        } else {
          setSubscriptionTier(
            data.user.subscriptionTier === "pro" ? "pro" : "free"
          );
        }
      } else {
        setAuthUser(null);
      }
    } catch {
      setAuthUser(null);
    }
  }, [setSubscriptionTier]);

  useEffect(() => {
    if (!configured) return;
    void (async () => {
      await refreshMe();
      try {
        const me = await fetch("/api/auth/me").then((r) => r.json());
        if (!me.user) return;
        await runWebSync();
      } catch {
        /* offline / no session */
      }
    })();
  }, [configured, refreshMe]);
  const setPref = (key: keyof RiderProfile["preferences"], value: boolean) => {
    updateRiderProfile({
      preferences: { ...profile.preferences, [key]: value },
    });
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
      const data = await res.json();
      if (!res.ok) throw new Error(data.error || "Login fehlgeschlagen");
      await refreshMe();
      setAuthMsg("Angemeldet.");
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
      const data = await res.json();
      if (!res.ok) throw new Error(data.error || "Registrierung fehlgeschlagen");
      if (data.needsConfirmation) {
        setAuthMsg("Bitte E-Mail bestätigen (Supabase), dann anmelden.");
      } else {
        await refreshMe();
        setAuthMsg("Konto erstellt und angemeldet.");
      }
    } catch (e) {
      setAuthMsg(e instanceof Error ? e.message : "Fehler");
    } finally {
      setBusy(false);
    }
  };

  const logout = async () => {
    setBusy(true);
    await fetch("/api/auth/logout", { method: "POST" });
    setAuthUser(null);
    setBusy(false);
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
      const data = await res.json();
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

  const syncNow = async () => {
    setBusy(true);
    setAuthMsg(null);
    try {
      const { message } = await runWebSync();
      setAuthMsg(message);
    } catch (e) {
      setAuthMsg(e instanceof Error ? e.message : "Sync fehlgeschlagen");
    } finally {
      setBusy(false);
    }
  };

  const startBilling = async (interval: "month" | "year") => {
    setBusy(true);
    setAuthMsg(null);
    try {
      const res = await fetch("/api/billing/checkout", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ interval }),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.error || "Checkout fehlgeschlagen");
      if (data.url) window.location.href = data.url;
    } catch (e) {
      setAuthMsg(e instanceof Error ? e.message : "Billing-Fehler");
      setBusy(false);
    }
  };

  const openPortal = async () => {
    setBusy(true);
    try {
      const res = await fetch("/api/billing/portal", { method: "POST" });
      const data = await res.json();
      if (!res.ok) throw new Error(data.error || "Portal fehlgeschlagen");
      if (data.url) window.location.href = data.url;
    } catch (e) {
      setAuthMsg(e instanceof Error ? e.message : "Portal-Fehler");
      setBusy(false);
    }
  };

  const deleteAccount = async () => {
    const ok = window.confirm(
      "Konto löschen?\n\nRemote-Konto und lokale App-Daten werden entfernt. " +
        "Exportiere vorher GPX/JSON unter Daten & Privatsphäre."
    );
    if (!ok) return;
    const confirmText = window.prompt(
      'Zum Bestätigen „DELETE“ eingeben:',
      ""
    );
    if (confirmText !== "DELETE") {
      setAuthMsg("Abgebrochen — Bestätigung war nicht DELETE.");
      return;
    }
    setBusy(true);
    setAuthMsg(null);
    let remoteMsg: string | null = null;
    try {
      const res = await fetch("/api/account/delete", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ confirm: "DELETE" }),
      });
      const data = (await res.json().catch(() => ({}))) as {
        error?: string;
        message?: string;
      };
      if (res.status === 200) {
        remoteMsg = "Remote-Konto gelöscht.";
      } else if (res.status === 503) {
        remoteMsg =
          data.message ||
          "Remote-Löschung nicht verfügbar (Service-Role fehlt) — nur lokale Daten werden entfernt.";
      } else if (res.status === 401) {
        remoteMsg = "Nicht angemeldet — nur lokale Daten werden entfernt.";
      } else {
        remoteMsg = `Remote-Löschung fehlgeschlagen (${
          data.message || data.error || res.status
        }) — lokal trotzdem gelöscht.`;
      }
    } catch {
      remoteMsg = "Server nicht erreichbar — nur lokale Daten werden entfernt.";
    }
    try {
      await fetch("/api/auth/logout", { method: "POST" });
    } catch {
      /* ignore */
    }
    try {
      await useAppStore.persist.clearStorage();
    } catch {
      try {
        localStorage.removeItem("aetherride-storage");
      } catch {
        /* ignore */
      }
    }
    setAuthUser(null);
    setBusy(false);
    setAuthMsg(
      remoteMsg ??
        "Lokale Daten gelöscht. Export ggf. unter Privatsphäre nachholen."
    );
    window.setTimeout(() => {
      window.location.href = "/";
    }, 800);
  };

  return (
    <div className="flex flex-col gap-5 p-4 pt-6">
      <header className="flex items-center gap-3">
        <div className="flex h-14 w-14 items-center justify-center rounded-full bg-accent text-xl font-bold text-white">
          AR
        </div>
        <div>
          <h1 className="text-xl font-bold">Rider Profil</h1>
          <p className="text-sm text-text-secondary">
            Fahrstil und Terrain — jederzeit korrigierbar
          </p>
        </div>
      </header>

      <section className="rounded-2xl border border-border bg-surface p-4">
        <h3 className="mb-2 flex items-center gap-2 font-semibold">
          <LogIn className="h-4 w-4 text-accent" /> Konto
        </h3>
        {!configured ? (
          <p className="text-xs text-text-secondary">
            Supabase Env fehlt — lokale Nutzung ohne Sync.
          </p>
        ) : authUser ? (
          <div className="space-y-2 text-sm">
            <p>
              {authUser.email} · Status {authUser.subscriptionStatus}
            </p>
            <div className="flex flex-wrap gap-2">
              <button
                type="button"
                disabled={busy}
                onClick={() => void syncNow()}
                className="inline-flex items-center gap-1 rounded-xl bg-surface-elevated px-3 py-2 text-xs font-medium"
              >
                <Cloud className="h-3.5 w-3.5" /> Sync
              </button>
              <button
                type="button"
                disabled={busy}
                onClick={() => void logout()}
                className="inline-flex items-center gap-1 rounded-xl bg-surface-elevated px-3 py-2 text-xs font-medium"
              >
                <LogOut className="h-3.5 w-3.5" /> Abmelden
              </button>
              <button
                type="button"
                disabled={busy}
                onClick={() => void deleteAccount()}
                className="inline-flex items-center gap-1 rounded-xl border border-error/50 px-3 py-2 text-xs font-medium text-error"
              >
                <Trash2 className="h-3.5 w-3.5" /> Konto löschen
              </button>
            </div>
          </div>
        ) : (
          <div className="space-y-2">
            <input
              type="email"
              placeholder="E-Mail"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="w-full rounded-xl border border-border bg-surface-elevated px-3 py-2 text-sm"
            />
            <input
              type="password"
              placeholder="Passwort (min. 8)"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="w-full rounded-xl border border-border bg-surface-elevated px-3 py-2 text-sm"
            />
            <div className="grid grid-cols-2 gap-2">
              <button
                type="button"
                disabled={busy}
                onClick={() => void login()}
                className="rounded-xl bg-accent py-2 text-sm font-medium text-white"
              >
                Anmelden
              </button>
              <button
                type="button"
                disabled={busy}
                onClick={() => void register()}
                className="rounded-xl bg-surface-elevated py-2 text-sm font-medium"
              >
                Registrieren
              </button>
            </div>
            <div className="grid grid-cols-2 gap-2">
              <button
                type="button"
                disabled={busy}
                onClick={() => void oauth("google")}
                className="rounded-xl border border-border py-2 text-xs"
              >
                Google
              </button>
              <button
                type="button"
                disabled={busy}
                onClick={() => void oauth("apple")}
                className="rounded-xl border border-border py-2 text-xs"
              >
                Apple
              </button>
            </div>
          </div>
        )}
        {authMsg && (
          <p className="mt-2 text-xs text-text-secondary">{authMsg}</p>
        )}
      </section>

      <PublicProfilePanel />

      <section className="rounded-2xl border border-border bg-surface p-4">
        <h3 className="mb-2 flex items-center gap-2 font-semibold">
          <Crown className="h-4 w-4 text-accent" /> Abo
        </h3>
        <p className="mb-3 text-xs text-text-secondary">
          Free: 1 Bike, Basis. Pro: Multi-Bike, Bracketing, Reichweite.
          Offline-Packs unter Discover herunterladen; Aktivierung in der
          Mobile-App. KI-Coach — 6,99 €/Mo oder 59,99 €/Jahr.
        </p>
        <p className="mb-3 text-sm font-medium">
          Aktuell: {subscriptionTier === "pro" ? "Pro" : "Free"}
          {authUser ? ` (${authUser.subscriptionStatus})` : " (lokal)"}
        </p>
        {authUser ? (
          <div className="grid grid-cols-2 gap-2">
            <button
              type="button"
              disabled={busy || subscriptionTier === "pro"}
              onClick={() => void startBilling("month")}
              className="rounded-xl bg-accent py-2 text-sm font-medium text-white disabled:opacity-40"
            >
              Pro 6,99 €/Mo
            </button>
            <button
              type="button"
              disabled={busy || subscriptionTier === "pro"}
              onClick={() => void startBilling("year")}
              className="rounded-xl bg-accent py-2 text-sm font-medium text-white disabled:opacity-40"
            >
              Pro 59,99 €/Jahr
            </button>
            {authUser.hasStripeCustomer && (
              <button
                type="button"
                disabled={busy}
                onClick={() => void openPortal()}
                className="col-span-2 rounded-xl bg-surface-elevated py-2 text-sm"
              >
                Abo verwalten (Stripe Portal)
              </button>
            )}
          </div>
        ) : (
          <p className="text-xs text-text-secondary">
            Zum Upgrade bitte anmelden. Ohne Konto bleibt Free lokal nutzbar.
          </p>
        )}
      </section>

      <section className="rounded-2xl border border-border bg-surface p-4">
        <h3 className="mb-3 flex items-center gap-2 font-semibold">
          <User className="h-4 w-4 text-accent" /> Fahrstil
        </h3>
        <label className="mb-3 block text-sm">
          Style
          <select
            value={profile.style}
            onChange={(e) =>
              updateRiderProfile({
                style: e.target.value as RiderProfile["style"],
              })
            }
            className="mt-1 w-full rounded-xl border border-border bg-surface-elevated px-3 py-2"
          >
            <option value="aggressive">Aggressiv</option>
            <option value="flow">Flow</option>
            <option value="efficient">Effizient</option>
            <option value="explorative">Explorativ</option>
          </select>
          <p className="mt-1 text-[11px] text-text-secondary">
            {explanations.style}
          </p>
        </label>
        <label className="mb-3 block text-sm">
          Skill Level ({profile.skillLevel}/5)
          <input
            type="range"
            min={1}
            max={5}
            value={profile.skillLevel}
            onChange={(e) =>
              updateRiderProfile({
                skillLevel: Number(e.target.value) as 1 | 2 | 3 | 4 | 5,
              })
            }
            className="mt-1 w-full"
          />
          <p className="mt-1 text-[11px] text-text-secondary">
            {explanations.skillLevel}
          </p>
        </label>
        <label className="block text-sm">
          Fahrergewicht (kg)
          <input
            type="number"
            value={profile.riderWeightKg ?? 78}
            onChange={(e) =>
              updateRiderProfile({ riderWeightKg: Number(e.target.value) })
            }
            className="mt-1 w-full rounded-xl border border-border bg-surface-elevated px-3 py-2"
          />
          <p className="mt-1 text-[11px] text-text-secondary">
            {explanations.riderWeightKg}
          </p>
        </label>
      </section>

      <button
        type="button"
        onClick={() => setAdvanced((v) => !v)}
        className="rounded-xl border border-border bg-surface-elevated px-3 py-2 text-sm text-text-secondary"
      >
        {advanced
          ? "Erweiterte Einstellungen ausblenden"
          : "Erweiterte Einstellungen (Terrain & Indikatoren)"}
      </button>

      {advanced && (
      <section className="rounded-2xl border border-border bg-surface p-4">
        <h3 className="mb-3 font-semibold">Terrainanteil</h3>
        <p className="mb-2 text-[11px] text-text-secondary">
          {explanations.terrainShare}
        </p>
        {(
          [
            ["s0s1", "S0–S1 / easy"],
            ["s2", "S2"],
            ["s3plus", "S3+"],
            ["gravelRoad", "Gravel/Straße"],
          ] as const
        ).map(([key, label]) => (
          <label key={key} className="mb-2 block text-sm">
            {label}: {profile.terrainShare?.[key] ?? 0}%
            <input
              type="range"
              min={0}
              max={100}
              value={profile.terrainShare?.[key] ?? 0}
              onChange={(e) =>
                updateRiderProfile({
                  terrainShare: {
                    s0s1: profile.terrainShare?.s0s1 ?? 0,
                    s2: profile.terrainShare?.s2 ?? 0,
                    s3plus: profile.terrainShare?.s3plus ?? 0,
                    gravelRoad: profile.terrainShare?.gravelRoad ?? 0,
                    [key]: Number(e.target.value),
                  },
                })
              }
              className="mt-1 w-full"
            />
          </label>
        ))}
      </section>
      )}

      {advanced && (
      <section className="rounded-2xl border border-border bg-surface p-4">
        <h3 className="mb-3 font-semibold">Fahrstil-Indikatoren</h3>
        <p className="mb-2 text-[11px] text-text-secondary">
          {explanations.styleIndicators}
        </p>
        {(
          [
            ["brakeIntensityBeforeCorners", "Bremsintensität vor Kurven"],
            ["timeOver04gLateralPct", "% Zeit > 0,4 g Quer"],
            ["impactsPerHour", "Impacts / Stunde"],
            ["jumpsPerRide", "Sprünge / Ride"],
          ] as const
        ).map(([key, label]) => (
          <label key={key} className="mb-2 block text-sm">
            {label}: {profile.styleIndicators?.[key] ?? 0}
            <input
              type="range"
              min={0}
              max={key === "jumpsPerRide" ? 20 : 100}
              value={profile.styleIndicators?.[key] ?? 0}
              onChange={(e) =>
                updateRiderProfile({
                  styleIndicators: {
                    brakeIntensityBeforeCorners:
                      profile.styleIndicators?.brakeIntensityBeforeCorners ?? 0,
                    timeOver04gLateralPct:
                      profile.styleIndicators?.timeOver04gLateralPct ?? 0,
                    impactsPerHour:
                      profile.styleIndicators?.impactsPerHour ?? 0,
                    jumpsPerRide: profile.styleIndicators?.jumpsPerRide ?? 0,
                    [key]: Number(e.target.value),
                  },
                })
              }
              className="mt-1 w-full"
            />
          </label>
        ))}
      </section>
      )}

      <section className="rounded-2xl border border-border bg-surface p-4">
        <h3 className="mb-3 flex items-center gap-2 font-semibold">
          <Sparkles className="h-4 w-4 text-accent" /> Präferenzen
        </h3>
        {(
          [
            ["preferTechnical", "Technisch"],
            ["preferFlow", "Flow"],
            ["preferSteep", "Steil"],
          ] as const
        ).map(([key, label]) => (
          <label
            key={key}
            className="mb-2 flex items-start gap-2 text-sm"
          >
            <input
              type="checkbox"
              checked={profile.preferences[key]}
              onChange={(e) => setPref(key, e.target.checked)}
              className="mt-1"
            />
            <span>
              {label}
              <span className="mt-0.5 block text-[11px] text-text-secondary">
                {explanations[key]}
              </span>
            </span>
          </label>
        ))}
        <label className="mt-2 block text-sm">
          E-Bike Assist-Präferenz (Logging)
          <select
            value={profile.preferences.eBikeAssistPreference}
            onChange={(e) =>
              updateRiderProfile({
                preferences: {
                  ...profile.preferences,
                  eBikeAssistPreference: e.target
                    .value as RiderProfile["preferences"]["eBikeAssistPreference"],
                },
              })
            }
            className="mt-1 w-full rounded-xl border border-border bg-surface-elevated px-3 py-2"
          >
            <option value="eco">eco</option>
            <option value="tour">tour</option>
            <option value="sport">sport</option>
            <option value="turbo">turbo</option>
          </select>
          <p className="mt-1 text-[11px] text-text-secondary">
            {explanations.eBikeAssistPreference}
          </p>
        </label>
      </section>

      {rangeCalibration && (
        <section className="rounded-2xl border border-border bg-surface p-4 text-sm">
          <h3 className="mb-2 font-semibold">Reichweiten-Kalibrierung</h3>
          <p className="text-xs text-text-secondary">
            Crr {rangeCalibration.crr.toFixed(4)} · CdA{" "}
            {rangeCalibration.cdA.toFixed(3)} · P_fahrer{" "}
            {Math.round(rangeCalibration.riderPowerW)} W · n=
            {rangeCalibration.samples}
          </p>
        </section>
      )}

      <section className="grid grid-cols-2 gap-3">
        <div className="rounded-xl border border-border bg-surface p-3 text-center">
          <div className="text-2xl font-bold tabular-nums">{bikes.length}</div>
          <div className="text-xs text-text-secondary">Bikes</div>
        </div>
        <div className="rounded-xl border border-border bg-surface p-3 text-center">
          <div className="text-2xl font-bold tabular-nums">{rides.length}</div>
          <div className="text-xs text-text-secondary">Rides</div>
        </div>
      </section>

      <Link href="/privacy" className="text-center text-sm text-accent">
        Datenexport · Privatsphäre · Familie →
      </Link>
      <Link href="/chat" className="text-center text-sm text-accent">
        Mehr fragen (KI-Chat, Power-User) →
      </Link>
    </div>
  );
}
