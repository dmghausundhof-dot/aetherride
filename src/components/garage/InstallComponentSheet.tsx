"use client";

import { useMemo, useState } from "react";
import { listComponentModels, modelDisplayName } from "@/lib/catalog/components";
import { slotLabel } from "@/lib/catalog/slots";
import {
  aggregateVerdict,
  checkCandidateOnBike,
} from "@/lib/compatibility/engine";
import { VerdictPill } from "@/components/garage/VerdictPill";
import { useAppStore } from "@/store/useAppStore";
import type { Bike, ComponentSlot } from "@/types";
import { X } from "lucide-react";

export function InstallComponentSheet({
  bike,
  slot,
  onClose,
}: {
  bike: Bike;
  slot: ComponentSlot;
  onClose: () => void;
}) {
  const installComponent = useAppStore((s) => s.installComponent);
  const models = useMemo(() => listComponentModels(slot), [slot]);
  const [modelId, setModelId] = useState(models[0]?.id ?? "");
  const [freeText, setFreeText] = useState("");
  const [useFree, setUseFree] = useState(models.length === 0);

  const results = useMemo(() => {
    if (!modelId || useFree) return [];
    return checkCandidateOnBike(bike, slot, modelId);
  }, [bike, slot, modelId, useFree]);

  const verdict = results.length
    ? aggregateVerdict(results)
    : ("INSUFFICIENT_DATA" as const);

  const submit = () => {
    if (useFree) {
      installComponent({
        bikeId: bike.id,
        slot,
        freeText: freeText || "Unbekanntes Teil",
      });
    } else if (modelId) {
      installComponent({ bikeId: bike.id, slot, componentModelId: modelId });
    }
    onClose();
  };

  return (
    <div className="fixed inset-0 z-[60] flex items-end justify-center bg-black/60 sm:items-center sm:p-4">
      <div className="max-h-[90dvh] w-full max-w-lg overflow-y-auto rounded-t-2xl border border-border bg-surface p-4 sm:rounded-2xl">
        <div className="mb-3 flex items-center justify-between">
          <h2 className="text-lg font-bold">{slotLabel(slot)} einbauen</h2>
          <button
            type="button"
            onClick={onClose}
            aria-label="Schließen"
            className="p-2"
          >
            <X className="h-5 w-5" aria-hidden />
          </button>
        </div>

        <div className="mb-3 flex gap-2">
          <button
            type="button"
            disabled={models.length === 0}
            onClick={() => setUseFree(false)}
            className={`flex-1 rounded-xl py-2 text-sm ${
              !useFree ? "bg-accent text-white" : "bg-surface-elevated"
            }`}
          >
            Katalog
          </button>
          <button
            type="button"
            onClick={() => setUseFree(true)}
            className={`flex-1 rounded-xl py-2 text-sm ${
              useFree ? "bg-accent text-white" : "bg-surface-elevated"
            }`}
          >
            Freitext
          </button>
        </div>

        {useFree ? (
          <>
            <p className="mb-2 text-xs text-warning">
              Ohne Katalogbezug sind Kompatibilitätsprüfung und Setup-Automatik
              eingeschränkt.
            </p>
            <input
              value={freeText}
              onChange={(e) => setFreeText(e.target.value)}
              placeholder="Hersteller Modell"
              className="w-full rounded-xl border border-border bg-surface-elevated px-3 py-2"
            />
          </>
        ) : (
          <>
            <select
              value={modelId}
              onChange={(e) => setModelId(e.target.value)}
              className="mb-3 w-full rounded-xl border border-border bg-surface-elevated px-3 py-2"
            >
              {models.map((m) => (
                <option key={m.id} value={m.id}>
                  {modelDisplayName(m)}
                </option>
              ))}
            </select>
            <div className="mb-2 flex items-center gap-2">
              <span className="text-sm text-text-secondary">Urteil:</span>
              <VerdictPill verdict={verdict} />
            </div>
            <div className="flex max-h-48 flex-col gap-2 overflow-y-auto">
              {results.map((r) => (
                <div
                  key={r.ruleCode}
                  className="rounded-xl border border-border bg-surface-elevated p-2 text-xs"
                >
                  <div className="mb-1 flex items-center justify-between gap-2">
                    <span className="font-medium">{r.ruleCode}</span>
                    <VerdictPill verdict={r.verdict} />
                  </div>
                  <p className="text-text-secondary">{r.explainDe}</p>
                  {r.missingAttributes.map((m) => (
                    <p key={m.key} className="mt-1 text-warning">
                      Fehlt: {m.key} — {m.howToObtain}
                    </p>
                  ))}
                  {r.safetyWorkshopHint && (
                    <p className="mt-1 text-error">{r.safetyWorkshopHint}</p>
                  )}
                  {r.torqueSpecs.map((t) => (
                    <p key={t.fastener} className="mt-1 tabular-nums">
                      Drehmoment {t.fastener}: {t.nm} Nm ({t.sourceLabel})
                    </p>
                  ))}
                </div>
              ))}
              {results.length === 0 && (
                <p className="text-xs text-text-secondary">
                  Keine anwendbare Regel für diesen Slot (Partner-Slot fehlt
                  noch) → INSUFFICIENT_DATA.
                </p>
              )}
            </div>
          </>
        )}

        <button
          type="button"
          onClick={submit}
          disabled={!useFree && verdict === "INCOMPATIBLE"}
          className="mt-4 w-full rounded-xl bg-accent py-3 font-semibold text-white disabled:opacity-40"
        >
          {verdict === "INCOMPATIBLE" && !useFree
            ? "Inkompatibel – Einbau blockiert"
            : "Einbauen"}
        </button>
      </div>
    </div>
  );
}
