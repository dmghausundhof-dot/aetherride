/**
 * Setup template labels/disclaimers. Domain stores German; UI maps by id.
 */
import type { ChromeLang } from "./chromeLang";

export type SetupTemplateChrome = {
  label: string;
  disclaimer: string;
};

type Row = Record<ChromeLang, SetupTemplateChrome>;

const BY_ID: Record<string, Row> = {
  "tpl-fox-oem-base": {
    de: {
      label: "Fox OEM Basis (Gewichtstabelle)",
      disclaimer:
        "Ausgangspunkt laut Fox Starting-Points-Tabelle — keine persönliche Empfehlung. SAG danach messen und Kammern ausgleichen.",
    },
    en: {
      label: "Fox OEM base (weight chart)",
      disclaimer:
        "Starting point from the Fox starting-points chart — not a personal recommendation. Measure sag afterwards and equalise chambers.",
    },
    fr: {
      label: "Fox OEM de base (tableau de poids)",
      disclaimer:
        "Point de départ du tableau Fox — pas une reco personnelle. Mesure le SAG ensuite et équilibre les chambres.",
    },
    it: {
      label: "Fox OEM base (tabella peso)",
      disclaimer:
        "Punto di partenza dalla tabella Fox — non una reco personale. Misura il SAG dopo e bilancia le camere.",
    },
    nl: {
      label: "Fox OEM-basis (gewichtstabel)",
      disclaimer:
        "Startpunt uit de Fox-starttabel — geen persoonlijk advies. Meet daarna SAG en gelijk de kamers.",
    },
  },
  "tpl-fox-x2-oem": {
    de: {
      label: "Fox Float X2 OEM (lbs→psi + Klicks)",
      disclaimer:
        "Fox X2: Start-Druck ≈ Gewicht in lbs, SAG ~30 %, dann Dämpfer-Tabelle. Rahmenhebelverhältnis nicht enthalten — Ausgangspunkt.",
    },
    en: {
      label: "Fox Float X2 OEM (lbs→psi + clicks)",
      disclaimer:
        "Fox X2: start pressure ≈ body weight in lbs, sag ~30 %, then the damper chart. Leverage ratio not included — a starting point.",
    },
    fr: {
      label: "Fox Float X2 OEM (lbs→psi + clics)",
      disclaimer:
        "Fox X2 : pression de départ ≈ poids en lbs, SAG ~30 %, puis tableau amortisseur. Ratio de levier non inclus — point de départ.",
    },
    it: {
      label: "Fox Float X2 OEM (lbs→psi + click)",
      disclaimer:
        "Fox X2: pressione di partenza ≈ peso in lbs, SAG ~30 %, poi tabella ammortizzatore. Rapporto leva non incluso — punto di partenza.",
    },
    nl: {
      label: "Fox Float X2 OEM (lbs→psi + clicks)",
      disclaimer:
        "Fox X2: startdruk ≈ gewicht in lbs, SAG ~30 %, daarna dempertabel. Heverhouding niet inbegrepen — startpunt.",
    },
  },
  "tpl-rockshox-sag-start": {
    de: {
      label: "RockShox SAG-Start (TrailHead-Näherung)",
      disclaimer:
        "RockShox: Dämpfer-Start ≈ Körpergewicht in lbs; Gabel nach Bein-Chart/TrailHead. Dann auf 25–30 % SAG trimmen. Kein Ersatz für die TrailHead-App mit Seriennummer.",
    },
    en: {
      label: "RockShox sag start (TrailHead approximation)",
      disclaimer:
        "RockShox: shock start ≈ body weight in lbs; fork from the leg chart/TrailHead. Then trim to 25–30 % sag. Not a substitute for the TrailHead app with serial number.",
    },
    fr: {
      label: "RockShox départ SAG (approx. TrailHead)",
      disclaimer:
        "RockShox : départ amortisseur ≈ poids en lbs ; fourche selon tableau/TrailHead. Puis viser 25–30 % de SAG. Pas un remplacement de l’app TrailHead avec n° de série.",
    },
    it: {
      label: "RockShox partenza SAG (approx. TrailHead)",
      disclaimer:
        "RockShox: partenza ammortizzatore ≈ peso in lbs; forcella da tabella/TrailHead. Poi regola al 25–30 % SAG. Non sostituisce l’app TrailHead col numero di serie.",
    },
    nl: {
      label: "RockShox SAG-start (TrailHead-benadering)",
      disclaimer:
        "RockShox: demperstart ≈ lichaamsgewicht in lbs; vork via been-chart/TrailHead. Daarna op 25–30 % SAG trimmen. Geen vervanging van de TrailHead-app met serienummer.",
    },
  },
  "tpl-editorial-wet-roots": {
    de: {
      label: "Editorial: Nasse Roots",
      disclaimer:
        "Redaktions-Preset als Ausgangspunkt — kein Ersatz für Bracketing auf deinem Trail.",
    },
    en: {
      label: "Editorial: wet roots",
      disclaimer:
        "Editorial preset as a starting point — not a substitute for bracketing on your trail.",
    },
    fr: {
      label: "Édito : roots mouillées",
      disclaimer:
        "Preset éditorial comme point de départ — pas un remplacement du bracketing sur ton trail.",
    },
    it: {
      label: "Editoriale: roots bagnate",
      disclaimer:
        "Preset editoriale come punto di partenza — non sostituisce il bracketing sul tuo trail.",
    },
    nl: {
      label: "Redactioneel: natte roots",
      disclaimer:
        "Redactioneel preset als startpunt — geen vervanging van bracketing op jouw trail.",
    },
  },
  "tpl-editorial-bikepark": {
    de: {
      label: "Editorial: Bikepark",
      disclaimer: "Ausgangspunkt für Park — mehr Support, weniger SAG-Spiel.",
    },
    en: {
      label: "Editorial: bike park",
      disclaimer: "Starting point for park — more support, less sag play.",
    },
    fr: {
      label: "Édito : bikepark",
      disclaimer: "Point de départ park — plus de support, moins de jeu en SAG.",
    },
    it: {
      label: "Editoriale: bike park",
      disclaimer: "Punto di partenza park — più supporto, meno gioco in SAG.",
    },
    nl: {
      label: "Redactioneel: bikepark",
      disclaimer: "Startpunt voor park — meer support, minder SAG-speling.",
    },
  },
  "tpl-editorial-marathon": {
    de: {
      label: "Editorial: Marathon / lange Tour",
      disclaimer:
        "Effizienz-lastiger Ausgangspunkt für lange Touren — weniger SAG, mehr Pedal-Plattform.",
    },
    en: {
      label: "Editorial: marathon / long ride",
      disclaimer:
        "Efficiency-leaning starting point for long rides — less sag, more pedal platform.",
    },
    fr: {
      label: "Édito : marathon / longue sortie",
      disclaimer:
        "Départ plus efficace pour les longues sorties — moins de SAG, plus de plateforme pédale.",
    },
    it: {
      label: "Editoriale: marathon / giro lungo",
      disclaimer:
        "Partenza più efficiente per giri lunghi — meno SAG, più piattaforma pedale.",
    },
    nl: {
      label: "Redactioneel: marathon / lange tocht",
      disclaimer:
        "Efficiënter startpunt voor lange ritten — minder SAG, meer pedaalplatform.",
    },
  },
  "tpl-editorial-race-enduro": {
    de: {
      label: "Editorial: Enduro-Rennen",
      disclaimer:
        "Race-Ausgangspunkt — aggressiver Support. Nur Startpunkt vor Track-Walk-Bracketing.",
    },
    en: {
      label: "Editorial: enduro race",
      disclaimer:
        "Race starting point — more aggressive support. Only a start before track-walk bracketing.",
    },
    fr: {
      label: "Édito : course enduro",
      disclaimer:
        "Départ course — support plus agressif. Seulement un start avant le bracketing du recce.",
    },
    it: {
      label: "Editoriale: gara enduro",
      disclaimer:
        "Partenza gara — supporto più aggressivo. Solo un inizio prima del bracketing sul recce.",
    },
    nl: {
      label: "Redactioneel: enduro-race",
      disclaimer:
        "Race-startpunt — agressievere support. Alleen een start vóór bracketing op de recce.",
    },
  },
  "tpl-gravel-base": {
    de: {
      label: "Gravel Basisdruck",
      disclaimer: "Grobe Startdrücke für 40–45 mm Gravelreifen — Tubeless beachten.",
    },
    en: {
      label: "Gravel base pressure",
      disclaimer: "Rough start pressures for 40–45 mm gravel tyres — mind tubeless.",
    },
    fr: {
      label: "Pression gravel de base",
      disclaimer:
        "Pressions de départ approximatives pour pneus gravel 40–45 mm — pense au tubeless.",
    },
    it: {
      label: "Pressione gravel di base",
      disclaimer:
        "Pressioni di partenza approssimative per copertoni gravel 40–45 mm — tieni presente il tubeless.",
    },
    nl: {
      label: "Gravel-basisdruk",
      disclaimer: "Ruwe startdrukken voor 40–45 mm gravelbanden — let op tubeless.",
    },
  },
  "tpl-road-tires": {
    de: {
      label: "Rennrad Basisdruck",
      disclaimer:
        "Grober Startdruck für 700c — Reifenbreite und Schlauchlos beachten.",
    },
    en: {
      label: "Road base pressure",
      disclaimer: "Rough start pressure for 700c — mind tyre width and tubeless.",
    },
    fr: {
      label: "Pression route de base",
      disclaimer:
        "Pression de départ approximative pour 700c — largeur et tubeless à vérifier.",
    },
    it: {
      label: "Pressione strada di base",
      disclaimer:
        "Pressione di partenza approssimativa per 700c — larghezza e tubeless da tenere d’occhio.",
    },
    nl: {
      label: "Racefiets-basisdruk",
      disclaimer: "Ruwe startdruk voor 700c — let op bandbreedte en tubeless.",
    },
  },
  "tpl-urban-tires": {
    de: {
      label: "City / Trekking Basisdruck",
      disclaimer: "Grober Startdruck — am Reifen nachmessen, kein OEM-Wert.",
    },
    en: {
      label: "City / trekking base pressure",
      disclaimer: "Rough start pressure — measure on the tyre, not an OEM value.",
    },
    fr: {
      label: "Pression city / trekking de base",
      disclaimer:
        "Pression de départ approximative — à mesurer sur le pneu, pas une valeur OEM.",
    },
    it: {
      label: "Pressione city / trekking di base",
      disclaimer:
        "Pressione di partenza approssimativa — misura sul copertone, non un valore OEM.",
    },
    nl: {
      label: "City / trekking-basisdruk",
      disclaimer: "Ruwe startdruk — op de band nameten, geen OEM-waarde.",
    },
  },
};

export function presentSetupTemplate(
  id: string,
  lang: ChromeLang = "de",
  fallback?: { label: string; disclaimer: string }
): SetupTemplateChrome {
  const row = BY_ID[id];
  if (!row) {
    return {
      label: fallback?.label ?? id,
      disclaimer: fallback?.disclaimer ?? "",
    };
  }
  return row[lang] ?? row.de;
}
