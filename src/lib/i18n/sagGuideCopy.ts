/**
 * Setup-tab sag helper. Steps match Flutter garageSagStep*.
 */
import type { ChromeLang } from "./chromeLang";

export type SagGuideCopy = {
  title: string;
  hint: string;
  rider: string;
  gear: string;
  fork: string;
  shock: string;
  sagTarget: (min: number, max: number, mm: boolean) => string;
  psiStart: string;
  psiRange: string;
  note: string;
  magazine: (
    forkMin: number,
    forkMax: number,
    shockMin: number,
    shockMax: number
  ) => string;
  steps: (end: "fork" | "shock") => string[];
};

function pack(
  strings: Omit<SagGuideCopy, "steps"> & {
    extend: (part: string) => string;
    bounce: string;
    dismount: string;
    ratio: string;
    air: string;
  }
): SagGuideCopy {
  return {
    title: strings.title,
    hint: strings.hint,
    rider: strings.rider,
    gear: strings.gear,
    fork: strings.fork,
    shock: strings.shock,
    sagTarget: strings.sagTarget,
    psiStart: strings.psiStart,
    psiRange: strings.psiRange,
    note: strings.note,
    magazine: strings.magazine,
    steps: (end) => {
      const part = end === "fork" ? strings.fork : strings.shock;
      return [
        strings.extend(part),
        strings.bounce,
        strings.dismount,
        strings.ratio,
        strings.air,
      ];
    },
  };
}

const DE = pack({
  title: "SAG einstellen",
  hint: "Gewicht → Luft-Richtwert → am Rad messen. Quellen: Enduro MTB Mag / Simplon / Dirt (SAG-Spannen).",
  rider: "Fahrer (kg)",
  gear: "Ausrüstung (kg)",
  fork: "Gabel",
  shock: "Dämpfer",
  sagTarget: (min, max, mm) =>
    `SAG-Ziel (${min}–${max}${mm ? " %, mm" : ""})`,
  psiStart: "psi Start",
  psiRange: "psi Spanne",
  note: "Richtwert zum Einstieg — am Rad messen (O-Ring), dann ±5 psi. Keine Kolbenfläche, kein Rahmenhebel.",
  magazine: (forkMin, forkMax, shockMin, shockMax) =>
    `Magazin-Spannen: Gabel ${forkMin}–${forkMax} % · Dämpfer ${shockMin}–${shockMax} %`,
  extend: (part) =>
    `${part} voll ausfedern, O-Ring an die Dichtung schieben.`,
  bounce: "Fahrbereit aufsteigen, 3× leicht einfedern.",
  dismount: "Vorsichtig absteigen, ohne den O-Ring zu verschieben.",
  ratio: "Negativfederweg messen ÷ Gesamtfederweg → SAG %.",
  air: "Luft nachpumpen oder ablassen bis Zielbereich.",
});

const EN = pack({
  title: "Set sag",
  hint: "Weight → air starting point → measure on the bike. Sources: Enduro MTB Mag / Simplon / Dirt (sag ranges).",
  rider: "Rider (kg)",
  gear: "Kit (kg)",
  fork: "Fork",
  shock: "Shock",
  sagTarget: (min, max, mm) =>
    `Sag target (${min}–${max}${mm ? " %, mm" : ""})`,
  psiStart: "psi start",
  psiRange: "psi range",
  note: "Starting point — measure on the bike (O-ring), then ±5 psi. No piston area, no leverage ratio.",
  magazine: (forkMin, forkMax, shockMin, shockMax) =>
    `Magazine ranges: fork ${forkMin}–${forkMax} % · shock ${shockMin}–${shockMax} %`,
  extend: (part) => `Fully extend the ${part}, slide the O-ring to the seal.`,
  bounce: "Mount ready to ride, bounce lightly 3 times.",
  dismount: "Dismount carefully without moving the O-ring.",
  ratio: "Measure sag ÷ total travel → SAG %.",
  air: "Add or release air until you hit the target.",
});

