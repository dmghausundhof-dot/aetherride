/**
 * Setup-Hinweis bei Bedingungen (nass vs. trocken).
 */

import type { Setup, SetupCondition } from "@/types";

export type TrailHint = "dry_likely" | "damp_possible" | "wet_likely";

export interface SetupConditionHint {
  message: string;
  suggestedSetupId?: string;
  suggestedLabel?: string;
  reasoning: string;
}

const TRAIL_TO_CONDITION: Record<TrailHint, SetupCondition[]> = {
  dry_likely: ["dry", "mixed", "bikepark", "race"],
  damp_possible: ["mixed", "wet", "dry"],
  wet_likely: ["wet", "mixed"],
};

export function setupConditionHint(
  current: Setup | undefined,
  allSetups: Setup[],
  trailHint: TrailHint | null
): SetupConditionHint | null {
  if (!current || !trailHint) return null;

  const preferred = TRAIL_TO_CONDITION[trailHint];
  if (preferred.includes(current.conditions)) return null;

  const better = allSetups.find(
    (s) => !s.isCurrent && preferred.includes(s.conditions)
  );

  const trailLabel =
    trailHint === "wet_likely"
      ? "nass"
      : trailHint === "damp_possible"
        ? "feucht"
        : "trocken";

  if (better) {
    return {
      message: `Setup „${current.label}“ (${current.conditions}) passt schlecht zu ${trailLabel}en Trails — „${better.label}“ wäre besser.`,
      suggestedSetupId: better.id,
      suggestedLabel: better.label,
      reasoning: `Aktuelles Setup für ${current.conditions}, Wetterlage ${trailHint}.`,
    };
  }

  if (current.conditions === "wet" && trailHint === "dry_likely") {
    return {
      message: `Setup „${current.label}“ ist auf nass ausgelegt — heute eher trocken.`,
      reasoning: `conditions=${current.conditions}, trailHint=${trailHint}`,
    };
  }

  if (current.conditions === "dry" && trailHint === "wet_likely") {
    return {
      message: `Setup „${current.label}“ ist auf trocken ausgelegt — Trails eher nass.`,
      reasoning: `conditions=${current.conditions}, trailHint=${trailHint}`,
    };
  }

  return null;
}
