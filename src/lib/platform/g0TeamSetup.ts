/**
 * G-0 — Team-Setup / Mobile-Stack (Spec §9.2 / §5.1)
 *
 * Gate bestätigt Flutter vs. Native und Backend-Sprache vor Sprint 1.
 * Diese Datei dokumentiert die Entscheidung — sie fälscht keine Flutter-App.
 * Closure: Team setzt G0_MOBILE_STACK_CONFIRMED + decided* Felder.
 */

export const G0_MOBILE_STACK_CONFIRMED: boolean = false;

export type G0Status = "open" | "workshop_done" | "stack_confirmed";
export type MobileStackChoice = "undecided" | "flutter" | "native_swift_kotlin";
export type BackendLanguageChoice = "undecided" | "kotlin" | "go";

export interface G0ChecklistItem {
  id: string;
  label: string;
  done: boolean;
  notes?: string;
}

export interface NativeModuleRow {
  id: string;
  specModule: string;
  iosApi: string;
  androidApi: string;
  channelOrFfi: string;
  webDemo: "simulator" | "stub" | "absent";
  ownerRole: string;
}

export interface G0DecisionRecord {
  status: G0Status;
  chosenStack: MobileStackChoice;
  backendLanguage: BackendLanguageChoice;
  decidedAt: string | null;
  decidedBy: string | null;
  rationale: string | null;
  checklist: G0ChecklistItem[];
  gegenanzeigeApplies: boolean | null;
  sensorBleSpecialistAvailable: boolean | null;
  launchEligible: boolean;
}

export const NATIVE_MODULE_MATRIX: NativeModuleRow[] = [
  {
    id: "sensor_core",
    specModule: "sensor_core",
    iosApi: "CoreMotion",
    androidApi: "SensorManager",
    channelOrFfi: "aetherride/sensor_batch (1-s Batches, kein Sample/Channel)",
    webDemo: "simulator",
    ownerRole: "Mobile Sensor/BLE",
  },
  {
    id: "location_core",
    specModule: "location_core",
    iosApi: "CoreLocation",
    androidApi: "FusedLocationProvider",
    channelOrFfi: "aetherride/location",
    webDemo: "stub",
    ownerRole: "Mobile",
  },
  {
    id: "ble_core",
    specModule: "ble_core",
    iosApi: "CoreBluetooth",
    androidApi: "Android BLE",
    channelOrFfi: "aetherride/ble_standard · ble_bosch_ldi",
    webDemo: "simulator",
    ownerRole: "Mobile Sensor/BLE",
  },
  {
    id: "map_core",
    specModule: "map_core",
    iosApi: "MapLibre / Metal",
    androidApi: "MapLibre / OpenGL",
    channelOrFfi: "aetherride/pmtiles",
    webDemo: "stub",
    ownerRole: "Mobile Maps",
  },
  {
    id: "routing_core",
    specModule: "routing_core",
    iosApi: "Valhalla FFI",
    androidApi: "Valhalla FFI",
    channelOrFfi: "aetherride/routing_valhalla",
    webDemo: "stub",
    ownerRole: "Mobile + Backend",
  },
  {
    id: "dsp_core",
    specModule: "dsp_core (Rust)",
    iosApi: "FFI",
    androidApi: "FFI",
    channelOrFfi: "aetherride/dsp_ffi",
    webDemo: "absent",
    ownerRole: "Native/DSP",
  },
];

