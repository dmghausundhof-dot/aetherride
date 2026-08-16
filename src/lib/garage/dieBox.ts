/**
 * Die Box — Werkstatt IA. Tab stays Werkstatt; this is the resident stall.
 * Mirrors mobile/lib/domain/garage/die_box.dart
 */
import type { Bike, BikeCategory, BikeComponent, ComponentSlot, Setup } from "@/types/garage";
import type { MaintenanceLogEntry } from "@/types/garage";
import { catalogDriveIdentity } from "@/lib/catalog/bikes";

export type WerkstattKind = "mtb" | "gravel" | "road" | "urban" | "hiking";
export type DieBoxReadiness = "ready" | "almost" | "unknown";

export type DieBoxItemId =
  | "setActive"
  | "pressureUnknown"
  | "sagUnknown"
  | "travelUnknown"
  | "chainTeach"
  | "lightsMissing"
  | "lockMissing"
  | "rackMissing"
  | "bagsMissing"
  | "brakesUnknown"
  | "dueCare"
  | "pairCsc"
  | "parkTrail";

export type DieBoxChip = { label: string; known: boolean };
export type DieBoxTodayItem = {
  id: DieBoxItemId;
  title: string;
  hint: string;
  cta: string;
  slot?: ComponentSlot;
};

export type DieBoxPlan = {
  kind: WerkstattKind;
  hasElectricAssist: boolean;
  hasSuspension: boolean;
  readiness: DieBoxReadiness;
  sentence: string;
  chips: DieBoxChip[];
  today: DieBoxTodayItem[];
  onBike: BikeComponent[];
  addableSlots: ComponentSlot[];
  showParkTrail: boolean;
  parkSetup?: Setup;
  trailSetup?: Setup;
  primary: DieBoxTodayItem | null;
  heuteRest: DieBoxTodayItem[];
  isReady: boolean;
};

export function werkstattKindFor(category: BikeCategory): WerkstattKind {
  if (
    category === "mtb_trail" ||
    category === "mtb_am" ||
    category === "mtb_enduro" ||
    category === "dh" ||
    category === "emtb"
  ) {
    return "mtb";
  }
  if (category === "gravel") return "gravel";
  if (category === "road") return "road";
  if (category === "hiking") return "hiking";
  return "urban";
}

function installed(bike: Bike): BikeComponent[] {
  return bike.components.filter((c) => !c.removedAt);
}

function hasSlot(parts: BikeComponent[], slot: ComponentSlot): boolean {
  return parts.some((c) => c.slot === slot);
}

function userLoggedPressure(setups: Setup[]): boolean {
  return setups.some(
    (s) =>
      s.createdBy === "user" &&
      s.values.some(
        (v) =>
          v.adjusterKey === "tire_front.pressure_psi" ||
          v.adjusterKey === "tire_rear.pressure_psi"
      )
  );
}

function userLoggedSag(setups: Setup[]): boolean {
  return setups.some(
    (s) =>
      s.createdBy === "user" &&
      s.values.some(
        (v) => v.adjusterKey === "fork.sag_pct" || v.adjusterKey === "shock.sag_pct"
      )
  );
}

function logMentions(
  logs: MaintenanceLogEntry[],
  bikeId: string,
  needle: string
): boolean {
  const n = needle.toLowerCase();
  return logs.some((e) => {
    if (e.bikeId !== bikeId) return false;
    return `${e.activity ?? ""} ${e.notes ?? ""}`.toLowerCase().includes(n);
  });
}

function isPark(s: Setup): boolean {
  const blob = `${s.conditions} ${s.label}`.toLowerCase();
  return blob.includes("bikepark") || blob.includes("park") || blob.includes("dh");
}

function isTrail(s: Setup): boolean {
  const blob = `${s.conditions} ${s.label}`.toLowerCase();
  return (
    blob.includes("trail") ||
    blob.includes("general") ||
    blob.includes("wet") ||
    blob.includes("dry") ||
    blob.includes("mixed")
  );
}

function wheelLabel(bike: Bike): string | undefined {
  if (!bike.wheelSizeFront) return undefined;
  if (bike.wheelSizeFront === "700c") return "700c";
  if (bike.wheelSizeFront === "650b") return "650b";
  if (bike.wheelSizeFront === "29") return '29"';
  if (bike.wheelSizeFront === "27_5") return '27.5"';
  return bike.wheelSizeFront;
}

