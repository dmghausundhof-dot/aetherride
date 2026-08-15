"use client";

import { useEffect, useState } from "react";
import { Camera, Star } from "lucide-react";
import {
  countsFromPayload,
  countsMapFromBatch,
  hasCommunity,
  type TourCommunityCounts,
} from "@/lib/community/tourCommunity";

const cache: Record<string, TourCommunityCounts> = {};
const inflight = new Map<string, Promise<void>>();

async function fetchOne(tourId: string): Promise<TourCommunityCounts> {
  if (cache[tourId]) return cache[tourId];
  const pending = inflight.get(tourId);
  if (pending) {
    await pending;
    return cache[tourId] ?? { reviewCount: 0, photoCount: 0, averageRating: null };
  }
  const run = (async () => {
    try {
      const r = await fetch(
        `/api/community/tour?id=${encodeURIComponent(tourId)}`,
        { cache: "no-store" }
      );
      if (!r.ok) return;
      const j = await r.json();
      cache[tourId] = countsFromPayload(j);
    } catch {
      cache[tourId] = {
        reviewCount: 0,
        photoCount: 0,
        averageRating: null,
      };
    } finally {
      inflight.delete(tourId);
    }
  })();
  inflight.set(tourId, run);
  await run;
  return cache[tourId] ?? { reviewCount: 0, photoCount: 0, averageRating: null };
}

export async function prefetchTourCommunityCounts(ids: string[]) {
  const missing = ids.filter((id) => id && !cache[id]).slice(0, 40);
  if (missing.length === 0) return;
  try {
    const r = await fetch(
      `/api/community/tour?ids=${encodeURIComponent(missing.join(","))}`,
      { cache: "no-store" }
    );
    if (!r.ok) return;
    const mapped = countsMapFromBatch(await r.json());
    Object.assign(cache, mapped);
  } catch {
    /* chips stay hidden */
  }
}

export function TourCommunityChip({
  tourId,
  className = "",
}: {
  tourId: string;
  className?: string;
}) {
  const [counts, setCounts] = useState<TourCommunityCounts | null>(
    cache[tourId] ?? null
  );

  useEffect(() => {
    let alive = true;
    void fetchOne(tourId).then((c) => {
      if (alive) setCounts(c);
    });
    return () => {
      alive = false;
    };
  }, [tourId]);

  if (!counts || !hasCommunity(counts)) return null;

  return (
    <span
      className={`inline-flex items-center gap-1 rounded-full bg-accent/15 px-2 py-0.5 text-[11px] font-semibold text-accent ${className}`}
    >
      {counts.reviewCount > 0 && (
        <>
          <Star className="h-3 w-3 fill-current" />
          {counts.averageRating != null
            ? `${counts.averageRating} (${counts.reviewCount})`
            : counts.reviewCount}
        </>
      )}
      {counts.photoCount > 0 && (
        <>
          {counts.reviewCount > 0 ? <span className="opacity-60">·</span> : null}
          <Camera className="h-3 w-3" />
          {counts.photoCount}
        </>
      )}
    </span>
  );
}
