import type { Metadata } from "next";
import Link from "next/link";
import { LandingHeader } from "@/components/landing/LandingHeader";
import { LandingFooter } from "@/components/landing/LandingFooter";
import {
  COMMUNITY_CLUBS,
  COMMUNITY_EVENTS,
} from "@/lib/community/seed";
import { getRegion } from "@/lib/catalog/regions";
import { Users, Calendar, Shield } from "lucide-react";

export const metadata: Metadata = {
  title: "Community – Clubs, Events & geteilte Touren",
  description:
    "AetherRide Community light: Events, Clubs und geteilte Sammlungen — Privacy-first, moderierte Reviews.",
};

export default function CommunityPage() {
  return (
    <div className="flex min-h-screen flex-col">
      <LandingHeader />
      <main className="flex-1 px-4 py-12 sm:px-6">
        <div className="mx-auto max-w-4xl">
          <h1 className="text-3xl font-bold tracking-tight sm:text-4xl">
            Community
          </h1>
          <p className="mt-3 max-w-2xl text-text-secondary">
            Kontrolliert und ehrlich: Events und Clubs als Orientierung,
            Tour-Reviews mit Moderation, Sammlungen teilen ohne Social-Feed-Spam.
          </p>

          <div className="mt-6 grid gap-3 sm:grid-cols-3">
            <div className="rounded-xl border border-border bg-surface p-4 text-sm">
              <Shield className="h-5 w-5 text-accent" />
              <p className="mt-2 font-medium">Privacy-first</p>
              <p className="mt-1 text-xs text-text-secondary">
                Keine Tracks in Reviews. Public Profile nur mit Opt-in.
              </p>
            </div>
            <div className="rounded-xl border border-border bg-surface p-4 text-sm">
              <Users className="h-5 w-5 text-accent" />
              <p className="mt-2 font-medium">Moderation</p>
              <p className="mt-1 text-xs text-text-secondary">
                Neue Reviews starten „in Prüfung“, Editorial klar gelabelt.
              </p>
            </div>
            <div className="rounded-xl border border-border bg-surface p-4 text-sm">
              <Calendar className="h-5 w-5 text-accent" />
              <p className="mt-2 font-medium">Events light</p>
              <p className="mt-1 text-xs text-text-secondary">
                Lokale Treffen ohne Zwang zu Live-Standort-Sharing.
              </p>
            </div>
          </div>

          <section className="mt-12">
            <h2 className="text-xl font-bold">Kommende Events</h2>
            <ul className="mt-4 space-y-3">
              {COMMUNITY_EVENTS.map((e) => {
                const region = getRegion(e.regionSlug);
                return (
                  <li
                    key={e.id}
                    className="rounded-2xl border border-border bg-surface p-5"
                  >
                    <p className="text-[11px] font-medium uppercase tracking-wide text-accent">
                      {e.sport} · {region?.name ?? e.regionSlug}
                    </p>
                    <h3 className="mt-1 text-lg font-semibold">{e.title}</h3>
                    <p className="mt-1 text-xs text-text-secondary">
                      {e.dateLabel}
                    </p>
                    <p className="mt-2 text-sm text-text-secondary">{e.blurb}</p>
                    {e.href && (
                      <Link
                        href={e.href}
                        className="mt-3 inline-block text-xs font-semibold text-accent hover:underline"
                      >
                        Region ansehen →
                      </Link>
                    )}
                  </li>
                );
              })}
            </ul>
          </section>

          <section className="mt-12">
            <h2 className="text-xl font-bold">Clubs light</h2>
            <p className="mt-1 text-sm text-text-secondary">
              Orientierung — keine Live-Mitgliedschaftspflicht. Kontakte über
              regionale Communitys.
            </p>
            <div className="mt-4 grid gap-3 sm:grid-cols-2">
              {COMMUNITY_CLUBS.map((c) => {
                const region = getRegion(c.regionSlug);
                return (
                  <div
                    key={c.id}
                    className="rounded-2xl border border-border bg-surface p-5"
                  >
                    <h3 className="font-semibold">{c.name}</h3>
                    <p className="mt-0.5 text-xs text-text-secondary">
                      {region?.name} · {c.sports.join(" · ")}
                    </p>
                    <p className="mt-2 text-sm text-text-secondary">{c.blurb}</p>
                    {c.href && (
                      <Link
                        href={c.href}
                        className="mt-3 inline-block text-xs font-semibold text-accent hover:underline"
                      >
                        Touren in der Region →
                      </Link>
                    )}
                  </div>
                );
              })}
            </div>
          </section>

          <section className="mt-12 rounded-2xl border border-border bg-surface p-6">
            <h2 className="text-lg font-semibold">Mitmachen</h2>
            <ul className="mt-3 space-y-2 text-sm text-text-secondary">
              <li>
                · Review auf einer{" "}
                <Link href="/regions" className="text-accent hover:underline">
                  Tour-Seite
                </Link>{" "}
                schreiben
              </li>
              <li>
                · Sammlung in der{" "}
                <Link href="/library" className="text-accent hover:underline">
                  Bibliothek
                </Link>{" "}
                teilen
              </li>
              <li>
                · Optionales{" "}
                <Link href="/profile#public-profile" className="text-accent hover:underline">
                  Public Profile
                </Link>{" "}
                aktivieren
              </li>
            </ul>
          </section>
        </div>
      </main>
      <LandingFooter />
    </div>
  );
}
