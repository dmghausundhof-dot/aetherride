"use client";

import { useEffect, useMemo, useState } from "react";
import Link from "next/link";
import { Star, Trash2 } from "lucide-react";
import { ChromeGlyph } from "@/components/chrome/ChromeGlyph";
import { useCommunityStore } from "@/store/useCommunityStore";
import {
  countsFromPayload,
  hasCommunity,
  type TourCommunityCounts,
} from "@/lib/community/tourCommunity";
import { parseStimmeTags, STIMME_TAG_WIRES } from "@/lib/community/stimmeTags";
import { parseDifficultyDelta } from "@/lib/community/difficultyAggregate";
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
  tags?: unknown;
  pin_lat?: unknown;
  pin_lng?: unknown;
  difficulty_delta?: unknown;
};

type CloudPhoto = {
  id?: string;
  url?: string | null;
  caption?: string | null;
  lat?: number | null;
  lng?: number | null;
};

function crowdLine(
  counts: TourCommunityCounts,
  s: ReturnType<typeof catalogCopy>["stimmen"],
): string | null {
  const d = counts.difficulty;
  if (!d?.shown || !d.label) return null;
  if (d.label === "easier") return s.crowdEasier(d.n);
  if (d.label === "harder") return s.crowdHarder(d.n);
  return s.crowdAsMarked(d.n);
}

function pinOf(r: CloudReview): { lat: number; lng: number } | null {
  const lat = Number(r.pin_lat);
  const lng = Number(r.pin_lng);
  if (!Number.isFinite(lat) || !Number.isFinite(lng)) return null;
  if (Math.abs(lat) > 90 || Math.abs(lng) > 180) return null;
  return { lat, lng };
}

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
  const [tags, setTags] = useState<string[]>([]);
  const [difficultyDelta, setDifficultyDelta] = useState<number | null>(null);
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

  const toggleTag = (wire: string) => {
    setTags((cur) => parseStimmeTags(
      cur.includes(wire) ? cur.filter((t) => t !== wire) : [...cur, wire],
    ));
  };

  const onSubmit = async () => {
    const local = submitReview({
      tourId,
      rating,
      body,
      authorLabel: name,
      tags,
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
      const delta = parseDifficultyDelta(difficultyDelta);
      const res = await fetch("/api/community/tour", {
        method: "POST",
        credentials: "include",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          tourId,
          rating,
          body: local.body,
          authorLabel: local.authorLabel,
          tags,
          ...(delta != null ? { difficultyDelta: delta } : {}),
          photos,
        }),
      });
      setPhotoFile(null);
      setTags([]);
      setDifficultyDelta(null);
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
  const crowd = crowdLine(counts, s);

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
      {crowd ? (
        <p className="mt-1 text-xs text-text-secondary">{crowd}</p>
      ) : null}

      {liveEmpty && (
        <p className="mt-4 text-sm text-text-secondary">{s.empty}</p>
      )}

      {cloudPhotos.filter((p) => p.url).length > 0 && (
        <div className="mt-4 flex gap-2 overflow-x-auto">
          {cloudPhotos
            .filter((p) => p.url)
            .slice(0, 8)
            .map((p) => {
              const plat = Number(p.lat);
              const plng = Number(p.lng);
              const geo =
                Number.isFinite(plat) &&
                Number.isFinite(plng) &&
                Math.abs(plat) <= 90 &&
                Math.abs(plng) <= 180;
              return (
                <div key={p.id || p.url!} className="relative shrink-0">
                  {/* eslint-disable-next-line @next/next/no-img-element */}
                  <img
                    src={p.url!}
                    alt={p.caption || s.photoAlt}
                    className="h-20 w-28 rounded-lg object-cover"
                  />
                  {geo ? (
                    <span className="absolute left-1 top-1 text-[10px] font-semibold text-white drop-shadow">
                      {plat.toFixed(3)}, {plng.toFixed(3)}
                    </span>
                  ) : null}
                </div>
              );
            })}
        </div>
      )}

      <ul className="mt-4 space-y-3">
        {cloudReviews.map((r) => {
          const pin = pinOf(r);
          const rowTags = parseStimmeTags(r.tags);
          const delta = parseDifficultyDelta(r.difficulty_delta);
          return (
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
              {rowTags.length > 0 ? (
                <p className="mt-1 text-[11px] text-text-secondary">
                  {rowTags.map((t) => s.tagLabel(t)).join(" · ")}
                </p>
              ) : null}
              {delta != null ? (
                <p className="mt-0.5 text-[11px] text-text-secondary">
                  {delta < 0
                    ? s.difficultyEasier
                    : delta > 0
                      ? s.difficultyHarder
                      : s.difficultyAsMarked}
                </p>
              ) : null}
              {pin ? (
                <p className="mt-1 inline-flex items-center gap-1 text-[11px] text-text-secondary">
                  <ChromeGlyph name="karte" size={12} />
                  {s.pinOnLine} · {pin.lat.toFixed(4)}, {pin.lng.toFixed(4)}
                </p>
              ) : null}
            </li>
          );
        })}
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
        <p className="mt-3 text-[11px] text-text-secondary">{s.tagsHint}</p>
        <div className="mt-1 flex flex-wrap gap-1.5">
          {STIMME_TAG_WIRES.map((wire) => (
            <button
              key={wire}
              type="button"
              onClick={() => toggleTag(wire)}
              className={`rounded-full border px-2.5 py-1 text-[11px] ${
                tags.includes(wire)
                  ? "border-accent bg-accent/15 text-accent"
                  : "border-border text-text-secondary"
              }`}
            >
              {s.tagLabel(wire)}
            </button>
          ))}
        </div>
        <p className="mt-3 text-[11px] text-text-secondary">{s.difficultyHint}</p>
        <div className="mt-1 flex flex-wrap gap-1.5">
          {([-1, 0, 1] as const).map((d) => (
            <button
              key={d}
              type="button"
              onClick={() =>
                setDifficultyDelta((cur) => (cur === d ? null : d))
              }
              className={`rounded-full border px-2.5 py-1 text-[11px] ${
                difficultyDelta === d
                  ? "border-accent bg-accent/15 text-accent"
                  : "border-border text-text-secondary"
              }`}
            >
              {d < 0
                ? s.difficultyEasier
                : d > 0
                  ? s.difficultyHarder
                  : s.difficultyAsMarked}
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
          <ChromeGlyph name="photo" size={14} current className="text-text-secondary" />
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
