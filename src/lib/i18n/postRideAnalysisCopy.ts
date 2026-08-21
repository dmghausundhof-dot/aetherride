import type { ChromeLang } from "./chromeLang";
import type {
  PostRideObservation,
  SetupChangeSuggestion,
} from "@/lib/ai/postRideAnalysis";
import {
  localizeSetupCondition,
  recapChromeCopy,
} from "./recapChromeCopy";

export type PostRideAnalysisCopy = {
  factRide: string;
  factRideElev: string;
  obsImpacts: string;
  obsSmooth: string;
  obsFlowHigh: string;
  obsFlowLow: string;
  obsPeakG: string;
  obsElevGap: string;
  obsSteep: string;
  obsSteepDown: string;
  obsFbHarsh: string;
  obsFbSoft: string;
  feelTooFirm: string;
  feelOk: string;
  feelHarsh: string;
  feelNone: string;
  sugReboundSlowTitle: string;
  sugReboundSlowContent: string;
  sugReboundSlowEffect: string;
  sugReboundFastTitle: string;
  sugReboundFastContent: string;
  sugReboundFastEffect: string;
  sugPressureTitle: string;
  sugPressureContent: string;
  sugPressureEffect: string;
  sugLimitsClicks: string;
  factSetup: string;
  factMotor: string;
  reasonHarshBumps: string;
  reasonFrontFirm: string;
  reasonFrontLoad: string;
  reasonDive: string;
  reasonFrontSoft: string;
  reasonSoftDive: string;
  reasonPeakLong: string;
  reasonImpacts: string;
  reasonRms: string;
};

const DE: PostRideAnalysisCopy = {
  factRide: "{km} km · {hm} hm · {min} min",
  factRideElev: "{km} km · {climb} hm ↑ · {descent} hm ↓ · {min} min",
  obsImpacts:
    "Viele harte Impacts ({count} auf {km} km) — Front/Dämpfer stark belastet.",
  obsSmooth: "Wenige Impacts bei {km} km — eher flowig oder glatter Untergrund.",
  obsFlowHigh: "Hoher Flow-Score ({flow}) — Tempo und Linienwahl wirkten stimmig.",
  obsFlowLow: "Niedriger Flow-Score ({flow}) — viele Tempo-Brüche oder Stopps.",
  obsPeakG: "Peak {g} g — harte Einschläge; Setup und Reifendruck prüfen.",
  obsElevGap: "Höhenlücken auf {gap} km — Neigung dort nicht belastbar.",
  obsSteep: "Steile Passagen — max +{grade} %.",
  obsSteepDown: "Steile Abfahrten — max {grade} %.",
  obsFbHarsh: "Feedback: Front {front} · kleine Schläge {bumps}.",
  obsFbSoft: "Feedback: Front wirkt weich / taucht beim Anbremsen ab.",
  feelTooFirm: "zu hart",
  feelOk: "ok",
  feelHarsh: "rau",
  feelNone: "—",
  sugReboundSlowTitle: "Zugstufe Gabel: 2 Klicks langsamer",
  sugReboundSlowContent: "Aktuell ca. {current} Klicks von geschlossen → Ziel {next}.",
  sugReboundSlowEffect: "Ruhigere Front bei Schlagfolgen, etwas weniger Pop.",
  sugReboundFastTitle: "Zugstufe Gabel: 2 Klicks schneller",
  sugReboundFastContent: "Aktuell ca. {current} Klicks → Ziel {next} (weniger Dive).",
  sugReboundFastEffect: "Stabileres Anbremsen, weniger Durchschlag-Gefühl.",
  sugPressureTitle: "Luftdruck Front prüfen",
  sugPressureContent: "Viele Impacts bei niedrigem Flow — Reifendruck und Sag kurz checken.",
  sugPressureEffect: "Weniger Felgenschläge, klareres Handling.",
  sugLimitsClicks: "Herstellerbereich typisch 0–14 Klicks von geschlossen.",
  factSetup: "Setup „{label}“ ({conditions})",
  factMotor: "Ø SOC {soc}% · Rider {power} W",
  reasonHarshBumps: "Feedback „kleine Schläge rau“",
  reasonFrontFirm: "Feedback „Front zu hart“",
  reasonFrontLoad: "Hohe Schlagbelastung an der Front",
  reasonDive: "Feedback „taucht ab“",
  reasonFrontSoft: "Feedback „Front zu weich“",
  reasonSoftDive: "Front zu weich / Dive",
  reasonPeakLong: "Peak ≥ 5 g bei längerer Fahrt",
  reasonImpacts: "{count} Impacts / {km} km",
  reasonRms: "RMS {rms} g",
};

