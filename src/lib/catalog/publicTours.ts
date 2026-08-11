/**
 * Öffentlicher Tour-Katalog für SEO-Seiten (/tours/[id], /regions/*).
 * Redaktionelle Tour-Ideen — immer verfügbar (kein Demo-Fail-Closed).
 * Geometrie wird beim Planen live geroutet; hier nur Metadaten + Pin.
 */

import type { BikeCategory } from "@/types";
import { demoCenterLngLat } from "@/lib/routing/demoGeometry";
import { bikeCategoryLabel } from "@/lib/catalog/slots";
import { getRegion, type RegionDef } from "@/lib/catalog/regions";

export type PublicTour = {
  id: string;
  name: string;
  /** 1–2 Sätze für Cards & Meta */
  summary: string;
  /** Längerer SEO-Text */
  description: string;
  primaryCategory: BikeCategory;
  categories: BikeCategory[];
  distanceKm: number;
  elevationM: number;
  durationMin: number;
  difficulty: string;
  surface: string;
  loop: boolean;
  regionSlug: string;
  /** [lng, lat] */
  center: [number, number];
  tags: string[];
};

type TourInput = Omit<PublicTour, "center" | "summary" | "description"> & {
  summary?: string;
  description?: string;
};

const RAW: TourInput[] = [
  {
    id: "idea-koenigstuhl",
    name: "Königstuhl Trail-Idee",
    primaryCategory: "mtb_am",
    categories: ["mtb_enduro", "mtb_am", "mtb_trail", "emtb"],
    distanceKm: 18,
    elevationM: 620,
    durationMin: 110,
    difficulty: "S1–S2",
    surface: "trail/forest",
    loop: true,
    regionSlug: "rhein-neckar",
    tags: ["trail", "heidelberg", "mtb"],
  },
  {
    id: "idea-odenwald-trail",
    name: "Odenwald Süd Trail-Idee",
    primaryCategory: "mtb_trail",
    categories: ["mtb_trail", "mtb_am", "gravel", "emtb"],
    distanceKm: 28,
    elevationM: 740,
    durationMin: 140,
    difficulty: "S1–S2",
    surface: "trail/root",
    loop: true,
    regionSlug: "rhein-neckar",
    tags: ["odenwald", "trail", "gravel-mix"],
  },
  {
    id: "idea-neckartal-gravel",
    name: "Neckartal Gravel-Idee",
    primaryCategory: "gravel",
    categories: ["gravel", "etrekking", "road", "emtb"],
    distanceKm: 42,
    elevationM: 280,
    durationMin: 150,
    difficulty: "—",
    surface: "gravel/asphalt",
    loop: false,
    regionSlug: "rhein-neckar",
    tags: ["gravel", "neckar", "touring"],
  },
  {
    id: "r-heidelberg-city",
    name: "Heidelberg City Loop",
    primaryCategory: "urban",
    categories: ["urban", "etrekking", "road"],
    distanceKm: 14,
    elevationM: 160,
    durationMin: 50,
    difficulty: "—",
    surface: "asphalt/bike-lane",
    loop: true,
    regionSlug: "rhein-neckar",
    tags: ["city", "alltag", "radweg"],
  },
  {
    id: "idea-kaltenbronn",
    name: "Kaltenbronn Runden-Idee",
    primaryCategory: "mtb_am",
    categories: ["mtb_enduro", "mtb_am", "mtb_trail", "emtb", "gravel"],
    distanceKm: 34,
    elevationM: 980,
    durationMin: 160,
    difficulty: "S1–S2",
    surface: "trail/root",
    loop: true,
    regionSlug: "schwarzwald",
    tags: ["schwarzwald", "mtb", "flow"],
  },
  {
    id: "idea-schauinsland",
    name: "Schauinsland Trail-Idee",
    primaryCategory: "mtb_enduro",
    categories: ["mtb_enduro", "mtb_am", "mtb_trail", "emtb"],
    distanceKm: 22,
    elevationM: 980,
    durationMin: 130,
    difficulty: "S1–S2",
    surface: "trail/forest",
    loop: true,
    regionSlug: "schwarzwald",
    tags: ["freiburg", "trail", "hm"],
  },
  {
    id: "idea-dreisam-city",
    name: "Dreisam City-Schleife",
    primaryCategory: "urban",
    categories: ["urban", "etrekking", "road"],
    distanceKm: 12,
    elevationM: 80,
    durationMin: 45,
    difficulty: "—",
    surface: "asphalt/path",
    loop: true,
    regionSlug: "baden-wuerttemberg",
    tags: ["freiburg", "city"],
  },
  {
    id: "idea-kaiserstuhl-road",
    name: "Kaiserstuhl Rennrad-Idee",
    primaryCategory: "road",
    categories: ["road", "gravel", "etrekking"],
    distanceKm: 48,
    elevationM: 620,
    durationMin: 140,
    difficulty: "—",
    surface: "asphalt",
    loop: true,
    regionSlug: "baden-wuerttemberg",
    tags: ["rennrad", "kaiserstuhl", "weinberge"],
  },
  {
    id: "r-kitz-gravel",
    name: "Gravel Loop Kitzbühel (Idee)",
    primaryCategory: "gravel",
    categories: ["gravel", "etrekking", "road"],
    distanceKm: 62.1,
    elevationM: 890,
    durationMin: 180,
    difficulty: "—",
    surface: "gravel/asphalt",
    loop: true,
    regionSlug: "bayern",
    tags: ["gravel", "alpen", "urlaub"],
  },
  {
    id: "r-hochkoenig-emtb",
    name: "E-MTB Hochkönig (Idee)",
    primaryCategory: "emtb",
    categories: ["emtb", "mtb_enduro"],
    distanceKm: 41.2,
    elevationM: 1580,
    durationMin: 165,
    difficulty: "S2–S3",
    surface: "trail/alpine",
    loop: false,
    regionSlug: "bayern",
    tags: ["emtb", "alpin", "reichweite"],
  },
  {
    id: "r-wilder-kaiser-hike",
    name: "Wilder Kaiser Höhenweg",
    primaryCategory: "hiking",
    categories: ["hiking"],
    distanceKm: 14.2,
    elevationM: 980,
    durationMin: 300,
    difficulty: "T2",
    surface: "path",
    loop: false,
    regionSlug: "bayern",
    tags: ["wandern", "alpen"],
  },
  {
    id: "r-inn-flat",
    name: "Inn-Radweg Entspannt",
    primaryCategory: "road",
    categories: ["road", "gravel", "etrekking", "urban"],
    distanceKm: 34,
    elevationM: 120,
    durationMin: 90,
    difficulty: "—",
    surface: "asphalt",
    loop: false,
    regionSlug: "bayern",
    tags: ["touring", "flach", "familie"],
  },
  {
    id: "r-freiburg-city",
    name: "Freiburg City Loop",
    primaryCategory: "urban",
    categories: ["urban", "etrekking", "road"],
    distanceKm: 18.5,
    elevationM: 210,
    durationMin: 55,
    difficulty: "—",
    surface: "asphalt/bike-lane",
    loop: true,
    regionSlug: "baden-wuerttemberg",
    tags: ["city", "freiburg"],
  },
  {
    id: "r-schwarzwald-gravel",
    name: "Schwarzwald Gravel West",
    primaryCategory: "gravel",
    categories: ["gravel", "etrekking"],
    distanceKm: 58,
    elevationM: 1120,
    durationMin: 210,
    difficulty: "—",
    surface: "gravel/forest",
    loop: true,
    regionSlug: "schwarzwald",
    tags: ["gravel", "hm", "forst"],
  },
  {
    id: "r-bodensee-road",
    name: "Bodensee Südufer",
    primaryCategory: "road",
    categories: ["road", "etrekking", "urban"],
    distanceKm: 72,
    elevationM: 280,
    durationMin: 200,
    difficulty: "—",
    surface: "asphalt",
    loop: false,
    regionSlug: "bodensee",
    tags: ["rennrad", "see", "touring"],
  },
  {
    id: "r-stuttgart-urban",
    name: "Stuttgart Höhenpark-Runde",
    primaryCategory: "urban",
    categories: ["urban", "etrekking"],
    distanceKm: 22,
    elevationM: 340,
    durationMin: 70,
    difficulty: "—",
    surface: "asphalt/path",
    loop: true,
    regionSlug: "baden-wuerttemberg",
    tags: ["city", "stuttgart"],
  },
  {
    id: "r-tegernsee-gravel",
    name: "Tegernsee Gravel Mix",
    primaryCategory: "gravel",
    categories: ["gravel", "road", "emtb"],
    distanceKm: 45,
    elevationM: 780,
    durationMin: 150,
    difficulty: "—",
    surface: "gravel/asphalt",
    loop: true,
    regionSlug: "bayern",
    tags: ["gravel", "see"],
  },
  {
    id: "r-vosges-gravel",
    name: "Vosges Ballon d'Alsace",
    primaryCategory: "gravel",
    categories: ["gravel", "mtb_am", "emtb", "etrekking"],
    distanceKm: 42,
    elevationM: 1100,
    durationMin: 180,
    difficulty: "S1",
    surface: "gravel/forest",
    loop: true,
    regionSlug: "elsass-vogesen",
    tags: ["vogesen", "gravel", "hm"],
  },
  {
    id: "r-alsace-road",
    name: "Route des Vins d'Alsace",
    primaryCategory: "road",
    categories: ["road", "etrekking", "gravel"],
    distanceKm: 55,
    elevationM: 480,
    durationMin: 160,
    difficulty: "—",
    surface: "asphalt",
    loop: false,
    regionSlug: "elsass-vogesen",
    tags: ["rennrad", "weinstraße"],
  },
  {
    id: "r-annecy-road",
    name: "Lac d'Annecy Rundfahrt",
    primaryCategory: "road",
    categories: ["road", "urban", "etrekking"],
    distanceKm: 40,
    elevationM: 220,
    durationMin: 120,
    difficulty: "—",
    surface: "asphalt/bike-lane",
    loop: true,
    regionSlug: "alpen-west",
    tags: ["rennrad", "see", "urlaub"],
  },
  {
    id: "r-morzine-emtb",
    name: "Morzine Portes du Soleil",
    primaryCategory: "emtb",
    categories: ["emtb", "mtb_enduro", "mtb_am"],
    distanceKm: 28,
    elevationM: 1200,
    durationMin: 150,
    difficulty: "S2–S3",
    surface: "trail/alpine",
    loop: false,
    regionSlug: "alpen-west",
    tags: ["emtb", "alpen"],
  },
  {
    id: "r-provence-gravel",
    name: "Luberon Gravel Mix",
    primaryCategory: "gravel",
    categories: ["gravel", "road", "etrekking"],
    distanceKm: 48,
    elevationM: 650,
    durationMin: 170,
    difficulty: "—",
    surface: "gravel/asphalt",
    loop: true,
    regionSlug: "alpen-west",
    tags: ["gravel", "südfrankreich"],
  },
  {
    id: "r-bretagne-coast",
    name: "Côte de Granit Rose",
    primaryCategory: "road",
    categories: ["road", "urban", "etrekking"],
    distanceKm: 38,
    elevationM: 180,
    durationMin: 110,
    difficulty: "—",
    surface: "asphalt/path",
    loop: false,
    regionSlug: "alpen-west",
    tags: ["küste", "rennrad"],
  },
  {
    id: "r-rhein-radweg",
    name: "Rheinradweg Mannheim–Speyer",
    primaryCategory: "road",
    categories: ["road", "etrekking", "urban"],
    distanceKm: 46,
    elevationM: 90,
    durationMin: 130,
    difficulty: "—",
    surface: "asphalt/bike-lane",
    loop: false,
    regionSlug: "rhein-neckar",
    tags: ["touring", "rhein", "flach"],
  },
  {
    id: "r-neckar-touring",
    name: "Neckartal-Radweg Etappe",
    primaryCategory: "etrekking",
    categories: ["etrekking", "road", "gravel"],
    distanceKm: 52,
    elevationM: 210,
    durationMin: 170,
    difficulty: "—",
    surface: "asphalt/path",
    loop: false,
    regionSlug: "rhein-neckar",
    tags: ["touring", "e-bike", "neckar"],
  },
  {
    id: "r-pfalz-gravel",
    name: "Pfälzerwald Gravel Süd",
    primaryCategory: "gravel",
    categories: ["gravel", "etrekking"],
    distanceKm: 54,
    elevationM: 720,
    durationMin: 190,
    difficulty: "—",
    surface: "gravel/forest",
    loop: true,
    regionSlug: "baden-wuerttemberg",
    tags: ["gravel", "pfalz"],
  },
  {
    id: "r-karlsruhe-urban",
    name: "Karlsruhe Fächer-Runde",
    primaryCategory: "urban",
    categories: ["urban", "road", "etrekking"],
    distanceKm: 16,
    elevationM: 60,
    durationMin: 50,
    difficulty: "—",
    surface: "asphalt/bike-lane",
    loop: true,
    regionSlug: "rhein-neckar",
    tags: ["city", "alltag"],
  },
  {
    id: "r-donau-touring",
    name: "Donauradweg Ulm–Donauwörth",
    primaryCategory: "etrekking",
    categories: ["etrekking", "road"],
    distanceKm: 68,
    elevationM: 140,
    durationMin: 220,
    difficulty: "—",
    surface: "asphalt",
    loop: false,
    regionSlug: "bayern",
    tags: ["touring", "donau", "fernradweg"],
  },
  {
    id: "r-muenchen-road",
    name: "München Isar–Starnberg",
    primaryCategory: "road",
    categories: ["road", "urban", "etrekking"],
    distanceKm: 58,
    elevationM: 320,
    durationMin: 160,
    difficulty: "—",
    surface: "asphalt/bike-lane",
    loop: false,
    regionSlug: "bayern",
    tags: ["rennrad", "münchen", "see"],
  },
  {
    id: "r-elbe-touring",
    name: "Elberadweg Dresden–Meißen",
    primaryCategory: "etrekking",
    categories: ["etrekking", "road", "urban"],
    distanceKm: 32,
    elevationM: 80,
    durationMin: 100,
    difficulty: "—",
    surface: "asphalt/path",
    loop: false,
    regionSlug: "sachsen",
    tags: ["touring", "elbe", "flach"],
  },
  {
    id: "r-eifel-gravel",
    name: "Eifel Gravel Vulkane",
    primaryCategory: "gravel",
    categories: ["gravel", "road", "emtb"],
    distanceKm: 61,
    elevationM: 890,
    durationMin: 200,
    difficulty: "—",
    surface: "gravel/asphalt",
    loop: true,
    regionSlug: "eifel",
    tags: ["gravel", "eifel", "hm"],
  },
  // --- Content-Sprint multi-sport (Region A + Ergänzungen) ---
  {
    id: "r-heidelberg-road",
    name: "Heidelberg Philosophenweg–Neckar",
    primaryCategory: "road",
    categories: ["road", "urban", "etrekking"],
    distanceKm: 28,
    elevationM: 240,
    durationMin: 85,
    difficulty: "—",
    surface: "asphalt",
    loop: true,
    regionSlug: "rhein-neckar",
    tags: ["rennrad", "heidelberg", "neckar"],
  },
  {
    id: "r-mannheim-urban",
    name: "Mannheim Quadrate–Rhein",
    primaryCategory: "urban",
    categories: ["urban", "road", "etrekking"],
    distanceKm: 14,
    elevationM: 40,
    durationMin: 45,
    difficulty: "—",
    surface: "asphalt/bike-lane",
    loop: true,
    regionSlug: "rhein-neckar",
    tags: ["city", "mannheim", "alltag"],
  },
  {
    id: "r-odenwald-gravel",
    name: "Odenwald Gravel Bergstraße",
    primaryCategory: "gravel",
    categories: ["gravel", "road", "emtb"],
    distanceKm: 48,
    elevationM: 680,
    durationMin: 165,
    difficulty: "—",
    surface: "gravel/asphalt",
    loop: true,
    regionSlug: "rhein-neckar",
    tags: ["gravel", "odenwald", "bergstraße"],
  },
  {
    id: "r-kaiserstuhl-gravel",
    name: "Kaiserstuhl Weinberge Gravel",
    primaryCategory: "gravel",
    categories: ["gravel", "road", "etrekking"],
    distanceKm: 36,
    elevationM: 420,
    durationMin: 120,
    difficulty: "—",
    surface: "gravel/asphalt",
    loop: true,
    regionSlug: "baden-wuerttemberg",
    tags: ["gravel", "wein", "kaiserstuhl"],
  },
  {
    id: "r-freiburg-road",
    name: "Freiburg–Tuniberg Rennrad",
    primaryCategory: "road",
    categories: ["road", "etrekking"],
    distanceKm: 52,
    elevationM: 380,
    durationMin: 145,
    difficulty: "—",
    surface: "asphalt",
    loop: true,
    regionSlug: "baden-wuerttemberg",
    tags: ["rennrad", "freiburg"],
  },
  {
    id: "r-schauinsland-emtb",
    name: "Schauinsland E-MTB Höhenrunde",
    primaryCategory: "emtb",
    categories: ["emtb", "mtb_am", "etrekking"],
    distanceKm: 34,
    elevationM: 980,
    durationMin: 140,
    difficulty: "S1–S2",
    surface: "trail/forest",
    loop: true,
    regionSlug: "schwarzwald",
    tags: ["e-mtb", "schauinsland", "hm"],
  },
  {
    id: "r-titisee-road",
    name: "Titisee–Feldberg Road Climb",
    primaryCategory: "road",
    categories: ["road", "emtb"],
    distanceKm: 44,
    elevationM: 920,
    durationMin: 160,
    difficulty: "—",
    surface: "asphalt",
    loop: false,
    regionSlug: "schwarzwald",
    tags: ["rennrad", "berg", "titisee"],
  },
  {
    id: "r-stuttgart-road",
    name: "Stuttgart Kessel–Solitude",
    primaryCategory: "road",
    categories: ["road", "urban"],
    distanceKm: 41,
    elevationM: 520,
    durationMin: 130,
    difficulty: "—",
    surface: "asphalt",
    loop: true,
    regionSlug: "baden-wuerttemberg",
    tags: ["rennrad", "stuttgart"],
  },
  {
    id: "r-muenchen-urban",
    name: "München Englischer Garten Loop",
    primaryCategory: "urban",
    categories: ["urban", "road", "etrekking"],
    distanceKm: 19,
    elevationM: 90,
    durationMin: 55,
    difficulty: "—",
    surface: "asphalt/path",
    loop: true,
    regionSlug: "bayern",
    tags: ["city", "münchen", "alltag"],
  },
  {
    id: "r-chiemsee-road",
    name: "Chiemsee Rundfahrt Road",
    primaryCategory: "road",
    categories: ["road", "etrekking", "urban"],
    distanceKm: 64,
    elevationM: 260,
    durationMin: 180,
    difficulty: "—",
    surface: "asphalt",
    loop: true,
    regionSlug: "bayern",
    tags: ["rennrad", "see", "chiemsee"],
  },
  {
    id: "r-nuernberg-urban",
    name: "Nürnberg Pegnitz–Altstadt",
    primaryCategory: "urban",
    categories: ["urban", "road", "etrekking"],
    distanceKm: 21,
    elevationM: 120,
    durationMin: 60,
    difficulty: "—",
    surface: "asphalt/bike-lane",
    loop: true,
    regionSlug: "bayern",
    tags: ["city", "nürnberg"],
  },
  {
    id: "r-koeln-urban",
    name: "Köln Rheinauen Pendelrunde",
    primaryCategory: "urban",
    categories: ["urban", "road", "etrekking"],
    distanceKm: 24,
    elevationM: 80,
    durationMin: 70,
    difficulty: "—",
    surface: "asphalt/bike-lane",
    loop: true,
    regionSlug: "eifel",
    tags: ["city", "köln", "rhein"],
  },
  {
    id: "r-mainz-road",
    name: "Mainz–Rheingau Road",
    primaryCategory: "road",
    categories: ["road", "etrekking"],
    distanceKm: 56,
    elevationM: 310,
    durationMin: 155,
    difficulty: "—",
    surface: "asphalt",
    loop: false,
    regionSlug: "rhein-neckar",
    tags: ["rennrad", "rheingau"],
  },
  {
    id: "r-konstanz-urban",
    name: "Konstanz Seeufer City",
    primaryCategory: "urban",
    categories: ["urban", "road", "etrekking"],
    distanceKm: 17,
    elevationM: 70,
    durationMin: 50,
    difficulty: "—",
    surface: "asphalt/path",
    loop: true,
    regionSlug: "bodensee",
    tags: ["city", "bodensee", "konstanz"],
  },
  {
    id: "r-ulm-urban",
    name: "Ulm Donau–Münster",
    primaryCategory: "urban",
    categories: ["urban", "road", "etrekking"],
    distanceKm: 15,
    elevationM: 55,
    durationMin: 45,
    difficulty: "—",
    surface: "asphalt/bike-lane",
    loop: true,
    regionSlug: "baden-wuerttemberg",
    tags: ["city", "ulm", "donau"],
  },
];

