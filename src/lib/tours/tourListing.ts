/**
 * Freigabe-Gate für User-Touren.
 *
 * Link-Share ≠ Karten-Pin. Erst k fremde Stimmen in einem Zeitfenster
 * machen eine Tour listen-fähig — sonst wieder privat. Katalog bleibt
 * redaktionell und überspringt das Gate.
 */

export const LISTING_CONFIRM_K = 3;
export const LISTING_WINDOW_DAYS = 14;

export type TourListingState = "none" | "candidate" | "listed" | "reverted";

export type ListingConfirmationKind = "stimme" | "ride";

export type ListingConfirmation = {
  riderId: string;
  at: string;
  kind: ListingConfirmationKind;
};

export type ListingSnapshot = {
  visibility: "private" | "shared";
  listing: TourListingState;
  candidateSince: string | null;
  listedAt: string | null;
  shareEpoch: number;
};

export type ListingTickInput = ListingSnapshot & {
  isCatalog: boolean;
  confirmations: ListingConfirmation[];
  now: Date;
};

export type ListingNotice = "none" | "candidate" | "listed" | "reverted";

export type ListingDecision = ListingSnapshot & {
  confirmCount: number;
  needed: number;
  notice: ListingNotice;
  changed: boolean;
  expiresAt: string | null;
};

const OWNER_IDS = new Set(["", "du", "ich", "you", "me", "rider"]);

export function parseListingState(raw: unknown): TourListingState {
  if (raw === "candidate" || raw === "listed" || raw === "reverted") {
    return raw;
  }
  return "none";
}

export function uniqueConfirmCount(
  confirmations: ListingConfirmation[],
  since?: Date | null
): number {
  const seen = new Set<string>();
  const start = since?.getTime() ?? 0;
  for (const c of confirmations) {
    const id = c.riderId.trim().toLowerCase();
    if (!id || OWNER_IDS.has(id)) continue;
    const at = Date.parse(c.at);
    if (!Number.isFinite(at)) continue;
    if (start > 0 && at < start) continue;
    seen.add(id);
  }
  return seen.size;
}

/** Stimmen fremder Fahrer — eigene und redaktionelle zählen nicht. */
export function confirmationsFromReviews(
  reviews: Array<{
    authorLabel?: string | null;
    authorHandle?: string | null;
    authorId?: string | null;
    createdAt: string;
    status?: string | null;
    editorial?: boolean;
  }>,
  ownerLabel?: string | null
): ListingConfirmation[] {
  const owner = (ownerLabel ?? "").trim().toLowerCase();
  const out: ListingConfirmation[] = [];
  const seen = new Set<string>();
  for (const r of reviews) {
    if (r.editorial) continue;
    if (r.status && r.status !== "approved") continue;
    const riderId = (
      r.authorId ||
      r.authorHandle ||
      r.authorLabel ||
      ""
    ).trim();
    const key = riderId.toLowerCase();
    if (!key || OWNER_IDS.has(key) || key === owner) continue;
    if (seen.has(key)) continue;
    seen.add(key);
    out.push({ riderId, at: r.createdAt, kind: "stimme" });
  }
  return out;
}

function iso(d: Date): string {
  return d.toISOString();
}

function addDays(d: Date, days: number): Date {
  return new Date(d.getTime() + days * 24 * 60 * 60 * 1000);
}

function sameSnapshot(a: ListingSnapshot, b: ListingSnapshot): boolean {
  return (
    a.visibility === b.visibility &&
    a.listing === b.listing &&
    a.candidateSince === b.candidateSince &&
    a.listedAt === b.listedAt &&
    a.shareEpoch === b.shareEpoch
  );
}

function decision(
  snap: ListingSnapshot,
  prev: ListingSnapshot,
  confirmCount: number,
  notice: ListingNotice,
  expiresAt: string | null
): ListingDecision {
  return {
    ...snap,
    confirmCount,
    needed: LISTING_CONFIRM_K,
    notice,
    changed: !sameSnapshot(snap, prev),
    expiresAt,
  };
}

