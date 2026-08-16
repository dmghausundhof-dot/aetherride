import type { ChromeLang } from "./chromeLang";

export type OverlayCopy = {
  waysOsm: string;
  on: string;
  off: string;
  unrated: string;
  gravel: string;
  road: string;
  urban: string;
  scaleNote: string;
};

const DE: OverlayCopy = {
  waysOsm: "Wege · OSM",
  on: "an",
  off: "aus",
  unrated: "unbewertet",
  gravel: "Gravel",
  road: "Radweg / Asphalt",
  urban: "City",
  scaleNote:
    "S0–S3+ nur bei OSM-Tag mtb:scale. sac_scale wird nicht umgemünzt.",
};

const EN: OverlayCopy = {
  waysOsm: "Ways · OSM",
  on: "on",
  off: "off",
  unrated: "unrated",
  gravel: "Gravel",
  road: "Cycleway / asphalt",
  urban: "City",
  scaleNote:
    "S0–S3+ only with OSM tag mtb:scale. sac_scale is not remapped.",
};

const FR: OverlayCopy = {
  waysOsm: "Chemins · OSM",
  on: "on",
  off: "off",
  unrated: "non noté",
  gravel: "Gravel",
  road: "Piste cyclable / asphalte",
  urban: "City",
  scaleNote:
    "S0–S3+ seulement avec le tag OSM mtb:scale. sac_scale n’est pas converti.",
};

const IT: OverlayCopy = {
  waysOsm: "Vie · OSM",
  on: "on",
  off: "off",
  unrated: "non valutato",
  gravel: "Gravel",
  road: "Pista ciclabile / asfalto",
  urban: "City",
  scaleNote:
    "S0–S3+ solo con tag OSM mtb:scale. sac_scale non viene convertito.",
};

const BY_LANG: Record<ChromeLang, OverlayCopy> = {
  de: DE,
  en: EN,
  fr: FR,
  it: IT,
};

export function overlayCopy(lang: ChromeLang): OverlayCopy {
  return BY_LANG[lang];
}

export function overlayLegendLabel(key: string, lang: ChromeLang): string {
  const o = overlayCopy(lang);
  if (key === "unrated") return o.unrated;
  if (key === "gravel") return o.gravel;
  if (key === "road") return o.road;
  if (key === "urban") return o.urban;
  return key;
}
