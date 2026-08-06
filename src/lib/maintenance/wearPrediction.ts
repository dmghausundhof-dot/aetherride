/**
 * F-GAR-005 P1 — Belastungsgewichtete Verschleißprognose
 *
 * Ausgabe IMMER als Spanne („Belagwechsel in 250–400 km"), nie als Punktwert.
 *
 * Quellen (Magazine / Wartungs-Apps / Herstellerpraxis):
 * - Velopit Serviceintervalle 2026: Kette MTB 1.000–1.800 km; Kassette 3.000–5.000 km;
 *   Beläge 1.500–4.000 km bzw. Bergfahrer 800–2.500 km
 * - Velopit / Bavarian Bike / Park Tool: Wechselziel 0,5 % Längung (11-/12-fach)
 * - BIKE Magazin: Belagdicke < 0,5–1 mm = Wechsel; Matsch/Regen kann Beläge an einem Tag abraspeln
 * - Linexo E-Bike: E-MTB-Ketten oft 1.000–2.000 km, früher prüfen wegen Drehmoment
 */

import type { Bike, BikeComponent, Ride } from "@/types";

export type WearKind =
  | "chain"
  | "brake_pads_front"
  | "brake_pads_rear"
  | "cassette"
  | "tires";

export interface WearForecast {
  kind: WearKind;
  slotLabel: string;
  /** Verbrauchte Lebensdauer 0–1+ */
  usedRatio: number;
  remainingKmLow: number;
  remainingKmHigh: number;
  label: string;
  reasoning: string;
  sourceLabel: string;
  dueSoon: boolean;
}

function activeComp(bike: Bike, slot: string): BikeComponent | undefined {
  return bike.components.find((c) => c.slot === slot && !c.removedAt);
}

function ridesForComp(bike: Bike, comp: BikeComponent, rides: Ride[]): Ride[] {
  const start = new Date(comp.installedAt).getTime();
  const end = comp.removedAt ? new Date(comp.removedAt).getTime() : Date.now();
  return rides.filter((r) => {
    if (r.bikeId !== bike.id) return false;
    const t = new Date(r.startTime).getTime();
    return t >= start && t <= end;
  });
}

function sumKm(rides: Ride[]): number {
  return rides.reduce((s, r) => s + r.distanceM / 1000, 0);
}

/** Abfahrts-HM-Proxy: ohne Negativ-Höhenmeter ≈ ElevGain (Rundkurs-Annahme) */
function sumDescentProxy(rides: Ride[]): number {
  return rides.reduce((s, r) => s + r.elevationGainM, 0);
}

function sumMovingHours(rides: Ride[]): number {
  return rides.reduce((s, r) => s + r.durationSec / 3600, 0);
}

function sumHardImpacts(rides: Ride[]): number {
  return rides.reduce((s, r) => s + (r.summaryMetrics.impactCount || 0), 0);
}

/** Nässe-Indikator: Wetter-API-Platzhalter über Ride-Notes (Spec: Wetter zum Ride-Zeitpunkt) */
function wetRideShare(rides: Ride[]): number {
  if (rides.length === 0) return 0.15; // Unsicherheit ohne Daten
  const wet = rides.filter((r) =>
    /nass|regen|wet|mud|matsch|schlamm/i.test(r.notes ?? "")
  ).length;
  return wet / rides.length;
}

function rangeRemaining(
  lifeKmLow: number,
  lifeKmHigh: number,
  usedKmEffective: number
): { low: number; high: number; ratio: number } {
  const mid = (lifeKmLow + lifeKmHigh) / 2;
  const ratio = usedKmEffective / mid;
  return {
    low: Math.max(0, Math.round(lifeKmLow - usedKmEffective)),
    high: Math.max(0, Math.round(lifeKmHigh - usedKmEffective * 0.85)),
    ratio,
  };
}

