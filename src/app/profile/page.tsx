"use client";

import { useCallback, useEffect, useState } from "react";
import { useAppStore } from "@/store/useAppStore";
import { ChromeGlyph } from "@/components/chrome/ChromeGlyph";
import Link from "next/link";
import type { RiderProfile } from "@/types";
import { PublicProfilePanel } from "@/components/community/PublicProfilePanel";
import {
  isSupabaseConfigured,
} from "@/lib/supabase/client";
import {
  runWebSync,
  resolveSyncConflict,
  type SyncConflictState,
} from "@/lib/sync/webSync";
import { HofPageHeader } from "@/components/hof/HofPageHeader";
import { useHofCopy } from "@/hooks/useHofCopy";
import { SyncConflictPanel } from "@/components/sync/SyncConflictPanel";
import { AuthCard } from "@/components/auth/AuthCard";
import { ChromeLangPicker } from "@/components/profile/ChromeLangPicker";
import { isCommerceOpen } from "@/lib/config/appStage";
import type { BikeCategory } from "@/types/garage";
import { rideSportLabel } from "@/lib/i18n/rideSportLabel";
import { useChromeLang } from "@/hooks/useChromeLang";
import { chromeDateLocale } from "@/lib/i18n/chromeLang";
import { profileCopy } from "@/lib/i18n/profileCopy";
import { rideTelemetryCopy } from "@/lib/i18n/rideTelemetryCopy";
import { buildRideTelemetry } from "@/lib/ride/rideTelemetry";
import { terrainCaption } from "@/lib/ride/terrainCaption";
import { RideTerrainPeek } from "@/components/ride/ActivitySparkline";

const PROFILE_DISCIPLINES: BikeCategory[] = [
  "urban",
  "cargo",
  "folding",
  "kids",
  "etrekking",
  "gravel",
  "road",
  "emtb",
  "mtb_trail",
  "mtb_am",
  "mtb_enduro",
];

type AuthUser = {
  id: string;
  email: string | null;
  displayName: string | null;
  subscriptionTier: "free" | "pro";
  subscriptionStatus: string;
  hasStripeCustomer: boolean;
};

