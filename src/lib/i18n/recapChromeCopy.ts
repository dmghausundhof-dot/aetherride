import type { ChromeLang } from "./chromeLang";

function fill(template: string, params: Record<string, string>): string {
  return template.replace(/\{(\w+)\}/g, (_, k) => params[k] ?? "");
}

export type RecapChromeCopy = {
  assistApproach: string;
  assistClimb: string;
  assistRest: string;
  assistManual: string;
  assistDisclaimer: string;
  sourceEstimated: string;
  sourceOem: string;
  sourceManual: string;
  chipFork: string;
  chipRebound: string;
  chipTireFront: string;
  condGeneral: string;
  condDry: string;
  condWet: string;
  condMixed: string;
  condBikepark: string;
  condRace: string;
  setupNamed: string;
  confPrefix: string;
  confLow: string;
  confMedium: string;
  confHigh: string;
  recWear: string;
  recSetupLimit: string;
  recFeel: string;
  recSeason: string;
  maintOverdue: string;
  maintSoon: string;
};

const DE: RecapChromeCopy = {
  assistApproach: "Schätzung: {mode} (Anfahrt)",
  assistClimb: "Schätzung: {mode} (Steigung, {pct} %)",
  assistRest: "Schätzung: {mode} (Rest)",
  assistManual: "Manuell: {mode}",
  assistDisclaimer:
    "Schätzungen aus Leistungs-/Geschwindigkeitssignatur — kein OEM-Auslesen. Keine Motorsteuerung.",
  sourceEstimated: "Schätzung",
  sourceOem: "OEM",
  sourceManual: "manuell",
  chipFork: "Gabel",
  chipRebound: "Zug",
  chipTireFront: "Reifen V",
  condGeneral: "Allgemein",
  condDry: "Trocken",
  condWet: "Nass",
  condMixed: "Gemischt",
  condBikepark: "Bikepark",
  condRace: "Rennen",
  setupNamed: "Setup „{label}“ · {conditions}",
  confPrefix: "Konfidenz",
  confLow: "niedrig",
  confMedium: "mittel",
  confHigh: "hoch",
  recWear: "{name} — wegen Verschleißprognose",
  recSetupLimit: "{name} — Setup am Anschlag",
  recFeel: "{name} — wiederkehrendes Fahrgefühl",
  recSeason: "{name} — Saisonwechsel nass",
  maintOverdue: "Wartung überfällig",
  maintSoon: "Wartung bald fällig",
};

const EN: RecapChromeCopy = {
  assistApproach: "Estimate: {mode} (approach)",
  assistClimb: "Estimate: {mode} (climb, {pct} %)",
  assistRest: "Estimate: {mode} (rest)",
  assistManual: "Manual: {mode}",
  assistDisclaimer:
    "Estimates from power/speed signature — not OEM readout. No motor control.",
  sourceEstimated: "estimate",
  sourceOem: "OEM",
  sourceManual: "manual",
  chipFork: "Fork",
  chipRebound: "Rebound",
  chipTireFront: "Front tire",
  condGeneral: "General",
  condDry: "Dry",
  condWet: "Wet",
  condMixed: "Mixed",
  condBikepark: "Bike park",
  condRace: "Race",
  setupNamed: "Setup “{label}” · {conditions}",
  confPrefix: "Confidence",
  confLow: "low",
  confMedium: "medium",
  confHigh: "high",
  recWear: "{name} — wear forecast",
  recSetupLimit: "{name} — setup at the stop",
  recFeel: "{name} — repeating ride feel",
  recSeason: "{name} — wet-season change",
  maintOverdue: "Maintenance overdue",
  maintSoon: "Maintenance due soon",
};

const FR: RecapChromeCopy = {
  assistApproach: "Estimation : {mode} (approche)",
  assistClimb: "Estimation : {mode} (montée, {pct} %)",
  assistRest: "Estimation : {mode} (reste)",
  assistManual: "Manuel : {mode}",
  assistDisclaimer:
    "Estimations à partir de la signature puissance/vitesse — pas de lecture OEM. Pas de commande moteur.",
  sourceEstimated: "estimation",
  sourceOem: "OEM",
  sourceManual: "manuel",
  chipFork: "Fourche",
  chipRebound: "Détente",
  chipTireFront: "Pneu avant",
  condGeneral: "Général",
  condDry: "Sec",
  condWet: "Mouillé",
  condMixed: "Mixte",
  condBikepark: "Bikepark",
  condRace: "Course",
  setupNamed: "Réglage « {label} » · {conditions}",
  confPrefix: "Confiance",
  confLow: "basse",
  confMedium: "moyenne",
  confHigh: "haute",
  recWear: "{name} — prévision d’usure",
  recSetupLimit: "{name} — setup en butée",
  recFeel: "{name} — sensation qui revient",
  recSeason: "{name} — saison humide",
  maintOverdue: "Entretien en retard",
  maintSoon: "Entretien bientôt dû",
};

