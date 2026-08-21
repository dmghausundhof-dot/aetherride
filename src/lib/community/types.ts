/**
 * Community light (Phase D) — Privacy-first, moderiert.
 *
 * Cloud: apply `supabase/tour_community.sql` then wire
 * `GET/POST /api/community/tour` (`stub: false` when tables exist).
 * Mobile keeps a local `TourCommunityStore` so the app never depends on cloud.
 */

export type ModerationStatus = "approved" | "pending" | "rejected" | "hidden";
export type ModerationSource = "ai" | "human" | "rule";

export type TourReview = {
  id: string;
  tourId: string;
  /** Anzeige-Name (kein Pflicht-Login) */
  authorLabel: string;
  /** Optionaler öffentlicher Handle */
  authorHandle?: string;
  rating: 1 | 2 | 3 | 4 | 5;
  /** Kurztext, max. ~500 Zeichen in UI */
  body: string;
  /** ISO date */
  createdAt: string;
  status: ModerationStatus;
  moderationSource?: ModerationSource;
  aiLabels?: string[];
  aiConfidence?: number;
  /** true = redaktioneller Seed, kein User-Inhalt */
  editorial?: boolean;
  /** Sport-Kontext z. B. gravel */
  sportHint?: string;
  /** Zustand-Tags (nass, zu, …) — nur von der Stimme, nie erfunden. */
  tags?: string[];
};

export type PublicProfileSettings = {
  enabled: boolean;
  handle: string;
  displayName: string;
  bio: string;
  sports: string[];
  /** Nur aggregierte Stats, keine Tracks */
  showRideCount: boolean;
  showPreferredSports: boolean;
  regionLabel?: string;
};

export type SharedCollectionPayload = {
  v: 1;
  name: string;
  description?: string;
  routeIds: string[];
  routeNames: string[];
  authorLabel: string;
  authorHandle?: string;
  createdAt: string;
};

/** Einzel-Tour-Freigabe. Geometrie nur wenn includeTrack — nie still. */
export type SharedTourPayload = {
  v: 1;
  kind: "tour";
  id: string;
  name: string;
  distanceKm: number;
  elevationM: number;
  durationMin: number;
  source: string;
  catalogTourId?: string;
  includeTrack: boolean;
  /** LineString-Koordinaten [lng, lat], nur bei includeTrack. */
  track?: [number, number][];
  authorLabel: string;
  createdAt: string;
  /** Zum lokalen Widerruf: Token älter als revoked epoch ist ungültig. */
  epoch?: number;
};

/**
 * Marketing-Seed auf /community. Kein Join, kein Live-GPS, keine Pins.
 * Gemeinsames Fahren: `RideGroup` in `rideGroup.ts` (Zusammen raus).
 */
export type CommunityEvent = {
  id: string;
  title: string;
  regionSlug: string;
  dateLabel: string;
  sport: string;
  blurb: string;
  href?: string;
};

/** Orientierung auf /community — keine Live-Mitgliedschaft. */
export type CommunityClub = {
  id: string;
  name: string;
  regionSlug: string;
  sports: string[];
  blurb: string;
  href?: string;
};

/** Hof-Name: Gruppe. CTA: Zusammen raus. Nicht „Runde“ (das ist Loop-Geometrie). */
export type RideGroupStatus = "scheduled" | "open" | "riding" | "closed";

/** privat: nur Einladungslink. öffentlich: Link + Platz + Treffen-Pin. Kein Live-GPS. */
export type RideGroupListing = "public" | "private";

export type RideGroupPresenceVisibility =
  | "live"
  | "stale"
  | "hidden_zone"
  | "hidden_offline"
  | "hidden_opt_out"
  | "hidden_window"
  | "hidden_not_member";

/**
 * Gemeinsame Fahrt — Mitglieder + optional Live-Pins auf dem Ride-HUD.
 * Nicht öffentlich auf Explore. Kein Presence-Stream in diesem Slice.
 */
export type RideGroup = {
  id: string;
  hostUserId: string;
  /** SavedRoute oder Katalog-Tour. Kein RideTogether/`freeride`. */
  savedRouteId: string;
  catalogTourId?: string;
  title: string;
  startWindowStart: string;
  startWindowEnd: string;
  /** Freitext, z. B. „Parkplatz Schwimmbad“. Kein POI. */
  meetingPoint?: string;
  /** 6 Zeichen. Öffentlich: zum Abtippen. Privat: nur im Token-Link. */
  joinCode: string;
  /** Default private. Fehlt = private (alte Zeilen). */
  visibility?: RideGroupListing;
  status: RideGroupStatus;
  /** Host erlaubt Pins. Jedes Mitglied opt-in’t trotzdem pro Session. */
  livePinsAllowed: boolean;
  createdAt: string;
  /** true = SQL-Zeile, sichtbar für eingeloggte Geräte. */
  onServer?: boolean;
};

export type RideGroupMember = {
  groupId: string;
  userId: string;
  displayLabel: string;
  joinedAt: string;
  liveOptIn: boolean;
};

/** Letzter Punkt, kein Track. Überschreiben, nicht historisieren. */
export type RideGroupPresence = {
  groupId: string;
  userId: string;
  lng?: number;
  lat?: number;
  updatedAt: string;
  visibility: RideGroupPresenceVisibility;
};
