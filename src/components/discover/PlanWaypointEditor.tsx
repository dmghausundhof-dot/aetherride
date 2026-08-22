"use client";

import { useState, type DragEvent, type ReactNode } from "react";
import { GripVertical } from "lucide-react";
import { ChromeGlyph } from "@/components/chrome/ChromeGlyph";
import {
  closeLoop,
  endOf,
  isClosedLoop,
  orderedWaypoints,
  removeWaypoint,
  reorderWaypoints,
  startOf,
  type PlanDraft,
  type PlanSlot,
} from "@/lib/routing/planDraft";
import type { discoverUi } from "@/lib/i18n/discoverUi";
import { plannerCopy } from "@/lib/i18n/plannerCopy";
import { useChromeLang } from "@/hooks/useChromeLang";
import { PlanPinMark } from "@/components/discover/PlanPinMark";

type Hit = { label: string; lat: number; lng: number };
type Copy = ReturnType<typeof discoverUi>;

export type PlanAddrSlot = "start" | "end" | string;

export function PlanWaypointEditor({
  draft,
  copy,
  addrQuery,
  addrTarget,
  addrHits,
  addrBusy,
  pickTarget,
  routingBusy,
  userPos,
  recents,
  onAddrQuery,
  onAddrTarget,
  onApplyHit,
  onDraft,
  onSwap,
  onPick,
  onMyLocation,
  onUndo,
  onRedo,
  canUndo = false,
  canRedo = false,
}: {
  draft: PlanDraft;
  copy: Copy;
  addrQuery: string;
  addrTarget: PlanAddrSlot;
  addrHits: Hit[];
  addrBusy: boolean;
  pickTarget: PlanSlot | null;
  routingBusy: boolean;
  userPos: [number, number] | null;
  recents?: Hit[];
  onAddrQuery: (q: string) => void;
  onAddrTarget: (t: PlanAddrSlot) => void;
  onApplyHit: (hit: Hit) => void;
  onDraft: (next: PlanDraft) => void;
  onSwap: () => void;
  onPick: (slot: PlanSlot) => void;
  onMyLocation: () => void;
  onUndo?: () => void;
  onRedo?: () => void;
  canUndo?: boolean;
  canRedo?: boolean;
}) {
  const tourLead = plannerCopy(useChromeLang()).tourLead;
  const waypoints = orderedWaypoints(draft);
  const start = waypoints.find((w) => w.role === "start");
  const dest = waypoints.find((w) => w.role === "end");
  const vias = waypoints.filter((w) => w.role === "via");
  const looped = isClosedLoop(draft);
  const startVal = addrTarget === "start" ? addrQuery : start?.label ?? "";
  const endVal = addrTarget === "end" ? addrQuery : dest?.label ?? "";
  const showEnd = Boolean(start || dest || pickTarget === "end");
  const showStops = Boolean(start && dest);
  const emptyTour = !start && !dest;
  const hint =
    pickTarget === "via"
      ? copy.nextPickVia
      : emptyTour
        ? tourLead
        : !start
          ? copy.tapStart
          : !dest
            ? copy.nextPickEnd
            : copy.tapLineVia;
  const [dragFrom, setDragFrom] = useState<number | null>(null);
  const showRecents =
    recents &&
    recents.length > 0 &&
    addrHits.length === 0 &&
    addrQuery.trim().length < 2;

  return (
    <div className="flex flex-col gap-3">
      {hint ? (
        <p className="text-[13px] font-semibold leading-snug text-foreground">
          {hint}
        </p>
      ) : null}
      <div className="relative rounded-2xl border border-border bg-surface px-3 py-2">
        {showEnd ? (
          <div
            aria-hidden
            className="pointer-events-none absolute bottom-8 left-[1.375rem] top-8 w-px bg-border"
          />
        ) : null}
        <WaypointRow
          kind="start"
          inputId="plan-start"
          label={copy.start}
          placeholder={copy.startAddr}
          value={startVal}
          onFocus={() => {
            onAddrTarget("start");
            onAddrQuery(start?.label ?? "");
          }}
          onChange={(v) => {
            onAddrTarget("start");
            onAddrQuery(v);
          }}
          onPick={() => onPick("start")}
          trailing={
            userPos ? (
              <button
                type="button"
                className="grid h-8 w-8 shrink-0 place-items-center rounded-full text-chrome hover:bg-chrome/10"
                onClick={onMyLocation}
                aria-label={copy.startMyPos}
                title={copy.startMyPos}
              >
                <ChromeGlyph name="locate" size={16} current />
              </button>
            ) : null
          }
        />
        {showStops ? (
          <div className="flex justify-end pr-1">
            <button
              type="button"
              onClick={onSwap}
              className="grid h-8 w-8 place-items-center rounded-full text-text-secondary hover:bg-surface-elevated hover:text-foreground"
              aria-label={copy.swapStartEnd}
              title={copy.swapStartEnd}
            >
              <ChromeGlyph name="swap" size={16} current />
            </button>
          </div>
        ) : null}
        {showStops
          ? vias.map((w, i) => (
              <WaypointRow
                key={w.id}
                kind="via"
                badge={String(i + 1)}
                inputId={`plan-via-${w.id}`}
                label={copy.viaN(i + 1)}
                placeholder={copy.viaAddr}
                value={addrTarget === w.id ? addrQuery : w.label ?? ""}
                onDragOver={(e) => e.preventDefault()}
                onDrop={() => {
                  if (dragFrom == null || dragFrom === i) return;
                  onDraft(reorderWaypoints(draft, dragFrom + 1, i + 1));
                  setDragFrom(null);
                }}
                onFocus={() => {
                  onAddrTarget(w.id);
                  onAddrQuery(w.label ?? "");
                }}
                onChange={(v) => {
                  onAddrTarget(w.id);
                  onAddrQuery(v);
                }}
                onPick={() => onPick("via")}
                trailing={
                  <span className="flex shrink-0 items-center">
                    <span
                      draggable
                      onDragStart={() => setDragFrom(i)}
                      onDragEnd={() => setDragFrom(null)}
                      className="grid h-8 w-7 cursor-grab touch-none place-items-center text-text-secondary active:cursor-grabbing"
                      aria-label={copy.viaN(i + 1)}
                    >
                      <GripVertical className="h-4 w-4" />
                    </span>
                    <button
                      type="button"
                      className="grid h-8 w-7 place-items-center text-text-secondary"
                      onClick={() => onDraft(removeWaypoint(draft, w.id))}
                      aria-label={copy.remove}
                    >
                      ×
                    </button>
                  </span>
                }
              />
            ))
          : null}
        {showEnd ? (
          <WaypointRow
            kind="finish"
            inputId="plan-end"
            label={copy.end}
            placeholder={copy.endAddr}
            value={endVal}
            onFocus={() => {
              onAddrTarget("end");
              onAddrQuery(dest?.label ?? "");
            }}
            onChange={(v) => {
              onAddrTarget("end");
              onAddrQuery(v);
            }}
            onPick={() => onPick("end")}
          />
        ) : null}
      </div>
      {routingBusy ? (
        <p className="text-[11px] text-text-secondary">{copy.routingAdapts}</p>
      ) : addrBusy ? (
        <p className="text-[11px] text-text-secondary">{copy.search}…</p>
      ) : null}
      {addrHits.length > 0 ? (
        <HitList hits={addrHits} onApplyHit={onApplyHit} />
      ) : showRecents ? (
        <div>
          <p className="mb-1 text-[11px] font-semibold text-text-secondary">
            {copy.recently}
          </p>
          <HitList hits={recents!} onApplyHit={onApplyHit} />
        </div>
      ) : null}
      {showStops ? (
        <div className="flex flex-wrap gap-1.5">
          <button
            type="button"
            onClick={() => onPick("via")}
            className={`rounded-full border px-3 py-1.5 text-[12px] ${
              pickTarget === "via"
                ? "border-chrome bg-chrome/10"
                : "border-border bg-surface"
            }`}
          >
            + {copy.addStop}
          </button>
          <button
            type="button"
            onClick={() => onDraft(closeLoop(draft, start?.label ?? copy.start))}
            disabled={!startOf(draft)}
            className="rounded-full border border-border bg-surface px-3 py-1.5 text-[12px] disabled:opacity-40"
          >
            {looped ? copy.loopClosed : copy.closeLoop}
          </button>
          {canUndo ? (
            <button
              type="button"
              onClick={() => onUndo?.()}
              className="inline-flex items-center gap-1 rounded-full border border-border bg-surface px-3 py-1.5 text-[12px]"
            >
              <ChromeGlyph name="undo" size={14} current className="text-text-secondary" />
              {copy.planUndo}
            </button>
          ) : null}
          {canRedo ? (
            <button
              type="button"
              onClick={() => onRedo?.()}
              className="inline-flex items-center gap-1 rounded-full border border-border bg-surface px-3 py-1.5 text-[12px]"
            >
              <ChromeGlyph name="redo" size={14} current className="text-text-secondary" />
              {copy.planRedo}
            </button>
          ) : null}
        </div>
      ) : null}
      {showStops && looped ? (
        <p className="text-[11px] text-text-secondary">{copy.closeLoopHint}</p>
      ) : null}
      {!routingBusy && startOf(draft) && endOf(draft) && !draft.computed ? (
        <p className="text-[11px] text-text-secondary">{copy.computingRoute}</p>
      ) : null}
    </div>
  );
}

