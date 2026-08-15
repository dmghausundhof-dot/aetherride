/**
 * SEO-Regionen für Explore / Regionen-Landingpages.
 * Redaktionelle Content-Schicht (kein Demo-Flag).
 */

export type RegionDef = {
  slug: string;
  name: string;
  country: string;
  /** Kurz für Cards */
  teaser: string;
  /** SEO-Beschreibung */
  description: string;
  /** Kartenmitte [lng, lat] */
  center: [number, number];
  zoom: number;
  sports: string[];
};

export const REGIONS: RegionDef[] = [
  {
    slug: "baden-wuerttemberg",
    name: "Baden-Württemberg",
    country: "DE",
    teaser: "Rhein, Neckar, Schwarzwald — Asphalt bis Singletrail.",
    description:
      "Rennrad am Kaiserstuhl, Gravel im Schwarzwald, City in Heidelberg und Stuttgart, Trails am Königstuhl und Schauinsland.",
    center: [8.4, 48.5],
    zoom: 8,
    sports: ["road", "gravel", "mtb", "urban", "touring"],
  },
  {
    slug: "schwarzwald",
    name: "Schwarzwald",
    country: "DE",
    teaser: "Höhenmeter, Forstwege und klassische Tourenregion.",
    description:
      "Gravel West, Kaltenbronn, Schauinsland und lange E-Bike-Touren — Hausberge um Freiburg und Baden-Baden.",
    center: [8.15, 48.1],
    zoom: 9,
    sports: ["gravel", "mtb", "ebike", "road"],
  },
  {
    slug: "rhein-neckar",
    name: "Rhein-Neckar",
    country: "DE",
    teaser: "City-Loops, Neckartal und flache Radwege.",
    description:
      "Heidelberg, Mannheim–Speyer am Rhein, Neckartal-Etappen und Alltagstouren um Karlsruhe.",
    center: [8.65, 49.4],
    zoom: 10,
    sports: ["road", "urban", "touring", "gravel"],
  },
  {
    slug: "bayern",
    name: "Bayern & Alpenvorland",
    country: "DE",
    teaser: "Seen, Gravel und alpine Anstiege.",
    description:
      "Tegernsee Gravel, München–Starnberg, Inn-Radweg und anspruchsvolle E-MTB-Ideen im Grenzraum.",
    center: [11.5, 47.8],
    zoom: 8,
    sports: ["gravel", "road", "mtb", "ebike", "touring"],
  },
  {
    slug: "bodensee",
    name: "Bodensee",
    country: "DE/AT/CH",
    teaser: "Flache Uferrouten und genussvolle Rennrad-Tage.",
    description:
      "Südufer-Asphalt, entspannte Trekking-Etappen und Ausflüge ins Hinterland.",
    center: [9.2, 47.66],
    zoom: 10,
    sports: ["road", "touring", "urban"],
  },
  {
    slug: "elsass-vogesen",
    name: "Elsass & Vogesen",
    country: "FR",
    teaser: "Weinstraße, Ballons und Gravel-Mix.",
    description:
      "Route des Vins, Ballon d'Alsace und grenzüberschreitende Touren ab Freiburg.",
    center: [7.3, 48.0],
    zoom: 9,
    sports: ["road", "gravel", "mtb"],
  },
  {
    slug: "sachsen",
    name: "Sachsen",
    country: "DE",
    teaser: "Elbe, Städte und flache Fernradwege.",
    description:
      "Elberadweg Dresden–Meißen und urbane Anbindungen für Alltags- und Tourenfahrer.",
    center: [13.7, 51.05],
    zoom: 10,
    sports: ["touring", "road", "urban"],
  },
  {
    slug: "eifel",
    name: "Eifel",
    country: "DE",
    teaser: "Vulkangravel und rollende Landschaften.",
    description:
      "Gravel-Runden mit Höhenmetern, gemischt Asphalt und unpaved — ideal für Ausdauer.",
    center: [6.7, 50.35],
    zoom: 9,
    sports: ["gravel", "road", "ebike"],
  },
  {
    slug: "alpen-west",
    name: "Westalpen (Idee)",
    country: "FR/CH",
    teaser: "Annecy, Morzine und alpine Profile.",
    description:
      "Rennrad am Lac d'Annecy, E-MTB Portes du Soleil — redaktionelle Ideen für Urlaubsplanung.",
    center: [6.4, 46.0],
    zoom: 8,
    sports: ["road", "mtb", "ebike"],
  },
  {
    slug: "berlin-brandenburg",
    name: "Berlin & Brandenburg",
    country: "DE",
    teaser: "Spree, Havelseen und urbane Radwege.",
    description:
      "Stadt-Loops, Mauerweg-Ideen und Gravel in Brandenburg — GPS-first, nicht pauschal Alpen.",
    center: [13.4, 52.5],
    zoom: 9,
    sports: ["urban", "road", "gravel"],
  },
  {
    slug: "norddeutschland",
    name: "Norddeutschland",
    country: "DE",
    teaser: "Alster, Förde, Elbe und flache Touren.",
    description:
      "Hamburg, Kiel, Lübeck, Bremen und Mecklenburg — Wind, Deiche, Alltagsradwege.",
    center: [10.0, 53.6],
    zoom: 7,
    sports: ["road", "urban", "touring"],
  },
  {
    slug: "nrw",
    name: "Nordrhein-Westfalen",
    country: "DE",
    teaser: "Rhein, Ruhr, Sauerland.",
    description:
      "Köln und Düsseldorf urban, Ruhrgebiet-Alltag, Sauerland-Trails und Eifel-Gravel.",
    center: [7.2, 51.2],
    zoom: 8,
    sports: ["urban", "road", "mtb", "gravel"],
  },
  {
    slug: "hessen-thueringen",
    name: "Hessen & Thüringen",
    country: "DE",
    teaser: "Rhein-Main, Rhön und Thüringer Wald.",
    description:
      "Frankfurt urban, Kassel, Erfurt und Wald-Gravel — Mitte Deutschlands.",
    center: [10.0, 50.7],
    zoom: 8,
    sports: ["urban", "gravel", "mtb"],
  },
  {
    slug: "osten",
    name: "Sachsen, Anhalt, Lausitz",
    country: "DE",
    teaser: "Elbe, Neuseenland, Harz.",
    description:
      "Dresden-Elbland, Leipzig, Magdeburg und Harz-Höhen — kuratierte Nähe plus OSM.",
    center: [13.0, 51.4],
    zoom: 8,
    sports: ["road", "touring", "gravel"],
  },
  {
    slug: "oesterreich",
    name: "Österreich",
    country: "AT",
    teaser: "Wienerwald, Tirol, Salzburg, Steiermark.",
    description:
      "Wien urban, Innsbruck-Trails, Salzburg, Graz und Kärnten — alpine Profile ehrlich gelabelt.",
    center: [13.5, 47.5],
    zoom: 7,
    sports: ["mtb", "road", "ebike", "gravel"],
  },
  {
    slug: "schweiz",
    name: "Schweiz",
    country: "CH",
    teaser: "Mittelland, Alpen, Tessin.",
    description:
      "Zürich, Bern, Basel, Léman, Graubünden und Tessin — SchweizMobil-Namen plus OSM-Tracks.",
    center: [8.2, 46.8],
    zoom: 7,
    sports: ["road", "mtb", "gravel", "urban"],
  },
];

export function getRegion(slug: string): RegionDef | null {
  return REGIONS.find((r) => r.slug === slug) ?? null;
}

export function listRegions(): RegionDef[] {
  return REGIONS;
}
