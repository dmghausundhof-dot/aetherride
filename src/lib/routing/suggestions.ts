/**
 * Routenvorschläge
 * Jeder Vorschlag nennt genau drei Begründungsfaktoren.
 * Eingang: aktives Bike (optional), Rider-Profil, verfügbare Zeit.
 */

import type { Bike, BikeCategory, RiderProfile } from "@/types";
import type { RoutingProfile } from "@/lib/routing/profiles";
import { demoCenterLngLat, haversineKm } from "@/lib/routing/demoGeometry";

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
  /** Pin-Zentrum [lng, lat] */
  center?: [number, number];
  /** Luftlinie vom Discover-Standort (km), wenn near gesetzt */
  distanceFromOriginKm?: number;
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
    id: "idea-kaltenbronn",
    name: "Kaltenbronn Runden-Idee",
    categories: ["mtb_enduro", "mtb_am", "mtb_trail", "emtb", "gravel"],
    distanceKm: 34,
    elevationM: 980,
    durationMin: 160,
    mtbScale: "S1–S2",
    surface: "trail/root",
    loop: true,
    uncertainKmPct: 15,
    technical: false,
    steep: false,
    flowy: true,
    ebikeFriendly: true,
  },
  {
    id: "idea-schauinsland",
    name: "Schauinsland Trail-Idee",
    categories: ["mtb_enduro", "mtb_am", "mtb_trail", "emtb"],
    distanceKm: 22,
    elevationM: 980,
    durationMin: 130,
    mtbScale: "S1–S2",
    surface: "trail/forest",
    loop: true,
    uncertainKmPct: 18,
    technical: true,
    steep: true,
    flowy: false,
    ebikeFriendly: true,
  },
  {
    id: "idea-dreisam-city",
    name: "Dreisam City-Schleife",
    categories: ["urban", "etrekking", "road"],
    distanceKm: 12,
    elevationM: 80,
    durationMin: 45,
    mtbScale: "—",
    surface: "asphalt/path",
    loop: true,
    uncertainKmPct: 8,
    technical: false,
    steep: false,
    flowy: true,
    ebikeFriendly: true,
  },
  {
    id: "idea-kaiserstuhl-road",
    name: "Kaiserstuhl Rennrad-Idee",
    categories: ["road", "gravel", "etrekking"],
    distanceKm: 48,
    elevationM: 620,
    durationMin: 140,
    mtbScale: "—",
    surface: "asphalt",
    loop: true,
    uncertainKmPct: 10,
    technical: false,
    steep: false,
    flowy: true,
    ebikeFriendly: true,
  },
  {
    id: "r-kitz-gravel",
    name: "Gravel Loop Kitzbühel (Idee)",
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
    name: "E-MTB Hochkönig (Idee)",
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
  {
    id: "r-freiburg-city",
    name: "Freiburg City Loop",
    categories: ["urban", "etrekking", "road"],
    distanceKm: 18.5,
    elevationM: 210,
    durationMin: 55,
    mtbScale: "—",
    surface: "asphalt/bike-lane",
    loop: true,
    uncertainKmPct: 3,
    technical: false,
    steep: false,
    flowy: true,
    ebikeFriendly: true,
  },
  {
    id: "r-schwarzwald-gravel",
    name: "Schwarzwald Gravel West",
    categories: ["gravel", "etrekking"],
    distanceKm: 58,
    elevationM: 1120,
    durationMin: 210,
    mtbScale: "—",
    surface: "gravel/forest",
    loop: true,
    uncertainKmPct: 8,
    technical: false,
    steep: true,
    flowy: true,
    ebikeFriendly: true,
  },
  {
    id: "r-bodensee-road",
    name: "Bodensee Südufer",
    categories: ["road", "etrekking", "urban"],
    distanceKm: 72,
    elevationM: 280,
    durationMin: 200,
    mtbScale: "—",
    surface: "asphalt",
    loop: false,
    uncertainKmPct: 2,
    technical: false,
    steep: false,
    flowy: true,
    ebikeFriendly: true,
  },
  {
    id: "r-stuttgart-urban",
    name: "Stuttgart Höhenpark-Runde",
    categories: ["urban", "etrekking"],
    distanceKm: 22,
    elevationM: 340,
    durationMin: 70,
    mtbScale: "—",
    surface: "asphalt/path",
    loop: true,
    uncertainKmPct: 4,
    technical: false,
    steep: true,
    flowy: false,
    ebikeFriendly: true,
  },
  {
    id: "r-tegernsee-gravel",
    name: "Tegernsee Gravel Mix",
    categories: ["gravel", "road", "emtb"],
    distanceKm: 45,
    elevationM: 780,
    durationMin: 150,
    mtbScale: "—",
    surface: "gravel/asphalt",
    loop: true,
    uncertainKmPct: 6,
    technical: false,
    steep: false,
    flowy: true,
    ebikeFriendly: true,
  },
  {
    id: "r-vosges-gravel",
    name: "Vosges Ballon d'Alsace",
    categories: ["gravel", "mtb_am", "emtb", "etrekking"],
    distanceKm: 42,
    elevationM: 1100,
    durationMin: 180,
    mtbScale: "S1",
    surface: "gravel/forest",
    loop: true,
    uncertainKmPct: 8,
    technical: false,
    steep: true,
    flowy: true,
    ebikeFriendly: true,
  },
  {
    id: "r-alsace-road",
    name: "Route des Vins d'Alsace",
    categories: ["road", "etrekking", "gravel"],
    distanceKm: 55,
    elevationM: 480,
    durationMin: 160,
    mtbScale: "—",
    surface: "asphalt",
    loop: false,
    uncertainKmPct: 3,
    technical: false,
    steep: false,
    flowy: true,
    ebikeFriendly: true,
  },
  {
    id: "r-annecy-road",
    name: "Lac d'Annecy Rundfahrt",
    categories: ["road", "urban", "etrekking"],
    distanceKm: 40,
    elevationM: 220,
    durationMin: 120,
    mtbScale: "—",
    surface: "asphalt/bike-lane",
    loop: true,
    uncertainKmPct: 2,
    technical: false,
    steep: false,
    flowy: true,
    ebikeFriendly: true,
  },
  {
    id: "r-morzine-emtb",
    name: "Morzine Portes du Soleil",
    categories: ["emtb", "mtb_enduro", "mtb_am"],
    distanceKm: 28,
    elevationM: 1200,
    durationMin: 150,
    mtbScale: "S2–S3",
    surface: "trail/alpine",
    loop: false,
    uncertainKmPct: 15,
    technical: true,
    steep: true,
    flowy: false,
    ebikeFriendly: true,
  },
  {
    id: "r-provence-gravel",
    name: "Luberon Gravel Mix",
    categories: ["gravel", "road", "etrekking"],
    distanceKm: 48,
    elevationM: 650,
    durationMin: 170,
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
    id: "r-bretagne-coast",
    name: "Côte de Granit Rose",
    categories: ["road", "urban", "etrekking"],
    distanceKm: 38,
    elevationM: 180,
    durationMin: 110,
    mtbScale: "—",
    surface: "asphalt/path",
    loop: false,
    uncertainKmPct: 3,
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

type SuggestInput = {
  bike?: Bike | null;
  categoryHint?: BikeCategory;
  profile: RiderProfile;
  availableMinutes?: number;
  rangeKmHigh?: number;
  /** Discover-Standort [lng, lat] — sortiert Touren nach Nähe */
  near?: [number, number];
};

function scoreSeed(
  s: RouteSeed,
  input: SuggestInput,
  category: BikeCategory
): RouteSuggestion {
  const minutes = input.availableMinutes ?? 150;
  const bikeName = input.bike?.name ?? "dein Profil";
  const travel = input.bike?.travelFrontMm;
  const isEbike = input.bike?.isEbike ?? false;
  const reasons: string[] = [];
  let score = 50;

  if (s.categories.includes(category)) {
    score += 15;
    reasons.push(
      input.bike
        ? `Passt zu ${bikeName}${travel ? ` (${travel} mm Federweg)` : ""}`
        : `Passt zu ${category.replace(/_/g, " ")}`
    );
  } else {
    reasons.push(
      `Andere Region/Kategorie (${s.categories[0]?.replace(/_/g, " ") ?? "Tour"})`
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
  } else if (reasons.length < 2) {
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
    score -= 4;
    reasons.push(`Andere Dauer (${s.durationMin} vs ${minutes} min)`);
  }

  let rangeOk: boolean | undefined;
  let rangeNote: string | undefined;
  if (isEbike && input.rangeKmHigh !== undefined) {
    rangeOk = s.distanceKm <= input.rangeKmHigh * 0.85;
    if (rangeOk) {
      score += 8;
      if (reasons.length < 3)
        reasons.push(`Distanz ${s.distanceKm} km innerhalb Reichweitenband`);
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
    category: s.categories.includes(category) ? category : s.categories[0],
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
    center: demoCenterLngLat(s.id),
  };
}

/** Vollständiger Discover-Katalog — nach Standort-Nähe, dann Match. */
export function listAllRouteSuggestions(
  input: SuggestInput
): RouteSuggestion[] {
  const category =
    input.bike?.category ?? input.categoryHint ?? "mtb_am";
  const near = input.near;
  const scored = SEEDS.map((s) => {
    const r = scoreSeed(s, input, category);
    if (!near || !r.center) return r;
    const dKm = haversineKm(near, r.center);
    // Nähe boostet Match leicht (innerhalb ~80 km stark)
    let match = r.matchScore;
    if (dKm <= 25) match += 18;
    else if (dKm <= 80) match += 10;
    else if (dKm <= 200) match += 3;
    else match -= 6;
    return {
      ...r,
      distanceFromOriginKm: Math.round(dKm),
      matchScore: Math.max(0, Math.min(99, match)),
    };
  });
  if (near) {
    return scored.sort((a, b) => {
      const da = a.distanceFromOriginKm ?? 1e9;
      const db = b.distanceFromOriginKm ?? 1e9;
      if (da !== db) return da - db;
      return b.matchScore - a.matchScore;
    });
  }
  return scored.sort((a, b) => b.matchScore - a.matchScore);
}

/** Top-Vorschläge für Home/Chat (max. 5, Kategorie-fokussiert). */
export function suggestRoutes(input: SuggestInput): RouteSuggestion[] {
  const category =
    input.bike?.category ?? input.categoryHint ?? "mtb_am";
  const all = listAllRouteSuggestions(input);
  const matched = all.filter((r) => {
    const seed = SEEDS.find((s) => s.id === r.id);
    return seed?.categories.includes(category);
  });
  const scored = (matched.length ? matched : all).slice(0, 5);
  return scored;
}

/** Einzelnen Seed als Vorschlag auflösen (Deep-Link / Detail). */
export function getSuggestionById(
  id: string,
  input: SuggestInput
): RouteSuggestion | null {
  const fromList = listAllRouteSuggestions({
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