/**
 * Ein Tick: Share starten, listen, oder nach dem Fenster zurück auf privat.
 * Bereits gelistete Touren fallen nicht still um — nur Kandidaten laufen ab.
 */
export function tickTourListing(input: ListingTickInput): ListingDecision {
  const prev: ListingSnapshot = {
    visibility: input.visibility,
    listing: input.listing,
    candidateSince: input.candidateSince,
    listedAt: input.listedAt,
    shareEpoch: input.shareEpoch,
  };
  const since = input.candidateSince
    ? new Date(input.candidateSince)
    : null;
  const confirmCount = uniqueConfirmCount(input.confirmations, since);

  if (input.isCatalog) {
    return decision(
      {
        visibility: input.visibility,
        listing: "none",
        candidateSince: null,
        listedAt: null,
        shareEpoch: input.shareEpoch,
      },
      prev,
      confirmCount,
      "none",
      null
    );
  }

  if (input.visibility === "private") {
    const listing =
      input.listing === "reverted" ? "reverted" : "none";
    return decision(
      {
        visibility: "private",
        listing,
        candidateSince: listing === "reverted" ? input.candidateSince : null,
        listedAt: null,
        shareEpoch: input.shareEpoch,
      },
      prev,
      confirmCount,
      listing === "reverted" ? "reverted" : "none",
      null
    );
  }

  if (input.listing === "listed") {
    return decision(
      {
        visibility: "shared",
        listing: "listed",
        candidateSince: input.candidateSince,
        listedAt: input.listedAt ?? iso(input.now),
        shareEpoch: input.shareEpoch,
      },
      prev,
      Math.max(confirmCount, LISTING_CONFIRM_K),
      "listed",
      null
    );
  }

  const candidateSince = input.candidateSince ?? iso(input.now);
  const started = new Date(candidateSince);
  const expiresAt = iso(addDays(started, LISTING_WINDOW_DAYS));

  if (confirmCount >= LISTING_CONFIRM_K) {
    return decision(
      {
        visibility: "shared",
        listing: "listed",
        candidateSince,
        listedAt: iso(input.now),
        shareEpoch: input.shareEpoch,
      },
      prev,
      confirmCount,
      "listed",
      null
    );
  }

  if (input.now.getTime() >= Date.parse(expiresAt)) {
    return decision(
      {
        visibility: "private",
        listing: "reverted",
        candidateSince,
        listedAt: null,
        shareEpoch: input.shareEpoch + 1,
      },
      prev,
      confirmCount,
      "reverted",
      expiresAt
    );
  }

  return decision(
    {
      visibility: "shared",
      listing: "candidate",
      candidateSince,
      listedAt: null,
      shareEpoch: input.shareEpoch,
    },
    prev,
    confirmCount,
    "candidate",
    expiresAt
  );
}

/** Nutzer tippt Freigeben — Link ja, Karten-Pin erst nach dem Gate. */
export function beginTourShare(
  snap: ListingSnapshot,
  now: Date,
  isCatalog: boolean
): ListingSnapshot {
  if (isCatalog) {
    return {
      visibility: "shared",
      listing: "none",
      candidateSince: null,
      listedAt: null,
      shareEpoch: snap.shareEpoch,
    };
  }
  if (snap.listing === "listed" && snap.visibility === "shared") {
    return { ...snap, visibility: "shared" };
  }
  return {
    visibility: "shared",
    listing: "candidate",
    candidateSince: iso(now),
    listedAt: null,
    shareEpoch: snap.shareEpoch,
  };
}