const EN: PostRideAnalysisCopy = {
  factRide: "{km} km · {hm} hm · {min} min",
  factRideElev: "{km} km · {climb} hm ↑ · {descent} hm ↓ · {min} min",
  obsImpacts:
    "Many hard impacts ({count} over {km} km) — fork/shock heavily loaded.",
  obsSmooth: "Few impacts over {km} km — more flowy or smoother ground.",
  obsFlowHigh: "High flow score ({flow}) — pace and line choice felt in sync.",
  obsFlowLow: "Low flow score ({flow}) — many pace breaks or stops.",
  obsPeakG: "Peak {g} g — hard hits; check setup and tire pressure.",
  obsElevGap: "Elevation gaps over {gap} km — grade is not reliable there.",
  obsSteep: "Steep climbs — max +{grade} %.",
  obsSteepDown: "Steep descents — max {grade} %.",
  obsFbHarsh: "Feedback: front {front} · small bumps {bumps}.",
  obsFbSoft: "Feedback: front feels soft / dives under braking.",
  feelTooFirm: "too firm",
  feelOk: "ok",
  feelHarsh: "harsh",
  feelNone: "—",
  sugReboundSlowTitle: "Fork rebound: 2 clicks slower",
  sugReboundSlowContent: "Currently about {current} clicks from closed → target {next}.",
  sugReboundSlowEffect: "Calmer front on hit sequences, a bit less pop.",
  sugReboundFastTitle: "Fork rebound: 2 clicks faster",
  sugReboundFastContent: "Currently about {current} clicks → target {next} (less dive).",
  sugReboundFastEffect: "Steadier braking, less blown-through feel.",
  sugPressureTitle: "Check front air pressure",
  sugPressureContent: "Many impacts at low flow — check tire pressure and sag.",
  sugPressureEffect: "Fewer rim strikes, clearer handling.",
  sugLimitsClicks: "Typical manufacturer range 0–14 clicks from closed.",
  factSetup: "Setup “{label}” ({conditions})",
  factMotor: "Avg SOC {soc}% · rider {power} W",
  reasonHarshBumps: "Feedback “small bumps harsh”",
  reasonFrontFirm: "Feedback “front too firm”",
  reasonFrontLoad: "High hit load on the front",
  reasonDive: "Feedback “dives”",
  reasonFrontSoft: "Feedback “front too soft”",
  reasonSoftDive: "Front too soft / dive",
  reasonPeakLong: "Peak ≥ 5 g on a longer ride",
  reasonImpacts: "{count} impacts / {km} km",
  reasonRms: "RMS {rms} g",
};

