/**
 * Redaktionell freigegebene Community-Inhalte (Moderation = approved).
 * Keine Fake-User-Masse — klar als Community/Editorial erkennbar.
 */

import type {
  CommunityClub,
  CommunityEvent,
  TourReview,
} from "@/lib/community/types";

/** Freigegebene Beispiel-Reviews für Tour-Seiten */
export const EDITORIAL_REVIEWS: TourReview[] = [
  {
    id: "er-bodensee-1",
    tourId: "r-bodensee-road",
    authorLabel: "Mara",
    authorHandle: "mara_road",
    rating: 5,
    body: "Flach, schön, am Wochenende etwas Verkehr am Südufer — früh starten lohnt sich.",
    createdAt: "2026-06-12T10:00:00.000Z",
    status: "approved",
    editorial: true,
    sportHint: "road",
  },
  {
    id: "er-kaiserstuhl-1",
    tourId: "idea-kaiserstuhl-road",
    authorLabel: "Jonas",
    authorHandle: "jonas_r",
    rating: 4,
    body: "Gute hm-Dichte, Asphalt top. Im Sommer heiß in den Weinbergen — Wasser mitnehmen.",
    createdAt: "2026-05-20T14:00:00.000Z",
    status: "approved",
    editorial: true,
    sportHint: "road",
  },
  {
    id: "er-schwarz-gravel-1",
    tourId: "r-schwarzwald-gravel",
    authorLabel: "Lea",
    authorHandle: "lea_gravel",
    rating: 5,
    body: "Forstwege wie beschrieben. Nach Regen rutschig — Profil „Gravel“ im Planner war passend.",
    createdAt: "2026-07-02T09:30:00.000Z",
    status: "approved",
    editorial: true,
    sportHint: "gravel",
  },
  {
    id: "er-heidelberg-1",
    tourId: "r-heidelberg-city",
    authorLabel: "Sam",
    rating: 4,
    body: "Kurze Feierabend-Runde, Radwege ok. Königstuhl extra ist steiler als die City-Loop.",
    createdAt: "2026-04-18T18:00:00.000Z",
    status: "approved",
    editorial: true,
    sportHint: "urban",
  },
  {
    id: "er-neckar-1",
    tourId: "r-neckar-touring",
    authorLabel: "Eva",
    authorHandle: "eva_tour",
    rating: 5,
    body: "E-Trekking-tauglich, flach, schöne Pausenorte. Etappe lässt sich gut teilen.",
    createdAt: "2026-08-01T11:00:00.000Z",
    status: "approved",
    editorial: true,
    sportHint: "touring",
  },
  {
    id: "er-koenigstuhl-1",
    tourId: "idea-koenigstuhl",
    authorLabel: "Tobi",
    authorHandle: "tobi_trails",
    rating: 4,
    body: "S1–S2 realistisch. Nach Regen Wurzeln — nicht unterschätzen. App-Nav war stimmig.",
    createdAt: "2026-03-22T16:00:00.000Z",
    status: "approved",
    editorial: true,
    sportHint: "mtb",
  },
];

export const COMMUNITY_EVENTS: CommunityEvent[] = [
  {
    id: "ev-gravel-bw",
    title: "Gravel-Treff Schwarzwald West",
    regionSlug: "schwarzwald",
    dateLabel: "Sa, 12. Sep 2026 · 09:00",
    sport: "gravel",
    blurb: "Lockere Gruppenfahrt, ca. 50 km. Keine Zeitnahme — nur Community.",
    href: "/regions/schwarzwald",
  },
  {
    id: "ev-city-hd",
    title: "Heidelberg Critical Mass light",
    regionSlug: "rhein-neckar",
    dateLabel: "Fr, 25. Sep 2026 · 18:30",
    sport: "urban",
    blurb: "Langsame Stadt-Runde für alle Räder. Treffpunkt am Neckar.",
    href: "/regions/rhein-neckar",
  },
  {
    id: "ev-road-bodensee",
    title: "Bodensee Südufer Genussfahrt",
    regionSlug: "bodensee",
    dateLabel: "So, 4. Okt 2026 · 08:30",
    sport: "road",
    blurb: "Flach, fotogen, Kaffee-Stops. Rennrad & E-Trekking willkommen.",
    href: "/regions/bodensee",
  },
  {
    id: "ev-alster-hh",
    title: "Hamburg Alster Feierabend",
    regionSlug: "norddeutschland",
    dateLabel: "Mi, 16. Sep 2026 · 18:00",
    sport: "urban",
    blurb: "Flache Runde um die Alster. City, nicht Alpen — Tempo nach Gefühl.",
    href: "/regions/norddeutschland",
  },
];

export const COMMUNITY_CLUBS: CommunityClub[] = [
  {
    id: "cl-rn-allround",
    name: "Rhein-Neckar Allround",
    regionSlug: "rhein-neckar",
    sports: ["road", "gravel", "urban"],
    blurb: "Wöchentliche Gruppen — Disziplin rotiert. Anfänger willkommen.",
    href: "/regions/rhein-neckar",
  },
  {
    id: "cl-sw-trails",
    name: "Schwarzwald Trail & Tour",
    regionSlug: "schwarzwald",
    sports: ["mtb", "gravel", "ebike"],
    blurb: "MTB und Gravel gemischt, Fokus auf sichere Linien und Trail-Etikette.",
    href: "/regions/schwarzwald",
  },
  {
    id: "cl-by-lakes",
    name: "Bayern Seenrunde",
    regionSlug: "bayern",
    sports: ["road", "gravel", "touring"],
    blurb: "Seen, Flachland und Alpenvorland — Touring-lastig.",
    href: "/regions/bayern",
  },
];