/** Nutzer nimmt die Freigabe zurück. */
export function unpublishTour(snap: ListingSnapshot): ListingSnapshot {
  const bump = snap.visibility === "shared" || snap.listing === "listed";
  return {
    visibility: "private",
    listing: "none",
    candidateSince: null,
    listedAt: null,
    shareEpoch: bump ? snap.shareEpoch + 1 : snap.shareEpoch,
  };
}

/** Nur gelistete User-Touren dürfen als Explore-Pin erscheinen. */
export function listedForPublicExplore(snap: {
  listing?: string | null;
  visibility?: string | null;
}): boolean {
  return snap.listing === "listed" && snap.visibility === "shared";
}

export function listingAkteHint(listing: TourListingState): string | null {
  if (listing === "candidate") {
    return "Link ist aktiv. Karten-Pin erst nach 3 Stimmen in 14 Tagen.";
  }
  if (listing === "listed") {
    return "Liegt auf der Karte — 3 Stimmen erreicht.";
  }
  if (listing === "reverted") {
    return "Wieder privat — zu wenig Stimmen im Fenster.";
  }
  return null;
}

export function listingTafelText(input: {
  name: string;
  notice: ListingNotice;
  confirmCount: number;
  needed?: number;
}): string | null {
  const name = input.name.trim() || "Tour";
  const need = input.needed ?? LISTING_CONFIRM_K;
  if (input.notice === "reverted") {
    return `${name} wieder privat — zu wenig Stimmen.`;
  }
  if (input.notice === "listed") {
    return `${name} liegt auf der Karte.`;
  }
  if (input.notice === "candidate") {
    return `${name} wartet auf Bestätigung (${input.confirmCount}/${need}).`;
  }
  return null;
}

export function nearbyListingTafelText(count: number): string | null {
  const n = Math.max(0, Math.floor(count));
  if (n <= 0) return null;
  if (n === 1) return "1 Runde in der Nähe wartet auf Bestätigung.";
  return `${n} Runden in der Nähe warten auf Bestätigung.`;
}

/** Eine Tafel-Zeile: eigene Reverts/Kandidaten vor Nearby. */
export function pickListingTafel(input: {
  own: Array<{
    name: string;
    notice: ListingNotice;
    confirmCount: number;
    candidateSince?: string | null;
  }>;
  nearbyWaiting?: number;
}): string | null {
  const reverted = input.own.filter((o) => o.notice === "reverted");
  if (reverted.length > 0) {
    reverted.sort((a, b) =>
      (b.candidateSince ?? "").localeCompare(a.candidateSince ?? "")
    );
    return listingTafelText(reverted[0]!);
  }
  const waiting = input.own.filter((o) => o.notice === "candidate");
  if (waiting.length > 0) {
    waiting.sort((a, b) => a.confirmCount - b.confirmCount);
    return listingTafelText(waiting[0]!);
  }
  const listed = input.own.filter((o) => o.notice === "listed");
  if (listed.length > 0) {
    return listingTafelText(listed[0]!);
  }
  return nearbyListingTafelText(input.nearbyWaiting ?? 0);
}

export function listingSnapshotOf(route: {
  visibility?: string | null;
  listing?: string | null;
  candidateSince?: string | null;
  listedAt?: string | null;
  shareEpoch?: number | null;
}): ListingSnapshot {
  return {
    visibility: route.visibility === "shared" ? "shared" : "private",
    listing: parseListingState(route.listing),
    candidateSince: route.candidateSince ?? null,
    listedAt: route.listedAt ?? null,
    shareEpoch: route.shareEpoch ?? 0,
  };
}

export function listingPatch(snap: ListingSnapshot): {
  visibility: "private" | "shared";
  listing: TourListingState;
  candidateSince: string | undefined;
  listedAt: string | undefined;
  shareEpoch: number;
} {
  return {
    visibility: snap.visibility,
    listing: snap.listing,
    candidateSince: snap.candidateSince ?? undefined,
    listedAt: snap.listedAt ?? undefined,
    shareEpoch: snap.shareEpoch,
  };
}
