/**
 * Gate-Status-Registry — ehrlich, alle Flags bleiben false bis Sign-off.
 * Kein Auto-Close; UI/Tests lesen diese Quelle.
 */

import { G0_MOBILE_STACK_CONFIRMED } from "@/lib/platform/g0TeamSetup";
import { G1_BOSCH_ACCESS_CLEARED } from "@/lib/ble/g1BoschOutreach";
import { G2_SUSPENSION_GATE_PASSED } from "@/lib/sensor/fni";
import { G5_LEGAL_REVIEW_PASSED } from "@/lib/routing/legalReview";
import { A08_LEGAL_REVIEW_PASSED } from "@/lib/legal/setupLiability";
import { A06_LEGAL_REVIEW_PASSED } from "@/lib/legal/a06OdblBrief";

export interface GateStatusRow {
  id: "G-0" | "G-1" | "G-2" | "G-4" | "G-5" | "A-06" | "A-08";
  titleDe: string;
  passed: boolean;
  packHintDe: string;
  blocksDe: string;
}

/** G-4 hat kein Boolean-Flag — Seed vs Spec ≥3000 */
export const G4_CATALOG_SPEC_TARGET = 3000;

export function listGateStatuses(input?: {
  bikeCount?: number;
}): GateStatusRow[] {
  const bikes = input?.bikeCount ?? 0;
  return [
    {
      id: "G-0",
      titleDe: "Mobile Stack (Flutter/Native)",
      passed: G0_MOBILE_STACK_CONFIRMED,
      packHintDe: "Workshop-Ops + nativeContracts — Flag bleibt false bis Stack bestätigt",
      blocksDe: "Native Offline-PMTiles, dsp_core, Valhalla FFI",
    },
    {
      id: "G-1",
      titleDe: "Bosch LDI Zugang",
      passed: G1_BOSCH_ACCESS_CLEARED,
      packHintDe: "Outreach-Pack — Flag false bis Freigabe",
      blocksDe: "Echte LDI-Telemetrie (Stufe 1+)",
    },
    {
      id: "G-2",
      titleDe: "Fahrwerk-Validierung / FNI",
      passed: G2_SUSPENSION_GATE_PASSED,
      packHintDe: "Studienplan — Flag false bis Kriterien erfüllt",
      blocksDe: "Auto-Setup-Übernahme, FNI als mm/%",
    },
    {
      id: "G-4",
      titleDe: "Katalog-Skalierung",
      passed: bikes >= G4_CATALOG_SPEC_TARGET,
      packHintDe: `Seed ${bikes} / Spec ≥${G4_CATALOG_SPEC_TARGET} — Scale-Packs, kein Close`,
      blocksDe: "Vollständige OEM-Abdeckung DACH+",
    },
    {
      id: "G-5",
      titleDe: "Wegerecht Legal Review",
      passed: G5_LEGAL_REVIEW_PASSED,
      packHintDe: "Attorney Brief + Counsel Dispatch — Flag false",
      blocksDe: "Unrestricted Routing in AT-7/DE-BY",
    },
    {
      id: "A-06",
      titleDe: "ODbL / Kartendaten",
      passed: A06_LEGAL_REVIEW_PASSED,
      packHintDe: "ODbL Brief — Flag false",
      blocksDe: "Produktions-Attribution/Derivative Claims",
    },
    {
      id: "A-08",
      titleDe: "Setup-Haftung",
      passed: A08_LEGAL_REVIEW_PASSED,
      packHintDe: "Counsel Brief + Nutzer-Akzeptanz — Legal-Flag false",
      blocksDe: "Finale Haftungsformulierung",
    },
  ];
}

export function allCriticalGatesOpen(): boolean {
  return listGateStatuses().every((g) => {
    if (g.id === "G-4") return true; // Seed-Fortschritt zählt nicht als Close
    return g.passed === false;
  });
}

export function gatesOpenSummary(): string {
  const open = listGateStatuses().filter((g) => !g.passed);
  return `Offen: ${open.map((g) => g.id).join(", ")} — keine Fake-Passes.`;
}
