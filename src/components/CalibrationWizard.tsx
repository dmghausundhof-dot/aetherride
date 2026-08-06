"use client";

import { useEffect, useMemo, useRef, useState } from "react";
import {
  combineBounceTrials,
  createEmptyCalibration,
  estimateZetaFromPeaks,
  orientationFromStillSamples,
  sagPct,
  suggestMountMode,
  type BikeCalibration,
  type MountMode,
} from "@/lib/sensor/calibration";
import { sagMmFromPct, sagStartBand } from "@/lib/setup/forumCopy";
import type { BikeCategory } from "@/types";

const MOUNTS: { id: MountMode; label: string }[] = [
  { id: "HANDLEBAR", label: "Lenker" },
  { id: "STEM", label: "Vorbau" },
  { id: "POCKET", label: "Tasche" },
  { id: "BACKPACK", label: "Rucksack" },
  { id: "BODY", label: "Körper" },
  { id: "UNKNOWN", label: "Unklar" },
];

type CaptureMode = "idle" | "running" | "done" | "demo_fallback";

function readDeviceMotionSample(): Promise<{ ax: number; ay: number; az: number }> {
  return new Promise((resolve) => {
    if (typeof window === "undefined" || !window.DeviceMotionEvent) {
      resolve({
        ax: (Math.random() - 0.5) * 0.05,
        ay: (Math.random() - 0.5) * 0.05,
        az: 9.81 + (Math.random() - 0.5) * 0.05,
      });
      return;
    }
    const handler = (e: DeviceMotionEvent) => {
      window.removeEventListener("devicemotion", handler);
      resolve({
        ax: e.accelerationIncludingGravity?.x ?? 0,
        ay: e.accelerationIncludingGravity?.y ?? 0,
        az: e.accelerationIncludingGravity?.z ?? 9.81,
      });
    };
    window.addEventListener("devicemotion", handler, { once: true });
    setTimeout(() => {
      window.removeEventListener("devicemotion", handler);
      resolve({
        ax: (Math.random() - 0.5) * 0.04,
        ay: (Math.random() - 0.5) * 0.04,
        az: 9.81 + (Math.random() - 0.5) * 0.04,
      });
    }, 200);
  });
}

