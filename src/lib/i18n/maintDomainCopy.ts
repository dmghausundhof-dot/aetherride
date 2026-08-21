/**
 * Interval / wear / remaining strings. Engine stores German; UI maps by label.
 * Keys match Flutter ARB (maintIntervalLabel / maintRemainingFor).
 */
import type { ChromeLang } from "./chromeLang";
import type { WearForecast, WearKind } from "@/lib/maintenance/wearPrediction";

function fill(template: string, params: Record<string, string>): string {
  return template.replace(/\{(\w+)\}/g, (_, k) => params[k] ?? "");
}

const INTERVAL: Record<ChromeLang, Record<string, string>> = {
  de: {
    "Gabel Lower-Leg Service": "Gabel Lower-Leg Service",
    "Gabel Vollservice (Feder/Dämpfer)": "Gabel Vollservice (Feder/Dämpfer)",
    "Dämpfer Air-Can Service": "Dämpfer Air-Can Service",
    "Dämpfer Vollservice": "Dämpfer Vollservice",
    "Kettenverschleiß prüfen": "Kettenverschleiß prüfen",
    "Kassette prüfen (nach 2–3 Ketten)": "Kassette prüfen (nach 2–3 Ketten)",
    "Bremsbeläge vorne prüfen": "Bremsbeläge vorne prüfen",
    "Bremsbeläge hinten prüfen": "Bremsbeläge hinten prüfen",
    "Tubeless-Milch erneuern": "Tubeless-Milch erneuern",
    "Dropper Lower-Post Service": "Dropper Lower-Post Service",
    "Jährliche Inspektion": "Jährliche Inspektion",
    "Jährliche E-Bike-Inspektion": "Jährliche E-Bike-Inspektion",
    "Erste Inspektion": "Erste Inspektion",
    "Erste E-Bike-Inspektion": "Erste E-Bike-Inspektion",
    "Reifen prüfen": "Reifen prüfen",
    "Lager prüfen (Steuersatz/Naben/Tretlager)":
      "Lager prüfen (Steuersatz/Naben/Tretlager)",
    "Bremsen: Druckpunkt / Entlüften": "Bremsen: Druckpunkt / Entlüften",
    "Akku-Check (Kontakte, Kapazität)": "Akku-Check (Kontakte, Kapazität)",
  },
  en: {
    "Gabel Lower-Leg Service": "Fork lower-leg service",
    "Gabel Vollservice (Feder/Dämpfer)": "Fork full service (spring/damper)",
    "Dämpfer Air-Can Service": "Shock air-can service",
    "Dämpfer Vollservice": "Shock full service",
    "Kettenverschleiß prüfen": "Check chain wear",
    "Kassette prüfen (nach 2–3 Ketten)": "Check cassette (after 2–3 chains)",
    "Bremsbeläge vorne prüfen": "Check front brake pads",
    "Bremsbeläge hinten prüfen": "Check rear brake pads",
    "Tubeless-Milch erneuern": "Refresh tubeless sealant",
    "Dropper Lower-Post Service": "Dropper lower-post service",
    "Jährliche Inspektion": "Annual inspection",
    "Jährliche E-Bike-Inspektion": "Annual e-bike inspection",
    "Erste Inspektion": "First inspection",
    "Erste E-Bike-Inspektion": "First e-bike inspection",
    "Reifen prüfen": "Check tyres",
    "Lager prüfen (Steuersatz/Naben/Tretlager)":
      "Check bearings (headset/hubs/BB)",
    "Bremsen: Druckpunkt / Entlüften": "Brakes: bite point / bleed",
    "Akku-Check (Kontakte, Kapazität)": "Battery check (contacts, capacity)",
  },
  fr: {
    "Gabel Lower-Leg Service": "Service lower-leg fourche",
    "Gabel Vollservice (Feder/Dämpfer)":
      "Révision complète fourche (ressort/amortisseur)",
    "Dämpfer Air-Can Service": "Service air-can amortisseur",
    "Dämpfer Vollservice": "Révision complète amortisseur",
    "Kettenverschleiß prüfen": "Contrôle usure chaîne",
    "Kassette prüfen (nach 2–3 Ketten)":
      "Contrôle cassette (après 2–3 chaînes)",
    "Bremsbeläge vorne prüfen": "Contrôle plaquettes avant",
    "Bremsbeläge hinten prüfen": "Contrôle plaquettes arrière",
    "Tubeless-Milch erneuern": "Renouveler le lait tubeless",
    "Dropper Lower-Post Service": "Service lower-post dropper",
    "Jährliche Inspektion": "Inspection annuelle",
    "Jährliche E-Bike-Inspektion": "Inspection annuelle e-bike",
    "Erste Inspektion": "Première inspection",
    "Erste E-Bike-Inspektion": "Première inspection e-bike",
    "Reifen prüfen": "Vérifier les pneus",
    "Lager prüfen (Steuersatz/Naben/Tretlager)":
      "Vérifier les roulements (jeu de direction/moyeux/boîtier)",
    "Bremsen: Druckpunkt / Entlüften": "Freins : point de pression / purge",
    "Akku-Check (Kontakte, Kapazität)":
      "Contrôle batterie (contacts, capacité)",
  },
  it: {
    "Gabel Lower-Leg Service": "Service lower-leg forcella",
    "Gabel Vollservice (Feder/Dämpfer)":
      "Revisione completa forcella (molla/ammortizzatore)",
    "Dämpfer Air-Can Service": "Service air-can ammortizzatore",
    "Dämpfer Vollservice": "Revisione completa ammortizzatore",
    "Kettenverschleiß prüfen": "Controlla usura catena",
    "Kassette prüfen (nach 2–3 Ketten)":
      "Controlla cassetta (dopo 2–3 catene)",
    "Bremsbeläge vorne prüfen": "Controlla pastiglie anteriori",
    "Bremsbeläge hinten prüfen": "Controlla pastiglie posteriori",
    "Tubeless-Milch erneuern": "Rinnova latte tubeless",
    "Dropper Lower-Post Service": "Service lower-post dropper",
    "Jährliche Inspektion": "Ispezione annuale",
    "Jährliche E-Bike-Inspektion": "Ispezione annuale e-bike",
    "Erste Inspektion": "Prima ispezione",
    "Erste E-Bike-Inspektion": "Prima ispezione e-bike",
    "Reifen prüfen": "Controlla gli pneumatici",
    "Lager prüfen (Steuersatz/Naben/Tretlager)":
      "Controlla i cuscinetti (serie sterzo/mozzi/movimento)",
    "Bremsen: Druckpunkt / Entlüften": "Freni: punto di stacco / spurgo",
    "Akku-Check (Kontakte, Kapazität)": "Check batteria (contatti, capacità)",
  },
  nl: {
    "Gabel Lower-Leg Service": "Voorvork lower-leg service",
    "Gabel Vollservice (Feder/Dämpfer)":
      "Voorvork volledige service (veer/demper)",
    "Dämpfer Air-Can Service": "Demper air-can service",
    "Dämpfer Vollservice": "Demper volledige service",
    "Kettenverschleiß prüfen": "Kettingsslijtage checken",
    "Kassette prüfen (nach 2–3 Ketten)": "Check cassette (na 2–3 kettingen)",
    "Bremsbeläge vorne prüfen": "Check voorremblokken",
    "Bremsbeläge hinten prüfen": "Check achterremblokken",
    "Tubeless-Milch erneuern": "Tubeless-melk vernieuwen",
    "Dropper Lower-Post Service": "Dropper lower-post service",
    "Jährliche Inspektion": "Jaarlijkse inspectie",
    "Jährliche E-Bike-Inspektion": "Jaarlijkse e-bike-inspectie",
    "Erste Inspektion": "Eerste inspectie",
    "Erste E-Bike-Inspektion": "Eerste e-bike-inspectie",
    "Reifen prüfen": "Banden controleren",
    "Lager prüfen (Steuersatz/Naben/Tretlager)":
      "Lagers controleren (balhoofd/naven/trapas)",
    "Bremsen: Druckpunkt / Entlüften": "Remmen: drukpunt / ontluchten",
    "Akku-Check (Kontakte, Kapazität)": "Accucheck (contacten, capaciteit)",
  },
};

