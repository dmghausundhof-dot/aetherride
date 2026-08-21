/**
 * Setup-tab bracketing chrome. Domain parameter ids stay English.
 */
import type { ChromeLang } from "./chromeLang";
import type { BracketingParameter } from "@/types";

export type BracketingCopy = {
  title: string;
  hint: string;
  pro: string;
  what: string;
  from: string;
  to: string;
  step: string;
  segment: string;
  defaultSegment: string;
  start: string;
  running: string;
  done: string;
  ready: string;
  runs: (n: number) => string;
  variant: (v: number) => string;
  evaluate: string;
  best: (value: number, unit: string) => string;
  noDiff: string;
  demo: (v: number) => string;
  param: (id: BracketingParameter) => string;
};

const PARAM: Record<ChromeLang, Record<BracketingParameter, string>> = {
  de: {
    "fork.rebound": "Gabel Zugstufe",
    "fork.lsc": "Gabel LSC",
    "fork.hsc": "Gabel HSC",
    "fork.sag_pct": "Gabel SAG %",
    "fork.air_pressure_psi": "Gabel Luftdruck",
    "shock.rebound": "Dämpfer Zugstufe",
    "shock.lsc": "Dämpfer LSC",
    "shock.hsc": "Dämpfer HSC",
    "shock.sag_pct": "Dämpfer SAG %",
    "shock.air_pressure_psi": "Dämpfer Luftdruck",
    "tire.front_psi": "Reifen vorn",
    "tire.rear_psi": "Reifen hinten",
  },
  en: {
    "fork.rebound": "Fork rebound",
    "fork.lsc": "Fork LSC",
    "fork.hsc": "Fork HSC",
    "fork.sag_pct": "Fork sag %",
    "fork.air_pressure_psi": "Fork air pressure",
    "shock.rebound": "Shock rebound",
    "shock.lsc": "Shock LSC",
    "shock.hsc": "Shock HSC",
    "shock.sag_pct": "Shock sag %",
    "shock.air_pressure_psi": "Shock air pressure",
    "tire.front_psi": "Front tyre",
    "tire.rear_psi": "Rear tyre",
  },
  fr: {
    "fork.rebound": "Détente fourche",
    "fork.lsc": "LSC fourche",
    "fork.hsc": "HSC fourche",
    "fork.sag_pct": "SAG fourche %",
    "fork.air_pressure_psi": "Pression fourche",
    "shock.rebound": "Détente amortisseur",
    "shock.lsc": "LSC amortisseur",
    "shock.hsc": "HSC amortisseur",
    "shock.sag_pct": "SAG amortisseur %",
    "shock.air_pressure_psi": "Pression amortisseur",
    "tire.front_psi": "Pneu avant",
    "tire.rear_psi": "Pneu arrière",
  },
  it: {
    "fork.rebound": "Ritorno forcella",
    "fork.lsc": "LSC forcella",
    "fork.hsc": "HSC forcella",
    "fork.sag_pct": "SAG forcella %",
    "fork.air_pressure_psi": "Pressione forcella",
    "shock.rebound": "Ritorno ammortizzatore",
    "shock.lsc": "LSC ammortizzatore",
    "shock.hsc": "HSC ammortizzatore",
    "shock.sag_pct": "SAG ammortizzatore %",
    "shock.air_pressure_psi": "Pressione ammortizzatore",
    "tire.front_psi": "Copertone anteriore",
    "tire.rear_psi": "Copertone posteriore",
  },
  nl: {
    "fork.rebound": "Vork rebound",
    "fork.lsc": "Vork LSC",
    "fork.hsc": "Vork HSC",
    "fork.sag_pct": "Vork SAG %",
    "fork.air_pressure_psi": "Vork luchtdruk",
    "shock.rebound": "Demper rebound",
    "shock.lsc": "Demper LSC",
    "shock.hsc": "Demper HSC",
    "shock.sag_pct": "Demper SAG %",
    "shock.air_pressure_psi": "Demper luchtdruk",
    "tire.front_psi": "Voorband",
    "tire.rear_psi": "Achterband",
  },
};

