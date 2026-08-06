"use client";

import { useMemo, useState } from "react";
import {
  Download,
  FileJson,
  Map as MapIcon,
  Shield,
  Users,
} from "lucide-react";
import { useAppStore } from "@/store/useAppStore";
import {
  downloadText,
  fullJsonExport,
  rideToGpx,
  rideToStravaActivityStub,
} from "@/lib/export/gpx";
import { downloadBytes, rideToFit } from "@/lib/export/fit";
import {
  CONSENT_LABELS,
  type ConsentPurpose,
} from "@/lib/privacy/consents";
import Link from "next/link";

export default function PrivacyExportPage() {
  const rides = useAppStore((s) => s.rides);
  const bikes = useAppStore((s) => s.bikes);
  const profile = useAppStore((s) => s.riderProfile);
  const consents = useAppStore((s) => s.consents);
  const setConsent = useAppStore((s) => s.setConsent);
  const privacyZones = useAppStore((s) => s.privacyZones);
  const addPrivacyZone = useAppStore((s) => s.addPrivacyZone);
  const removePrivacyZone = useAppStore((s) => s.removePrivacyZone);
  const familyRiders = useAppStore((s) => s.familyRiders);
  const addFamilyRider = useAppStore((s) => s.addFamilyRider);
  const activeFamilyRiderId = useAppStore((s) => s.activeFamilyRiderId);
  const setActiveFamilyRider = useAppStore((s) => s.setActiveFamilyRider);
  const assignSetupToRider = useAppStore((s) => s.assignSetupToRider);

  const [riderName, setRiderName] = useState("");
  const [riderWeight, setRiderWeight] = useState(70);
  const lastRide = rides[0];
  const activeBike = bikes.find((b) => b.isActive) || bikes[0];

  const jsonPreview = useMemo(
    () =>
      fullJsonExport({
        bikes,
        rides: rides.slice(0, 3),
        profile,
      }).slice(0, 400) + "…",
    [bikes, rides, profile]
  );

  return (
    <div className="flex flex-col gap-5 p-4 pt-6">
      <header>
        <h1 className="text-2xl font-bold">Daten & Privatsphäre</h1>
        <p className="text-sm text-text-secondary">
          F-ACC-003/005/006/007 · Export · Zonen · Familie
        </p>
      </header>

      <section className="rounded-2xl border border-border bg-surface p-4">
        <h3 className="mb-2 flex items-center gap-2 font-semibold">
          <Download className="h-4 w-4 text-accent" /> Export (Art. 20)
        </h3>
        <div className="flex flex-col gap-2">
          <button
            type="button"
            disabled={!lastRide}
            onClick={() => {
              if (!lastRide) return;
              const gpx = rideToGpx(lastRide, activeBike?.name);
              downloadText(
                `aetherride-${lastRide.id.slice(0, 8)}.gpx`,
                gpx,
                "application/gpx+xml"
              );
            }}
            className="rounded-xl bg-accent py-2.5 text-sm font-semibold text-white disabled:opacity-40"
          >
            Letzten Ride als GPX
          </button>
          <button
            type="button"
            onClick={() => {
              const json = fullJsonExport({ bikes, rides, profile });
              downloadText(
                "aetherride-export.json",
                json,
                "application/json"
              );
            }}
            className="flex items-center justify-center gap-2 rounded-xl border border-border py-2.5 text-sm"
          >
            <FileJson className="h-4 w-4" /> JSON-Vollexport
          </button>
          <button
            type="button"
            disabled={!lastRide}
            onClick={() => {
              if (!lastRide) return;
              const fit = rideToFit(lastRide);
              downloadBytes(
                `aetherride-${lastRide.id.slice(0, 8)}.fit`,
                fit,
                "application/octet-stream"
              );
            }}
            className="rounded-xl border border-border py-2.5 text-sm disabled:opacity-40"
          >
            Letzten Ride als FIT
          </button>
          <button
            type="button"
            disabled={!lastRide}
            onClick={() => {
              if (!lastRide) return;
              const stub = rideToStravaActivityStub(lastRide);
              downloadText(
                "strava-activity-payload.json",
                JSON.stringify(stub, null, 2),
                "application/json"
              );
            }}
            className="rounded-xl border border-border py-2.5 text-sm disabled:opacity-40"
          >
            Strava-Payload (ohne OAuth — spätere Anbindung)
          </button>
        </div>
        <pre className="mt-3 max-h-24 overflow-auto rounded-lg bg-surface-elevated p-2 text-[10px] text-text-secondary">
          {jsonPreview}
        </pre>
      </section>

      <section className="rounded-2xl border border-border bg-surface p-4">
        <h3 className="mb-2 flex items-center gap-2 font-semibold">
          <Shield className="h-4 w-4 text-accent" /> Einwilligungen
        </h3>
        {consents.map((c) => (
          <label
            key={c.purpose}
            className="mb-3 flex items-start gap-2 text-sm"
          >
            <input
              type="checkbox"
              className="mt-1"
              checked={c.granted}
              onChange={(e) =>
                setConsent(c.purpose as ConsentPurpose, e.target.checked)
              }
            />
            <span>
              <span className="font-medium">
                {CONSENT_LABELS[c.purpose].title}
              </span>
              <span className="mt-0.5 block text-[11px] text-text-secondary">
                {CONSENT_LABELS[c.purpose].description}
              </span>
              <span className="text-[10px] text-text-secondary">
                Policy {c.policyVersion} ·{" "}
                {new Date(c.updatedAt).toLocaleString("de-DE")}
              </span>
            </span>
          </label>
        ))}
      </section>

      <section className="rounded-2xl border border-border bg-surface p-4">
        <h3 className="mb-2 flex items-center gap-2 font-semibold">
          <MapIcon className="h-4 w-4 text-accent" /> Privatsphärenzonen
        </h3>
        <p className="mb-2 text-xs text-text-secondary">
          Tracks werden in diesen Radien für Heatmap/Export gekappt (Strava-Lehre).
        </p>
        {privacyZones.map((z) => (
          <div
            key={z.id}
            className="mb-2 flex items-center justify-between rounded-xl bg-surface-elevated px-3 py-2 text-sm"
          >
            <span>
              {z.label} · {z.radiusM} m · {z.lat.toFixed(3)}, {z.lng.toFixed(3)}
            </span>
            <button
              type="button"
              className="text-xs text-error"
              onClick={() => removePrivacyZone(z.id)}
            >
              Entfernen
            </button>
          </div>
        ))}
        <button
          type="button"
          onClick={() =>
            addPrivacyZone({
              label: "Arbeit",
              lat: 47.452,
              lng: 12.16,
              radiusM: 150,
            })
          }
          className="mt-1 text-sm text-accent"
        >
          + Demo-Zone „Arbeit“
        </button>
      </section>

      <section className="rounded-2xl border border-border bg-surface p-4">
        <h3 className="mb-2 flex items-center gap-2 font-semibold">
          <Users className="h-4 w-4 text-accent" /> Familien-Garage (P3)
        </h3>
        <p className="mb-2 text-xs text-text-secondary">
          Ein Bike, mehrere Fahrer mit eigenen Setups (F-ACC-007).
        </p>
        {familyRiders.map((r) => (
          <button
            key={r.id}
            type="button"
            onClick={() => setActiveFamilyRider(r.id)}
            className={`mb-2 w-full rounded-xl border px-3 py-2 text-left text-sm ${
              activeFamilyRiderId === r.id
                ? "border-accent bg-accent/10"
                : "border-border"
            }`}
          >
            {r.displayName} · {r.weightKg} kg · {r.setupIds.length} Setups
          </button>
        ))}
        <div className="mt-2 flex gap-2">
          <input
            value={riderName}
            onChange={(e) => setRiderName(e.target.value)}
            placeholder="Name"
            className="flex-1 rounded-xl border border-border bg-surface-elevated px-3 py-2 text-sm"
          />
          <input
            type="number"
            value={riderWeight}
            onChange={(e) => setRiderWeight(Number(e.target.value))}
            className="w-20 rounded-xl border border-border bg-surface-elevated px-2 py-2 text-sm"
          />
          <button
            type="button"
            onClick={() => {
              if (!riderName.trim()) return;
              const id = addFamilyRider(riderName.trim(), riderWeight);
              const setup = activeBike?.setups.find((s) => s.isCurrent);
              if (setup) assignSetupToRider(id, setup.id);
              setRiderName("");
            }}
            className="rounded-xl bg-accent px-3 text-sm font-medium text-white"
          >
            +
          </button>
        </div>
      </section>

      <Link href="/profile" className="text-center text-sm text-accent">
        ← Profil
      </Link>
    </div>
  );
}