export const G0_DECISION: G0DecisionRecord = {
  status: "open",
  chosenStack: "undecided",
  backendLanguage: "undecided",
  decidedAt: null,
  decidedBy: null,
  rationale: null,
  gegenanzeigeApplies: null,
  sensorBleSpecialistAvailable: null,
  launchEligible: false,
  checklist: [
    {
      id: "team-skills",
      label: "Team-Skills erhoben (Flutter vs. 2+2 native Gegenanzeige §5.1)",
      done: false,
    },
    {
      id: "sensor-ble",
      label: "Sensor/BLE-Spezialist:in verfügbar (Spec: nicht verhandelbar)",
      done: false,
    },
    {
      id: "stack-choice",
      label: "Mobile-Stack gewählt: Flutter oder Swift+Kotlin",
      done: false,
    },
    {
      id: "backend-lang",
      label: "Backend-Sprache: genau eine von Kotlin oder Go",
      done: false,
    },
    {
      id: "ffi-owner",
      label: "FFI-Ownership für dsp_core / Batch-Invariante geklärt",
      done: false,
    },
    {
      id: "sprint0-workshop",
      label: "G-0 Decision-Workshop vor Sprint 1 dokumentiert",
      done: false,
    },
  ],
};

export const G0_SPRINT0_PLAN = [
  "Decision-Workshop: Gegenanzeige prüfen, Stack + Backend festlegen",
  "G-1 parallel: Bosch LDI Zugang klären",
  "Shared Spec bleibt TypeScript-Domain; Flutter erst nach G-0 GO",
  "dsp_core Rust-Spike planen (nicht als Web-Demo faken)",
  "Katalog-Werkzeuge / Sync-Ops-Log weiter in Web-Demo pflegen",
] as const;

export const G0_NON_GOALS = [
  "Kein Flutter-Scaffold als G-0-Pass ausgeben",
  "Keine Capability-Flags auf true ohne native Builds",
  "Keine Marketing-Aussage „Mobile-Stack bestätigt“ vor Closure",
] as const;

export function isG0Closed(): boolean {
  return (
    G0_MOBILE_STACK_CONFIRMED === true &&
    G0_DECISION.status === "stack_confirmed" &&
    G0_DECISION.chosenStack !== "undecided" &&
    G0_DECISION.backendLanguage !== "undecided" &&
    G0_DECISION.decidedAt != null
  );
}

export type G0GoNoGo = "go_flutter" | "go_native" | "no_go";

export function evaluateG0GoNoGo(): {
  result: G0GoNoGo;
  reasons: string[];
} {
  const reasons: string[] = [];
  if (G0_DECISION.sensorBleSpecialistAvailable === false) {
    reasons.push("Kein Sensor/BLE-Spezialist — Sprint 1 NO-GO (Spec).");
    return { result: "no_go", reasons };
  }
  if (G0_DECISION.chosenStack === "undecided") {
    reasons.push("Mobile-Stack unentschieden — Gate G-0 offen.");
    return { result: "no_go", reasons };
  }
  if (G0_DECISION.backendLanguage === "undecided") {
    reasons.push("Backend-Sprache unentschieden.");
    return { result: "no_go", reasons };
  }
  if (G0_DECISION.gegenanzeigeApplies === true) {
    reasons.push(
      "Gegenanzeige §5.1: 2+2 native ohne Flutter → Swift+Kotlin neu bewerten."
    );
    return {
      result:
        G0_DECISION.chosenStack === "native_swift_kotlin"
          ? "go_native"
          : "no_go",
      reasons,
    };
  }
  if (G0_DECISION.chosenStack === "flutter") {
    reasons.push("Flutter bestätigt (nach Team-Skill-Check).");
    return { result: "go_flutter", reasons };
  }
  reasons.push("Native Swift+Kotlin bestätigt.");
  return { result: "go_native", reasons };
}

export function g0StatusBadge(): string {
  return isG0Closed() ? "Gate G-0 geschlossen" : "Gate G-0 offen";
}

export function g0StatusShort(): string {
  if (isG0Closed()) {
    return `Mobile-Stack bestätigt: ${G0_DECISION.chosenStack} · Backend ${G0_DECISION.backendLanguage}.`;
  }
  return "Web-Demo · Mobile-Stack unbestätigt · G-0 vor Sprint 1 klären (keine Flutter-App vorgetäuscht).";
}