function HitList({
  hits,
  onApplyHit,
}: {
  hits: Hit[];
  onApplyHit: (hit: Hit) => void;
}) {
  return (
    <ul className="max-h-32 overflow-auto rounded-xl border border-border">
      {hits.map((h) => (
        <li key={`${h.label}-${h.lat}`}>
          <button
            type="button"
            className="flex w-full items-center gap-2 px-2.5 py-2 text-left text-[12px] hover:bg-surface-elevated"
            onClick={() => onApplyHit(h)}
          >
            <ChromeGlyph name="karte" size={14} />
            {h.label}
          </button>
        </li>
      ))}
    </ul>
  );
}

function WaypointRow({
  kind,
  badge,
  inputId,
  label,
  placeholder,
  value,
  onChange,
  onFocus,
  onPick,
  trailing,
  onDragOver,
  onDrop,
}: {
  kind: "start" | "via" | "finish";
  badge?: string;
  inputId?: string;
  label: string;
  placeholder?: string;
  value?: string;
  onChange?: (v: string) => void;
  onFocus?: () => void;
  onPick: () => void;
  trailing?: ReactNode;
  onDragOver?: (e: DragEvent) => void;
  onDrop?: () => void;
}) {
  return (
        <div
      className="relative z-[1] flex items-center gap-2 py-1.5"
      onDragOver={onDragOver}
      onDrop={onDrop}
    >
      <button type="button" onClick={onPick} aria-label={label}>
        <PlanPinMark kind={kind} label={badge} />
      </button>
      {onChange ? (
        <input
          id={inputId}
          value={value ?? ""}
          onChange={(e) => onChange(e.target.value)}
          onFocus={(e) => {
            onFocus?.();
            e.currentTarget.scrollIntoView({ block: "center", behavior: "smooth" });
          }}
          placeholder={placeholder}
          aria-label={label}
          className="min-w-0 flex-1 bg-transparent py-1.5 text-sm outline-none placeholder:text-text-secondary"
        />
      ) : (
        <button
          type="button"
          onClick={onPick}
          className="min-w-0 flex-1 truncate py-1.5 text-left text-sm"
        >
          {label}
        </button>
      )}
      {trailing}
    </div>
  );
}
