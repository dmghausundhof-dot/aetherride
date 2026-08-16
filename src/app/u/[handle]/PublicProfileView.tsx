"use client";

/**
 * Public Profile light — Opt-in aus local store oder Editorial-Handle.
 */
import { useMemo } from "react";
import Link from "next/link";
import { useCommunityStore } from "@/store/useCommunityStore";
import { useAppStore } from "@/store/useAppStore";
import { EDITORIAL_REVIEWS } from "@/lib/community/seed";
import { getEditorialProfile } from "@/lib/community/editorialProfiles";
import { getPublicTour } from "@/lib/catalog/publicTours";
import { User } from "lucide-react";

export function PublicProfileView({ handle }: { handle: string }) {
  const publicProfile = useCommunityStore((s) => s.publicProfile);
  const myReviews = useCommunityStore((s) => s.myReviews);
  const rides = useAppStore((s) => s.rides);
  const preferredSport = useAppStore((s) => s.preferredSport);

  const isSelf =
    publicProfile.enabled &&
    publicProfile.handle &&
    publicProfile.handle === handle;

  const editorial = getEditorialProfile(handle);

  const profile = isSelf
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
      : null;

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
        <User className="mx-auto h-10 w-10 text-text-secondary" />
        <h1 className="mt-4 text-xl font-bold">Profil nicht öffentlich</h1>
        <p className="mt-2 text-sm text-text-secondary">
          Dieses Handle ist nicht freigeschaltet oder existiert nicht. Public
          Profiles sind Opt-in und speichern keine Tracks.
        </p>
        <div className="mt-6 flex flex-wrap justify-center gap-4 text-sm font-semibold text-chrome">
          <Link href="/profile#public-profile" className="hover:underline">
            Eigenes Profil freigeben
          </Link>
          <Link href="/community" className="hover:underline">
            Community
          </Link>
        </div>
      </div>
    );
  }

  return (
    <div className="mx-auto max-w-lg px-4 py-10 sm:px-6">
      <p className="text-[11px] font-bold tracking-wide text-text-secondary">
        {profile.editorial ? "Editorial-Beispiel" : "Public Profile"}
      </p>
      <div className="mt-3 flex items-start gap-4">
        <div className="flex h-14 w-14 items-center justify-center rounded-2xl bg-chrome/15 text-chrome">
          <User className="h-7 w-7" />
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
            {s.replace(/_/g, " ")}
          </span>
        ))}
        {profile.showRideCount ? (
          <span className="rounded-full border border-border px-2.5 py-1 text-[11px] text-text-secondary">
            {profile.rideCount} Fahrten (aggregiert, ohne Spur)
          </span>
        ) : null}
      </div>
      <p className="mt-4 text-[11px] text-text-secondary">
        Keine Heatmaps, keine Roh-GPS-Daten auf diesem Profil.
      </p>

      {reviewsByAuthor.length > 0 ? (
        <section className="mt-8">
          <h2 className="text-sm font-semibold">Stimmen</h2>
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
                    {tour?.name ?? "Tour"}
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
          Community
        </Link>
        <Link href="/share" className="text-chrome hover:underline">
          Teilen
        </Link>
        <Link href="/discover" className="text-chrome hover:underline">
          Karte
        </Link>
      </div>
    </div>
  );
}
