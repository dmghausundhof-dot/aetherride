"use client";

import Link from "next/link";
import { useCommunityStore } from "@/store/useCommunityStore";

const SPORT_OPTS = [
  "road",
  "gravel",
  "mtb",
  "urban",
  "ebike",
  "touring",
] as const;

export function PublicProfilePanel() {
  const publicProfile = useCommunityStore((s) => s.publicProfile);
  const updatePublicProfile = useCommunityStore((s) => s.updatePublicProfile);

  const toggleSport = (s: string) => {
    const has = publicProfile.sports.includes(s);
    updatePublicProfile({
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
        Sichtbar unter /u/dein_handle in diesem Browser (Server-Sync folgt).
      </p>
      <label className="flex items-center gap-2 text-sm">
        <input
          type="checkbox"
          checked={publicProfile.enabled}
          onChange={(e) =>
            updatePublicProfile({ enabled: e.target.checked })
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
            className="mt-1 w-full rounded-lg border border-border bg-background px-2 py-2 text-sm text-foreground"
            maxLength={40}
          />
        </label>
        <label className="text-xs text-text-secondary">
          Handle (a-z, 0-9, _)
          <input
            value={publicProfile.handle}
            onChange={(e) =>
              updatePublicProfile({ handle: e.target.value })
            }
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
                  ? "bg-accent text-white"
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
            updatePublicProfile({ showRideCount: e.target.checked })
          }
        />
        Ride-Anzahl anzeigen (nur Zahl, keine Tracks)
      </label>
      {publicProfile.enabled && publicProfile.handle && (
        <Link
          href={`/u/${publicProfile.handle}`}
          className="mt-3 inline-block text-sm font-semibold text-accent hover:underline"
        >
          Profil ansehen → /u/{publicProfile.handle}
        </Link>
      )}
    </section>
  );
}