export default function ProfilePage() {
  const copy = useHofCopy();
  const lang = useChromeLang();
  const p = profileCopy(lang);
  const tel = rideTelemetryCopy(lang);
  const dateLocale = chromeDateLocale(lang);
  const rides = useAppStore((s) => s.rides);
  const recentEnded = [...rides]
    .filter((r) => Boolean(r.endTime))
    .sort(
      (a, b) =>
        new Date(b.startTime).getTime() - new Date(a.startTime).getTime()
    )
    .slice(0, 5);

  const profile = useAppStore((s) => s.riderProfile);
  const updateRiderProfile = useAppStore((s) => s.updateRiderProfile);
  const preferredSport = useAppStore((s) => s.preferredSport);
  const preferredSports = useAppStore((s) => s.preferredSports);
  const setPrimarySport = useAppStore((s) => s.setPrimarySport);
  const togglePreferredSport = useAppStore((s) => s.togglePreferredSport);
  const subscriptionTier = useAppStore((s) => s.subscriptionTier);
  const setSubscriptionTier = useAppStore((s) => s.setSubscriptionTier);
  const bikes = useAppStore((s) => s.bikes);
  const rangeCalibration = useAppStore((s) => s.rangeCalibration);
  const [advanced, setAdvanced] = useState(false);
  const store = useAppStore();

  const [authUser, setAuthUser] = useState<AuthUser | null>(null);
  const [authMsg, setAuthMsg] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);
  const [syncConflict, setSyncConflict] = useState<SyncConflictState | null>(
    null
  );
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
        await runWebSync(lang);
      } catch {
        /* offline / no session */
      }
    })();
  }, [configured, refreshMe, lang]);
  const setPref = (key: keyof RiderProfile["preferences"], value: boolean) => {
    updateRiderProfile({
      preferences: { ...profile.preferences, [key]: value },
    });
  };

  const logout = async () => {
    setBusy(true);
    await fetch("/api/auth/logout", { method: "POST" });
    setAuthUser(null);
    setBusy(false);
  };

  const syncNow = async () => {
    setBusy(true);
    setAuthMsg(null);
    setSyncConflict(null);
    try {
      const result = await runWebSync(lang);
      if (result.ok) {
        setAuthMsg(result.message);
      } else if (result.conflict) {
        setSyncConflict(result.conflictState);
        setAuthMsg(result.message);
      } else {
        setAuthMsg(result.message);
      }
    } catch (e) {
      setAuthMsg(e instanceof Error ? e.message : p.syncFailed);
    } finally {
      setBusy(false);
    }
  };

  const resolveConflict = async (choice: "keep_remote" | "keep_local") => {
    if (!syncConflict) return;
    setBusy(true);
    try {
      const result = await resolveSyncConflict(choice, syncConflict, lang);
      if (result.ok) {
        setSyncConflict(null);
        setAuthMsg(result.message);
      } else {
        setAuthMsg(result.message);
      }
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
      if (!res.ok) throw new Error(data.error || p.checkoutFailed);
      if (data.url) window.location.href = data.url;
    } catch (e) {
      setAuthMsg(e instanceof Error ? e.message : p.billingFailed);
      setBusy(false);
    }
  };

  const openPortal = async () => {
    setBusy(true);
    try {
      const res = await fetch("/api/billing/portal", { method: "POST" });
      const data = await res.json();
      if (!res.ok) throw new Error(data.error || p.portalFailed);
      if (data.url) window.location.href = data.url;
    } catch (e) {
      setAuthMsg(e instanceof Error ? e.message : p.portalFailed);
      setBusy(false);
    }
  };

  const deleteAccount = async () => {
    const ok = window.confirm(
      `${p.deleteConfirmTitle}\n\n${p.deleteConfirmBody}`
    );
    if (!ok) return;
    const confirmText = window.prompt(p.deleteTypeDelete, "");
    if (confirmText !== "DELETE") {
      setAuthMsg(p.deleteAborted);
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
        remoteMsg = p.remoteDeleted;
      } else if (res.status === 503) {
        remoteMsg = data.message || p.remoteUnavailable;
      } else if (res.status === 401) {
        remoteMsg = p.notSignedInLocal;
      } else {
        remoteMsg = p.remoteFailed(
          String(data.message || data.error || res.status)
        );
      }
    } catch {
      remoteMsg = p.serverUnreachable;
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
    setAuthMsg(remoteMsg ?? p.localCleared);
    window.setTimeout(() => {
      window.location.href = "/";
    }, 800);
  };

  return (
    <div className="mx-auto flex max-w-2xl flex-col gap-5 px-5 pb-10 pt-6 lg:max-w-3xl lg:px-10">
      <HofPageHeader
        kicker={copy.profileKicker}
        title={copy.profileTitle}
        hint={copy.profileHint}
      />

      <section className="rounded-2xl border border-border bg-surface p-4">
        <h3 className="mb-2 flex items-center gap-2 font-semibold">
          <ChromeGlyph name="enter" size={16} current className="text-chrome" /> {p.account}
        </h3>
        {!configured ? (
          <p className="text-xs text-text-secondary">
            {copy.profileLocalOnly}
          </p>
        ) : authUser ? (
          <div className="space-y-2 text-sm">
            <p>
              {authUser.email} · {p.status} {authUser.subscriptionStatus}
            </p>
            <div className="flex flex-wrap gap-2">
              <button
                type="button"
                disabled={busy}
                onClick={() => void syncNow()}
                className="inline-flex items-center gap-1 rounded-xl bg-surface-elevated px-3 py-2 text-xs font-medium"
              >
                <ChromeGlyph name="cloud" size={14} current /> {p.sync}
              </button>
              <button
                type="button"
                disabled={busy}
                onClick={() => void logout()}
                className="inline-flex items-center gap-1 rounded-xl bg-surface-elevated px-3 py-2 text-xs font-medium"
              >
                <ChromeGlyph name="enter" size={14} current /> {p.signOut}
              </button>
              <button
                type="button"
                disabled={busy}
                onClick={() => void deleteAccount()}
                className="inline-flex items-center gap-1 rounded-xl border border-error/50 px-3 py-2 text-xs font-medium text-error"
              >
                <ChromeGlyph name="trash" size={14} current /> {p.deleteAccount}
              </button>
            </div>
            {syncConflict && (
              <div className="mt-3">
                <SyncConflictPanel
                  conflict={syncConflict}
                  busy={busy}
                  onKeepRemote={() => void resolveConflict("keep_remote")}
                  onKeepLocal={() => void resolveConflict("keep_local")}
                  onDismiss={() => setSyncConflict(null)}
                />
              </div>
            )}
          </div>
        ) : (
          <AuthCard
            variant="embedded"
            onAuthed={refreshMe}
          />
        )}
        {authMsg && (
          <p className="mt-2 text-xs text-text-secondary">{authMsg}</p>
        )}
      </section>

      <ChromeLangPicker />

      <PublicProfilePanel />

      <section className="rounded-2xl border border-border bg-surface p-4">
        <h3 className="mb-2 flex items-center gap-2 font-semibold">
          <ChromeGlyph name="crown" size={16} current className="text-chrome" /> {p.plan}
        </h3>
        <p className="mb-3 text-xs text-text-secondary">
          {p.planHint}
        </p>
        <p className="mb-3 text-sm font-medium">
          {p.current}: {subscriptionTier === "pro" ? "Pro" : "Free"}
          {authUser ? ` (${authUser.subscriptionStatus})` : ` (${p.local})`}
        </p>
        {!isCommerceOpen() ? (
          <p className="text-xs text-text-secondary">
            {p.commerceClosed}
          </p>
        ) : authUser ? (
          <div className="grid grid-cols-2 gap-2">
            <button
              type="button"
              disabled={busy || subscriptionTier === "pro"}
              onClick={() => void startBilling("month")}
              className="rounded-xl bg-chrome py-2 text-sm font-medium text-on-accent disabled:opacity-40"
            >
              {p.proMonth}
            </button>
            <button
              type="button"
              disabled={busy || subscriptionTier === "pro"}
              onClick={() => void startBilling("year")}
              className="rounded-xl bg-chrome py-2 text-sm font-medium text-on-accent disabled:opacity-40"
            >
              {p.proYear}
            </button>
            {authUser.hasStripeCustomer && (
              <button
                type="button"
                disabled={busy}
                onClick={() => void openPortal()}
                className="col-span-2 rounded-xl bg-surface-elevated py-2 text-sm"
              >
                {p.managePortal}
              </button>
            )}
          </div>
        ) : (
          <p className="text-xs text-text-secondary">
            {p.upgradeSignIn}
          </p>
        )}
      </section>

      <section className="rounded-2xl border border-border bg-surface p-4">
        <h3 className="mb-2 font-semibold">{copy.profileDisciplines}</h3>
        <p className="mb-3 text-xs text-text-secondary">
          {copy.profileDisciplinesHint}
        </p>
        <div className="flex flex-wrap gap-2">
          {PROFILE_DISCIPLINES.map((d) => {
            const selected = preferredSports.includes(d);
            const primary = preferredSport === d;
            return (
              <button
                key={d}
                type="button"
                onClick={() => {
                  if (selected && !primary) {
                    setPrimarySport(d);
                    return;
                  }
                  togglePreferredSport(d);
                }}
                className={`rounded-full border px-3 py-1.5 text-sm font-semibold ${
                  selected
                    ? "border-chrome bg-chrome/15 text-chrome"
                    : "border-border bg-surface-elevated text-text-secondary"
                }`}
              >
                {primary
                  ? `★ ${rideSportLabel(d, lang)} · ${copy.profilePrimary}`
                  : rideSportLabel(d, lang)}
              </button>
            );
          })}
        </div>
        {preferredSport ? (
          <p className="mt-2 text-[11px] font-semibold text-text-secondary">
            {copy.profilePrimary}: {rideSportLabel(preferredSport, lang)}
            {preferredSports.filter((s) => s !== preferredSport).length
              ? ` · ${copy.profileAlso} ${preferredSports
                  .filter((s) => s !== preferredSport)
                  .map((s) => rideSportLabel(s, lang))
                  .join(", ")}`
              : ""}
          </p>
        ) : null}
      </section>

      <section className="rounded-2xl border border-border bg-surface p-4">
        <h3 className="mb-3 flex items-center gap-2 font-semibold">
          <ChromeGlyph name="user" size={16} current className="text-chrome" /> {copy.profileStyle}
        </h3>
        <label className="mb-3 block text-sm">
          {copy.profileStyle}
          <select
            value={profile.style}
            onChange={(e) =>
              updateRiderProfile({
                style: e.target.value as RiderProfile["style"],
              })
            }
            className="mt-1 w-full rounded-xl border border-border bg-surface-elevated px-3 py-2"
          >
            <option value="aggressive">{p.styleAggressive}</option>
            <option value="flow">{p.styleFlow}</option>
            <option value="efficient">{p.styleEfficient}</option>
            <option value="explorative">{p.styleExploring}</option>
          </select>
          <p className="mt-1 text-[11px] text-text-secondary">
            {p.explainStyle}
          </p>
        </label>
        <label className="mb-3 block text-sm">
          {p.skill(profile.skillLevel)}
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
            {p.explainSkill}
          </p>
        </label>
        <label className="block text-sm">
          {p.riderWeight}
          <input
            type="number"
            value={profile.riderWeightKg ?? 78}
            onChange={(e) =>
              updateRiderProfile({ riderWeightKg: Number(e.target.value) })
            }
            className="mt-1 w-full rounded-xl border border-border bg-surface-elevated px-3 py-2"
          />
          <p className="mt-1 text-[11px] text-text-secondary">
            {p.explainWeight}
          </p>
        </label>
      </section>

      <button
        type="button"
        onClick={() => setAdvanced((v) => !v)}
        className="rounded-xl border border-border bg-surface-elevated px-3 py-2 text-sm text-text-secondary"
      >
        {advanced ? p.advancedHide : p.advancedShow}
      </button>

      {advanced && (
      <section className="rounded-2xl border border-border bg-surface p-4">
        <h3 className="mb-3 font-semibold">{p.terrain}</h3>
        <p className="mb-2 text-[11px] text-text-secondary">
          {p.explainTerrain}
        </p>
        {(
          [
            ["s0s1", p.terrainS0],
            ["s2", p.terrainS2],
            ["s3plus", p.terrainS3],
            ["gravelRoad", p.terrainGravel],
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
        <h3 className="mb-3 font-semibold">{copy.profileStyleIndicators}</h3>
        <p className="mb-2 text-[11px] text-text-secondary">
            {p.explainIndicators}
        </p>
        {(
          [
            ["brakeIntensityBeforeCorners", p.brakeBeforeCorners],
            ["timeOver04gLateralPct", p.lateralG],
            ["impactsPerHour", p.impactsPerHour],
            ["jumpsPerRide", p.jumpsPerRide],
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
          <ChromeGlyph name="filter" size={16} current className="text-chrome" /> {p.preferences}
        </h3>
        {(
          [
            ["preferTechnical", p.preferTechnical],
            ["preferFlow", p.preferFlow],
            ["preferSteep", p.preferSteep],
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
                {key === "preferTechnical"
                  ? p.explainTechnical
                  : key === "preferFlow"
                    ? p.explainFlow
                    : p.explainSteep}
              </span>
            </span>
          </label>
        ))}
        <label className="mt-2 block text-sm">
          {p.eBikeAssist}
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
            <option value="eco">Eco</option>
            <option value="tour">Tour</option>
            <option value="sport">Sport</option>
            <option value="turbo">Turbo</option>
          </select>
          <p className="mt-1 text-[11px] text-text-secondary">
            {p.explainAssist}
          </p>
        </label>
      </section>

      {rangeCalibration && (
        <section className="rounded-2xl border border-border bg-surface p-4 text-sm">
          <h3 className="mb-2 font-semibold">{p.rangeTitle}</h3>
          <p className="text-xs text-text-secondary">
            Crr {rangeCalibration.crr.toFixed(4)} · CdA{" "}
            {rangeCalibration.cdA.toFixed(3)} · P_fahrer{" "}
            {Math.round(rangeCalibration.riderPowerW)} W · n=
            {rangeCalibration.samples}
          </p>
        </section>
      )}

      <section className="rounded-2xl border border-border bg-surface p-4">
        <h3 className="font-semibold">{copy.profileBikesAtStand}</h3>
        {bikes.length === 0 ? (
          <p className="mt-2 text-sm text-text-secondary">
            {copy.noBikeHere} · {copy.profileNoKpi}
          </p>
        ) : (
          <ul className="mt-2 space-y-1 text-sm">
            {bikes.map((b) => (
              <li key={b.id} className="text-text-secondary">
                {b.name}
                {b.isActive ? ` · ${p.bikeFront}` : ""}
              </li>
            ))}
          </ul>
        )}
        <Link
          href="/home"
          className="mt-3 inline-block text-sm font-semibold text-chrome hover:underline"
        >
          {copy.profileArrive} →
        </Link>
      </section>

      {recentEnded.length > 0 ? (
        <section className="rounded-2xl border border-border bg-surface p-4">
          <h3 className="font-semibold">{copy.activitiesTitle}</h3>
          <p className="mt-1 text-xs text-text-secondary">{copy.activitiesHint}</p>
          <ul className="mt-3 space-y-3">
            {recentEnded.map((r) => {
              const telemetry = buildRideTelemetry(r.track);
              return (
                <li key={r.id}>
                  <Link
                    href={`/activities/${r.id}`}
                    className="block rounded-xl border border-border/60 px-3 py-2 hover:border-chrome/40"
                  >
                    <div className="flex items-baseline justify-between gap-2 text-sm">
                      <span className="tabular-nums">
                        {(r.distanceM / 1000).toFixed(1)} {tel.km}
                        {telemetry.channels.elev
                          ? ` · ${telemetry.climbM} ${tel.hm}`
                          : r.elevationGainM >= 10
                            ? ` · ${Math.round(r.elevationGainM)} ${tel.hm}`
                            : ""}
                      </span>
                      <span className="text-xs text-text-secondary">
                        {new Date(r.startTime).toLocaleDateString(dateLocale)}
                      </span>
                    </div>
                    <RideTerrainPeek
                      telemetry={telemetry}
                      caption={terrainCaption(telemetry, tel.hm)}
                      className="mt-2"
                    />
                  </Link>
                </li>
              );
            })}
          </ul>
          <Link
            href="/activities"
            className="mt-3 inline-block text-sm font-semibold text-chrome hover:underline"
          >
            {tel.backToList}
          </Link>
        </section>
      ) : null}

      <section className="rounded-2xl border border-border bg-surface p-4">
        <h3 className="font-semibold">{tel.profileMore}</h3>
        <p className="mt-1 text-xs text-text-secondary">{tel.profileMoreHint}</p>
        <ul className="mt-3 space-y-2 text-sm">
          <li>
            <Link href="/activities" className="font-semibold text-chrome hover:underline">
              {copy.activitiesTitle}
            </Link>
            <span className="block text-xs text-text-secondary">
              {copy.activitiesHint}
            </span>
          </li>
          <li>
            <Link href="/library" className="font-semibold text-chrome hover:underline">
              {copy.libraryKicker}
            </Link>
            <span className="block text-xs text-text-secondary">
              {copy.libraryHint}
            </span>
          </li>
          <li>
            <Link href="/chat" className="font-semibold text-chrome hover:underline">
              {tel.assistant}
            </Link>
            <span className="block text-xs text-text-secondary">
              {copy.chatHint}
            </span>
          </li>
          <li>
            <Link href="/privacy" className="font-semibold text-chrome hover:underline">
              {copy.privacyTitle}
            </Link>
            <span className="block text-xs text-text-secondary">
              {copy.privacyHint}
            </span>
          </li>
        </ul>
      </section>
    </div>
  );
}