const NONE: Record<ChromeLang, string> = {
  de: "Kein Intervall",
  en: "No interval",
  fr: "Pas d’intervalle",
  it: "Nessun intervallo",
  nl: "Geen interval",
};

const NEVER: Record<ChromeLang, string> = {
  de: "noch keine Inspektion gemerkt",
  en: "no inspection saved yet",
  fr: "aucune inspection notée",
  it: "nessuna ispezione salvata",
  nl: "nog geen inspectie onthouden",
};

const DUE_NOW: Record<ChromeLang, string> = {
  de: "fällig",
  en: "due",
  fr: "dû",
  it: "scaduto",
  nl: "verschuldigd",
};

const DAYS: Record<ChromeLang, (n: string) => string> = {
  de: (n) => `${n} Tage`,
  en: (n) => `${n} days`,
  fr: (n) => `${n} j`,
  it: (n) => `${n} giorni`,
  nl: (n) => `${n} dagen`,
};

export function maintIntervalLabel(de: string, lang: ChromeLang): string {
  return INTERVAL[lang][de] ?? de;
}

export function maintRemainingLabel(raw: string, lang: ChromeLang): string {
  if (!raw) return "";
  if (raw === "Kein Intervall") return NONE[lang];
  if (raw === "noch keine Inspektion gemerkt") return NEVER[lang];
  return raw.split(" · ").map((part) => remainingPart(part.trim(), lang)).join(" · ");
}

