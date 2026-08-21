/**
 * Undo/redo for plan waypoint edits (Komoot Zurück / AllTrails Cmd-Z).
 * Snapshots include `computed` so undo restores the previous ribbon immediately.
 */

import type { ClientRouteResult } from "@/lib/routing/profiles";
import type { PlanDraft } from "./planDraft";

const PLAN_HISTORY_MAX = 24;

function cloneComputed(
  computed: PlanDraft["computed"]
): PlanDraft["computed"] {
  if (!computed) return computed;
  const coords = (computed.geometry?.coordinates ?? []) as [number, number][];
  return {
    ...computed,
    geometry: {
      type: "LineString",
      coordinates: coords.map((c) => [c[0], c[1]] as [number, number]),
    },
  } as ClientRouteResult;
}

export type PlanEditSnap = {
  waypoints: PlanDraft["waypoints"];
  mode: PlanDraft["mode"];
  variant?: PlanDraft["variant"];
  label?: string;
  computed?: PlanDraft["computed"];
};

export type PlanHistory = {
  past: PlanEditSnap[];
  future: PlanEditSnap[];
};

export function emptyPlanHistory(): PlanHistory {
  return { past: [], future: [] };
}

export function planEditKey(draft: PlanDraft): string {
  return JSON.stringify({
    wp: draft.waypoints,
    mode: draft.mode,
    variant: draft.variant ?? "planned",
    label: draft.label ?? "",
  });
}

export function snapshotPlan(draft: PlanDraft): PlanEditSnap {
  return {
    waypoints: draft.waypoints.map((w) => ({
      ...w,
      lngLat: [...w.lngLat] as [number, number],
    })),
    mode: draft.mode,
    variant: draft.variant,
    label: draft.label,
    computed: cloneComputed(draft.computed),
  };
}

export function restorePlan(draft: PlanDraft, snap: PlanEditSnap): PlanDraft {
  return {
    ...draft,
    waypoints: snap.waypoints.map((w) => ({
      ...w,
      lngLat: [...w.lngLat] as [number, number],
    })),
    mode: snap.mode,
    variant: snap.variant,
    label: snap.label,
    computed: cloneComputed(snap.computed),
  };
}

export function pushPlanHistory(
  history: PlanHistory,
  before: PlanDraft
): PlanHistory {
  const past = [...history.past, snapshotPlan(before)];
  return {
    past: past.length > PLAN_HISTORY_MAX ? past.slice(-PLAN_HISTORY_MAX) : past,
    future: [],
  };
}

export function undoPlanHistory(
  history: PlanHistory,
  current: PlanDraft
): { draft: PlanDraft; history: PlanHistory } | null {
  if (history.past.length === 0) return null;
  const past = [...history.past];
  const snap = past.pop()!;
  return {
    draft: restorePlan(current, snap),
    history: {
      past,
      future: [...history.future, snapshotPlan(current)],
    },
  };
}

export function redoPlanHistory(
  history: PlanHistory,
  current: PlanDraft
): { draft: PlanDraft; history: PlanHistory } | null {
  if (history.future.length === 0) return null;
  const future = [...history.future];
  const snap = future.pop()!;
  return {
    draft: restorePlan(current, snap),
    history: {
      past: [...history.past, snapshotPlan(current)],
      future,
    },
  };
}
