/**
 * Editorial public profiles — Opt-in examples, no GPS, no fake kilometers.
 */

export type EditorialProfile = {
  handle: string;
  displayName: string;
  bio: string;
  sports: string[];
  regionLabel: string;
  regionSlug: string;
};

export const EDITORIAL_PROFILES: EditorialProfile[] = [
  {
    handle: "mara_road",
    displayName: "Mara",
    bio: "Rennrad an flachen Ufern. Editorial-Beispiel — keine GPS-Spuren auf diesem Profil.",
    sports: ["road"],
    regionLabel: "Bodensee",
    regionSlug: "bodensee",
  },
  {
    handle: "jonas_r",
    displayName: "Jonas",
    bio: "Asphalt und Höhenmeter. Editorial-Beispiel, klar gekennzeichnet.",
    sports: ["road"],
    regionLabel: "Kaiserstuhl",
    regionSlug: "baden-wuerttemberg",
  },
  {
    handle: "lea_gravel",
    displayName: "Lea",
    bio: "Forstwege, nach Regen ehrlich. Editorial-Beispiel ohne Track-Anhang.",
    sports: ["gravel"],
    regionLabel: "Schwarzwald",
    regionSlug: "schwarzwald",
  },
  {
    handle: "eva_tour",
    displayName: "Eva",
    bio: "E-Trekking, Etappen, Pausenorte. Editorial-Beispiel.",
    sports: ["touring"],
    regionLabel: "Neckar",
    regionSlug: "rhein-neckar",
  },
  {
    handle: "tobi_trails",
    displayName: "Tobi",
    bio: "S1–S2, Wurzeln nach Regen. Editorial-Beispiel, Navigation in der App.",
    sports: ["mtb"],
    regionLabel: "Heidelberg",
    regionSlug: "rhein-neckar",
  },
  {
    handle: "mira_gravel",
    displayName: "Mira",
    bio: "Neckar, Schotterkante, Feierabend. Editorial-Beispiel zur Referenz-Tour.",
    sports: ["gravel"],
    regionLabel: "Heidelberg",
    regionSlug: "rhein-neckar",
  },
];

export function getEditorialProfile(handle: string): EditorialProfile | null {
  const h = handle.trim().toLowerCase();
  return EDITORIAL_PROFILES.find((p) => p.handle.toLowerCase() === h) ?? null;
}

export function listEditorialHandles(): string[] {
  return EDITORIAL_PROFILES.map((p) => p.handle);
}

export function listEditorialProfilesForRegion(slug: string): EditorialProfile[] {
  return EDITORIAL_PROFILES.filter((p) => p.regionSlug === slug);
}
