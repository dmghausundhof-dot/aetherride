"use client";

import { useAppStore } from "@/store/useAppStore";
import { User, Sparkles, Settings } from "lucide-react";
import Link from "next/link";

export default function ProfilePage() {
  const profile = useAppStore((s) => s.riderProfile);
  const rides = useAppStore((s) => s.rides);
  const bikes = useAppStore((s) => s.bikes);

  return (
    <div className="flex flex-col gap-5 p-4 pt-6">
      <header className="flex items-center gap-3">
        <div className="flex h-14 w-14 items-center justify-center rounded-full bg-accent text-xl font-bold text-white">
          AR
        </div>
        <div>
          <h1 className="text-xl font-bold">Rider Profil</h1>
          <p className="text-sm text-text-secondary">KI-gestütztes Fahrerprofil</p>
        </div>
      </header>

      <section className="rounded-2xl bg-surface border border-border p-4">
        <h3 className="mb-3 flex items-center gap-2 font-semibold">
          <User className="h-4 w-4 text-accent" /> Fahrstil
        </h3>
        <div className="grid grid-cols-2 gap-3 text-sm">
          <div>
            <div className="text-text-secondary text-xs">Style</div>
            <div className="font-medium capitalize">{profile.style}</div>
          </div>
          <div>
            <div className="text-text-secondary text-xs">Skill Level</div>
            <div className="font-medium">{profile.skillLevel} / 5</div>
          </div>
          <div>
            <div className="text-text-secondary text-xs">Ø Ride Dauer</div>
            <div className="font-medium tabular-nums">
              {profile.fitnessIndicators.avgRideDurationMin} min
            </div>
          </div>
          <div>
            <div className="text-text-secondary text-xs">Wochen-km</div>
            <div className="font-medium tabular-nums">
              {profile.fitnessIndicators.weeklyDistanceKm} km
            </div>
          </div>
        </div>
      </section>

      <section className="rounded-2xl bg-surface border border-border p-4">
        <h3 className="mb-3 flex items-center gap-2 font-semibold">
          <Sparkles className="h-4 w-4 text-accent" /> Präferenzen
        </h3>
        <div className="flex flex-wrap gap-2">
          {profile.preferences.preferTechnical && (
            <span className="rounded-full bg-primary/30 px-3 py-1 text-xs">Technisch</span>
          )}
          {profile.preferences.preferFlow && (
            <span className="rounded-full bg-primary/30 px-3 py-1 text-xs">Flow</span>
          )}
          {profile.preferences.preferSteep && (
            <span className="rounded-full bg-primary/30 px-3 py-1 text-xs">Steil</span>
          )}
          <span className="rounded-full bg-primary/30 px-3 py-1 text-xs capitalize">
            Assist: {profile.preferences.eBikeAssistPreference}
          </span>
        </div>
      </section>

      <section className="grid grid-cols-2 gap-3">
        <div className="rounded-xl bg-surface border border-border p-3 text-center">
          <div className="tabular-nums text-2xl font-bold">{bikes.length}</div>
          <div className="text-xs text-text-secondary">Bikes</div>
        </div>
        <div className="rounded-xl bg-surface border border-border p-3 text-center">
          <div className="tabular-nums text-2xl font-bold">{rides.length}</div>
          <div className="text-xs text-text-secondary">Rides</div>
        </div>
      </section>

      <div className="rounded-xl border border-dashed border-border p-4 text-center text-sm text-text-secondary">
        <Settings className="mx-auto mb-2 h-8 w-8 opacity-40" />
        Natürliche Sprachschnittstelle & erweiterte KI in Produktion
      </div>

      <Link href="/" className="text-center text-sm text-accent">
        ← Zurück
      </Link>
    </div>
  );
}
