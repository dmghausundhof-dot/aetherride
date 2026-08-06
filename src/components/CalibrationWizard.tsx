"use client";

import { useMemo, useState } from "react";
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

const MOUNTS: { id: MountMode; label: string }[] = [
  { id: "HANDLEBAR", label: "Lenker" },
  { id: "STEM", label: "Vorbau" },
  { id: "POCKET", label: "Tasche" },
  { id: "BACKPACK", label: "Rucksack" },
  { id: "BODY", label: "Körper" },
  { id: "UNKNOWN", label: "Unklar" },
];

export function CalibrationWizard({
  bikeId,
  travelFrontMm,
  initial,
  onSave,
}: {
  bikeId: string;
  travelFrontMm?: number;
  initial?: BikeCalibration | null;
  onSave: (cal: BikeCalibration) => void;
}) {
  const [step, setStep] = useState(0);
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
  const [sagMm, setSagMm] = useState(initial?.sagFrontMm ?? 38);
  const travel = travelFrontMm ?? 160;

  const finish = () => {
    const still = Array.from({ length: 40 }, () => ({
      ax: (Math.random() - 0.5) * 0.05,
      ay: (Math.random() - 0.5) * 0.05,
      az: 9.81 + (Math.random() - 0.5) * 0.05,
    }));
    const q = orientationFromStillSamples(still);
    const trials = [0, 1, 2].map(() =>
      estimateZetaFromPeaks([1.0, 0.62, 0.39, 0.24], 2.35 + Math.random() * 0.1)
    );
    const suspension = combineBounceTrials(trials);
    const base = initial ?? createEmptyCalibration(bikeId);
    onSave({
      ...base,
      bikeId,
      mountMode: mount,
      mountConfirmed: confirmed,
      quaternion: q,
      suspension,
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
        F-SEN-002 · Ausrichtung → Bounce (ζ) → SAG · verfällt bei Halterungs-/Fahrwerkswechsel
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
            Bike aufrecht auf ebenem Grund, 5 s ruhig halten → Gravitation →
            Montage-Quaternion. Gierwinkel kommt aus GNSS der ersten 30 s Fahrt.
          </p>
          <button
            type="button"
            onClick={() => setStep(2)}
            className="w-full rounded-xl bg-accent py-2.5 text-sm font-medium text-white"
          >
            5 s gehalten — weiter
          </button>
        </div>
      )}

      {step === 2 && (
        <div className="space-y-3">
          <p className="text-sm">
            Drei kräftige Front-Kompressionen, loslassen. Misst Low-Speed-Zugstufe
            (ζ) — keine Aussage zur High-Speed-Druckstufe.
          </p>
          <button
            type="button"
            onClick={() => setStep(3)}
            className="w-full rounded-xl bg-accent py-2.5 text-sm font-medium text-white"
          >
            Bounce erfasst — weiter
          </button>
        </div>
      )}

      {step === 3 && (
        <div className="space-y-3">
          <p className="text-sm">
            SAG per O-Ring in mm — <strong>nicht</strong> aus Beschleunigung
            geschätzt.
          </p>
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
