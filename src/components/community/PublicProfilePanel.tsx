"use client";

import { useCallback, useEffect, useState } from "react";
import Link from "next/link";
import { useCommunityStore } from "@/store/useCommunityStore";
import type { PublicProfileSettings } from "@/lib/community/types";

const SPORT_OPTS = [
  "road",
  "gravel",
  "mtb",
  "urban",
  "ebike",
  "touring",
] as const;

function fromApi(raw: Record<string, unknown>): PublicProfileSettings {
  return {
    enabled: raw.enabled === true,
    handle: String(raw.handle ?? ""),
    displayName: String(raw.display_name ?? raw.displayName ?? ""),
    bio: String(raw.bio ?? ""),
    sports: Array.isArray(raw.sports)
      ? raw.sports.filter((s): s is string => typeof s === "string")
      : [],
    showRideCount: raw.show_ride_count !== false && raw.showRideCount !== false,
    showPreferredSports: raw.show_preferred_sports !== false,
    regionLabel: String(raw.region_label ?? raw.regionLabel ?? ""),
  };
}

export function PublicProfilePanel() {
  const publicProfile = useCommunityStore((s) => s.publicProfile);
  const updatePublicProfile = useCommunityStore((s) => s.updatePublicProfile);
  const [syncNote, setSyncNote] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    let cancelled = false;
    void fetch("/api/community/profile", { credentials: "include" })
      .then((r) => (r.ok ? r.json() : null))
      .then((data) => {
        if (cancelled || !data?.profile) return;
        updatePublicProfile(fromApi(data.profile as Record<string, unknown>));
        setSyncNote("Mit dem Konto synchronisiert.");
      })
      .catch(() => undefined);
    return () => {
      cancelled = true;
    };
  }, [updatePublicProfile]);

  const persist = useCallback(
    async (next: PublicProfileSettings) => {
      updatePublicProfile(next);
      const handle = next.handle.trim().toLowerCase();
      if (handle.length < 3) {
        setSyncNote("Handle mindestens 3 Zeichen, dann speichert der Server.");
        return;
      }
      setSaving(true);
      try {
        const res = await fetch("/api/community/profile", {
          method: "PUT",
          credentials: "include",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            handle,
            displayName: next.displayName,
            bio: next.bio,
            sports: next.sports,
            showRideCount: next.showRideCount,
            regionLabel: next.regionLabel,
            enabled: next.enabled,
          }),
        });
        if (res.status === 401) {
          setSyncNote("Anmelden, damit das Profil auf anderen Geräten erscheint.");
          return;
        }
        if (!res.ok) {
          const body = (await res.json().catch(() => ({}))) as {
            error?: string;
          };
          setSyncNote(
            body.error === "invalid_handle"
              ? "Handle: a–z, 0–9, Unterstrich, 3–24 Zeichen."
              : "Server hat nicht gespeichert — lokal bleibt der Stand.",
          );
          return;
        }
        setSyncNote("Gespeichert. Sichtbar unter /u/" + handle + ".");
      } catch {
        setSyncNote("Netz fehlt — Stand bleibt in diesem Browser.");
      } finally {
        setSaving(false);
      }
    },
    [updatePublicProfile],
  );

  const toggleSport = (s: string) => {
    const has = publicProfile.sports.includes(s);
    void persist({
      ...publicProfile,
      sports: has
        ? publicProfile.sports.filter((x) => x !== s)
        : [...publicProfile.sports, s],
    });
  };

  return (
    <section
      id="public-profile"
      className="rounded-2xl border border-border bg-surface p-4"
    >
      <h3 className="mb-1 font-semibold">Öffentliches Profil</h3>
      <p className="mb-3 text-xs text-text-secondary">
        Opt-in · keine Tracks · Handle für Stimmen und geteilte Sammlungen.
        Mit Konto liegt es auf dem Server, nicht nur in diesem Browser.
      </p>
      {syncNote ? (
        <p className="mb-3 text-xs text-chrome">{syncNote}</p>
      ) : null}
      <label className="flex items-center gap-2 text-sm">
        <input
          type="checkbox"
          checked={publicProfile.enabled}
          onChange={(e) =>
            void persist({ ...publicProfile, enabled: e.target.checked })
          }
        />
        Profil öffentlich schalten
      </label>
      <div className="mt-3 grid gap-2 sm:grid-cols-2">
        <label className="text-xs text-text-secondary">
          Anzeigename
          <input
            value={publicProfile.displayName}
            onChange={(e) =>
              updatePublicProfile({ displayName: e.target.value })
            }
            onBlur={() => void persist(publicProfile)}
            className="mt-1 w-full rounded-lg border border-border bg-background px-2 py-2 text-sm text-foreground"
            maxLength={40}
          />
        </label>
        <label className="text-xs text-text-secondary">
          Handle (a-z, 0-9, _)
          <input
            value={publicProfile.handle}
            onChange={(e) => updatePublicProfile({ handle: e.target.value })}
            onBlur={() => void persist(publicProfile)}
            className="mt-1 w-full rounded-lg border border-border bg-background px-2 py-2 text-sm text-foreground"
            placeholder="max_road"
            maxLength={24}
          />
        </label>
      </div>
      <label className="mt-2 block text-xs text-text-secondary">
        Bio
        <textarea
          value={publicProfile.bio}
          onChange={(e) => updatePublicProfile({ bio: e.target.value })}
          onBlur={() => void persist(publicProfile)}
          rows={2}
          className="mt-1 w-full rounded-lg border border-border bg-background px-2 py-2 text-sm text-foreground"
          maxLength={280}
        />
      </label>
      <label className="mt-2 block text-xs text-text-secondary">
        Region (Text)
        <input
          value={publicProfile.regionLabel ?? ""}
          onChange={(e) =>
            updatePublicProfile({ regionLabel: e.target.value })
          }
          onBlur={() => void persist(publicProfile)}
          className="mt-1 w-full rounded-lg border border-border bg-background px-2 py-2 text-sm text-foreground"
          placeholder="z. B. Baden-Württemberg"
        />
      </label>
      <div className="mt-3">
        <p className="text-xs text-text-secondary">Disziplinen</p>
        <div className="mt-1 flex flex-wrap gap-1.5">
          {SPORT_OPTS.map((s) => (
            <button
              key={s}
              type="button"
              onClick={() => toggleSport(s)}
              className={`rounded-full px-2.5 py-1 text-[11px] font-medium ${
                publicProfile.sports.includes(s)
                  ? "bg-accent text-on-accent"
                  : "bg-surface-elevated text-text-secondary"
              }`}
            >
              {s}
            </button>
          ))}
        </div>
      </div>
      <label className="mt-3 flex items-center gap-2 text-xs text-text-secondary">
        <input
          type="checkbox"
          checked={publicProfile.showRideCount}
          onChange={(e) =>
            void persist({
              ...publicProfile,
              showRideCount: e.target.checked,
            })
          }
        />
        Ride-Anzahl anzeigen (nur Zahl, keine Tracks)
      </label>
      {publicProfile.enabled && publicProfile.handle ? (
        <Link
          href={`/u/${publicProfile.handle}`}
          className="mt-3 inline-block text-sm font-semibold text-accent hover:underline"
        >
          Profil ansehen → /u/{publicProfile.handle}
        </Link>
      ) : null}
      {saving ? (
        <p className="mt-2 text-[11px] text-text-secondary">Speichert…</p>
      ) : null}
    </section>
  );
}