function autoSummary(t: TourInput): string {
  const cat = bikeCategoryLabel(t.primaryCategory);
  const shape = t.loop ? "Rundkurs" : "Etappe A→B";
  return `${cat}-Tour-Idee: ${t.distanceKm} km, ${t.elevationM} hm · ${shape} · Belag ${t.surface}.`;
}

function autoDescription(t: TourInput, region: RegionDef | null): string {
  const reg = region?.name ?? "der Region";
  const diff =
    t.difficulty && t.difficulty !== "—"
      ? ` Schwierigkeit ${t.difficulty}.`
      : "";
  return (
    `${t.name} ist eine redaktionelle Tour-Idee für ${bikeCategoryLabel(t.primaryCategory)} in ${reg}. ` +
    `Ca. ${t.distanceKm} km und ${t.elevationM} Höhenmeter in rund ${t.durationMin} Minuten. ` +
    `Oberfläche: ${t.surface}.${diff} ` +
    `Plane die Route unter Planen oder öffne sie unter Touren — Navigation läuft in der nativen App. ` +
    `Keine garantierte GPS-Spur: Geometrie wird beim Planen mit dem Routing-Profil berechnet.`
  );
}

function hydrate(t: TourInput): PublicTour {
  const region = getRegion(t.regionSlug);
  return {
    ...t,
    center: demoCenterLngLat(t.id),
    summary: t.summary ?? autoSummary(t),
    description: t.description ?? autoDescription(t, region),
  };
}

