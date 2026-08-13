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

export type CommunityEvent = {
  id: string;
  title: string;
  regionSlug: string;
  dateLabel: string;
  sport: string;
  blurb: string;
  href?: string;
};

export type CommunityClub = {
  id: string;
  name: string;
  regionSlug: string;
  sports: string[];
  blurb: string;
  href?: string;
};