const DE: Omit<BracketingCopy, "param"> = {
  title: "Zwei Varianten testen",
  hint: "Nur eine Einstellung pro Vergleich. Nach ein paar vergleichbaren Fahrten siehst du, welche Variante sich besser anfühlt.",
  pro: "Vergleichen ist Pro. Unter Profil freischalten.",
  what: "Was vergleichen?",
  from: "Von",
  to: "Bis",
  step: "Schrittweite",
  segment: "Vergleichsstrecke",
  defaultSegment: "Heimtrail Abfahrt",
  start: "Vergleich starten",
  running: "läuft",
  done: "fertig",
  ready: "bereit",
  runs: (n) => `${n} Durchgänge`,
  variant: (v) => `Variante ${v}`,
  evaluate: "Auswerten",
  best: (value, unit) => `Beste: ${value} ${unit}`,
  noDiff: "kein klarer Unterschied",
  demo: (v) => `Demo: +2 Fahrten @ ${v}`,
};

const EN: Omit<BracketingCopy, "param"> = {
  title: "Try two variants",
  hint: "One setting per comparison. After a few comparable rides you’ll see which variant feels better.",
  pro: "Compare is Pro. Unlock it under Profile.",
  what: "What to compare?",
  from: "From",
  to: "To",
  step: "Step",
  segment: "Comparison stretch",
  defaultSegment: "Home trail descent",
  start: "Start comparison",
  running: "running",
  done: "done",
  ready: "ready",
  runs: (n) => `${n} runs`,
  variant: (v) => `Variant ${v}`,
  evaluate: "Evaluate",
  best: (value, unit) => `Best: ${value} ${unit}`,
  noDiff: "no clear difference",
  demo: (v) => `Demo: +2 rides @ ${v}`,
};

const FR: Omit<BracketingCopy, "param"> = {
  title: "Tester deux variantes",
  hint: "Un seul réglage par comparaison. Après quelques sorties comparables, tu verras laquelle se sent mieux.",
  pro: "Comparer est Pro. Débloque-le sous Profil.",
  what: "Comparer quoi ?",
  from: "De",
  to: "À",
  step: "Pas",
  segment: "Tronçon de comparaison",
  defaultSegment: "Descente du trail maison",
  start: "Lancer la comparaison",
  running: "en cours",
  done: "terminé",
  ready: "prêt",
  runs: (n) => `${n} passages`,
  variant: (v) => `Variante ${v}`,
  evaluate: "Évaluer",
  best: (value, unit) => `Meilleure : ${value} ${unit}`,
  noDiff: "pas de différence nette",
  demo: (v) => `Démo : +2 sorties @ ${v}`,
};

const IT: Omit<BracketingCopy, "param"> = {
  title: "Prova due varianti",
  hint: "Una sola regolazione per confronto. Dopo qualche giro paragonabile vedi quale variante si sente meglio.",
  pro: "Confrontare è Pro. Sbloccalo sotto Profilo.",
  what: "Cosa confrontare?",
  from: "Da",
  to: "A",
  step: "Passo",
  segment: "Tratto di confronto",
  defaultSegment: "Discesa del trail di casa",
  start: "Avvia confronto",
  running: "in corso",
  done: "fatto",
  ready: "pronto",
  runs: (n) => `${n} passaggi`,
  variant: (v) => `Variante ${v}`,
  evaluate: "Valuta",
  best: (value, unit) => `Migliore: ${value} ${unit}`,
  noDiff: "nessuna differenza chiara",
  demo: (v) => `Demo: +2 giri @ ${v}`,
};

const NL: Omit<BracketingCopy, "param"> = {
  title: "Twee varianten testen",
  hint: "Eén instelling per vergelijking. Na een paar vergelijkbare ritten zie je welke variant beter aanvoelt.",
  pro: "Vergelijken is Pro. Ontgrendel het onder Profiel.",
  what: "Wat vergelijken?",
  from: "Van",
  to: "Tot",
  step: "Stap",
  segment: "Vergelijkingsstuk",
  defaultSegment: "Thuistrail afdaling",
  start: "Vergelijking starten",
  running: "loopt",
  done: "klaar",
  ready: "gereed",
  runs: (n) => `${n} ronden`,
  variant: (v) => `Variant ${v}`,
  evaluate: "Uitrekenen",
  best: (value, unit) => `Beste: ${value} ${unit}`,
  noDiff: "geen duidelijk verschil",
  demo: (v) => `Demo: +2 ritten @ ${v}`,
};

