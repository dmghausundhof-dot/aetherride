/**
 * Bracketing-Parameter ↔ Setup-Override-Keys (slot.adjuster)
 */

import type { BracketingParameter } from "@/types/garage";

/** Spec-konform: slot.adjusterKey wie in buildSetupValuesFromBike */
export const BRACKETING_PARAMS: {
  id: BracketingParameter;
  label: string;
  unit: string;
}[] = [
  { id: "fork.air_pressure_psi", label: "Gabel Luftdruck", unit: "psi" },
  { id: "fork.rebound", label: "Gabel Zugstufe", unit: "clicks" },
  { id: "fork.lsc", label: "Gabel LSC", unit: "clicks" },
  { id: "fork.hsc", label: "Gabel HSC", unit: "clicks" },
  { id: "fork.sag_pct", label: "Gabel SAG %", unit: "%" },
  {
    id: "rear_shock.air_pressure_psi",
    label: "Dämpfer Luftdruck",
    unit: "psi",
  },
  { id: "rear_shock.rebound", label: "Dämpfer Zugstufe", unit: "clicks" },
  { id: "rear_shock.lsc", label: "Dämpfer LSC", unit: "clicks" },
  { id: "rear_shock.hsc", label: "Dämpfer HSC", unit: "clicks" },
  { id: "rear_shock.sag_pct", label: "Dämpfer SAG %", unit: "%" },
  {
    id: "tire_front.pressure_psi",
    label: "Reifen vorn",
    unit: "psi",
  },
  {
    id: "tire_rear.pressure_psi",
    label: "Reifen hinten",
    unit: "psi",
  },
];

/** Legacy-Aliases aus älterem Demo-Code */
const LEGACY: Record<string, BracketingParameter> = {
  "shock.air_pressure_psi": "rear_shock.air_pressure_psi",
  "shock.rebound": "rear_shock.rebound",
  "shock.lsc": "rear_shock.lsc",
  "shock.hsc": "rear_shock.hsc",
  "shock.sag_pct": "rear_shock.sag_pct",
  "tire.front_psi": "tire_front.pressure_psi",
  "tire.rear_psi": "tire_rear.pressure_psi",
};

export function normalizeBracketingParameter(
  raw: string
): BracketingParameter | null {
  if (BRACKETING_PARAMS.some((p) => p.id === raw)) {
    return raw as BracketingParameter;
  }
  return LEGACY[raw] ?? null;
}

export function bracketingParamToSetupOverride(
  parameter: string,
  value: number
): Record<string, number> {
  const id = normalizeBracketingParameter(parameter) ?? parameter;
  return { [id]: value };
}

export function bracketingUnit(parameter: string): string {
  const id = normalizeBracketingParameter(parameter) ?? parameter;
  return BRACKETING_PARAMS.find((p) => p.id === id)?.unit ?? "";
}
