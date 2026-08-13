/**
 * Live-Community-Zähler für Tour-Karten / Detail.
 * Keine Stub-Sterne: leere API → Count 0, kein erfundenes Rating.
 */

export const COMMUNITY_EMPTY_COPY =
  "Noch keine Community-Beiträge — erste:in sein";

export type TourCommunityCounts = {
  reviewCount: number;
  photoCount: number;
  averageRating: number | null;
};

export const EMPTY_COMMUNITY_COUNTS: TourCommunityCounts = {
  reviewCount: 0,
  photoCount: 0,
  averageRating: null,
};

export function hasCommunity(c: TourCommunityCounts): boolean {
  return c.reviewCount > 0 || c.photoCount > 0;
}

function asRating(raw: unknown): number | null {
  if (typeof raw !== "number" || !Number.isFinite(raw)) return null;
  const n = Math.round(raw);
  if (n < 1 || n > 5) return null;
  return n;
}

export function countsFromPayload(data: unknown): TourCommunityCounts {
  if (!data || typeof data !== "object") return { ...EMPTY_COMMUNITY_COUNTS };
  const m = data as Record<string, unknown>;
  const reviews = Array.isArray(m.reviews) ? m.reviews : [];
  const photos = Array.isArray(m.photos) ? m.photos : [];
  const ratings: number[] = [];
  for (const r of reviews) {
    if (!r || typeof r !== "object") continue;
    const rating = asRating((r as { rating?: unknown }).rating);
    if (rating != null) ratings.push(rating);
  }
  const reviewCount =
    typeof m.reviewCount === "number" && Number.isFinite(m.reviewCount)
      ? Math.max(0, Math.round(m.reviewCount))
      : ratings.length;
  const photoCount =
    typeof m.photoCount === "number" && Number.isFinite(m.photoCount)
      ? Math.max(0, Math.round(m.photoCount))
      : photos.length;
  const averageRating =
    ratings.length === 0
      ? null
      : Math.round(
          (ratings.reduce((a, b) => a + b, 0) / ratings.length) * 10
        ) / 10;
  return { reviewCount, photoCount, averageRating };
}

export function countsMapFromBatch(data: unknown): Record<string, TourCommunityCounts> {
  if (!data || typeof data !== "object") return {};
  const raw = (data as { counts?: unknown }).counts;
  if (!raw || typeof raw !== "object") return {};
  const out: Record<string, TourCommunityCounts> = {};
  for (const [id, v] of Object.entries(raw as Record<string, unknown>)) {
    if (!id.trim()) continue;
    if (v && typeof v === "object") {
      const row = v as { reviewCount?: unknown; photoCount?: unknown };
      const reviewCount =
        typeof row.reviewCount === "number" ? Math.max(0, Math.round(row.reviewCount)) : 0;
      const photoCount =
        typeof row.photoCount === "number" ? Math.max(0, Math.round(row.photoCount)) : 0;
      out[id] = {
        reviewCount,
        photoCount,
        averageRating: null,
      };
    }
  }
  return out;
}

export function communityChipLabel(c: TourCommunityCounts): string | null {
  if (!hasCommunity(c)) return null;
  const parts: string[] = [];
  if (c.reviewCount > 0) {
    parts.push(
      c.averageRating != null
        ? `★ ${c.averageRating} (${c.reviewCount})`
        : `${c.reviewCount} Bewertungen`
    );
  }
  if (c.photoCount > 0) {
    parts.push(`${c.photoCount} Fotos`);
  }
  return parts.join(" · ");
}
