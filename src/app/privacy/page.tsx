"use client";

import { useEffect, useMemo, useState } from "react";
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
  rideHasExportableTrack,
  rideToStravaActivityStub,
} from "@/lib/export/gpx";
import { downloadBytes, rideToFit } from "@/lib/export/fit";
import {
  CONSENT_LABELS,
  type ConsentPurpose,
} from "@/lib/privacy/consents";
import Link from "next/link";
import { useHofCopy } from "@/hooks/useHofCopy";
import { HofPageHeader } from "@/components/hof/HofPageHeader";

export default function PrivacyExportPage() {
  const copy = useHofCopy();

  const rides = useAppStore((s) => s.rides);
  const bikes = useAppStore((s) => s.bikes);
  const profile = useAppStore((s) => s.riderProfile);
  const consents = useAppStore((s) => s.consents);
  const setConsent = useAppStore((s) => s.setConsent);
  const [stravaConfigured, setStravaConfigured] = useState(false);
  const [stravaAuthorizeUrl, setStravaAuthorizeUrl] = useState<string | null>(
    null
  );
  const [stravaConnected, setStravaConnected] = useState(false);
  const [stravaStatusMsg, setStravaStatusMsg] = useState<string | null>(null);
  const [stravaBusy, setStravaBusy] = useState(false);
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

  useEffect(() => {
    const flag = new URLSearchParams(window.location.search).get("strava");
    if (flag === "connected") {
      setStravaConnected(true);
      setStravaStatusMsg("Strava verbunden.");
    } else if (flag === "not_configured") {
      setStravaStatusMsg("Strava OAuth nicht konfiguriert.");
    } else if (flag) {
      setStravaStatusMsg(`Strava: ${flag}`);
    }
    if (document.cookie.includes("strava_connected=1")) {
      setStravaConnected(true);
    }
  }, []);

  useEffect(() => {
    let cancelled = false;
    void fetch("/api/strava/status")
      .then((r) => r.json())
      .then((data: { configured?: boolean; connected?: boolean }) => {
        if (cancelled) return;
        if (data.configured) setStravaConfigured(true);
        if (data.connected) setStravaConnected(true);
      })
      .catch(() => {});
    void fetch("/api/strava")
      .then((r) => r.json())
      .then(
        (data: {
          configured?: boolean;
          authorizeUrl?: string;
          message?: string;
        }) => {
          if (cancelled) return;
          setStravaConfigured(Boolean(data.configured));
          setStravaAuthorizeUrl(data.authorizeUrl ?? null);
          if (!data.configured && data.message) {
            setStravaStatusMsg((prev) => prev ?? data.message!);
          }
        }
      )
      .catch(() => {
        if (!cancelled) setStravaConfigured(false);
      });
    return () => {
      cancelled = true;
    };
  }, []);

  async function uploadLastRideToStrava() {
    if (!lastRide) return;
    setStravaBusy(true);
    setStravaStatusMsg(null);
    try {
      const stub = rideToStravaActivityStub(lastRide) as {
        name?: string;
        type?: string;
        sport_type?: string;
        start_date_local?: string;
        elapsed_time?: number;
        distance?: number;
        total_elevation_gain?: number;
        description?: string;
      };
      const gpx = rideHasExportableTrack(lastRide)
        ? rideToGpx(lastRide, activeBike?.name)
        : undefined;
      const res = await fetch("/api/strava/upload", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          name: stub.name,
          type: stub.type,
          sport_type: stub.sport_type,
          start_date_local: stub.start_date_local,
          elapsed_time: stub.elapsed_time,
          distance: stub.distance,
          total_elevation_gain: stub.total_elevation_gain,
          description: stub.description,
          ...(gpx ? { gpx } : {}),
        }),
      });
      const data = (await res.json()) as {
        ok?: boolean;
        message?: string;
        error?: string;
        mode?: string;
        warning?: string;
      };
      if (!res.ok) {
        setStravaStatusMsg(data.message || data.error || `Upload ${res.status}`);
        return;
      }
      if (data.mode === "gpx_upload") {
        setStravaStatusMsg("Bei Strava hochgeladen (mit Track).");
      } else {
        setStravaStatusMsg(
          data.warning || "Bei Strava hochgeladen (nur Metadaten)."
        );
      }
    } catch (e) {
      setStravaStatusMsg(e instanceof Error ? e.message : "Upload fehlgeschlagen");
    } finally {
      setStravaBusy(false);
    }
  }

  return (
    <div className="flex flex-col gap-5 p-4 pt-6">
      <header>
        <HofPageHeader
          kicker={copy.privacyKicker}
          title={copy.privacyTitle}
          hint={copy.privacyHint}
        />
      </header>

      <section className="rounded-2xl border border-border bg-surface p-4">
        <h3 className="mb-2 flex items-center gap-2 font-semibold">
          <Download className="h-4 w-4 text-chrome" /> Export (Art. 20)
        </h3>
        <div className="flex flex-col gap-2">
          <button
            type="button"
            disabled={!lastRide}
            onClick={() => {
              if (!lastRide) return;
              if (!rideHasExportableTrack(lastRide)) {
                window.alert(
                  "Dieser Ride hat keinen GPS-Track — GPX wäre leer. JSON-Export nutzen."
                );
                return;
              }
              const gpx = rideToGpx(lastRide, activeBike?.name);
              downloadText(
                `aetherride-${lastRide.id.slice(0, 8)}.gpx`,
                gpx,
                "application/gpx+xml"
              );
            }}
            className="rounded-xl bg-accent py-2.5 text-sm font-semibold text-on-accent disabled:opacity-40"
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
          {stravaConfigured ? (
            <>
              <p className="rounded-xl border border-border px-3 py-2 text-xs">
                Status:{" "}
                <strong>
                  {stravaConnected ? "verbunden" : "konfiguriert, nicht verbunden"}
                </strong>
              </p>
              {stravaAuthorizeUrl && !stravaConnected && (
                <a
                  href={stravaAuthorizeUrl}
                  className="rounded-xl bg-accent py-2.5 text-center text-sm font-semibold text-on-accent"
                >
                  Mit Strava verbinden
                </a>
              )}
              {stravaConnected && (
                <button
                  type="button"
                  disabled={!lastRide || stravaBusy}
                  onClick={() => void uploadLastRideToStrava()}
                  className="rounded-xl bg-accent py-2.5 text-sm font-semibold text-on-accent disabled:opacity-40"
                >
                  {stravaBusy ? "Lade hoch…" : "Letzten Ride zu Strava"}
                </button>
              )}
              <details className="rounded-xl border border-border px-3 py-2">
                <summary className="cursor-pointer text-xs text-text-secondary">
                  Advanced — Stub-Export
                </summary>
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
                  className="mt-2 w-full rounded-xl border border-border py-2.5 text-sm disabled:opacity-40"
                >
                  Strava-Payload (Stub JSON)
                </button>
                <p className="mt-1 text-[10px] text-text-secondary">
                  Lokaler Dev-/QA-Export — kein Live-Upload.
                </p>
              </details>
            </>
          ) : (
            <p className="rounded-xl border border-dashed border-border px-3 py-2.5 text-xs text-text-secondary">
              Strava Live-Upload braucht{" "}
              <code className="text-[10px]">STRAVA_CLIENT_ID</code> /{" "}
              <code className="text-[10px]">SECRET</code> und Tabelle{" "}
              <code className="text-[10px]">strava_connections</code>. Bis dahin:
              GPX/FIT.
            </p>
          )}
          {!stravaConfigured && lastRide && (
            <details className="rounded-xl border border-border px-3 py-2">
              <summary className="cursor-pointer text-xs text-text-secondary">
                Advanced — Stub-Export
              </summary>
              <button
                type="button"
                onClick={() => {
                  const stub = rideToStravaActivityStub(lastRide);
                  downloadText(
                    "strava-activity-payload.json",
                    JSON.stringify(stub, null, 2),
                    "application/json"
                  );
                }}
                className="mt-2 w-full rounded-xl border border-border py-2.5 text-sm"
              >
                Strava-Payload (Stub JSON)
              </button>
              <p className="mt-1 text-[10px] text-text-secondary">
                Lokaler Dev-/QA-Export — kein Live-Upload.
              </p>
            </details>
          )}
          {stravaStatusMsg && (
            <p className="text-xs text-text-secondary">{stravaStatusMsg}</p>
          )}
        </div>
        <pre className="mt-3 max-h-24 overflow-auto rounded-lg bg-surface-elevated p-2 text-[10px] text-text-secondary">
          {jsonPreview}
        </pre>
      </section>

      <section className="rounded-2xl border border-border bg-surface p-4">
        <h3 className="mb-2 flex items-center gap-2 font-semibold">
          <Shield className="h-4 w-4 text-chrome" /> Einwilligungen
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
          <MapIcon className="h-4 w-4 text-chrome" /> Privatsphärenzonen
        </h3>
        <p className="mb-2 text-xs text-text-secondary">
          Tracks werden in diesen Radien gekappt — für Export und wo viele fahren.
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
          className="mt-1 text-sm text-chrome"
        >
          + Beispiel-Zone „Arbeit“
        </button>
      </section>

      <section className="rounded-2xl border border-border bg-surface p-4">
        <h3 className="mb-2 flex items-center gap-2 font-semibold">
          <Users className="h-4 w-4 text-chrome" /> Familien-Garage
        </h3>
        <p className="mb-2 text-xs text-text-secondary">
          Ein Bike, mehrere Fahrer mit eigenen Setups.
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
            className="rounded-xl bg-accent px-3 text-sm font-medium text-on-accent"
          >
            +
          </button>
        </div>
      </section>

      <Link href="/profile" className="text-center text-sm text-chrome">
        ← Profil
      </Link>
    </div>
  );
}
