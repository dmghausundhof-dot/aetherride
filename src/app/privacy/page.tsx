"use client";

import { useEffect, useMemo, useState } from "react";
import { ChromeGlyph } from "@/components/chrome/ChromeGlyph";
import { useAppStore } from "@/store/useAppStore";
import {
  downloadText,
  fullJsonExport,
  rideToGpx,
  rideHasExportableTrack,
  rideToStravaActivityStub,
} from "@/lib/export/gpx";
import { downloadBytes, rideToFit } from "@/lib/export/fit";
import { type ConsentPurpose } from "@/lib/privacy/consents";
import { rideWithTrimmedTrack } from "@/lib/privacy/trimRide";
import Link from "next/link";
import { useHofCopy } from "@/hooks/useHofCopy";
import { useChromeLang } from "@/hooks/useChromeLang";
import { chromeDateLocale } from "@/lib/i18n/chromeLang";
import {
  privacyCopy,
  presentPrivacyStatus,
} from "@/lib/i18n/privacyCopy";
import { HofPageHeader } from "@/components/hof/HofPageHeader";

export default function PrivacyExportPage() {
  const copy = useHofCopy();
  const lang = useChromeLang();
  const p = privacyCopy(lang);
  const dateLocale = chromeDateLocale(lang);

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
  const privacyTrimEnds = useAppStore((s) => s.privacyTrimEnds);
  const setPrivacyTrimEnds = useAppStore((s) => s.setPrivacyTrimEnds);
  const familyRiders = useAppStore((s) => s.familyRiders);
  const addFamilyRider = useAppStore((s) => s.addFamilyRider);
  const activeFamilyRiderId = useAppStore((s) => s.activeFamilyRiderId);
  const setActiveFamilyRider = useAppStore((s) => s.setActiveFamilyRider);
  const assignSetupToRider = useAppStore((s) => s.assignSetupToRider);

  const [riderName, setRiderName] = useState("");
  const [riderWeight, setRiderWeight] = useState(70);
  const [zoneLabel, setZoneLabel] = useState("");
  const [zoneLat, setZoneLat] = useState("");
  const [zoneLng, setZoneLng] = useState("");
  const [zoneRadiusM, setZoneRadiusM] = useState(500);
  const [zoneError, setZoneError] = useState<string | null>(null);
  const lastRide = rides[0];
  const activeBike = bikes.find((b) => b.isActive) || bikes[0];
  const trimEndsM = privacyTrimEnds ? 200 : 0;

  const jsonPreview = useMemo(
    () =>
      fullJsonExport({
        bikes,
        rides: rides
          .slice(0, 3)
          .map((r) => rideWithTrimmedTrack(r, privacyZones, trimEndsM)),
        profile,
      }).slice(0, 400) + "…",
    [bikes, rides, profile, privacyZones, trimEndsM]
  );

  useEffect(() => {
    const flag = new URLSearchParams(window.location.search).get("strava");
    if (flag === "connected") {
      setStravaConnected(true);
      setStravaStatusMsg(p.stravaLinked);
    } else if (flag === "not_configured") {
      setStravaStatusMsg(p.stravaOauthOff);
    } else if (flag) {
      setStravaStatusMsg(`Strava: ${flag}`);
    }
    if (document.cookie.includes("strava_connected=1")) {
      setStravaConnected(true);
    }
  }, [p.stravaLinked, p.stravaOauthOff]);

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
            setStravaStatusMsg(
              (prev) => prev ?? presentPrivacyStatus(data.message!, lang)
            );
          }
        }
      )
      .catch(() => {
        if (!cancelled) setStravaConfigured(false);
      });
    return () => {
      cancelled = true;
    };
  }, [lang]);

  async function uploadLastRideToStrava() {
    if (!lastRide) return;
    setStravaBusy(true);
    setStravaStatusMsg(null);
    try {
      const forUpload = rideWithTrimmedTrack(lastRide, privacyZones, trimEndsM);
      const stub = rideToStravaActivityStub(forUpload) as {
        name?: string;
        type?: string;
        sport_type?: string;
        start_date_local?: string;
        elapsed_time?: number;
        distance?: number;
        total_elevation_gain?: number;
        description?: string;
      };
      const gpx = rideHasExportableTrack(forUpload)
        ? rideToGpx(forUpload, activeBike?.name)
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
        setStravaStatusMsg(
          presentPrivacyStatus(
            data.message || data.error || p.uploadFailed,
            lang
          )
        );
        return;
      }
      if (data.mode === "gpx_upload") {
        setStravaStatusMsg(p.uploadedGpx);
      } else {
        setStravaStatusMsg(
          data.warning
            ? presentPrivacyStatus(data.warning, lang)
            : p.uploadedMeta
        );
      }
    } catch (e) {
      setStravaStatusMsg(
        e instanceof Error
          ? presentPrivacyStatus(e.message, lang)
          : p.uploadFailed
      );
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
          <ChromeGlyph name="download" size={16} current className="text-chrome" />{" "}
          {p.exportTitle}
        </h3>
        <div className="flex flex-col gap-2">
          <button
            type="button"
            disabled={!lastRide}
            onClick={() => {
              if (!lastRide) return;
              if (!rideHasExportableTrack(lastRide)) {
                window.alert(p.gpxEmpty);
                return;
              }
              const gpx = rideToGpx(
                rideWithTrimmedTrack(lastRide, privacyZones, trimEndsM),
                activeBike?.name
              );
              downloadText(
                `aetherride-${lastRide.id.slice(0, 8)}.gpx`,
                gpx,
                "application/gpx+xml"
              );
            }}
            className="rounded-xl bg-accent py-2.5 text-sm font-semibold text-on-accent disabled:opacity-40"
          >
            {p.exportGpx}
          </button>
          <button
            type="button"
            onClick={() => {
              const json = fullJsonExport({
                bikes,
                rides: rides.map((r) =>
                  rideWithTrimmedTrack(r, privacyZones, trimEndsM)
                ),
                profile,
              });
              downloadText(
                "aetherride-export.json",
                json,
                "application/json"
              );
            }}
            className="flex items-center justify-center gap-2 rounded-xl border border-border py-2.5 text-sm"
          >
            <ChromeGlyph name="download" size={16} current /> {p.exportJson}
          </button>
          <button
            type="button"
            disabled={!lastRide}
            onClick={() => {
              if (!lastRide) return;
              const fit = rideToFit(
                rideWithTrimmedTrack(lastRide, privacyZones, trimEndsM)
              );
              downloadBytes(
                `aetherride-${lastRide.id.slice(0, 8)}.fit`,
                fit,
                "application/octet-stream"
              );
            }}
            className="rounded-xl border border-border py-2.5 text-sm disabled:opacity-40"
          >
            {p.exportFit}
          </button>
          {stravaConfigured ? (
            <>
              <p className="rounded-xl border border-border px-3 py-2 text-xs">
                {p.stravaStatus(
                  stravaConnected ? p.stravaConnected : p.stravaConfiguredOff
                )}
              </p>
              {stravaAuthorizeUrl && !stravaConnected && (
                <a
                  href={stravaAuthorizeUrl}
                  className="rounded-xl bg-accent py-2.5 text-center text-sm font-semibold text-on-accent"
                >
                  {p.stravaConnect}
                </a>
              )}
              {stravaConnected && (
                <button
                  type="button"
                  disabled={!lastRide || stravaBusy}
                  onClick={() => void uploadLastRideToStrava()}
                  className="rounded-xl bg-accent py-2.5 text-sm font-semibold text-on-accent disabled:opacity-40"
                >
                  {stravaBusy ? p.stravaUploading : p.stravaUpload}
                </button>
              )}
              <details className="rounded-xl border border-border px-3 py-2">
                <summary className="cursor-pointer text-xs text-text-secondary">
                  {p.stubSummary}
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
                  {p.exportStub}
                </button>
                <p className="mt-1 text-[10px] text-text-secondary">
                  {p.stubLocal}
                </p>
              </details>
            </>
          ) : (
            <p className="rounded-xl border border-dashed border-border px-3 py-2.5 text-xs text-text-secondary">
              {p.stravaMissing}
            </p>
          )}
          {!stravaConfigured && lastRide && (
            <details className="rounded-xl border border-border px-3 py-2">
              <summary className="cursor-pointer text-xs text-text-secondary">
                {p.stubSummary}
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
                {p.exportStub}
              </button>
              <p className="mt-1 text-[10px] text-text-secondary">
                {p.stubLocal}
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
          <ChromeGlyph name="shield" size={16} current className="text-chrome" />{" "}
          {p.consents}
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
                {p.consent[c.purpose as ConsentPurpose].title}
              </span>
              <span className="mt-0.5 block text-[11px] text-text-secondary">
                {p.consent[c.purpose as ConsentPurpose].description}
              </span>
              <span className="text-[10px] text-text-secondary">
                {p.policy(c.policyVersion)} ·{" "}
                {new Date(c.updatedAt).toLocaleString(dateLocale)}
              </span>
            </span>
          </label>
        ))}
      </section>

      <section className="rounded-2xl border border-border bg-surface p-4">
        <h3 className="mb-2 flex items-center gap-2 font-semibold">
          <ChromeGlyph name="karte" size={16} current className="text-chrome" />{" "}
          {p.zones}
        </h3>
        <p className="mb-2 text-xs text-text-secondary">{p.zonesLead}</p>
        <label className="mb-3 flex items-start gap-2 text-sm">
          <input
            type="checkbox"
            className="mt-1"
            checked={privacyTrimEnds}
            onChange={(e) => setPrivacyTrimEnds(e.target.checked)}
          />
          <span>
            <span className="font-medium">{p.trimEndsTitle}</span>
            <span className="mt-0.5 block text-[11px] text-text-secondary">
              {p.trimEndsBody}
            </span>
          </span>
        </label>
        {privacyZones.length === 0 ? (
          <p className="mb-2 text-sm text-text-secondary">{p.noZonesWeb}</p>
        ) : (
          privacyZones.map((z) => (
            <div
              key={z.id}
              className="mb-2 flex items-center justify-between rounded-xl bg-surface-elevated px-3 py-2 text-sm"
            >
              <span>
                {z.label} · {z.radiusM} m · {z.lat.toFixed(3)},{" "}
                {z.lng.toFixed(3)}
              </span>
              <button
                type="button"
                className="text-xs text-error"
                onClick={() => removePrivacyZone(z.id)}
              >
                {p.zoneDelete}
              </button>
            </div>
          ))
        )}
        <div className="mt-3 space-y-2 rounded-xl border border-border p-3">
          <p className="text-xs font-semibold">{p.zoneAdd}</p>
          <input
            value={zoneLabel}
            onChange={(e) => setZoneLabel(e.target.value)}
            placeholder={p.zoneLabel}
            className="w-full rounded-xl border border-border bg-surface-elevated px-3 py-2 text-sm"
          />
          <div className="flex flex-wrap gap-1.5">
            {(
              [
                [200, p.zoneRadius200],
                [500, p.zoneRadius500],
                [1000, p.zoneRadius1000],
              ] as const
            ).map(([m, label]) => (
              <button
                key={m}
                type="button"
                onClick={() => setZoneRadiusM(m)}
                className={`rounded-lg border px-2.5 py-1 text-xs ${
                  zoneRadiusM === m
                    ? "border-accent bg-accent/10 font-semibold"
                    : "border-border"
                }`}
              >
                {label}
              </button>
            ))}
          </div>
          <div className="flex gap-2">
            <input
              value={zoneLat}
              onChange={(e) => setZoneLat(e.target.value)}
              placeholder={p.zoneLat}
              inputMode="decimal"
              className="w-1/2 rounded-xl border border-border bg-surface-elevated px-3 py-2 text-sm"
            />
            <input
              value={zoneLng}
              onChange={(e) => setZoneLng(e.target.value)}
              placeholder={p.zoneLng}
              inputMode="decimal"
              className="w-1/2 rounded-xl border border-border bg-surface-elevated px-3 py-2 text-sm"
            />
          </div>
          <div className="flex flex-wrap gap-2">
            <button
              type="button"
              className="rounded-xl border border-border px-3 py-2 text-xs"
              onClick={() => {
                if (!navigator.geolocation) {
                  setZoneError(p.zoneInvalid);
                  return;
                }
                navigator.geolocation.getCurrentPosition(
                  (pos) => {
                    setZoneLat(pos.coords.latitude.toFixed(5));
                    setZoneLng(pos.coords.longitude.toFixed(5));
                    setZoneError(null);
                  },
                  () => setZoneError(p.zoneInvalid),
                  { enableHighAccuracy: true, timeout: 12000 }
                );
              }}
            >
              {p.zoneUseGps}
            </button>
            <button
              type="button"
              className="rounded-xl bg-accent px-3 py-2 text-xs font-semibold text-on-accent"
              onClick={() => {
                const lat = Number(zoneLat.replace(",", "."));
                const lng = Number(zoneLng.replace(",", "."));
                if (
                  !Number.isFinite(lat) ||
                  !Number.isFinite(lng) ||
                  Math.abs(lat) > 90 ||
                  Math.abs(lng) > 180 ||
                  (Math.abs(lat) < 1e-4 && Math.abs(lng) < 1e-4)
                ) {
                  setZoneError(p.zoneInvalid);
                  return;
                }
                addPrivacyZone({
                  label: zoneLabel.trim() || "Zone",
                  lat,
                  lng,
                  radiusM: zoneRadiusM,
                });
                setZoneError(null);
                setZoneLat("");
                setZoneLng("");
              }}
            >
              {p.zoneSave}
            </button>
          </div>
          {zoneError && (
            <p className="text-xs text-error">{zoneError}</p>
          )}
        </div>
      </section>

      <section className="rounded-2xl border border-border bg-surface p-4">
        <h3 className="mb-2 flex items-center gap-2 font-semibold">
          <ChromeGlyph name="users" size={16} current className="text-chrome" />{" "}
          {p.familyTitle}
        </h3>
        <p className="mb-2 text-xs text-text-secondary">{p.familyOneBike}</p>
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
            {r.displayName} · {r.weightKg} kg · {p.familySetups(r.setupIds.length)}
          </button>
        ))}
        <div className="mt-2 flex gap-2">
          <input
            value={riderName}
            onChange={(e) => setRiderName(e.target.value)}
            placeholder={copy.workshopFamilyName}
            className="flex-1 rounded-xl border border-border bg-surface-elevated px-3 py-2 text-sm"
          />
          <input
            type="number"
            value={riderWeight}
            onChange={(e) => setRiderWeight(Number(e.target.value))}
            aria-label={copy.workshopFamilyWeight}
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
        {p.backToProfile}
      </Link>
    </div>
  );
}