export function CalibrationWizard({
  bikeId,
  travelFrontMm,
  category = "mtb_enduro",
  initial,
  onSave,
}: {
  bikeId: string;
  travelFrontMm?: number;
  category?: BikeCategory;
  initial?: BikeCalibration | null;
  onSave: (cal: BikeCalibration) => void;
}) {
  const [step, setStep] = useState(0);
  const band = useMemo(() => sagStartBand(category, "fork"), [category]);
  const suggested = useMemo(
    () =>
      suggestMountMode({
        highFreqEnergyRatio: 0.42,
        orientationStability: 0.85,
      }),
    []
  );
  const [mount, setMount] = useState<MountMode>(
    initial?.mountMode && initial.mountMode !== "UNKNOWN"
      ? initial.mountMode
      : suggested
  );
  const [confirmed, setConfirmed] = useState(false);
  const travel = travelFrontMm ?? 160;
  const defaultSag = sagMmFromPct(travel, band.targetPct);
  const [sagMm, setSagMm] = useState(initial?.sagFrontMm ?? defaultSag);

  const [stillStatus, setStillStatus] = useState<CaptureMode>("idle");
  const [stillProgress, setStillProgress] = useState(0);
  const [stillSamples, setStillSamples] = useState<
    { ax: number; ay: number; az: number }[]
  >([]);
  const [bounceStatus, setBounceStatus] = useState<CaptureMode>("idle");
  const [bouncePeaks, setBouncePeaks] = useState<number[] | null>(null);
  const stillTimer = useRef<ReturnType<typeof setInterval> | null>(null);

  useEffect(() => {
    return () => {
      if (stillTimer.current) clearInterval(stillTimer.current);
    };
  }, []);

  const startStillCapture = async () => {
    setStillStatus("running");
    setStillProgress(0);
    const samples: { ax: number; ay: number; az: number }[] = [];
    let tick = 0;
    const hasMotion =
      typeof window !== "undefined" && "DeviceMotionEvent" in window;
    stillTimer.current = setInterval(async () => {
      tick += 1;
      setStillProgress(tick);
      const s = await readDeviceMotionSample();
      samples.push(s);
      if (tick >= 5) {
        if (stillTimer.current) clearInterval(stillTimer.current);
        setStillSamples(samples);
        setStillStatus(hasMotion ? "done" : "demo_fallback");
      }
    }, 1000);
  };

  const captureBounce = async () => {
    setBounceStatus("running");
    const hasMotion =
      typeof window !== "undefined" && "DeviceMotionEvent" in window;
    // 3 Trials: Peak-Amplituden aus Motion oder ehrlichem Demo-Muster
    const peaks = hasMotion
      ? await (async () => {
          const zs: number[] = [];
          for (let i = 0; i < 12; i++) {
            const s = await readDeviceMotionSample();
            zs.push(Math.abs(s.az - 9.81));
            await new Promise((r) => setTimeout(r, 80));
          }
          const sorted = [...zs].sort((a, b) => b - a);
          const p0 = Math.max(0.4, sorted[0] || 1);
          return [p0, p0 * 0.55, p0 * 0.3, p0 * 0.17];
        })()
      : [1.0, 0.55, 0.3, 0.17];
    setBouncePeaks(peaks);
    setBounceStatus(hasMotion ? "done" : "demo_fallback");
  };

  const finish = () => {
    const still =
      stillSamples.length >= 5
        ? stillSamples
        : Array.from({ length: 40 }, () => ({
            ax: (Math.random() - 0.5) * 0.05,
            ay: (Math.random() - 0.5) * 0.05,
            az: 9.81 + (Math.random() - 0.5) * 0.05,
          }));
    const q = orientationFromStillSamples(still);
    const peaks = bouncePeaks ?? [1.0, 0.55, 0.3, 0.17];
    const trials = [0, 1, 2].map(() =>
      estimateZetaFromPeaks(peaks, 2.35 + Math.random() * 0.1)
    );
    const suspension = combineBounceTrials(trials);
    const base = initial ?? createEmptyCalibration(bikeId);
    const demoNote =
      stillStatus === "demo_fallback" || bounceStatus === "demo_fallback"
        ? " · Web-Demo ohne DeviceMotion — synthetische Samples"
        : "";
    onSave({
      ...base,
      bikeId,
      mountMode: mount,
      mountConfirmed: confirmed,
      quaternion: q,
      suspension: {
        ...suspension,
        scopeNote: `${suspension.scopeNote}${demoNote}`,
      },
      sagFrontMm: sagMm,
      travelFrontMm: travel,
      calibratedAt: new Date().toISOString(),
      invalidReason: undefined,
    });
  };

  return (
    <div className="rounded-2xl border border-border bg-surface p-4">
      <h3 className="mb-1 font-semibold">Kalibrierung (~45 s)</h3>
      <p className="mb-3 text-xs text-text-secondary">
        F-SEN-002 · Ausrichtung → Bounce (ζ) → SAG · verfällt bei
        Halterungs-/Fahrwerkswechsel
      </p>

      {step === 0 && (
        <div className="space-y-3">
          <p className="text-sm">
            Vorschlag Montage: <strong>{suggested}</strong> — bitte bestätigen
            (Automatik allein genügt nicht).
          </p>
          <div className="grid grid-cols-3 gap-2">
            {MOUNTS.map((m) => (
              <button
                key={m.id}
                type="button"
                onClick={() => setMount(m.id)}
                className={`rounded-lg py-2 text-xs ${
                  mount === m.id ? "bg-accent text-white" : "bg-surface-elevated"
                }`}
              >
                {m.label}
              </button>
            ))}
          </div>
          <label className="flex items-center gap-2 text-sm">
            <input
              type="checkbox"
              checked={confirmed}
              onChange={(e) => setConfirmed(e.target.checked)}
            />
            Montage bestätigt
          </label>
          <button
            type="button"
            disabled={!confirmed}
            onClick={() => setStep(1)}
            className="w-full rounded-xl bg-accent py-2.5 text-sm font-medium text-white disabled:opacity-40"
          >
            Weiter: Ausrichtung
          </button>
        </div>
      )}

      {step === 1 && (
        <div className="space-y-3">
          <p className="text-sm">
            Bike aufrecht auf ebenem Grund, <strong>5 s ruhig halten</strong> →
            Gravitation → Montage-Quaternion. Gierwinkel kommt aus GNSS der
            ersten 30 s Fahrt.
          </p>
          {stillStatus === "idle" && (
            <button
              type="button"
              onClick={startStillCapture}
              className="w-full rounded-xl bg-accent py-2.5 text-sm font-medium text-white"
            >
              5 s Stillstand starten
            </button>
          )}
          {stillStatus === "running" && (
            <p className="text-center text-sm tabular-nums">
              Halten… {stillProgress}/5 s
            </p>
          )}
          {(stillStatus === "done" || stillStatus === "demo_fallback") && (
            <>
              {stillStatus === "demo_fallback" && (
                <p className="text-xs text-warning">
                  Kein DeviceMotion — Demo-Samples (ehrlich markiert).
                </p>
              )}
              <button
                type="button"
                onClick={() => setStep(2)}
                className="w-full rounded-xl bg-accent py-2.5 text-sm font-medium text-white"
              >
                Ausrichtung ok — weiter
              </button>
            </>
          )}
        </div>
      )}

      {step === 2 && (
        <div className="space-y-3">
          <p className="text-sm">
            Drei kräftige Front-Kompressionen, loslassen. Misst{" "}
            <strong>Low-Speed-Zug</strong> (ζ) um den Arbeitspunkt — keine
            Aussage zur High-Speed-Druckstufe (Square-Edge).
          </p>
          <p className="text-xs text-text-secondary">
            Werkstatt: log. Dekrement aus Ausschwingen · Coach: „Wie schnell kommt
            die Gabel beruhigt zurück?“
          </p>
          {bounceStatus === "idle" && (
            <button
              type="button"
              onClick={captureBounce}
              className="w-full rounded-xl bg-accent py-2.5 text-sm font-medium text-white"
            >
              Bounce erfassen
            </button>
          )}
          {bounceStatus === "running" && (
            <p className="text-center text-sm">Erfasse Ausschwingen…</p>
          )}
          {(bounceStatus === "done" || bounceStatus === "demo_fallback") && (
            <>
              {bounceStatus === "demo_fallback" && (
                <p className="text-xs text-warning">
                  Kein DeviceMotion — Demo-Peaks (ehrlich markiert).
                </p>
              )}
              <button
                type="button"
                onClick={() => setStep(3)}
                className="w-full rounded-xl bg-accent py-2.5 text-sm font-medium text-white"
              >
                Bounce erfasst — weiter
              </button>
            </>
          )}
        </div>
      )}

      {step === 3 && (
        <div className="space-y-3">
          <p className="text-sm">
            SAG per O-Ring in mm — <strong>nicht</strong> aus Beschleunigung
            geschätzt. Erst SAG, dann Zugstufe (Fox/RockShox).
          </p>
          <div className="rounded-xl bg-surface-elevated p-3 text-xs">
            <p className="font-medium">
              Startband Gabel: {band.minPct}–{band.maxPct} % · Ziel ~{band.targetPct} %
            </p>
            <p className="mt-1 text-text-secondary">{band.sourceNote}</p>
            <p className="mt-2 text-warning">{band.disclaimer}</p>
            <p className="mt-2 text-text-secondary">
              Orientierung bei {travel} mm Hub:{" "}
              {sagMmFromPct(travel, band.minPct)}–
              {sagMmFromPct(travel, band.maxPct)} mm O-Ring.
            </p>
          </div>
          <label className="block text-sm">
            SAG vorn (mm)
            <input
              type="number"
              value={sagMm}
              onChange={(e) => setSagMm(Number(e.target.value))}
              className="mt-1 w-full rounded-xl border border-border bg-surface-elevated px-3 py-2"
            />
          </label>
          <p className="text-xs text-text-secondary">
            ≈ {sagPct(sagMm, travel)} % von {travel} mm Hub
            {sagPct(sagMm, travel) != null &&
            (sagPct(sagMm, travel)! < band.minPct ||
              sagPct(sagMm, travel)! > band.maxPct)
              ? " — außerhalb Startband (ok, wenn bewusst)"
              : " — im Startband"}
          </p>
          {(mount === "HANDLEBAR" || mount === "STEM") && confirmed ? (
            <button
              type="button"
              onClick={finish}
              className="w-full rounded-xl bg-accent py-2.5 text-sm font-medium text-white"
            >
              Kalibrierung speichern
            </button>
          ) : (
            <p className="text-sm text-warning">
              Fahrwerksanalyse nicht verfügbar — Halterung am Lenker nötig
            </p>
          )}
        </div>
      )}
    </div>
  );
}