const FR: PostRideAnalysisCopy = {
  factRide: "{km} km · {hm} hm · {min} min",
  factRideElev: "{km} km · {climb} hm ↑ · {descent} hm ↓ · {min} min",
  obsImpacts:
    "Beaucoup d'impacts durs ({count} sur {km} km) — avant/amortisseur très sollicités.",
  obsSmooth: "Peu d'impacts sur {km} km — plutôt fluide ou sol lisse.",
  obsFlowHigh: "Flow élevé ({flow}) — rythme et lignes semblaient justes.",
  obsFlowLow: "Flow bas ({flow}) — beaucoup de cassures de rythme ou d'arrêts.",
  obsPeakG: "Peak {g} g — chocs durs; vérifie setup et pression.",
  obsElevGap: "Trous d’altitude sur {gap} km — pente peu fiable là.",
  obsSteep: "Passages raides — max +{grade} %.",
  obsSteepDown: "Descentes raides — max {grade} %.",
  obsFbHarsh: "Retour: avant {front} · petits chocs {bumps}.",
  obsFbSoft: "Retour: l'avant est mou / plonge au freinage.",
  feelTooFirm: "trop ferme",
  feelOk: "ok",
  feelHarsh: "rudes",
  feelNone: "—",
  sugReboundSlowTitle: "Détente fourche: 2 clics plus lent",
  sugReboundSlowContent: "Actuellement env. {current} clics de fermé → cible {next}.",
  sugReboundSlowEffect: "Avant plus calme sur les enchaînements, un peu moins de pop.",
  sugReboundFastTitle: "Détente fourche: 2 clics plus rapide",
  sugReboundFastContent: "Actuellement env. {current} clics → cible {next} (moins de plongée).",
  sugReboundFastEffect: "Freinage plus stable, moins d’effet de fond de course.",
  sugPressureTitle: "Vérifier la pression avant",
  sugPressureContent: "Beaucoup d’impacts à flow bas — vérifie pression et sag.",
  sugPressureEffect: "Moins de coups de jante, direction plus claire.",
  sugLimitsClicks: "Plage constructeur typique 0–14 clics de fermé.",
  factSetup: "Réglage « {label} » ({conditions})",
  factMotor: "SOC moy. {soc}% · cycliste {power} W",
  reasonHarshBumps: "Retour « petits chocs rudes »",
  reasonFrontFirm: "Retour « avant trop dur »",
  reasonFrontLoad: "Forte charge de chocs à l'avant",
  reasonDive: "Retour « plonge »",
  reasonFrontSoft: "Retour « avant trop mou »",
  reasonSoftDive: "Avant trop mou / plongée",
  reasonPeakLong: "Peak ≥ 5 g sur une sortie plus longue",
  reasonImpacts: "{count} impacts / {km} km",
  reasonRms: "RMS {rms} g",
};

const IT: PostRideAnalysisCopy = {
  factRide: "{km} km · {hm} hm · {min} min",
  factRideElev: "{km} km · {climb} hm ↑ · {descent} hm ↓ · {min} min",
  obsImpacts:
    "Molti impact duri ({count} su {km} km) — anteriore/ammortizzatore molto caricati.",
  obsSmooth: "Pochi impact su {km} km — più fluido o fondo liscio.",
  obsFlowHigh: "Flow alto ({flow}) — ritmo e linea sembravano giusti.",
  obsFlowLow: "Flow basso ({flow}) — molte interruzioni di ritmo o fermate.",
  obsPeakG: "Peak {g} g — urti duri; controlla setup e pressione.",
  obsElevGap: "Buchi di quota su {gap} km — pendenza non affidabile lì.",
  obsSteep: "Passaggi ripidi — max +{grade} %.",
  obsSteepDown: "Discese ripide — max {grade} %.",
  obsFbHarsh: "Feedback: anteriore {front} · piccoli urti {bumps}.",
  obsFbSoft: "Feedback: l'anteriore è morbido / affonda in frenata.",
  feelTooFirm: "troppo dura",
  feelOk: "ok",
  feelHarsh: "ruvidi",
  feelNone: "—",
  sugReboundSlowTitle: "Ritorno forcella: 2 click più lento",
  sugReboundSlowContent: "Ora circa {current} click da chiuso → obiettivo {next}.",
  sugReboundSlowEffect: "Anteriore più calmo sulle sequenze, un po’ meno pop.",
  sugReboundFastTitle: "Ritorno forcella: 2 click più veloce",
  sugReboundFastContent: "Ora circa {current} click → obiettivo {next} (meno affondo).",
  sugReboundFastEffect: "Frenata più stabile, meno sensazione di fine corsa.",
  sugPressureTitle: "Controlla pressione anteriore",
  sugPressureContent: "Molti impact a flow basso — controlla pressione e sag.",
  sugPressureEffect: "Meno colpi sul cerchio, guida più chiara.",
  sugLimitsClicks: "Range produttore tipico 0–14 click da chiuso.",
  factSetup: "Setup “{label}” ({conditions})",
  factMotor: "SOC medio {soc}% · rider {power} W",
  reasonHarshBumps: "Feedback “piccoli urti ruvidi”",
  reasonFrontFirm: "Feedback “anteriore troppo duro”",
  reasonFrontLoad: "Alto carico di urti sull'anteriore",
  reasonDive: "Feedback “affonda”",
  reasonFrontSoft: "Feedback “anteriore troppo morbido”",
  reasonSoftDive: "Anteriore troppo morbido / affondo",
  reasonPeakLong: "Peak ≥ 5 g su un giro più lungo",
  reasonImpacts: "{count} impact / {km} km",
  reasonRms: "RMS {rms} g",
};

