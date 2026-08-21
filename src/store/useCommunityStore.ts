"use client";

/**
 * Lokale Community-Daten (Reviews, Public Profile, Share-Meta).
 * Persistiert im Browser — Server-Moderation später austauschbar.
 */

import { create } from "zustand";
import { persist } from "zustand/middleware";
import { v4 as uuidv4 } from "uuid";
import type {
  PublicProfileSettings,
  TourReview,
} from "@/lib/community/types";
import { EDITORIAL_REVIEWS } from "@/lib/community/seed";
import { parseStimmeTags } from "@/lib/community/stimmeTags";

const MAX_BODY = 500;

const defaultPublicProfile: PublicProfileSettings = {
  enabled: false,
  handle: "",
  displayName: "",
  bio: "",
  sports: [],
  showRideCount: true,
  showPreferredSports: true,
  regionLabel: "",
};

type CommunityState = {
  /** User-submitted reviews (pending until moderation — local: visible to self) */
  myReviews: TourReview[];
  publicProfile: PublicProfileSettings;
  /** collectionId → last share token */
  collectionShareTokens: Record<string, string>;

  submitReview: (input: {
    tourId: string;
    rating: 1 | 2 | 3 | 4 | 5;
    body: string;
    authorLabel?: string;
    tags?: string[];
  }) => TourReview | { error: string };
  removeMyReview: (id: string) => void;
  updatePublicProfile: (patch: Partial<PublicProfileSettings>) => void;
  setCollectionShareToken: (collectionId: string, token: string) => void;
};

export function approvedReviewsForTour(tourId: string, myReviews: TourReview[]) {
  const editorial = EDITORIAL_REVIEWS.filter(
    (r) => r.tourId === tourId && r.status === "approved"
  );
  const mine = myReviews.filter(
    (r) =>
      r.tourId === tourId &&
      (r.status === "approved" || r.status === "pending")
  );
  return [...mine, ...editorial].sort(
    (a, b) =>
      new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime()
  );
}

export function averageRating(reviews: TourReview[]): number | null {
  const rated = reviews.filter((r) => r.status === "approved" || r.editorial);
  if (!rated.length) return null;
  const sum = rated.reduce((s, r) => s + r.rating, 0);
  return Math.round((sum / rated.length) * 10) / 10;
}

export const useCommunityStore = create<CommunityState>()(
  persist(
    (set, get) => ({
      myReviews: [],
      publicProfile: defaultPublicProfile,
      collectionShareTokens: {},

      submitReview: (input) => {
        const body = input.body.trim().slice(0, MAX_BODY);
        if (body.length < 8) {
          return { error: "Bitte mindestens 8 Zeichen schreiben." };
        }
        if (input.rating < 1 || input.rating > 5) {
          return { error: "Bewertung 1–5." };
        }
        const profile = get().publicProfile;
        const tags = parseStimmeTags(input.tags);
        const review: TourReview = {
          id: `ur-${uuidv4()}`,
          tourId: input.tourId,
          authorLabel:
            input.authorLabel?.trim() ||
            profile.displayName?.trim() ||
            "Du",
          authorHandle: profile.enabled ? profile.handle || undefined : undefined,
          rating: input.rating,
          body,
          createdAt: new Date().toISOString(),
          // Lokal: pending = sichtbar nur dir, wartet auf Server-Moderation
          status: "pending",
          ...(tags.length ? { tags } : {}),
        };
        set((s) => ({ myReviews: [review, ...s.myReviews] }));
        return review;
      },

      removeMyReview: (id) =>
        set((s) => ({
          myReviews: s.myReviews.filter((r) => r.id !== id),
        })),

      updatePublicProfile: (patch) =>
        set((s) => {
          const next = { ...s.publicProfile, ...patch };
          if (next.handle) {
            next.handle = next.handle
              .toLowerCase()
              .replace(/[^a-z0-9_]/g, "")
              .slice(0, 24);
          }
          next.bio = (next.bio ?? "").slice(0, 280);
          next.displayName = (next.displayName ?? "").slice(0, 40);
          return { publicProfile: next };
        }),

      setCollectionShareToken: (collectionId, token) =>
        set((s) => ({
          collectionShareTokens: {
            ...s.collectionShareTokens,
            [collectionId]: token,
          },
        })),
    }),
    {
      name: "aetherride-community-v1",
      partialize: (s) => ({
        myReviews: s.myReviews,
        publicProfile: s.publicProfile,
        collectionShareTokens: s.collectionShareTokens,
      }),
    }
  )
);