const TOURS: PublicTour[] = RAW.map(hydrate);

export function listPublicTours(): PublicTour[] {
  return TOURS;
}

export function getPublicTour(id: string): PublicTour | null {
  return TOURS.find((t) => t.id === id) ?? null;
}

export function listPublicTourIds(): string[] {
  return TOURS.map((t) => t.id);
}

export function listToursByRegion(regionSlug: string): PublicTour[] {
  return TOURS.filter((t) => t.regionSlug === regionSlug);
}

export function listToursBySport(sport: string): PublicTour[] {
  const s = sport.toLowerCase();
  return TOURS.filter((t) => {
    if (s === "mtb")
      return t.categories.some((c) =>
        ["mtb_trail", "mtb_am", "mtb_enduro", "dh", "emtb"].includes(c)
      );
    if (s === "road") return t.categories.includes("road");
    if (s === "gravel") return t.categories.includes("gravel");
    if (s === "urban") return t.categories.includes("urban");
    if (s === "ebike")
      return t.categories.some((c) => c === "emtb" || c === "etrekking");
    if (s === "touring")
      return t.categories.some(
        (c) => c === "etrekking" || c === "road" || c === "gravel"
      );
    if (s === "hiking") return t.categories.includes("hiking");
    return true;
  });
}

export function relatedTours(tour: PublicTour, limit = 4): PublicTour[] {
  return TOURS.filter(
    (t) =>
      t.id !== tour.id &&
      (t.regionSlug === tour.regionSlug ||
        t.primaryCategory === tour.primaryCategory)
  ).slice(0, limit);
}

/** JSON-LD SportsActivityLocation / Tour */
export function tourJsonLd(tour: PublicTour, baseUrl: string) {
  const region = getRegion(tour.regionSlug);
  return {
    "@context": "https://schema.org",
    "@type": "SportsActivityLocation",
    name: tour.name,
    description: tour.summary,
    url: `${baseUrl}/tours/${tour.id}`,
    geo: {
      "@type": "GeoCoordinates",
      latitude: tour.center[1],
      longitude: tour.center[0],
    },
    address: region
      ? {
          "@type": "PostalAddress",
          addressRegion: region.name,
          addressCountry: region.country,
        }
      : undefined,
  };
}
