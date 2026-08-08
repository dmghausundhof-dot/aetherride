/**
 * Routenvorschläge
 * Jeder Vorschlag nennt genau drei Begründungsfaktoren.
 * Eingang: aktives Bike (optional), Rider-Profil, verfügbare Zeit.
 */

import type { Bike, BikeCategory, RiderProfile } from "@/types";
import type { RoutingProfile } from "@/lib/routing/profiles";

export interface RouteSuggestion {
  id: string;
  name: string;
  category: BikeCategory;
  distanceKm: number;
  elevationM: number;
  durationMin: number;
  mtbScale: string;
  surface: string;
  loop: boolean;
  uncertainKmPct: number;
  matchScore: number;
  /** Genau drei Faktoren */
  reasons: [string, string, string];
  rangeOk?: boolean;
  rangeNote?: string;
}

interface RouteSeed {
  id: string;
  name: string;
  categories: BikeCategory[];
  distanceKm: number;
  elevationM: number;
  durationMin: number;
  mtbScale: string;
  surface: string;
  loop: boolean;
  uncertainKmPct: number;
  technical: boolean;
  steep: boolean;
  flowy: boolean;
  ebikeFriendly: boolean;
}

const SEEDS: RouteSeed[] = [
  {
    id: "r-kaltenbronn",
    name: "Kaltenbronn Runde",
    categories: ["mtb_enduro", "mtb_am", "mtb_trail", "emtb"],
    distanceKm: 34,
    elevationM: 980,
    durationMin: 160,
    mtbScale: "S1–S2",
    surface: "trail/root",
    loop: true,
    uncertainKmPct: 10,
    technical: false,
    steep: false,
    flowy: true,
    ebikeFriendly: true,
  },
  {
    id: "r-alpbach-enduro",
    name: "Enduro Alpbachtal",
    categories: ["mtb_enduro", "mtb_am", "emtb"],
    distanceKm: 28.4,
    elevationM: 1240,
    durationMin: 150,
    mtbScale: "S2–S3",
    surface: "trail/root",
    loop: true,
    uncertainKmPct: 12,
    technical: true,
    steep: true,
    flowy: false,
    ebikeFriendly: true,
  },
  {
    id: "r-soell-flow",
    name: "Flow Trail Söll",
    categories: ["mtb_trail", "mtb_am", "emtb"],
    distanceKm: 18.7,
    elevationM: 720,
    durationMin: 95,
    mtbScale: "S1–S2",
    surface: "flow/compact",
    loop: true,
    uncertainKmPct: 8,
    technical: false,
    steep: false,
    flowy: true,
    ebikeFriendly: true,
  },
  {
    id: "r-kitz-gravel",
    name: "Gravel Loop Kitzbühel",
    categories: ["gravel", "etrekking", "road"],
    distanceKm: 62.1,
    elevationM: 890,
    durationMin: 180,
    mtbScale: "—",
    surface: "gravel/asphalt",
    loop: true,
    uncertainKmPct: 5,
    technical: false,
    steep: false,
    flowy: true,
    ebikeFriendly: true,
  },
  {
    id: "r-hochkoenig-emtb",
    name: "E-MTB Hochkönig",
    categories: ["emtb", "mtb_enduro"],
    distanceKm: 41.2,
    elevationM: 1580,
    durationMin: 165,
    mtbScale: "S2–S3",
    surface: "trail/alpine",
    loop: false,
    uncertainKmPct: 18,
    technical: true,
    steep: true,
    flowy: false,
    ebikeFriendly: true,
  },
  {
    id: "r-wilder-kaiser-hike",
    name: "Wilder Kaiser Höhenweg",
    categories: ["hiking"],
    distanceKm: 14.2,
    elevationM: 980,
    durationMin: 300,
    mtbScale: "T2",
    surface: "path",
    loop: false,
    uncertainKmPct: 10,
    technical: true,
    steep: true,
    flowy: false,
    ebikeFriendly: false,
  },
  {
    id: "r-inn-flat",
    name: "Inn-Radweg Entspannt",
    categories: ["road", "gravel", "etrekking", "urban"],
    distanceKm: 34,
    elevationM: 120,
    durationMin: 90,
    mtbScale: "—",
    surface: "asphalt",
    loop: false,
    uncertainKmPct: 2,
    technical: false,
    steep: false,
    flowy: true,
    ebikeFriendly: true,
  },
];

export function categoryForRoutingProfile(
  profile: RoutingProfile
): BikeCategory {
  switch (profile) {
    case "mtb_enduro":
      return "mtb_enduro";
    case "gravel":
      return "gravel";
    case "road":
      return "road";
    case "urban":
      return "urban";
    case "ebike":
      return "etrekking";
    case "emtb":
      return "emtb";
    case "hiking":
      return "hiking";
    case "mtb_allmountain":
    default:
      return "mtb_am";
  }
}

