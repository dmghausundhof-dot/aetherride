import type { BikeCategory } from "@/types/garage";

/** psi per bar — UI converts; storage stays `tire_*.pressure_psi`. */
export const PSI_PER_BAR = 14.503773773;

const PSI_CATEGORIES: BikeCategory[] = [
  "mtb_trail",
  "mtb_am",
  "mtb_enduro",
  "dh",
  "emtb",
];

/** MTB/E-MTB/DH: psi. Everyday, gravel, road, trekking: bar. */
export function pressureUsesBar(category: BikeCategory): boolean {
  return !PSI_CATEGORIES.includes(category);
}

export function pressureUnitLabel(category: BikeCategory): "bar" | "psi" {
  return pressureUsesBar(category) ? "bar" : "psi";
}

export function barToPsi(bar: number): number {
  return Math.round(bar * PSI_PER_BAR * 10) / 10;
}

export function psiToBar(psi: number): number {
  return Math.round((psi / PSI_PER_BAR) * 10) / 10;
}

/** Typed field → stored psi. */
export function enteredPressureToPsi(
  entered: number,
  category: BikeCategory
): number {
  return pressureUsesBar(category) ? barToPsi(entered) : entered;
}