const FR = pack({
  title: "Régler le SAG",
  hint: "Poids → pression de départ → mesurer sur le vélo. Sources : Enduro MTB Mag / Simplon / Dirt.",
  rider: "Pilote (kg)",
  gear: "Équipement (kg)",
  fork: "Fourche",
  shock: "Amortisseur",
  sagTarget: (min, max, mm) =>
    `SAG cible (${min}–${max}${mm ? " %, mm" : ""})`,
  psiStart: "psi départ",
  psiRange: "psi plage",
  note: "Repère de départ — mesure sur le vélo (O-ring), puis ±5 psi. Pas de surface de piston, pas de ratio.",
  magazine: (forkMin, forkMax, shockMin, shockMax) =>
    `Plages magazine : fourche ${forkMin}–${forkMax} % · amortisseur ${shockMin}–${shockMax} %`,
  extend: (part) =>
    `Détendre complètement la ${part}, glisser le O-ring contre le joint.`,
  bounce: "Monter prêt à rouler, enfoncer légèrement 3 fois.",
  dismount: "Descendre sans bouger le O-ring.",
  ratio: "Mesurer le SAG ÷ débattement total → SAG %.",
  air: "Ajouter ou relâcher de l’air jusqu’à la cible.",
});

const IT = pack({
  title: "Regolare il SAG",
  hint: "Peso → pressione di partenza → misura sulla bici. Fonti: Enduro MTB Mag / Simplon / Dirt.",
  rider: "Rider (kg)",
  gear: "Kit (kg)",
  fork: "Forcella",
  shock: "Ammortizzatore",
  sagTarget: (min, max, mm) =>
    `SAG obiettivo (${min}–${max}${mm ? " %, mm" : ""})`,
  psiStart: "psi partenza",
  psiRange: "psi range",
  note: "Valore di partenza — misura sulla bici (O-ring), poi ±5 psi. Niente area pistone, niente rapporto leva.",
  magazine: (forkMin, forkMax, shockMin, shockMax) =>
    `Range magazine: forcella ${forkMin}–${forkMax} % · ammortizzatore ${shockMin}–${shockMax} %`,
  extend: (part) =>
    `Estendi a fondo la ${part}, spingi l’O-ring contro la tenuta.`,
  bounce: "Sali pronto a partire, comprimi piano 3 volte.",
  dismount: "Scendi senza spostare l’O-ring.",
  ratio: "Misura SAG ÷ corsa totale → SAG %.",
  air: "Aggiungi o togli aria fino all’obiettivo.",
});

const NL = pack({
  title: "SAG instellen",
  hint: "Gewicht → lucht-startpunt → op de fiets meten. Bronnen: Enduro MTB Mag / Simplon / Dirt.",
  rider: "Rijder (kg)",
  gear: "Uitrusting (kg)",
  fork: "Vork",
  shock: "Demper",
  sagTarget: (min, max, mm) =>
    `SAG-doel (${min}–${max}${mm ? " %, mm" : ""})`,
  psiStart: "psi start",
  psiRange: "psi bereik",
  note: "Startpunt — meet op de fiets (O-ring), daarna ±5 psi. Geen zuigeroppervlak, geen heverhouding.",
  magazine: (forkMin, forkMax, shockMin, shockMax) =>
    `Magazine-bereiken: vork ${forkMin}–${forkMax} % · demper ${shockMin}–${shockMax} %`,
  extend: (part) =>
    `${part} volledig uitveren, O-ring naar de dichting schuiven.`,
  bounce: "Opstappen rijklaar, 3× licht inveren.",
  dismount: "Voorzichtig afstappen zonder de O-ring te verschuiven.",
  ratio: "SAG meten ÷ totale veerweg → SAG %.",
  air: "Lucht bijpompen of laten ontsnappen tot het doel.",
});

const BY: Record<ChromeLang, SagGuideCopy> = {
  de: DE,
  en: EN,
  fr: FR,
  it: IT,
  nl: NL,
};

export function sagGuideCopy(lang: ChromeLang = "de"): SagGuideCopy {
  return BY[lang] ?? DE;
}
