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

  const finish = () => {
    const still = Array.from({ length: 40 }, () => ({
      ax: (Math.random() - 0.5) * 0.05,
      ay: (Math.random() - 0.5) * 0.05,
      az: 9.81 + (Math.random() - 0.5) * 0.05,
    }));
    const q = orientationFromStillSamples(still);
    const trials = [0, 1, 2].map(() =>
      estimateZetaFromPeaks([1.0, 0.55, 0.3, 0.17], 2.35 + Math.random() * 0.1)
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
            Drei kräftige Front-Kompressionen, loslassen. Misst{" "}
            <strong>Low-Speed-Zug</strong> (ζ) um den Arbeitspunkt — keine
            Aussage zur High-Speed-Druckstufe (Square-Edge).
          </p>
          <p className="text-xs text-text-secondary">
            Werkstatt: log. Dekrement aus Ausschwingen · Coach: „Wie schnell kommt
            die Gabel beruhigt zurück?“
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