export function addableSlotsFor(input: {
  kind: WerkstattKind;
  hasSuspension: boolean;
  hasElectricAssist: boolean;
}): ComponentSlot[] {
  if (input.kind === "hiking") {
    return ["hiking_shoes", "hiking_pack", "hiking_poles"];
  }
  const slots = new Set<ComponentSlot>([
    "tire_front",
    "tire_rear",
    "chain",
    "brake_front",
    "brake_rear",
  ]);
  if (input.kind === "urban") {
    slots.add("light");
    slots.add("lock");
    slots.add("rack");
    slots.add("handlebar");
    slots.add("stem");
  }
  if (input.kind === "gravel") slots.add("bags");
  if (input.kind === "gravel" || input.kind === "road") {
    slots.add("handlebar");
    slots.add("stem");
    slots.add("cassette");
  }
  if (input.hasSuspension) {
    slots.add("fork");
    slots.add("rear_shock");
  }
  if (input.hasElectricAssist) {
    slots.add("motor");
    slots.add("battery");
    slots.add("display");
  }
  return [...slots];
}

export function planDieBox(input: {
  bike: Bike;
  logs?: MaintenanceLogEntry[];
  due?: { slot?: ComponentSlot; label: string; remainingLabel?: string; sourceLabel?: string }[];
  cscPaired?: boolean;
}): DieBoxPlan {
  const { bike } = input;
  const logs = input.logs ?? [];
  const due = input.due ?? [];
  const kind = werkstattKindFor(bike.category);
  const parts = installed(bike);
  const hasFork = hasSlot(parts, "fork");
  const hasShock = hasSlot(parts, "rear_shock");
  const travelF = bike.travelFrontMm ?? 0;
  const travelR = bike.travelRearMm ?? 0;
  const hasSuspension = travelF > 0 || travelR > 0 || hasFork || hasShock;
  const hasElectricAssist =
    bike.isEbike || bike.category === "emtb" || bike.category === "etrekking";
  const setups = bike.setups ?? [];

  const hasLights = hasSlot(parts, "light");
  const hasLock = hasSlot(parts, "lock");
  const hasRack = hasSlot(parts, "rack");
  const hasBags = hasSlot(parts, "bags");
  const hasChain = hasSlot(parts, "chain");
  const hasBrakes = hasSlot(parts, "brake_front") || hasSlot(parts, "brake_rear");
  const pressureKnown =
    userLoggedPressure(setups) || logMentions(logs, bike.id, "druck");
  const sagKnown = hasSuspension && userLoggedSag(setups);
  const chainMeasured =
    logMentions(logs, bike.id, "kette gemessen") ||
    logMentions(logs, bike.id, "chain_measured");

  const everyday = kind === "urban";
  const gravel = kind === "gravel";
  const road = kind === "road";
  const mtb = kind === "mtb";

  let park: Setup | undefined;
  let trail: Setup | undefined;
  for (const s of setups) {
    if (!park && isPark(s)) park = s;
    if (!trail && isTrail(s) && !isPark(s)) trail = s;
  }
  const showParkTrail = mtb && !!park && !!trail;

  const hasCockpit = hasSlot(parts, "handlebar") || hasSlot(parts, "stem");

  const chips: DieBoxChip[] = [];
  const wheel = wheelLabel(bike);
  if (wheel) chips.push({ label: wheel, known: true });
  if (everyday) {
    if (hasLights) chips.push({ label: "Licht", known: true });
    if (hasLock) chips.push({ label: "Schloss", known: true });
    if (hasRack) chips.push({ label: "Träger", known: true });
    if (hasChain || chainMeasured) chips.push({ label: "Kette", known: true });
    if (pressureKnown) chips.push({ label: "Druck", known: true });
  }
  if (gravel) {
    if (pressureKnown) chips.push({ label: "Druck", known: true });
    if (hasBags) chips.push({ label: "Taschen", known: true });
    if (hasCockpit) chips.push({ label: "Cockpit", known: true });
    if (hasChain || chainMeasured) chips.push({ label: "Kette", known: true });
  }
  if (road) {
    if (pressureKnown) chips.push({ label: "Druck", known: true });
    if (chainMeasured) chips.push({ label: "Kette", known: true });
    if (hasCockpit) chips.push({ label: "Cockpit", known: true });
  }
  if (mtb) {
    if (hasSuspension && (travelF > 0 || travelR > 0)) {
      chips.push({
        label: `${bike.travelFrontMm ?? "–"}/${bike.travelRearMm ?? "–"} mm`,
        known: true,
      });
    }
    if (sagKnown) chips.push({ label: "SAG", known: true });
    if (pressureKnown) chips.push({ label: "Reifen", known: true });
    if (hasBrakes) chips.push({ label: "Bremsen", known: true });
    if (showParkTrail) chips.push({ label: "Park | Trail", known: true });
  }
  const drive = hasElectricAssist
    ? catalogDriveIdentity(bike.catalogBikeId)
    : {};
  if (hasElectricAssist) {
    if (drive.motor) chips.push({ label: drive.motor, known: true });
    if (drive.battery) chips.push({ label: drive.battery, known: true });
    if (input.cscPaired) chips.push({ label: "CSC", known: true });
  }
  if (hasLights && !everyday) chips.push({ label: "Licht", known: true });

  const today: DieBoxTodayItem[] = [];
  if (!bike.isActive) {
    today.push({
      id: "setActive",
      title: "Dieses Rad nach vorn",
      hint: "Eines steht in der Box — Umschalten holt es nach vorn.",
      cta: "Als aktiv setzen",
    });
  }
  if (everyday && !hasLights) {
    today.push({
      id: "lightsMissing",
      title: "Licht eintragen",
      hint: "Nur wenn Licht wirklich am Rad ist.",
      cta: "Licht eintragen",
      slot: "light",
    });
  }
  if (everyday && !hasLock) {
    today.push({
      id: "lockMissing",
      title: "Schloss eintragen",
      hint: "Nur wenn ein Schloss am Rad ist.",
      cta: "Schloss eintragen",
      slot: "lock",
    });
  }
  if (everyday && !hasRack) {
    today.push({
      id: "rackMissing",
      title: "Träger eintragen",
      hint: "Nur wenn das Rad einen Gepäckträger hat.",
      cta: "Träger eintragen",
      slot: "rack",
    });
  }
  if (gravel && !hasBags) {
    today.push({
      id: "bagsMissing",
      title: "Taschen eintragen",
      hint: "Nur wenn Taschen am Rad sind.",
      cta: "Taschen eintragen",
      slot: "bags",
    });
  }
  if ((everyday || gravel || road) && !pressureKnown) {
    today.push({
      id: "pressureUnknown",
      title: "Druck merken",
      hint: "Vorn und hinten am Ventil ablesen.",
      cta: "Druck merken",
    });
  }
  if (mtb && hasSuspension && !pressureKnown) {
    today.push({
      id: "pressureUnknown",
      title: "Reifendruck merken",
      hint: "Vorn und hinten am Ventil ablesen.",
      cta: "Druck merken",
    });
  }
  if (mtb && !hasSuspension) {
    today.push({
      id: "travelUnknown",
      title: "Federweg eintragen",
      hint: "Nur der Federweg, der am Rad steht.",
      cta: "Federweg eintragen",
    });
  }
  if (mtb && hasSuspension && !sagKnown) {
    today.push({
      id: "sagUnknown",
      title: "Federung merken",
      hint: "Eine Zahl an Gabel und Dämpfer, abgelesen am Rad.",
      cta: "Federung merken",
    });
  }
  if ((road || gravel || everyday) && !chainMeasured) {
    today.push({
      id: "chainTeach",
      title: "Kette merken",
      hint: "Mit der Lehre messen, dann hier merken.",
      cta: "Kette gemessen",
      slot: "chain",
    });
  }
  if (mtb && !hasBrakes) {
    today.push({
      id: "brakesUnknown",
      title: "Bremsen eintragen",
      hint: "Nur wenn Beläge am Rad sind.",
      cta: "Bremse eintragen",
      slot: "brake_front",
    });
  }
  for (const a of due.slice(0, 4)) {
    const teachChain = a.slot === "chain";
    today.push({
      id: "dueCare",
      title: teachChain ? "Kette mit der Lehre prüfen" : a.label,
      hint: teachChain
        ? "Anschauen und mit der Lehre messen."
        : `${a.remainingLabel ?? ""}${a.sourceLabel ? ` · ${a.sourceLabel}` : ""}`,
      cta: "Erledigt",
      slot: a.slot,
    });
  }
  if (showParkTrail) {
    today.push({
      id: "parkTrail",
      title: "Park oder Trail",
      hint: "Beide Setups sind da — wechseln, wenn du willst.",
      cta: "Wechseln",
    });
  }

  const unknownCount = today.filter(
    (t) => t.id !== "setActive" && t.id !== "dueCare" && t.id !== "parkTrail"
  ).length;
  const hasDue = today.some((t) => t.id === "dueCare");
  let readiness: DieBoxReadiness;
  if (!bike.isActive) readiness = "almost";
  else if (unknownCount === 0 && !hasDue) readiness = "ready";
  else if (unknownCount <= 2 && !hasDue) readiness = "almost";
  else readiness = "unknown";

  const sentence = buildSentence({
    bike,
    kind,
    readiness,
    everyday,
    gravel,
    road,
    mtb,
    hasLights,
    hasChain: hasChain || chainMeasured,
    pressureKnown,
    sagKnown,
    hasBags,
    chainMeasured,
    showParkTrail,
    park,
    wheel,
    motorLabel: drive.motor,
  });

  const addable = addableSlotsFor({ kind, hasSuspension, hasElectricAssist });
  const onBike: BikeComponent[] = [];
  for (const s of addable) {
    const hit = parts.find((c) => c.slot === s);
    if (hit) onBike.push(hit);
  }
  for (const c of parts) {
    if (onBike.some((x) => x.id === c.id)) continue;
    const explicit = Boolean(c.freeText) && !c.componentModelId;
    if (explicit) onBike.push(c);
  }

  return {
    kind,
    hasElectricAssist,
    hasSuspension,
    readiness,
    sentence,
    chips,
    today,
    onBike,
    addableSlots: addable,
    showParkTrail,
    parkSetup: park,
    trailSetup: trail,
    primary: today[0] ?? null,
    heuteRest: today.slice(1),
    isReady: readiness === "ready" && today.length === 0,
  };
}