function remainingPart(part: string, lang: ChromeLang): string {
  if (part === "noch keine Inspektion gemerkt") return NEVER[lang];
  if (part.startsWith("fällig")) return DUE_NOW[lang];
  const days = /^(\d+)\s+Tage$/.exec(part);
  if (days) return DAYS[lang](days[1]!);
  return part;
}

const WEAR_SLOT: Record<ChromeLang, Record<WearKind, string>> = {
  de: {
    chain: "Kette",
    brake_pads_front: "Bremsbeläge vorne",
    brake_pads_rear: "Bremsbeläge hinten",
    cassette: "Kassette",
    tires: "Vorderradreifen",
  },
  en: {
    chain: "Chain",
    brake_pads_front: "Front brake pads",
    brake_pads_rear: "Rear brake pads",
    cassette: "Cassette",
    tires: "Front tyre",
  },
  fr: {
    chain: "Chaîne",
    brake_pads_front: "Plaquettes avant",
    brake_pads_rear: "Plaquettes arrière",
    cassette: "Cassette",
    tires: "Pneu avant",
  },
  it: {
    chain: "Catena",
    brake_pads_front: "Pastiglie anteriori",
    brake_pads_rear: "Pastiglie posteriori",
    cassette: "Cassetta",
    tires: "Gomma anteriore",
  },
  nl: {
    chain: "Ketting",
    brake_pads_front: "Voorremblokken",
    brake_pads_rear: "Achterremblokken",
    cassette: "Cassette",
    tires: "Voorband",
  },
};

const WEAR_RANGE: Record<ChromeLang, Record<WearKind, string>> = {
  de: {
    chain: "Kettenwechsel in {low}–{high} km",
    brake_pads_front: "Belagwechsel vorne in {low}–{high} km",
    brake_pads_rear: "Belagwechsel hinten in {low}–{high} km",
    cassette: "Kassette prüfen in {low}–{high} km",
    tires: "Reifen prüfen in {low}–{high} km",
  },
  en: {
    chain: "Chain replacement in {low}–{high} km",
    brake_pads_front: "Front pad change in {low}–{high} km",
    brake_pads_rear: "Rear pad change in {low}–{high} km",
    cassette: "Check cassette in {low}–{high} km",
    tires: "Check tyres in {low}–{high} km",
  },
  fr: {
    chain: "Changement de chaîne dans {low}–{high} km",
    brake_pads_front: "Changement plaquettes avant dans {low}–{high} km",
    brake_pads_rear: "Changement plaquettes arrière dans {low}–{high} km",
    cassette: "Contrôle cassette dans {low}–{high} km",
    tires: "Contrôle pneus dans {low}–{high} km",
  },
  it: {
    chain: "Cambio catena tra {low}–{high} km",
    brake_pads_front: "Cambio pastiglie anteriori tra {low}–{high} km",
    brake_pads_rear: "Cambio pastiglie posteriori tra {low}–{high} km",
    cassette: "Controlla cassetta tra {low}–{high} km",
    tires: "Controlla pneumatici tra {low}–{high} km",
  },
  nl: {
    chain: "Ketting wisselen over {low}–{high} km",
    brake_pads_front: "Voorblokken wisselen over {low}–{high} km",
    brake_pads_rear: "Achterblokken wisselen over {low}–{high} km",
    cassette: "Cassette checken over {low}–{high} km",
    tires: "Banden checken over {low}–{high} km",
  },
};

const EBIKE: Record<ChromeLang, string> = {
  de: " E-Drehmoment-Faktor 0,7.",
  en: " E-bike torque factor 0.7.",
  fr: " Facteur couple VAE 0,7.",
  it: " Fattore coppia e-bike 0,7.",
  nl: " E-bike-koppel factor 0,7.",
};

const WEAR_REASON: Record<
  ChromeLang,
  Record<WearKind, string>
