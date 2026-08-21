"use client";

import { useMemo, useState } from "react";
import {
  searchComponentModels,
  modelDisplayName,
} from "@/lib/catalog/components";
import { slotLabel } from "@/lib/catalog/slots";
import { garageTabCopy } from "@/lib/i18n/garageTabCopy";
import { presentCompat } from "@/lib/i18n/compatCopy";
import { useChromeLang } from "@/hooks/useChromeLang";
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
  const lang = useChromeLang();
  const tab = garageTabCopy(lang);
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
        freeText: freeText.trim() || tab.logged,
      });
    }
    onClose();
  };

  return (
    <div className="fixed inset-0 z-[60] flex items-end justify-center bg-black/60 sm:items-center sm:p-4">
      <div className="max-h-[90dvh] w-full max-w-lg overflow-y-auto rounded-t-2xl border border-border bg-surface p-4 sm:rounded-2xl">
        <div className="mb-3 flex items-center justify-between">
          <h2 className="text-lg font-bold">{tab.installTitle}</h2>
          <button
            type="button"
            onClick={onClose}
            aria-label={tab.close}
            className="p-2"
          >
            <X className="h-5 w-5" aria-hidden />
          </button>
        </div>

        <label className="mb-3 block text-sm">
          {tab.slot}
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
                {slotLabel(s, lang)}
              </option>
            ))}
          </select>
        </label>

        <label className="mb-2 block text-sm">
          {tab.makerModel}
          <input
            value={freeText}
            onChange={(e) => {
              setFreeText(e.target.value);
              if (modelId) setModelId("");
            }}
            placeholder={tab.makerPlaceholder}
            className="mt-1 w-full rounded-xl border border-border bg-surface-elevated px-3 py-2"
          />
        </label>

        <label className="mb-2 block text-sm">
          {tab.catalogSearch}
          <input
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder={tab.catalogPlaceholder}
            className="mt-1 w-full rounded-xl border border-border bg-surface-elevated px-3 py-2"
          />
        </label>

        {query.trim().length >= 2 && (
          <ul className="mb-3 max-h-40 overflow-y-auto rounded-xl border border-border">
            {hits.length === 0 ? (
              <li className="px-3 py-2 text-xs text-text-secondary">
                {tab.noHit}
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
            {tab.catalogLinked}
          </p>
        ) : (
          <p className="mb-2 text-xs text-text-secondary">
            {tab.saveName}
          </p>
        )}

        {modelId && results.length > 0 && (
          <details className="mb-2 rounded-xl border border-border bg-surface-elevated p-2">
            <summary className="flex cursor-pointer list-none items-center gap-2 text-sm">
              <span>{tab.compatHeading}</span>
              <VerdictPill verdict={verdict} />
            </summary>
            <div className="mt-2 flex max-h-40 flex-col gap-2 overflow-y-auto">
              {results.map((r) => {
                const presented = presentCompat(r, lang);
                return (
                <div key={r.ruleCode} className="text-xs">
                  <div className="mb-1 flex items-center justify-between gap-2">
                    <span className="font-medium">{presented.title}</span>
                    <VerdictPill verdict={r.verdict} />
                  </div>
                  <p className="text-text-secondary">{presented.explain}</p>
                </div>
                );
              })}
            </div>
          </details>
        )}

        <button
          type="button"
          onClick={submit}
          disabled={!freeText.trim() && !modelId}
          className="mt-4 w-full rounded-xl bg-accent py-3 font-semibold text-on-accent disabled:opacity-40"
        >
          {modelId ? tab.assignInstall : tab.rememberWithout}
        </button>
      </div>
    </div>
  );
}