export function suggestRoutes(input: {
  bike?: Bike | null;
  categoryHint?: BikeCategory;
  profile: RiderProfile;
  availableMinutes?: number;
  rangeKmHigh?: number;
}): RouteSuggestion[] {
  const minutes = input.availableMinutes ?? 150;
  const category =
    input.bike?.category ?? input.categoryHint ?? "mtb_am";
  const bikeName = input.bike?.name ?? "dein Profil";
  const travel = input.bike?.travelFrontMm;
  const isEbike = input.bike?.isEbike ?? false;

  const scored = SEEDS.filter((s) => s.categories.includes(category))
    .map((s) => {
      const reasons: string[] = [];
      let score = 50;

      if (s.categories.includes(category)) {
        score += 15;
        reasons.push(
          input.bike
            ? `Passt zu ${bikeName}${
                travel ? ` (${travel} mm Federweg)` : ""
              }`
            : `Passt zu ${category.replace(/_/g, " ")}`
        );
      }

      const terrain = input.profile.terrainShare;
      if (input.profile.preferences.preferTechnical && s.technical) {
        score += 12;
        reasons.push(`Technisch (mtb:scale ${s.mtbScale}) wie von dir bevorzugt`);
      } else if (input.profile.preferences.preferFlow && s.flowy) {
        score += 12;
        reasons.push(`Flow-Charakter (${s.surface}) matched dein Profil`);
      } else if (input.profile.preferences.preferSteep && s.steep) {
        score += 10;
        reasons.push(`Steile Abschnitte (~${s.elevationM} hm)`);
      } else if (terrain && s.mtbScale.includes("S3") && terrain.s3plus >= 30) {
        score += 10;
        reasons.push(`S3+-Anteil ${terrain.s3plus}% in deinem Terrainprofil`);
      } else {
        reasons.push(
          `Oberfläche ${s.surface}, Unsicherheit ${s.uncertainKmPct}% OSM-Tags`
        );
      }

      const timeDelta = Math.abs(s.durationMin - minutes);
      if (timeDelta <= 30) {
        score += 12;
        reasons.push(`Dauer ~${s.durationMin} min passt zu deinen ${minutes} min`);
      } else if (s.durationMin <= minutes + 45) {
        score += 6;
        reasons.push(`Machbar in ~${s.durationMin} min (Ziel ${minutes} min)`);
      } else {
        score -= 8;
        reasons.push(`Länger als geplant (${s.durationMin} vs ${minutes} min)`);
      }

      let rangeOk: boolean | undefined;
      let rangeNote: string | undefined;
      if (isEbike && input.rangeKmHigh !== undefined) {
        rangeOk = s.distanceKm <= input.rangeKmHigh * 0.85;
        if (rangeOk) {
          score += 8;
          if (reasons.length < 3)
            reasons.push(
              `Distanz ${s.distanceKm} km innerhalb Reichweitenband`
            );
        } else {
          score -= 15;
          rangeNote = `Route ${s.distanceKm} km > prognostizierte Reichweite ~${input.rangeKmHigh} km`;
        }
      }

      while (reasons.length < 3) {
        reasons.push(
          s.loop
            ? `Rundkurs · ${s.distanceKm} km · ${s.elevationM} hm`
            : `Point-to-point · ${s.distanceKm} km · ${s.elevationM} hm`
        );
      }

      return {
        id: s.id,
        name: s.name,
        category,
        distanceKm: s.distanceKm,
        elevationM: s.elevationM,
        durationMin: s.durationMin,
        mtbScale: s.mtbScale,
        surface: s.surface,
        loop: s.loop,
        uncertainKmPct: s.uncertainKmPct,
        matchScore: Math.max(0, Math.min(99, Math.round(score))),
        reasons: reasons.slice(0, 3) as [string, string, string],
        rangeOk,
        rangeNote,
      } satisfies RouteSuggestion;
    })
    .sort((a, b) => b.matchScore - a.matchScore)
    .slice(0, 5);

  return scored.length
    ? scored
    : SEEDS.slice(0, 3).map((s, i) => ({
        id: s.id,
        name: s.name,
        category,
        distanceKm: s.distanceKm,
        elevationM: s.elevationM,
        durationMin: s.durationMin,
        mtbScale: s.mtbScale,
        surface: s.surface,
        loop: s.loop,
        uncertainKmPct: s.uncertainKmPct,
        matchScore: 60 - i * 5,
        reasons: [
          "Wenige exakte Kategorie-Treffer — allgemeine Vorschläge",
          `${s.distanceKm} km · ${s.elevationM} hm`,
          `Unsichere OSM-Kilometer: ${s.uncertainKmPct}%`,
        ] as [string, string, string],
      }));
}

/** Einzelnen Seed als Vorschlag auflösen (Deep-Link / Detail). */
export function getSuggestionById(
  id: string,
  input: {
    bike?: Bike | null;
    categoryHint?: BikeCategory;
    profile: RiderProfile;
    availableMinutes?: number;
    rangeKmHigh?: number;
  }
): RouteSuggestion | null {
  const fromList = suggestRoutes({
    ...input,
    availableMinutes: input.availableMinutes ?? 300,
  }).find((r) => r.id === id);
  if (fromList) return fromList;

  const seed = SEEDS.find((s) => s.id === id);
  if (!seed) return null;
  const category =
    input.bike?.category ?? input.categoryHint ?? seed.categories[0];

  return {
    id: seed.id,
    name: seed.name,
    category,
    distanceKm: seed.distanceKm,
    elevationM: seed.elevationM,
    durationMin: seed.durationMin,
    mtbScale: seed.mtbScale,
    surface: seed.surface,
    loop: seed.loop,
    uncertainKmPct: seed.uncertainKmPct,
    matchScore: 70,
    reasons: [
      input.bike
        ? `Passt grob zu ${input.bike.name}`
        : `Passend für ${category.replace(/_/g, " ")}`,
      `${seed.distanceKm} km · ${seed.elevationM} hm · ${seed.mtbScale}`,
      seed.loop ? "Rundkurs" : "Point-to-point",
    ],
  };
}