export function forecastWear(bike: Bike, rides: Ride[]): WearForecast[] {
  const out: WearForecast[] = [];
  // E-MTB: höheres Drehmoment → kürzeres Kettenleben (Linexo / Praxis ≈ 0,7×)
  const eFactor = bike.isEbike ? 0.7 : 1;

  const chain = activeComp(bike, "chain");
  if (chain) {
    const rr = ridesForComp(bike, chain, rides);
    const km = sumKm(rr);
    const hours = sumMovingHours(rr);
    const wet = wetRideShare(rr);
    // Nässe beschleunigt Abrieb (BIKE / Velopit); Faktor 1 + bis 0,35
    const wetPenalty = 1 + wet * 0.35;
    const effective = (km / eFactor) * wetPenalty + hours * 8;
    // Velopit MTB 1000–1800; Road etwas höher → Kategorie-Spanne
    const lifeLow =
      bike.category === "road" || bike.category === "gravel" ? 1500 : 1000;
    const lifeHigh =
      bike.category === "road" || bike.category === "gravel" ? 3000 : 1800;
    const rem = rangeRemaining(lifeLow, lifeHigh, effective);
    out.push({
      kind: "chain",
      slotLabel: "Kette",
      usedRatio: rem.ratio,
      remainingKmLow: rem.low,
      remainingKmHigh: rem.high,
      label: `Kettenwechsel in ${rem.low}–${rem.high} km`,
      reasoning: `Basis ${lifeLow}–${lifeHigh} km (Velopit 2026); gemessen ≈ ${km.toFixed(0)} km + ${hours.toFixed(1)} h. ${
        bike.isEbike ? "E-MTB-Drehmoment-Faktor 0,7 (Linexo). " : ""
      }Nässe-Anteil ${(wet * 100).toFixed(0)} % in der Spanne. Wechselziel 0,5 % Längung (11-/12-fach, Park Tool / Bavarian Bike).`,
      sourceLabel: "Velopit 2026 · Bavarian Bike · BIKE Magazin · Linexo",
      dueSoon: rem.ratio >= 0.75,
    });
  }

  const padsF = activeComp(bike, "brake_pads_front");
  if (padsF) {
    const rr = ridesForComp(bike, padsF, rides);
    const descent = sumDescentProxy(rr);
    const impacts = sumHardImpacts(rr);
    const wet = wetRideShare(rr);
    // Bergfahrer ~3× schneller (Velopit); Abfahrts-HM + Impacts + Nässe (BIKE: Matsch-Tag)
    const effectiveKm =
      descent / 40 + impacts * 2 + sumKm(rr) * 0.3 + wet * sumKm(rr) * 0.4;
    const lifeLow = 800;
    const lifeHigh = 2500;
    const rem = rangeRemaining(lifeLow, lifeHigh, effectiveKm);
    out.push({
      kind: "brake_pads_front",
      slotLabel: "Bremsbeläge vorne",
      usedRatio: rem.ratio,
      remainingKmLow: rem.low,
      remainingKmHigh: rem.high,
      label: `Belagwechsel vorne in ${rem.low}–${rem.high} km`,
      reasoning: `Skaliert mit Abfahrts-HM (Proxy ${descent.toFixed(0)} hm), ${impacts} Impacts, Nässe ${(wet * 100).toFixed(0)} %. Spanne Bergfahrer 800–2500 km (Velopit); Wechsel bei < 0,5–1 mm Belagdicke (BIKE Magazin).`,
      sourceLabel: "Velopit MTB-Wartung · BIKE Magazin Belagsverschleiß",
      dueSoon: rem.ratio >= 0.75,
    });
  }

  const padsR = activeComp(bike, "brake_pads_rear");
  if (padsR) {
    const rr = ridesForComp(bike, padsR, rides);
    const descent = sumDescentProxy(rr);
    const impacts = sumHardImpacts(rr);
    const wet = wetRideShare(rr);
    const effectiveKm =
      descent / 35 + impacts * 2.2 + sumKm(rr) * 0.35 + wet * sumKm(rr) * 0.45;
    const lifeLow = 700;
    const lifeHigh = 2200;
    const rem = rangeRemaining(lifeLow, lifeHigh, effectiveKm);
    out.push({
      kind: "brake_pads_rear",
      slotLabel: "Bremsbeläge hinten",
      usedRatio: rem.ratio,
      remainingKmLow: rem.low,
      remainingKmHigh: rem.high,
      label: `Belagwechsel hinten in ${rem.low}–${rem.high} km`,
      reasoning: `Hintere Beläge oft früher; Abfahrts-HM ${descent.toFixed(0)}, Impacts ${impacts}. Nie Punktwert — immer Spanne (Spec F-GAR-005).`,
      sourceLabel: "Velopit · BIKE Magazin · Industriepraxis",
      dueSoon: rem.ratio >= 0.75,
    });
  }

  const cassette = activeComp(bike, "cassette");
  if (cassette) {
    const rr = ridesForComp(bike, cassette, rides);
    const km = sumKm(rr);
    // Velopit: 3000–5000 km wenn Kette rechtzeitig gewechselt (2–3 Ketten)
    const rem = rangeRemaining(3000, 5000, km / eFactor);
    out.push({
      kind: "cassette",
      slotLabel: "Kassette",
      usedRatio: rem.ratio,
      remainingKmLow: rem.low,
      remainingKmHigh: rem.high,
      label: `Kassette prüfen in ${rem.low}–${rem.high} km`,
      reasoning: `Hält typisch 2–3 Ketten (3.000–5.000 km, Velopit), sofern Kette bei 0,5 % gewechselt wird. Bei > 1 % Längung oft Kette+Kassette (Bavarian Bike).`,
      sourceLabel: "Velopit 2026 · Bavarian Bike · Zero Friction Praxis",
      dueSoon: rem.ratio >= 0.8,
    });
  }

  const tireF = activeComp(bike, "tire_front");
  if (tireF) {
    const rr = ridesForComp(bike, tireF, rides);
    const km = sumKm(rr);
    const lifeLow =
      bike.category === "road" || bike.category === "gravel" ? 3000 : 1500;
    const lifeHigh =
      bike.category === "road" || bike.category === "gravel" ? 7000 : 4000;
    const rem = rangeRemaining(lifeLow, lifeHigh, km);
    out.push({
      kind: "tires",
      slotLabel: "Vorderradreifen",
      usedRatio: rem.ratio,
      remainingKmLow: rem.low,
      remainingKmHigh: rem.high,
      label: `Reifen prüfen in ${rem.low}–${rem.high} km`,
      reasoning: `MTB 1.500–4.000 km / Straße 3.000–7.000 km (Velopit). Stollenrundung = Grip weg — Sichtprüfung vor jeder Tour.`,
      sourceLabel: "Velopit Serviceintervalle 2026",
      dueSoon: rem.ratio >= 0.85,
    });
  }

  return out;
}
