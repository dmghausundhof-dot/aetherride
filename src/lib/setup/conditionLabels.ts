import type { ChromeLang } from "@/lib/i18n/chromeLang";
import { recapChromeCopy } from "@/lib/i18n/recapChromeCopy";
import type { SetupCondition } from "@/types";

export function setupConditionLabel(
  c: SetupCondition,
  lang: ChromeLang = "de"
): string {
  const copy = recapChromeCopy(lang);
  switch (c) {
    case "general":
      return copy.condGeneral;
    case "dry":
      return copy.condDry;
    case "wet":
      return copy.condWet;
    case "mixed":
      return copy.condMixed;
    case "bikepark":
      return copy.condBikepark;
    case "race":
      return copy.condRace;
    default:
      return c;
  }
}

export function setupConditionOptions(lang: ChromeLang = "de"): {
  value: SetupCondition;
  label: string;
}[] {
  return (
    ["dry", "wet", "mixed", "bikepark", "race", "general"] as SetupCondition[]
  ).map((value) => ({ value, label: setupConditionLabel(value, lang) }));
}

export const SETUP_CONDITION_OPTIONS = setupConditionOptions("de");