const NL: PostRideAnalysisCopy = {
  factRide: "{km} km · {hm} hm · {min} min",
  factRideElev: "{km} km · {climb} hm ↑ · {descent} hm ↓ · {min} min",
  obsImpacts:
    "Veel harde klappen ({count} over {km} km) — vork/demper zwaar belast.",
  obsSmooth: "Weinig klappen over {km} km — meer flow of gladdere ondergrond.",
  obsFlowHigh: "Hoge flowscore ({flow}) — tempo en lijnkeuze voelden synchroon.",
  obsFlowLow: "Lage flowscore ({flow}) — veel tempobreuken of stops.",
  obsPeakG: "Piek {g} g — harde klappen; check setup en bandenspanning.",
  obsElevGap: "Hoogtegaten over {gap} km — helling daar niet betrouwbaar.",
  obsSteep: "Steile stukken — max +{grade} %.",
  obsSteepDown: "Steile afdalingen — max {grade} %.",
  obsFbHarsh: "Feedback: voor {front} · kleine klappen {bumps}.",
  obsFbSoft: "Feedback: voor voelt zacht / duikt bij remmen.",
  feelTooFirm: "te hard",
  feelOk: "ok",
  feelHarsh: "hard",
  feelNone: "—",
  sugReboundSlowTitle: "Vork-rebound: 2 klikken langzamer",
  sugReboundSlowContent: "Nu ca. {current} klikken vanaf dicht → doel {next}.",
  sugReboundSlowEffect: "Kalmere voorzijde bij klappen, iets minder pop.",
  sugReboundFastTitle: "Vork-rebound: 2 klikken sneller",
  sugReboundFastContent: "Nu ca. {current} klikken → doel {next} (minder duik).",
  sugReboundFastEffect: "Stabieler remmen, minder doorzakken.",
  sugPressureTitle: "Luchtdruk voor checken",
  sugPressureContent: "Veel impacts bij lage flow — check bandenspanning en sag.",
  sugPressureEffect: "Minder velgslagen, duidelijker sturen.",
  sugLimitsClicks: "Typisch bereik 0–14 klikken vanaf dicht.",
  factSetup: "Setup “{label}” ({conditions})",
  factMotor: "Gem. SOC {soc}% · rider {power} W",
  reasonHarshBumps: "Feedback “kleine klappen hard”",
  reasonFrontFirm: "Feedback “voor te stug”",
  reasonFrontLoad: "Hoge klapbelasting vooraan",
  reasonDive: "Feedback “duikt”",
  reasonFrontSoft: "Feedback “voor te zacht”",
  reasonSoftDive: "Voor te zacht / duiken",
  reasonPeakLong: "Piek ≥ 5 g op een langere rit",
  reasonImpacts: "{count} klappen / {km} km",
  reasonRms: "RMS {rms} g",
};

const BY_LANG: Record<ChromeLang, PostRideAnalysisCopy> = {
  de: DE,
  en: EN,
  fr: FR,
  it: IT,
  nl: NL,
};

export function postRideAnalysisCopy(lang: ChromeLang): PostRideAnalysisCopy {
  return BY_LANG[lang];
}

export function fillCopy(
  template: string,
  params: Record<string, string>
): string {
  return template.replace(/\{(\w+)\}/g, (_, k) => params[k] ?? "");
}

export function localizePostRideFact(
  fact: string,
  copy: PostRideAnalysisCopy,
  lang: ChromeLang = "de"
): string {
  const elev = /^([\d.]+) km · (\d+) hm ↑ · (\d+) hm ↓ · ([\d.]+) min$/.exec(
    fact
  );
  if (elev) {
    return fillCopy(copy.factRideElev, {
      km: elev[1],
      climb: elev[2],
      descent: elev[3],
      min: elev[4],
    });
  }
  const ride = /^([\d.]+) km · (\d+) hm · ([\d.]+) min$/.exec(fact);
  if (ride) {
    return fillCopy(copy.factRide, {
      km: ride[1],
      hm: ride[2],
      min: ride[3],
    });
  }
  const setup = /^Setup „(.+)“ \((.+)\)$/.exec(fact);
  if (setup) {
    return fillCopy(copy.factSetup, {
      label: setup[1],
      conditions: localizeSetupCondition(setup[2], recapChromeCopy(lang)),
    });
  }
  const motor = /^Ø SOC (\d+)% · Rider (\d+) W$/.exec(fact);
  if (motor) {
    return fillCopy(copy.factMotor, { soc: motor[1], power: motor[2] });
  }
  return fact;
}

