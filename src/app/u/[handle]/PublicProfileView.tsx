"use client";

/**
 * Public Profile light — Opt-in aus Store, Server oder Editorial-Handle.
 */
import { useEffect, useMemo, useState } from "react";
import Link from "next/link";
import { useCommunityStore } from "@/store/useCommunityStore";
import { useAppStore } from "@/store/useAppStore";
import { EDITORIAL_REVIEWS } from "@/lib/community/seed";
import { getEditorialProfile } from "@/lib/community/editorialProfiles";
import { getPublicTour } from "@/lib/catalog/publicTours";
import { ChromeGlyph } from "@/components/chrome/ChromeGlyph";
import { useChromeLang } from "@/hooks/useChromeLang";
import { profileCopy, publicDisciplineLabel } from "@/lib/i18n/profileCopy";
import { webChrome } from "@/lib/i18n/webChrome";

type ViewProfile = {
  displayName: string;
  handle: string;
  bio: string;
  sports: string[];
  showRideCount: boolean;
  rideCount: number;
  regionLabel?: string;
  editorial: boolean;
};

export function PublicProfileView({ handle }: { handle: string }) {
  const lang = useChromeLang();
  const p = profileCopy(lang);
  const chrome = webChrome(lang);
  const publicProfile = useCommunityStore((s) => s.publicProfile);
  const myReviews = useCommunityStore((s) => s.myReviews);
  const rides = useAppStore((s) => s.rides);
  const preferredSport = useAppStore((s) => s.preferredSport);
  const [remote, setRemote] = useState<ViewProfile | null>(null);

  const isSelf =
    publicProfile.enabled &&
    publicProfile.handle &&
    publicProfile.handle === handle;

  const editorial = getEditorialProfile(handle);

  useEffect(() => {
    if (isSelf || editorial) return;
    let cancelled = false;
    void fetch(
      `/api/community/profile?handle=${encodeURIComponent(handle)}`,
      { credentials: "include" },
    )
      .then((r) => (r.ok ? r.json() : null))
      .then((data) => {
        if (cancelled || !data?.profile) return;
        const raw = data.profile as Record<string, unknown>;
        setRemote({
          displayName: String(raw.display_name ?? raw.displayName ?? handle),
          handle: String(raw.handle ?? handle),
          bio: String(raw.bio ?? ""),
          sports: Array.isArray(raw.sports)
            ? raw.sports.filter((s: unknown): s is string => typeof s === "string")
            : [],
          showRideCount: raw.show_ride_count === true || raw.showRideCount === true,
          rideCount: 0,
          regionLabel: String(raw.region_label ?? raw.regionLabel ?? "") || undefined,
          editorial: false,
        });
      })
      .catch(() => undefined);
    return () => {
      cancelled = true;
    };
  }, [handle, isSelf, editorial]);

  const profile: ViewProfile | null = isSelf
    ? {
        displayName: publicProfile.displayName || publicProfile.handle,
        handle: publicProfile.handle,
        bio: publicProfile.bio,
        sports: publicProfile.sports.length
          ? publicProfile.sports
          : preferredSport
            ? [preferredSport]
            : [],
        showRideCount: publicProfile.showRideCount,
        rideCount: rides.length,
        regionLabel: publicProfile.regionLabel,
        editorial: false,
      }
    : editorial
      ? {
          displayName: editorial.displayName,
          handle: editorial.handle,
          bio: editorial.bio,
          sports: editorial.sports,
          showRideCount: false,
          rideCount: 0,
          regionLabel: editorial.regionLabel,
          editorial: true,
        }
      : remote;

  const reviewsByAuthor = useMemo(() => {
    const fromEditorial = EDITORIAL_REVIEWS.filter(
      (r) => r.authorHandle?.toLowerCase() === handle,
    );
    const fromMine = isSelf
      ? myReviews.filter((r) => r.status !== "rejected")
      : [];
    return [...fromMine, ...fromEditorial];
  }, [handle, isSelf, myReviews]);

  if (!profile) {
    return (
      <div className="mx-auto max-w-lg px-4 py-20 text-center">
        <ChromeGlyph name="user" size={40} current className="mx-auto text-text-secondary" />
        <h1 className="mt-4 text-xl font-bold">{p.publicMissingTitle}</h1>
        <p className="mt-2 text-sm text-text-secondary">{p.publicMissingHint}</p>
        <div className="mt-6 flex flex-wrap justify-center gap-4 text-sm font-semibold text-chrome">
          <Link href="/profile#public-profile" className="hover:underline">
            {p.publicEnable}
          </Link>
          <Link href="/community" className="hover:underline">
            {chrome.marketingNav["/community"]}
          </Link>
        </div>
      </div>
    );
  }

  return (
    <div className="mx-auto max-w-lg px-4 py-10 sm:px-6">
      <p className="text-[11px] font-bold tracking-wide text-text-secondary">
        {profile.editorial ? p.publicEditorial : p.publicTitle}
      </p>
      <div className="mt-3 flex items-start gap-4">
        <div className="flex h-14 w-14 items-center justify-center rounded-2xl bg-chrome/15 text-chrome">
          <ChromeGlyph name="user" size={28} current />
        </div>
        <div>
          <h1 className="text-2xl font-bold">{profile.displayName}</h1>
          <p className="text-sm text-chrome">@{profile.handle}</p>
          {profile.regionLabel ? (
            <p className="mt-1 text-xs text-text-secondary">
              {profile.regionLabel}
            </p>
          ) : null}
        </div>
      </div>
      {profile.bio ? (
        <p className="mt-4 text-sm text-text-secondary">{profile.bio}</p>
      ) : null}
      <div className="mt-4 flex flex-wrap gap-2">
        {profile.sports.map((s) => (
          <span
            key={s}
            className="rounded-full bg-surface-elevated px-2.5 py-1 text-[11px] capitalize"
          >
            {publicDisciplineLabel(s, lang)}
          </span>
        ))}
        {profile.showRideCount ? (
          <span className="rounded-full border border-border px-2.5 py-1 text-[11px] text-text-secondary">
            {p.publicRidesAgg(profile.rideCount)}
          </span>
        ) : null}
      </div>
      <p className="mt-4 text-[11px] text-text-secondary">
        {p.publicNoHeatmap}
      </p>

      {reviewsByAuthor.length > 0 ? (
        <section className="mt-8">
          <h2 className="text-sm font-semibold">{p.publicStimmen}</h2>
          <ul className="mt-3 space-y-2">
            {reviewsByAuthor.map((r) => {
              const tour = getPublicTour(r.tourId);
              return (
                <li
                  key={r.id}
                  className="rounded-xl border border-border bg-surface p-3 text-sm"
                >
                  <Link
                    href={`/tours/${r.tourId}`}
                    className="font-medium text-chrome hover:underline"
                  >
                    {tour?.name ?? p.publicTour}
                  </Link>
                  <span className="text-text-secondary"> · {r.rating}★</span>
                  <p className="mt-1 text-xs text-text-secondary">{r.body}</p>
                </li>
              );
            })}
          </ul>
        </section>
      ) : null}

      <div className="mt-10 flex flex-wrap gap-3 text-sm">
        <Link href="/community" className="text-chrome hover:underline">
          {chrome.marketingNav["/community"]}
        </Link>
        <Link href="/share" className="text-chrome hover:underline">
          {chrome.share}
        </Link>
        <Link href="/discover" className="text-chrome hover:underline">
          {chrome.hofNav.karte}
        </Link>
      </div>
    </div>
  );
}
