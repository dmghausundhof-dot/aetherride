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

export function formatPressureValue(psi: number, usesBar: boolean): string {
  return usesBar ? psiToBar(psi).toFixed(1) : String(Math.round(psi));
}

/** First logged front/rear psi on the setups list — same order as the app. */
export function loggedTirePsi(
  setups: { values: { adjusterKey: string; valueNum: number }[] }[]
): { front?: number; rear?: number } {
  let front: number | undefined;
  let rear: number | undefined;
  for (const s of setups) {
    for (const v of s.values) {
      if (v.adjusterKey === "tire_front.pressure_psi" && front == null) {
        front = v.valueNum;
      }
      if (v.adjusterKey === "tire_rear.pressure_psi" && rear == null) {
        rear = v.valueNum;
      }
    }
    if (front != null && rear != null) break;
  }
  return { front, rear };
}

/** e.g. `1.8 / 2.0 bar` or `26 psi`. */
export function formatLoggedTirePressure(
  setups: { values: { adjusterKey: string; valueNum: number }[] }[],
  usesBar: boolean
): string | null {
  const pair = loggedTirePsi(setups);
  if (pair.front == null && pair.rear == null) return null;
  const unit = usesBar ? "bar" : "psi";
  if (pair.front != null && pair.rear != null) {
    return `${formatPressureValue(pair.front, usesBar)} / ${formatPressureValue(pair.rear, usesBar)} ${unit}`;
  }
  const one = pair.front ?? pair.rear!;
  return `${formatPressureValue(one, usesBar)} ${unit}`;
}
