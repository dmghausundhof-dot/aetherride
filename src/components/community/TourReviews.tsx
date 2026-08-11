"use client";

import { useMemo, useState } from "react";
import Link from "next/link";
import { Star, Trash2 } from "lucide-react";
import {
  approvedReviewsForTour,
  averageRating,
  useCommunityStore,
} from "@/store/useCommunityStore";

export function TourReviews({ tourId }: { tourId: string }) {
  const myReviews = useCommunityStore((s) => s.myReviews);
  const submitReview = useCommunityStore((s) => s.submitReview);
  const removeMyReview = useCommunityStore((s) => s.removeMyReview);
  const publicProfile = useCommunityStore((s) => s.publicProfile);

  const [rating, setRating] = useState<1 | 2 | 3 | 4 | 5>(4);
  const [body, setBody] = useState("");
  const [name, setName] = useState(publicProfile.displayName || "");
  const [msg, setMsg] = useState<string | null>(null);

  const reviews = useMemo(
    () => approvedReviewsForTour(tourId, myReviews),
    [tourId, myReviews]
  );
  const avg = averageRating(
    reviews.filter((r) => r.status === "approved" || r.editorial)
  );

  const onSubmit = () => {
    const res = submitReview({
      tourId,
      rating,
      body,
      authorLabel: name,
    });
    if ("error" in res) {
      setMsg(res.error);
      return;
    }
    setBody("");
    setMsg(
      "Danke — Review ist „in Prüfung“ und nur für dich sichtbar, bis moderiert."
    );
  };

  return (
    <section className="rounded-2xl border border-border bg-surface p-4 sm:p-5">
      <div className="flex flex-wrap items-center justify-between gap-2">
        <h2 className="text-lg font-semibold">Community-Reviews</h2>
        {avg != null && (
          <p className="flex items-center gap-1 text-sm tabular-nums text-text-secondary">
            <Star className="h-4 w-4 fill-accent text-accent" />
            {avg} · {reviews.filter((r) => r.editorial || r.status === "approved").length}{" "}
            freigegeben
          </p>
        )}
      </div>
      <p className="mt-1 text-[11px] text-text-secondary">
        Privacy-first: neue Beiträge starten als „in Prüfung“. Redaktionelle
        Beispiele sind gekennzeichnet. Keine Tracks in Reviews.
      </p>

      <ul className="mt-4 space-y-3">
        {reviews.length === 0 && (
          <li className="text-sm text-text-secondary">
            Noch keine freigegebenen Reviews — sei die/der Erste.
          </li>
        )}
        {reviews.map((r) => (
          <li
            key={r.id}
            className="rounded-xl border border-border bg-background/50 p-3"
          >
            <div className="flex flex-wrap items-center gap-2 text-xs">
              <span className="font-semibold text-foreground">
                {r.authorLabel}
              </span>
              {r.authorHandle && (
                <Link
                  href={`/u/${r.authorHandle}`}
                  className="text-accent hover:underline"
                >
                  @{r.authorHandle}
                </Link>
              )}
              <span className="flex items-center gap-0.5 text-accent">
                {Array.from({ length: r.rating }).map((_, i) => (
                  <Star key={i} className="h-3 w-3 fill-current" />
                ))}
              </span>
              {r.editorial && (
                <span className="rounded-full bg-primary/20 px-2 py-0.5 text-[10px] font-medium text-text-secondary">
                  Editorial
                </span>
              )}
              {r.status === "pending" && (
                <span className="rounded-full bg-warning/15 px-2 py-0.5 text-[10px] font-medium text-warning">
                  In Prüfung
                </span>
              )}
            </div>
            <p className="mt-1.5 text-sm text-text-secondary">{r.body}</p>
            {r.id.startsWith("ur-") && (
              <button
                type="button"
                onClick={() => removeMyReview(r.id)}
                className="mt-2 inline-flex items-center gap-1 text-[11px] text-text-secondary hover:text-error"
              >
                <Trash2 className="h-3 w-3" /> Entfernen
              </button>
            )}
          </li>
        ))}
      </ul>

      <div className="mt-6 border-t border-border pt-4">
        <h3 className="text-sm font-semibold">Review schreiben</h3>
        <div className="mt-2 flex gap-1">
          {([1, 2, 3, 4, 5] as const).map((n) => (
            <button
              key={n}
              type="button"
              onClick={() => setRating(n)}
              className="p-1"
              aria-label={`${n} Sterne`}
            >
              <Star
                className={`h-6 w-6 ${
                  n <= rating
                    ? "fill-accent text-accent"
                    : "text-text-secondary"
                }`}
              />
            </button>
          ))}
        </div>
        <input
          value={name}
          onChange={(e) => setName(e.target.value)}
          placeholder="Anzeigename"
          className="mt-2 w-full rounded-lg border border-border bg-background px-3 py-2 text-sm"
          maxLength={40}
        />
        <textarea
          value={body}
          onChange={(e) => setBody(e.target.value.slice(0, 500))}
          placeholder="Wie war die Tour? Belag, Verkehr, Tipps… (keine privaten Orte)"
          rows={3}
          className="mt-2 w-full rounded-lg border border-border bg-background px-3 py-2 text-sm"
        />
        <div className="mt-2 flex flex-wrap items-center justify-between gap-2">
          <span className="text-[11px] text-text-secondary">
            {body.length}/500
          </span>
          <button
            type="button"
            onClick={onSubmit}
            className="rounded-xl bg-accent px-4 py-2 text-sm font-semibold text-white"
          >
            Absenden
          </button>
        </div>
        {msg && (
          <p className="mt-2 text-xs text-text-secondary" role="status">
            {msg}
          </p>
        )}
      </div>
    </section>
  );
}
