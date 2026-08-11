"use client";

/**
 * Public Profile light — nur Opt-in aus local store (gleicher Browser)
 * oder bekannte Editorial-Handles aus Reviews.
 */
import { useMemo } from "react";
import Link from "next/link";
import { useParams } from "next/navigation";
import { useCommunityStore } from "@/store/useCommunityStore";
import { useAppStore } from "@/store/useAppStore";
import { EDITORIAL_REVIEWS } from "@/lib/community/seed";
import { User } from "lucide-react";

export default function PublicProfilePage() {
  const params = useParams();
  const handle = (
    typeof params.handle === "string" ? params.handle : ""
  ).toLowerCase();

  const publicProfile = useCommunityStore((s) => s.publicProfile);
  const myReviews = useCommunityStore((s) => s.myReviews);
  const rides = useAppStore((s) => s.rides);
  const preferredSport = useAppStore((s) => s.preferredSport);

  const isSelf =
    publicProfile.enabled &&
    publicProfile.handle &&
    publicProfile.handle === handle;

  const editorialAuthor = useMemo(() => {
    const r = EDITORIAL_REVIEWS.find(
      (x) => x.authorHandle?.toLowerCase() === handle
    );
    if (!r) return null;
    return {
      displayName: r.authorLabel,
      handle: r.authorHandle!,
      bio: "Community-Beispielprofil (Editorial).",
      sports: r.sportHint ? [r.sportHint] : [],
    };
  }, [handle]);

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
      }
    : editorialAuthor
      ? {
          displayName: editorialAuthor.displayName,
          handle: editorialAuthor.handle,
          bio: editorialAuthor.bio,
          sports: editorialAuthor.sports,
          showRideCount: false,
          rideCount: 0,
          regionLabel: undefined as string | undefined,
        }
      : null;

  const reviewsByAuthor = useMemo(() => {
    const fromEditorial = EDITORIAL_REVIEWS.filter(
      (r) => r.authorHandle?.toLowerCase() === handle
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
        <Link
          href="/profile#public-profile"
          className="mt-6 inline-block text-sm font-semibold text-accent"
        >
          Eigenes Profil freigeben →
        </Link>
      </div>
    );
  }

  return (
    <div className="mx-auto max-w-lg px-4 py-10 sm:px-6">
      <div className="flex items-start gap-4">
        <div className="flex h-14 w-14 items-center justify-center rounded-2xl bg-accent/15 text-accent">
          <User className="h-7 w-7" />
        </div>
        <div>
          <h1 className="text-2xl font-bold">{profile.displayName}</h1>
          <p className="text-sm text-accent">@{profile.handle}</p>
          {profile.regionLabel && (
            <p className="mt-1 text-xs text-text-secondary">
              {profile.regionLabel}
            </p>
          )}
        </div>
      </div>
      {profile.bio && (
        <p className="mt-4 text-sm text-text-secondary">{profile.bio}</p>
      )}
      <div className="mt-4 flex flex-wrap gap-2">
        {profile.sports.map((s) => (
          <span
            key={s}
            className="rounded-full bg-surface-elevated px-2.5 py-1 text-[11px] capitalize"
          >
            {s.replace(/_/g, " ")}
          </span>
        ))}
        {profile.showRideCount && (
          <span className="rounded-full border border-border px-2.5 py-1 text-[11px] text-text-secondary">
            {profile.rideCount} Rides (aggregiert)
          </span>
        )}
      </div>
      <p className="mt-4 text-[11px] text-text-secondary">
        Keine Heatmaps, keine Roh-GPS-Daten auf diesem Profil.
      </p>

      {reviewsByAuthor.length > 0 && (
        <section className="mt-8">
          <h2 className="text-sm font-semibold">Reviews</h2>
          <ul className="mt-3 space-y-2">
            {reviewsByAuthor.map((r) => (
              <li
                key={r.id}
                className="rounded-xl border border-border bg-surface p-3 text-sm"
              >
                <Link
                  href={`/tours/${r.tourId}`}
                  className="font-medium text-accent hover:underline"
                >
                  Tour
                </Link>
                <span className="text-text-secondary"> · {r.rating}★</span>
                <p className="mt-1 text-xs text-text-secondary">{r.body}</p>
              </li>
            ))}
          </ul>
        </section>
      )}

      <div className="mt-10 flex flex-wrap gap-3 text-sm">
        <Link href="/community" className="text-accent hover:underline">
          Community
        </Link>
        <Link href="/discover" className="text-accent hover:underline">
          Explore
        </Link>
      </div>
    </div>
  );
}
