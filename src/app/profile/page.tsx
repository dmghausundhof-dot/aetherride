"use client";

import { useAppStore } from "@/store/useAppStore";
import { User, Sparkles, Crown } from "lucide-react";
import Link from "next/link";
import type { RiderProfile } from "@/types";

export default function ProfilePage() {
  const profile = useAppStore((s) => s.riderProfile);
  const explanations = useAppStore((s) => s.profileExplanations);
  const updateRiderProfile = useAppStore((s) => s.updateRiderProfile);
  const subscriptionTier = useAppStore((s) => s.subscriptionTier);
  const setSubscriptionTier = useAppStore((s) => s.setSubscriptionTier);
  const rides = useAppStore((s) => s.rides);
  const bikes = useAppStore((s) => s.bikes);
  const rangeCalibration = useAppStore((s) => s.rangeCalibration);
  const appMode = useAppStore((s) => s.appMode);
  const setAppMode = useAppStore((s) => s.setAppMode);

  const setPref = (key: keyof RiderProfile["preferences"], value: boolean) => {
    updateRiderProfile({
      preferences: { ...profile.preferences, [key]: value },
    });
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
            Erklärbar & korrigierbar (F-AI-002)
          </p>
        </div>
      </header>

      <section className="rounded-2xl border border-border bg-surface p-4">
        <h3 className="mb-2 font-semibold">App-Modus</h3>
        <div className="grid grid-cols-2 gap-2">
          <button
            type="button"
            onClick={() => setAppMode("bike")}
            className={`rounded-xl py-2 text-sm ${
              appMode === "bike" ? "bg-accent text-white" : "bg-surface-elevated"
            }`}
          >
            Bike
          </button>
          <button
            type="button"
            onClick={() => setAppMode("hiking")}
            className={`rounded-xl py-2 text-sm ${
              appMode === "hiking" ? "bg-accent text-white" : "bg-surface-elevated"
            }`}
          >
            Wandern
          </button>
        </div>
        <p className="mt-2 text-[11px] text-text-secondary">
          Wandern blendet Fahrwerk, Bracketing, Shop-Teile aus (Spec 2.8).
        </p>
        <Link href="/privacy" className="mt-2 inline-block text-xs text-accent">
          Konto · Export · Privatsphäre
        </Link>
      </section>

      <section className="rounded-2xl border border-border bg-surface p-4">
        <h3 className="mb-2 flex items-center gap-2 font-semibold">
          <Crown className="h-4 w-4 text-accent" /> Abo
        </h3>
        <p className="mb-3 text-xs text-text-secondary">
          Free: 1 Bike, Basis. Pro: Multi-Bike, Bracketing, Offline, Reichweite
          (Spec 1.4 — Demo-Toggle).
        </p>
        <div className="grid grid-cols-2 gap-2">
          <button
            type="button"
            onClick={() => setSubscriptionTier("free")}
            className={`rounded-xl py-2 text-sm font-medium ${
              subscriptionTier === "free"
                ? "bg-accent text-white"
                : "bg-surface-elevated"
            }`}
          >
            Free
          </button>
          <button
            type="button"
            onClick={() => setSubscriptionTier("pro")}
            className={`rounded-xl py-2 text-sm font-medium ${
              subscriptionTier === "pro"
                ? "bg-accent text-white"
                : "bg-surface-elevated"
            }`}
          >
            Pro 6,99 €/Mo
          </button>
        </div>
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
            <option value="aggressive">aggressive</option>
            <option value="flow">flow</option>
            <option value="efficient">efficient</option>
            <option value="explorative">explorative</option>
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

      <section className="rounded-2xl border border-border bg-surface p-4">
        <h3 className="mb-3 font-semibold">Terrainanteil (korrigierbar)</h3>
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
        KI-Chat (Engines + Numeric-Guard) →
      </Link>
      <Link href="/" className="text-center text-sm text-accent">
        ← Zurück
      </Link>
    </div>
  );
}