const PACK: Record<ChromeLang, Omit<BracketingCopy, "param">> = {
  de: DE,
  en: EN,
  fr: FR,
  it: IT,
  nl: NL,
};

export function bracketingCopy(lang: ChromeLang = "de"): BracketingCopy {
  const pack = PACK[lang] ?? DE;
  return {
    ...pack,
    param: (id) => PARAM[lang]?.[id] ?? PARAM.de[id] ?? id,
  };
}

const SUMMARY_NOT_READY: Record<ChromeLang, string> = {
  de: "Mindestens zwei verschiedene Konfigurationen mit je ≥ 2 Runs nötig.",
  en: "Need at least two configurations with ≥ 2 runs each.",
  fr: "Il faut au moins deux configs avec ≥ 2 passages chacune.",
  it: "Servono almeno due config con ≥ 2 passaggi ciascuna.",
  nl: "Minstens twee configuraties met elk ≥ 2 ronden nodig.",
};

const SUMMARY_MISSING: Record<ChromeLang, (tail: string) => string> = {
  de: (tail) =>
    `Noch nicht auswertbar: pro Konfiguration mind. 2 Durchgänge nötig. Fehlt: ${tail}`,
  en: (tail) =>
    `Not ready yet: at least 2 runs per configuration. Missing: ${tail}`,
  fr: (tail) =>
    `Pas encore évaluable : ≥ 2 passages par config. Manque : ${tail}`,
  it: (tail) =>
    `Non ancora valutabile: ≥ 2 passaggi per config. Manca: ${tail}`,
  nl: (tail) =>
    `Nog niet uit te rekenen: min. 2 ronden per configuratie. Ontbreekt: ${tail}`,
};

const SUMMARY_NO_DIFF: Record<ChromeLang, string> = {
  de: "Kein belegbarer Unterschied — die Lauf-zu-Lauf-Streuung übersteigt die gemessenen Differenzen.",
  en: "No proven difference — run-to-run scatter exceeds the measured deltas.",
  fr: "Pas de différence prouvable — la dispersion d’un run à l’autre dépasse les écarts mesurés.",
  it: "Nessuna differenza dimostrabile — lo scatter tra i giri supera i delta misurati.",
  nl: "Geen aantoonbaar verschil — de spreiding van ronde tot ronde is groter dan de gemeten delta’s.",
};

const SUMMARY_PROVEN: Record<ChromeLang, (param: string, value: string, unit: string) => string> = {
  de: (param, value, unit) =>
    `Belegbare Unterschiede vorhanden. Beste Konfiguration für ${param}: ${value} ${unit}.`,
  en: (param, value, unit) =>
    `Proven differences. Best configuration for ${param}: ${value} ${unit}.`,
  fr: (param, value, unit) =>
    `Écarts prouvables. Meilleure config pour ${param} : ${value} ${unit}.`,
  it: (param, value, unit) =>
    `Differenze dimostrabili. Config migliore per ${param}: ${value} ${unit}.`,
  nl: (param, value, unit) =>
    `Aantoonbare verschillen. Beste configuratie voor ${param}: ${value} ${unit}.`,
};

/** Engine stores German summaries; UI maps known shapes. */
export function presentBracketingSummary(
  de: string,
  lang: ChromeLang = "de"
): string {
  if (lang === "de") return de;
  if (de.startsWith("Noch nicht auswertbar")) {
    const tail = de.split("Fehlt: ")[1] ?? "";
    return SUMMARY_MISSING[lang](tail);
  }
  if (de.startsWith("Mindestens zwei")) return SUMMARY_NOT_READY[lang];
  if (de.startsWith("Kein belegbarer")) return SUMMARY_NO_DIFF[lang];
  const proven = de.match(
    /^Belegbare Unterschiede vorhanden\. Beste Konfiguration für (.+): ([^ ]+) ([^ ]+) \(/
  );
  if (proven) {
    return SUMMARY_PROVEN[lang](proven[1], proven[2], proven[3]);
  }
  return de;
}
