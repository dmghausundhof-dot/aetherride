"use client";

import { useEffect, useMemo, useState } from "react";
import Link from "next/link";
import { Camera, Star, Trash2 } from "lucide-react";
import {
  useCommunityStore,
} from "@/store/useCommunityStore";
import {
  countsFromPayload,
  hasCommunity,
  type TourCommunityCounts,
} from "@/lib/community/tourCommunity";
import {
  createClient,
  isSupabaseConfigured,
} from "@/lib/supabase/client";
import { useChromeLang } from "@/hooks/useChromeLang";
import { catalogCopy } from "@/lib/i18n/catalogCopy";
import { webChrome } from "@/lib/i18n/webChrome";

type CloudReview = {
  id: string;
  author_label?: string;
  rating?: number;
  body?: string;
  created_at?: string;
};

type CloudPhoto = {
  id?: string;
  url?: string | null;
  caption?: string | null;
};

export function TourReviews({
  tourId,
  showHeading = true,
}: {
  tourId: string;
  showHeading?: boolean;
}) {
  const myReviews = useCommunityStore((s) => s.myReviews);
  const submitReview = useCommunityStore((s) => s.submitReview);
  const removeMyReview = useCommunityStore((s) => s.removeMyReview);
  const publicProfile = useCommunityStore((s) => s.publicProfile);
  const s = catalogCopy(useChromeLang()).stimmen;
  const chrome = webChrome(useChromeLang());

  const [rating, setRating] = useState<1 | 2 | 3 | 4 | 5>(4);
  const [body, setBody] = useState("");
  const [name, setName] = useState(publicProfile.displayName || "");
  const [msg, setMsg] = useState<{ text: string; profile?: boolean } | null>(
    null,
  );
  const [cloudReviews, setCloudReviews] = useState<CloudReview[]>([]);
  const [cloudPhotos, setCloudPhotos] = useState<CloudPhoto[]>([]);
  const [counts, setCounts] = useState<TourCommunityCounts>({
    reviewCount: 0,
    photoCount: 0,
    averageRating: null,
  });
  const [photoFile, setPhotoFile] = useState<File | null>(null);
  const [busy, setBusy] = useState(false);

  const mine = useMemo(
    () => myReviews.filter((r) => r.tourId === tourId),
    [myReviews, tourId]
  );

  useEffect(() => {
    let alive = true;
    void (async () => {
      try {
        const r = await fetch(
          `/api/community/tour?id=${encodeURIComponent(tourId)}`,
          { cache: "no-store" }
        );
        if (!r.ok) return;
        const j = await r.json();
        if (!alive) return;
        setCloudReviews(Array.isArray(j.reviews) ? j.reviews : []);
        setCloudPhotos(Array.isArray(j.photos) ? j.photos : []);
        setCounts(countsFromPayload(j));
      } catch {
        /* empty state */
      }
    })();
    return () => {
      alive = false;
    };
  }, [tourId]);

  const onSubmit = async () => {
    const local = submitReview({
      tourId,
      rating,
      body,
      authorLabel: name,
    });
    if ("error" in local) {
      setMsg({
        text:
          local.error === "Bitte mindestens 8 Zeichen schreiben."
            ? s.minChars
            : local.error === "Bewertung 1–5."
              ? s.ratingRange
              : local.error,
      });
      return;
    }
    setBody("");
    setBusy(true);
    try {
      let photos: { storagePath: string }[] = [];
      if (photoFile && isSupabaseConfigured()) {
        const sb = createClient();
        const {
          data: { user },
        } = await sb.auth.getUser();
        if (user) {
          const path = `${user.id}/${tourId}/${Date.now()}-${photoFile.name.replace(/[^\w.-]+/g, "")}`;
          const up = await sb.storage.from("tour-photos").upload(path, photoFile, {
            upsert: true,
            contentType: photoFile.type || "image/jpeg",
          });
          if (!up.error) photos = [{ storagePath: path }];
        }
      }
      const res = await fetch("/api/community/tour", {
        method: "POST",
        credentials: "include",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          tourId,
          rating,
          body: local.body,
          authorLabel: local.authorLabel,
          photos,
        }),
      });
      setPhotoFile(null);
      if (res.status === 401) {
        setMsg({ text: s.savedLocalSignIn, profile: true });
        return;
      }
      if (res.ok) {
        const j = await res.json();
        setMsg({
          text:
            j.status === "approved" ? s.thanksPublished : s.thanksPending,
        });
        return;
      }
      setMsg({ text: s.savedLocalCloud });
    } catch {
      setMsg({ text: s.savedLocalCloud });
    } finally {
      setBusy(false);
    }
  };

  const liveEmpty = !hasCommunity(counts) && mine.length === 0;

  return (
    <section className="rounded-2xl border border-border bg-surface p-4 sm:p-5">
      <div className="flex flex-wrap items-center justify-between gap-2">
        {showHeading ? <h2 className="text-lg font-semibold">{s.heading}</h2> : null}
        {counts.averageRating != null && (
          <p className="flex items-center gap-1 text-sm tabular-nums text-text-secondary">
            <Star className="h-4 w-4 fill-accent text-accent" />
            {s.countLine(
              counts.averageRating,
              counts.reviewCount,
              counts.photoCount,
            )}
          </p>
        )}
      </div>
      <p className="mt-1 text-[11px] text-text-secondary">{s.liveHint}</p>

      {liveEmpty && (
        <p className="mt-4 text-sm text-text-secondary">{s.empty}</p>
      )}

      {cloudPhotos.filter((p) => p.url).length > 0 && (
        <div className="mt-4 flex gap-2 overflow-x-auto">
          {cloudPhotos
            .filter((p) => p.url)
            .slice(0, 8)
            .map((p) => (
              // eslint-disable-next-line @next/next/no-img-element
              <img
                key={p.id || p.url!}
                src={p.url!}
                alt={p.caption || s.photoAlt}
                className="h-20 w-28 rounded-lg object-cover"
              />
            ))}
        </div>
      )}

      <ul className="mt-4 space-y-3">
        {cloudReviews.map((r) => (
          <li
            key={r.id}
            className="rounded-xl border border-border bg-background/50 p-3"
          >
            <div className="flex flex-wrap items-center gap-2 text-xs">
              <span className="font-semibold text-foreground">
                {r.author_label || "Rider"}
              </span>
              {typeof r.rating === "number" && r.rating >= 1 && r.rating <= 5 && (
                <span className="flex items-center gap-0.5 text-accent">
                  {Array.from({ length: r.rating }).map((_, i) => (
                    <Star key={i} className="h-3 w-3 fill-current" />
                  ))}
                </span>
              )}
            </div>
            {r.body ? (
              <p className="mt-1.5 text-sm text-text-secondary">{r.body}</p>
            ) : null}
          </li>
        ))}
        {mine.map((r) => (
          <li
            key={r.id}
            className="rounded-xl border border-border bg-background/50 p-3"
          >
            <div className="flex flex-wrap items-center gap-2 text-xs">
              <span className="font-semibold text-foreground">
                {r.authorLabel}
              </span>
              <span className="flex items-center gap-0.5 text-accent">
                {Array.from({ length: r.rating }).map((_, i) => (
                  <Star key={i} className="h-3 w-3 fill-current" />
                ))}
              </span>
              {r.status === "pending" && (
                <span className="rounded-full bg-warning/15 px-2 py-0.5 text-[10px] font-medium text-warning">
                  {s.pending}
                </span>
              )}
            </div>
            <p className="mt-1.5 text-sm text-text-secondary">{r.body}</p>
            <button
              type="button"
              onClick={() => removeMyReview(r.id)}
              className="mt-2 inline-flex items-center gap-1 text-[11px] text-text-secondary hover:text-error"
            >
              <Trash2 className="h-3 w-3" /> {s.remove}
            </button>
          </li>
        ))}
      </ul>

      <div className="mt-6 border-t border-border pt-4">
        <h3 className="text-sm font-semibold">{s.write}</h3>
        <div className="mt-2 flex gap-1">
          {([1, 2, 3, 4, 5] as const).map((n) => (
            <button
              key={n}
              type="button"
              onClick={() => setRating(n)}
              className="p-1"
              aria-label={s.starsAria(n)}
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
          placeholder={s.namePlaceholder}
          aria-label={s.nameAria}
          className="mt-2 w-full rounded-lg border border-border bg-background px-3 py-2 text-sm"
          maxLength={40}
        />
        <textarea
          value={body}
          onChange={(e) => setBody(e.target.value.slice(0, 500))}
          placeholder={s.bodyPlaceholder}
          rows={3}
          className="mt-2 w-full rounded-lg border border-border bg-background px-3 py-2 text-sm"
        />
        <label className="mt-2 inline-flex cursor-pointer items-center gap-1.5 text-xs text-text-secondary">
          <Camera className="h-3.5 w-3.5" />
          {s.photo}
          <input
            type="file"
            accept="image/*"
            className="hidden"
            onChange={(e) => setPhotoFile(e.target.files?.[0] ?? null)}
          />
          {photoFile ? <span className="text-accent">{photoFile.name}</span> : null}
        </label>
        <div className="mt-2 flex flex-wrap items-center justify-between gap-2">
          <span className="text-[11px] text-text-secondary">
            {s.counter(body.length)}
          </span>
          <button
            type="button"
            disabled={busy}
            onClick={() => void onSubmit()}
            className="rounded-xl bg-accent px-4 py-2 text-sm font-semibold text-on-accent"
          >
            {busy ? "…" : s.submit}
          </button>
        </div>
        {msg && (
          <p className="mt-2 text-xs text-text-secondary" role="status">
            {msg.text}{" "}
            {msg.profile ? (
              <Link href="/profile" className="font-semibold text-accent">
                {chrome.profile}
              </Link>
            ) : null}
          </p>
        )}
      </div>
    </section>
  );
}