function buildSentence(p: {
  bike: Bike;
  kind: WerkstattKind;
  readiness: DieBoxReadiness;
  everyday: boolean;
  gravel: boolean;
  road: boolean;
  mtb: boolean;
  hasLights: boolean;
  hasChain: boolean;
  pressureKnown: boolean;
  sagKnown: boolean;
  hasBags: boolean;
  chainMeasured: boolean;
  showParkTrail: boolean;
  park?: Setup;
  wheel?: string;
  motorLabel?: string;
}): string {
  if (p.everyday) {
    if (p.readiness === "ready") {
      return `${p.bike.name} wohnt hier · Montag-bereit`;
    }
    return `${p.bike.name} wohnt hier`;
  }
  if (p.gravel) {
    const bits = [
      p.wheel,
      p.pressureKnown ? "Druck gemerkt" : null,
      p.hasBags ? "Taschen da" : null,
    ].filter(Boolean);
    const core =
      bits.length === 0
        ? `${p.bike.name} wohnt hier`
        : `${p.bike.name} · ${bits.join(" · ")}`;
    return p.readiness === "ready" ? `${core} · bereit` : core;
  }
  if (p.road) {
    const bits = [
      p.wheel,
      p.chainMeasured ? "Kette gemessen" : null,
      p.pressureKnown ? "Druck gemerkt" : null,
    ].filter(Boolean);
    const core =
      bits.length === 0
        ? `${p.bike.name} wohnt hier`
        : `${p.bike.name} · ${bits.join(" · ")}`;
    return p.readiness === "ready" ? `${core} · bereit` : core;
  }
  if (p.mtb) {
    if (p.showParkTrail && p.park?.isCurrent) {
      return "Park-Setup";
    }
    if ((p.bike.travelFrontMm ?? 0) === 0 && (p.bike.travelRearMm ?? 0) === 0) {
      return `${p.bike.name} wohnt hier`;
    }
    const travel = `${p.bike.travelFrontMm ?? "–"}/${p.bike.travelRearMm ?? "–"}`;
    const drive = p.motorLabel ? ` · ${p.motorLabel}` : "";
    const core = `${p.bike.name} · ${travel}${drive}`;
    return p.readiness === "ready" ? `${core} · bereit` : core;
  }
  return `${p.bike.name} wohnt hier`;
}

export function dieBoxReadinessLabel(r: DieBoxReadiness): string {
  if (r === "ready") return "Bereit";
  if (r === "almost") return "Fast bereit";
  return "Neu hier";
}
