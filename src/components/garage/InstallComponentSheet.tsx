"use client";

import { useMemo, useState } from "react";
import {
  searchComponentModels,
  modelDisplayName,
} from "@/lib/catalog/components";
import { slotLabel } from "@/lib/catalog/slots";
import {
  aggregateVerdict,
  checkCandidateOnBike,
} from "@/lib/compatibility/engine";
import { VerdictPill } from "@/components/garage/VerdictPill";
import { useAppStore } from "@/store/useAppStore";
import { SLOT_GROUPS } from "@/types";
import type { Bike, ComponentSlot } from "@/types";
import { X } from "lucide-react";

export function InstallComponentSheet({
  bike,
  slot: initialSlot,
  onClose,
}: {
  bike: Bike;
  slot: ComponentSlot;
  onClose: () => void;
}) {
  const installComponent = useAppStore((s) => s.installComponent);
  const [slot, setSlot] = useState<ComponentSlot>(initialSlot);
  const [query, setQuery] = useState("");
  const [modelId, setModelId] = useState("");
  const [freeText, setFreeText] = useState("");

  const slotOptions = useMemo(() => {
    if (bike.category === "hiking") {
      return (
        SLOT_GROUPS.find((g) => g.id === "hiking")?.slots ?? [
          "hiking_shoes" as ComponentSlot,
        ]
      );
    }
    const list = SLOT_GROUPS.filter((g) => {
      if (g.id === "hiking") return false;
      if (
        g.id === "ebike" &&
        !bike.isEbike &&
        bike.category !== "emtb" &&
        bike.category !== "etrekking"
      ) {
        return false;
      }
      return true;
    }).flatMap((g) => g.slots);
    if (!list.includes(initialSlot)) return [initialSlot, ...list];
    return list;
  }, [bike.category, bike.isEbike, initialSlot]);

  const hits = useMemo(
    () => searchComponentModels(slot, query, 10),
    [slot, query]
  );

  const results = useMemo(() => {
    if (!modelId) return [];
    return checkCandidateOnBike(bike, slot, modelId);
  }, [bike, slot, modelId]);

  const verdict = results.length
    ? aggregateVerdict(results)
    : ("INSUFFICIENT_DATA" as const);

  const submit = () => {
    if (modelId) {
      installComponent({ bikeId: bike.id, slot, componentModelId: modelId });
    } else {
      installComponent({
        bikeId: bike.id,
        slot,
        freeText: freeText.trim() || "Eingetragen",
      });
    }
    onClose();
  };

  return (
    <div className="fixed inset-0 z-[60] flex items-end justify-center bg-black/60 sm:items-center sm:p-4">
      <div className="max-h-[90dvh] w-full max-w-lg overflow-y-auto rounded-t-2xl border border-border bg-surface p-4 sm:rounded-2xl">
        <div className="mb-3 flex items-center justify-between">
          <h2 className="text-lg font-bold">Teil eintragen</h2>
          <button
            type="button"
            onClick={onClose}
            aria-label="Schließen"
            className="p-2"
          >
            <X className="h-5 w-5" aria-hidden />
          </button>
        </div>

        <label className="mb-3 block text-sm">
          Slot
          <select
            value={slot}
            onChange={(e) => {
              setSlot(e.target.value as ComponentSlot);
              setModelId("");
              setQuery("");
            }}
            className="mt-1 w-full rounded-xl border border-border bg-surface-elevated px-3 py-2"
          >
            {slotOptions.map((s) => (
              <option key={s} value={s}>
                {slotLabel(s)}
              </option>
            ))}
          </select>
        </label>

        <label className="mb-2 block text-sm">
          Hersteller und Modell
          <input
            value={freeText}
            onChange={(e) => {
              setFreeText(e.target.value);
              if (modelId) setModelId("");
            }}
            placeholder="z. B. Maxxis Assegai"
            className="mt-1 w-full rounded-xl border border-border bg-surface-elevated px-3 py-2"
          />
        </label>

        <label className="mb-2 block text-sm">
          Im Katalog suchen
          <input
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder="optional — Treffer zuordnen"
            className="mt-1 w-full rounded-xl border border-border bg-surface-elevated px-3 py-2"
          />
        </label>

        {query.trim().length >= 2 && (
          <ul className="mb-3 max-h-40 overflow-y-auto rounded-xl border border-border">
            {hits.length === 0 ? (
              <li className="px-3 py-2 text-xs text-text-secondary">
                Kein Treffer — einfach merken ohne Katalog.
              </li>
            ) : (
              hits.map((m) => (
                <li key={m.id}>
                  <button
                    type="button"
                    onClick={() => {
                      setModelId(m.id);
                      setFreeText(modelDisplayName(m));
                    }}
                    className={`w-full px-3 py-2 text-left text-sm ${
                      modelId === m.id
                        ? "bg-chrome/15 text-chrome"
                        : "hover:bg-surface-elevated"
                    }`}
                  >
                    {modelDisplayName(m)}
                  </button>
                </li>
              ))
            )}
          </ul>
        )}

        {modelId ? (
          <p className="mb-2 text-xs text-text-secondary">
            Katalog zugeordnet — Kompat nur wenn Partner-Slots da sind.
          </p>
        ) : (
          <p className="mb-2 text-xs text-text-secondary">
            Ohne Treffer speichern wir den Namen. Kompat kannst du später
            zuordnen.
          </p>
        )}

        {modelId && results.length > 0 && (
          <details className="mb-2 rounded-xl border border-border bg-surface-elevated p-2">
            <summary className="flex cursor-pointer list-none items-center gap-2 text-sm">
              <span>Kompat</span>
              <VerdictPill verdict={verdict} />
            </summary>
            <div className="mt-2 flex max-h-40 flex-col gap-2 overflow-y-auto">
              {results.map((r) => (
                <div key={r.ruleCode} className="text-xs">
                  <div className="mb-1 flex items-center justify-between gap-2">
                    <span className="font-medium">{r.ruleCode}</span>
                    <VerdictPill verdict={r.verdict} />
                  </div>
                  <p className="text-text-secondary">{r.explainDe}</p>
                </div>
              ))}
            </div>
          </details>
        )}

        <button
          type="button"
          onClick={submit}
          disabled={!freeText.trim() && !modelId}
          className="mt-4 w-full rounded-xl bg-accent py-3 font-semibold text-white disabled:opacity-40"
        >
          {modelId ? "Zuordnen und einbauen" : "Ohne Katalog merken"}
        </button>
      </div>
    </div>
  );
}
