/**
 * Die Box — Werkstatt IA. Tab stays Werkstatt; this is the resident stall.
 * Mirrors mobile/lib/domain/garage/die_box.dart
 */
import type { Bike, BikeCategory, BikeComponent, ComponentSlot, Setup } from "@/types/garage";
import type { MaintenanceLogEntry } from "@/types/garage";

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

  const chips: DieBoxChip[] = [];
  const wheel = wheelLabel(bike);
  if (wheel) chips.push({ label: wheel, known: true });
  if (everyday) {
    chips.push({ label: "Licht", known: hasLights });
    chips.push({ label: "Schloss", known: hasLock });
    chips.push({ label: "Träger", known: hasRack });
    chips.push({ label: "Kette", known: hasChain || chainMeasured });
    chips.push({ label: "Druck", known: pressureKnown });
  }
  if (gravel) {
    chips.push({ label: "Druck", known: pressureKnown });
    chips.push({ label: "Taschen", known: hasBags });
    chips.push({ label: "Cockpit", known: true });
    chips.push({ label: "Kette", known: hasChain || chainMeasured });
  }
  if (road) {
    chips.push({ label: "Druck", known: pressureKnown });
    chips.push({ label: "Kette", known: chainMeasured });
    chips.push({ label: "Cockpit", known: true });
  }
  if (mtb) {
    if (hasSuspension) {
      chips.push({
        label: `${bike.travelFrontMm ?? "–"}/${bike.travelRearMm ?? "–"} mm`,
        known: true,
      });
      chips.push({ label: "SAG", known: sagKnown });
    } else {
      chips.push({ label: "Federweg", known: false });
    }
    chips.push({ label: "Reifen", known: pressureKnown });
    chips.push({ label: "Bremsen", known: hasBrakes });
    if (showParkTrail) chips.push({ label: "Park | Trail", known: true });
  }
  if (hasElectricAssist) {
    chips.push({ label: "CSC", known: !!input.cscPaired });
    chips.push({ label: "Akku ehrlich", known: true });
  }
  if (hasLights && !everyday) chips.push({ label: "Licht", known: true });

  const today: DieBoxTodayItem[] = [];
  if (!bike.isActive) {
    today.push({
      id: "setActive",
      title: "Dieses Rad nach vorn",
      hint: "Ein Bewohner in der Box — Umschalten ist Wohnrecht.",
      cta: "Als aktiv setzen",
    });
  }
  if (everyday && !hasLights) {
    today.push({
      id: "lightsMissing",
      title: "Licht nicht eingetragen",
      hint: "Kein Ghost-Fahrwerk. Nur einhaken, wenn Licht wirklich da ist.",
      cta: "Licht eintragen",
      slot: "light",
    });
  }
  if (everyday && !hasLock) {
    today.push({
      id: "lockMissing",
      title: "Schloss nicht eingetragen",
      hint: "Alltag: anschließen, nicht nur abschließen.",
      cta: "Schloss eintragen",
      slot: "lock",
    });
  }
  if (everyday && !hasRack) {
    today.push({
      id: "rackMissing",
      title: "Gepäckträger nicht eingetragen",
      hint: "Nur wenn das Rad einen hat.",
      cta: "Träger eintragen",
      slot: "rack",
    });
  }
  if (gravel && !hasBags) {
    today.push({
      id: "bagsMissing",
      title: "Taschen nicht eingetragen",
      hint: "Kein erfundenes Apidura-Set — nur wenn Taschen am Rad sind.",
      cta: "Taschen eintragen",
      slot: "bags",
    });
  }
  if ((everyday || gravel || road) && !pressureKnown) {
    today.push({
      id: "pressureUnknown",
      title: "Druck nicht gemessen",
      hint: "Am Rad nachmessen. Keine OEM-Tabelle, kein erfundener psi.",
      cta: "Druck merken",
    });
  }
  if (mtb && hasSuspension && !pressureKnown) {
    today.push({
      id: "pressureUnknown",
      title: "Reifendruck nicht gemessen",
      hint: "psi am Ventil, nicht aus einer Gewichtstabelle.",
      cta: "Druck merken",
    });
  }
  if (mtb && !hasSuspension) {
    today.push({
      id: "travelUnknown",
      title: "Federweg nicht eingetragen",
      hint: "Keine erfundenen Fox-Zahlen. Travel nur wenn er am Rad steht.",
      cta: "Federweg eintragen",
    });
  }
  if (mtb && hasSuspension && !sagKnown) {
    today.push({
      id: "sagUnknown",
      title: "SAG nicht gemessen",
      hint: "O-Ring, Attack-Position, Prozent eintragen. Kein OEM-psi als SAG.",
      cta: "SAG messen",
    });
  }
  if ((road || gravel || everyday) && !chainMeasured) {
    today.push({
      id: "chainTeach",
      title: "Kette noch nicht gemessen",
      hint: "Die Lehre schlägt jede Kilometer-Rechnung. Messen, dann hier merken.",
      cta: "Kette gemessen",
      slot: "chain",
    });
  }
  if (mtb && !hasBrakes) {
    today.push({
      id: "brakesUnknown",
      title: "Beläge nicht eingetragen",
      hint: "Park braucht Beläge in der Box — nur wenn sie am Rad sind.",
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
        ? "Kein km-Orakel. Anschauen und messen."
        : `${a.remainingLabel ?? ""}${a.sourceLabel ? ` · ${a.sourceLabel}` : ""}`,
      cta: "Erledigt",
      slot: a.slot,
    });
  }
  if (showParkTrail) {
    today.push({
      id: "parkTrail",
      title: "Park oder Trail",
      hint: "Nur weil beide Setups existieren — kein zweiter Modus erfunden.",
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
  });

  const addable = addableSlotsFor({ kind, hasSuspension, hasElectricAssist });
  const onBike: BikeComponent[] = [];
  for (const s of addable) {
    const hit = parts.find((c) => c.slot === s);
    if (hit) onBike.push(hit);
  }
  for (const c of parts) {
    if (!onBike.some((x) => x.id === c.id)) onBike.push(c);
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
}): string {
  if (p.everyday) {
    if (p.readiness === "ready") {
      return `${p.bike.name} · Montag-bereit · Licht und Kette ok`;
    }
    const bits = [
      p.hasLights && p.hasChain ? "Licht und Kette ok" : null,
      !p.pressureKnown ? "Druck nicht gemessen" : null,
      !p.hasLights ? "Licht nicht eingetragen" : null,
    ].filter(Boolean);
    return bits.length === 0
      ? `${p.bike.name} · noch nicht bereit`
      : `${p.bike.name} · ${bits.join(" · ")}`;
  }
  if (p.gravel) {
    const bits = [
      p.wheel ?? "Laufrad offen",
      p.pressureKnown ? "Druck gemerkt" : "Druck grob — nachmessen",
      p.hasBags ? "Taschen da" : "Taschen nicht eingetragen",
    ];
    return `${p.bike.name} · ${bits.join(" · ")}`;
  }
  if (p.road) {
    const bits = [
      p.wheel ?? "700c",
      p.chainMeasured ? "Kette gemessen" : "Kette noch nicht gemessen",
      p.pressureKnown ? "Druck gemerkt" : "Druck heute offen",
    ];
    return `${p.bike.name} · ${bits.join(" · ")}`;
  }
  if (p.mtb) {
    if (p.showParkTrail && p.park?.isCurrent) {
      return `Park-Setup · ${p.sagKnown ? "SAG gemerkt" : "SAG nicht gemessen"}`;
    }
    if ((p.bike.travelFrontMm ?? 0) === 0 && (p.bike.travelRearMm ?? 0) === 0) {
      return `${p.bike.name} · Federweg nicht eingetragen`;
    }
    const travel = `${p.bike.travelFrontMm ?? "–"}/${p.bike.travelRearMm ?? "–"}`;
    return `${p.bike.name} · ${travel} · ${p.sagKnown ? "SAG gemerkt" : "SAG nicht gemessen"}`;
  }
  return `${p.bike.name}`;
}

export function dieBoxReadinessLabel(r: DieBoxReadiness): string {
  if (r === "ready") return "Bereit";
  if (r === "almost") return "Fast";
  return "Unbekannt";
}