const IT: RecapChromeCopy = {
  assistApproach: "Stima: {mode} (avvicinamento)",
  assistClimb: "Stima: {mode} (salita, {pct} %)",
  assistRest: "Stima: {mode} (resto)",
  assistManual: "Manuale: {mode}",
  assistDisclaimer:
    "Stime dalla firma potenza/velocità — non lettura OEM. Nessun controllo motore.",
  sourceEstimated: "stima",
  sourceOem: "OEM",
  sourceManual: "manuale",
  chipFork: "Forcella",
  chipRebound: "Ritorno",
  chipTireFront: "Gomma ant.",
  condGeneral: "Generale",
  condDry: "Asciutto",
  condWet: "Bagnato",
  condMixed: "Misto",
  condBikepark: "Bike park",
  condRace: "Gara",
  setupNamed: "Setup “{label}” · {conditions}",
  confPrefix: "Confidenza",
  confLow: "bassa",
  confMedium: "media",
  confHigh: "alta",
  recWear: "{name} — previsione usura",
  recSetupLimit: "{name} — setup al limite",
  recFeel: "{name} — sensazione che torna",
  recSeason: "{name} — stagione umida",
  maintOverdue: "Manutenzione scaduta",
  maintSoon: "Manutenzione in arrivo",
};

const NL: RecapChromeCopy = {
  assistApproach: "Schatting: {mode} (aanrit)",
  assistClimb: "Schatting: {mode} (klim, {pct} %)",
  assistRest: "Schatting: {mode} (rest)",
  assistManual: "Handmatig: {mode}",
  assistDisclaimer:
    "Schattingen uit vermogen/snelheid — geen OEM-uitlezing. Geen motorsturing.",
  sourceEstimated: "schatting",
  sourceOem: "OEM",
  sourceManual: "handmatig",
  chipFork: "Vork",
  chipRebound: "Rebound",
  chipTireFront: "Voorband",
  condGeneral: "Algemeen",
  condDry: "Droog",
  condWet: "Nat",
  condMixed: "Gemengd",
  condBikepark: "Bikepark",
  condRace: "Race",
  setupNamed: "Setup “{label}” · {conditions}",
  confPrefix: "Betrouwbaarheid",
  confLow: "laag",
  confMedium: "middel",
  confHigh: "hoog",
  recWear: "{name} — slijtageprognose",
  recSetupLimit: "{name} — setup aan de aanslag",
  recFeel: "{name} — terugkerend rijgevoel",
  recSeason: "{name} — nat seizoen",
  maintOverdue: "Onderhoud te laat",
  maintSoon: "Onderhoud binnenkort",
};

const BY_LANG: Record<ChromeLang, RecapChromeCopy> = {
  de: DE,
  en: EN,
  fr: FR,
  it: IT,
  nl: NL,
};

export function recapChromeCopy(lang: ChromeLang): RecapChromeCopy {
  return BY_LANG[lang];
}

export function localizeSetupCondition(
  raw: string,
  copy: RecapChromeCopy
): string {
  switch (raw.trim().toLowerCase()) {
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
      return raw;
  }
}

export function localizeAssistSegment(
  raw: string,
  copy: RecapChromeCopy
): string {
  const t = raw.trim();
  const approach = /^Schätzung: (\w+) \(Anfahrt\)$/.exec(t);
  if (approach) return fill(copy.assistApproach, { mode: approach[1] });
  const climb =
    /^Schätzung: (\w+) \(Steigung(?:, Konfidenz)?, (\d+) %\)$/.exec(t);
  if (climb) {
    return fill(copy.assistClimb, { mode: climb[1], pct: climb[2] });
  }
  const rest = /^Schätzung: (\w+) \(Rest\)$/.exec(t);
  if (rest) return fill(copy.assistRest, { mode: rest[1] });
  const manual = /^Manuell: (\w+)$/.exec(t);
  if (manual) return fill(copy.assistManual, { mode: manual[1] });
  return t;
}

export function localizeAssistDisclaimer(
  raw: string,
  copy: RecapChromeCopy
): string {
  if (raw.trim().startsWith("Schätzungen aus Leistungs")) {
    return copy.assistDisclaimer;
  }
  return raw;
}

export function localizeActivityRecTitle(
  title: string,
  copy: RecapChromeCopy
): string {
  if (title === "Wartung überfällig") return copy.maintOverdue;
  if (title === "Wartung bald fällig") return copy.maintSoon;
  const wear = /^(.+) — wegen Verschleißprognose$/.exec(title);
  if (wear) return fill(copy.recWear, { name: wear[1] });
  const limit = /^(.+) — Setup am Anschlag$/.exec(title);
  if (limit) return fill(copy.recSetupLimit, { name: limit[1] });
  const feel = /^(.+) — wiederkehrendes Fahrgefühl$/.exec(title);
  if (feel) return fill(copy.recFeel, { name: feel[1] });
  const season = /^(.+) — Saisonwechsel nass$/.exec(title);
  if (season) return fill(copy.recSeason, { name: season[1] });
  return title;
}

export function localizeAssistSource(
  source: string,
  copy: RecapChromeCopy
): string {
  switch (source) {
    case "estimated":
      return copy.sourceEstimated;
    case "oem":
      return copy.sourceOem;
    case "manual":
      return copy.sourceManual;
    default:
      return source;
  }
}