> = {
  de: {
    chain:
      "Basis {lifeLow}–{lifeHigh} km; gemessen ≈ {km} km + {hours} h.{ebike} Nässe {wet} %. Wechselziel 0,5 % Längung. Immer Spanne, nie Punktwert.",
    brake_pads_front:
      "Abfahrts-HM {descent}, {impacts} Impacts, Nässe {wet} %. Spanne {lifeLow}–{lifeHigh} km — nie Punktwert.",
    brake_pads_rear:
      "Hintere Beläge oft früher; Abfahrts-HM {descent}, Impacts {impacts}. Nie Punktwert — immer Spanne.",
    cassette:
      "Typisch 2–3 Ketten ({lifeLow}–{lifeHigh} km), wenn die Kette bei 0,5 % gewechselt wird.",
    tires:
      "Spanne {lifeLow}–{lifeHigh} km. Stollenrundung = Grip weg — Sichtprüfung vor der Tour.",
  },
  en: {
    chain:
      "Baseline {lifeLow}–{lifeHigh} km; measured ≈ {km} km + {hours} h.{ebike} Wet share {wet} %. Replace at 0.5 % elongation. Always a range, never a point.",
    brake_pads_front:
      "Descent hm {descent}, {impacts} impacts, wet {wet} %. Range {lifeLow}–{lifeHigh} km — never a point.",
    brake_pads_rear:
      "Rear pads often earlier; descent hm {descent}, impacts {impacts}. Always a range, never a point.",
    cassette:
      "Typically 2–3 chains ({lifeLow}–{lifeHigh} km) if the chain is changed at 0.5 %.",
    tires:
      "Range {lifeLow}–{lifeHigh} km. Rounded knobs mean grip is gone — inspect before the ride.",
  },
  fr: {
    chain:
      "Base {lifeLow}–{lifeHigh} km ; mesuré ≈ {km} km + {hours} h.{ebike} Humidité {wet} %. Seuil 0,5 % d’allongement. Toujours une plage, jamais un point.",
    brake_pads_front:
      "Dénivelé descente {descent} hm, {impacts} impacts, humidité {wet} %. Plage {lifeLow}–{lifeHigh} km — jamais un point.",
    brake_pads_rear:
      "Plaquettes arrière souvent plus tôt ; descente {descent} hm, impacts {impacts}. Toujours une plage.",
    cassette:
      "Typiquement 2–3 chaînes ({lifeLow}–{lifeHigh} km) si la chaîne est changée à 0,5 %.",
    tires:
      "Plage {lifeLow}–{lifeHigh} km. Crampons ronds = grip parti — contrôle visuel avant la sortie.",
  },
  it: {
    chain:
      "Base {lifeLow}–{lifeHigh} km; misurato ≈ {km} km + {hours} h.{ebike} Umido {wet} %. Soglia 0,5 % allungamento. Sempre un intervallo, mai un punto.",
    brake_pads_front:
      "Discesa {descent} hm, {impacts} impatti, umido {wet} %. Intervallo {lifeLow}–{lifeHigh} km — mai un punto.",
    brake_pads_rear:
      "Pastiglie posteriori spesso prima; discesa {descent} hm, impatti {impacts}. Sempre un intervallo.",
    cassette:
      "Di solito 2–3 catene ({lifeLow}–{lifeHigh} km) se la catena si cambia allo 0,5 %.",
    tires:
      "Intervallo {lifeLow}–{lifeHigh} km. Tasselli tondi = grip perso — controllo visivo prima dell’uscita.",
  },
  nl: {
    chain:
      "Basis {lifeLow}–{lifeHigh} km; gemeten ≈ {km} km + {hours} h.{ebike} Nat {wet} %. Wissel bij 0,5 % rek. Altijd een bereik, nooit een punt.",
    brake_pads_front:
      "Afdaling {descent} hm, {impacts} impacts, nat {wet} %. Bereik {lifeLow}–{lifeHigh} km — nooit een punt.",
    brake_pads_rear:
      "Achterblokken vaak eerder; afdaling {descent} hm, impacts {impacts}. Altijd een bereik.",
    cassette:
      "Typisch 2–3 kettingen ({lifeLow}–{lifeHigh} km) als de ketting bij 0,5 % gewisseld wordt.",
    tires:
      "Bereik {lifeLow}–{lifeHigh} km. Ronde noppen = grip weg — visuele check voor de rit.",
  },
};

export function wearSlotLabel(kind: WearKind, lang: ChromeLang): string {
  return WEAR_SLOT[lang][kind];
}

export function presentWear(
  f: WearForecast,
  lang: ChromeLang
): { slotLabel: string; label: string; reasoning: string } {
  const facts = f.facts;
  const label = fill(WEAR_RANGE[lang][f.kind], {
    low: String(f.remainingKmLow),
    high: String(f.remainingKmHigh),
  });
  if (!facts) {
    return { slotLabel: wearSlotLabel(f.kind, lang), label, reasoning: f.reasoning };
  }
  return {
    slotLabel: wearSlotLabel(f.kind, lang),
    label,
    reasoning: fill(WEAR_REASON[lang][f.kind], {
      lifeLow: String(facts.lifeLow),
      lifeHigh: String(facts.lifeHigh),
      km: facts.km != null ? facts.km.toFixed(0) : "0",
      hours: facts.hours != null ? facts.hours.toFixed(1) : "0.0",
      wet: facts.wetPct != null ? facts.wetPct.toFixed(0) : "0",
      descent: facts.descentHm != null ? facts.descentHm.toFixed(0) : "0",
      impacts: String(facts.impacts ?? 0),
      ebike: facts.isEbike ? EBIKE[lang] : "",
    }),
  };
}
