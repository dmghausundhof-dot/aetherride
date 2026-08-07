import type { SetupCondition } from "@/types";

const LABELS: Record<SetupCondition, string> = {
  general: "Allgemein",
  dry: "Trocken",
  wet: "Nass",
  mixed: "Gemischt",
  bikepark: "Bikepark",
  race: "Rennen",
};

export function setupConditionLabel(c: SetupCondition): string {
  return LABELS[c] ?? c;
}

export const SETUP_CONDITION_OPTIONS: {
  value: SetupCondition;
  label: string;
}[] = (
  ["dry", "wet", "mixed", "bikepark", "race", "general"] as SetupCondition[]
).map((value) => ({ value, label: LABELS[value] }));