export function localizePostRideReason(
  de: string,
  copy: PostRideAnalysisCopy
): string {
  return de
    .split(" · ")
    .map((part) => localizeReasonPart(part, copy))
    .join(" · ");
}

function localizeReasonPart(
  de: string,
  copy: PostRideAnalysisCopy
): string {
  switch (de) {
    case "Feedback „kleine Schläge rau“":
      return copy.reasonHarshBumps;
    case "Feedback „Front zu hart“":
      return copy.reasonFrontFirm;
    case "Hohe Schlagbelastung an der Front":
      return copy.reasonFrontLoad;
    case "Feedback „taucht ab“":
      return copy.reasonDive;
    case "Feedback „Front zu weich“":
      return copy.reasonFrontSoft;
    case "Front zu weich / Dive":
      return copy.reasonSoftDive;
    case "Peak ≥ 5 g bei längerer Fahrt":
      return copy.reasonPeakLong;
    default:
      break;
  }
  const impacts = /^(\d+) Impacts \/ ([\d.]+) km$/.exec(de);
  if (impacts) {
    return fillCopy(copy.reasonImpacts, {
      count: impacts[1],
      km: impacts[2],
    });
  }
  const rms = /^RMS ([\d.]+) g$/.exec(de);
  if (rms) return fillCopy(copy.reasonRms, { rms: rms[1] });
  return de;
}

export function localizePostRideObservation(
  o: PostRideObservation,
  copy: PostRideAnalysisCopy
): string {
  const p = o.params ?? {};
  switch (o.id) {
    case "impacts":
      return fillCopy(copy.obsImpacts, p);
    case "smooth":
      return fillCopy(copy.obsSmooth, p);
    case "flow-high":
      return fillCopy(copy.obsFlowHigh, p);
    case "flow-low":
      return fillCopy(copy.obsFlowLow, p);
    case "peak-g":
      return fillCopy(copy.obsPeakG, p);
    case "elev-gap":
      return fillCopy(copy.obsElevGap, p);
    case "steep":
      return fillCopy(copy.obsSteep, p);
    case "steep-down":
      return fillCopy(copy.obsSteepDown, p);
    case "fb-harsh":
      return fillCopy(copy.obsFbHarsh, {
        front: p.front === "too_firm" ? copy.feelTooFirm : copy.feelOk,
        bumps: p.bumps === "harsh" ? copy.feelHarsh : copy.feelNone,
      });
    case "fb-soft":
      return copy.obsFbSoft;
    default:
      return o.text;
  }
}

export function localizeSetupSuggestion(
  s: SetupChangeSuggestion,
  copy: PostRideAnalysisCopy
): Pick<
  SetupChangeSuggestion,
  "title" | "content" | "expectedEffect" | "limits"
> {
  const p = s.params ?? {};
  switch (s.kind) {
    case "rebound-slow":
      return {
        title: copy.sugReboundSlowTitle,
        content: fillCopy(copy.sugReboundSlowContent, p),
        expectedEffect: copy.sugReboundSlowEffect,
        limits: copy.sugLimitsClicks,
      };
    case "rebound-fast":
      return {
        title: copy.sugReboundFastTitle,
        content: fillCopy(copy.sugReboundFastContent, p),
        expectedEffect: copy.sugReboundFastEffect,
        limits: copy.sugLimitsClicks,
      };
    case "pressure":
      return {
        title: copy.sugPressureTitle,
        content: copy.sugPressureContent,
        expectedEffect: copy.sugPressureEffect,
        limits: s.limits,
      };
    default:
      return {
        title: s.title,
        content: s.content,
        expectedEffect: s.expectedEffect,
        limits: s.limits,
      };
  }
}
