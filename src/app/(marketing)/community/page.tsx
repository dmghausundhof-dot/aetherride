import type { Metadata } from "next";
import Link from "next/link";
import {
  COMMUNITY_CLUBS,
  COMMUNITY_EVENTS,
} from "@/lib/community/seed";
import { COMMUNITY_FEATURES, COMMUNITY_OUT } from "@/lib/content/communityMap";
import { getRegion } from "@/lib/catalog/regions";
import { Users, Calendar, Shield, MessageSquare, Share2 } from "lucide-react";

export const metadata: Metadata = {
  title: "Community – Platz, Stimmen, Gruppen",
  description:
    "FlowLine-Community hängt an der Tour: Stimmen, Mappe, Gruppen und Public Profile. Kein Feed auf dem Hof.",
};

export default function CommunityPage() {
  return (
    <div className="px-4 py-12 sm:px-6">
      <div className="mx-auto max-w-4xl">
        <p className="text-[11px] font-bold tracking-wide text-chrome">
          Community
        </p>
        <h1 className="mt-2 text-3xl font-bold tracking-tight sm:text-4xl">
          Am Platz, nicht im Feed
        </h1>
        <p className="mt-3 max-w-2xl text-text-secondary">
          FlowLine teilt Touren, Stimmen und Gruppen. Es gibt keine Timeline auf
          dem Hof und kein Live-GPS vor dem Tor. Die Tür heißt Platz.
        </p>

        <div className="mt-8 grid gap-3 sm:grid-cols-2">
          {COMMUNITY_FEATURES.map((f) => (
            <Link
              key={f.title}
              href={f.href}
              className="rounded-2xl border border-border bg-surface p-5 transition hover:border-chrome/40"
            >
              <h2 className="font-semibold">{f.title}</h2>
              <p className="mt-2 text-sm text-text-secondary">{f.body}</p>
              <p className="mt-3 text-xs font-semibold text-chrome">{f.cta} →</p>
            </Link>
          ))}
        </div>

        <div className="mt-8 grid gap-3 sm:grid-cols-3">
          <div className="rounded-xl border border-border bg-surface p-4 text-sm">
            <Shield className="h-5 w-5 text-chrome" />
            <p className="mt-2 font-medium">Privacy-first</p>
            <p className="mt-1 text-xs text-text-secondary">
              Keine Tracks in Stimmen. Public Profile nur mit Opt-in.
            </p>
          </div>
          <div className="rounded-xl border border-border bg-surface p-4 text-sm">
            <MessageSquare className="h-5 w-5 text-accent" />
            <p className="mt-2 font-medium">Moderation</p>
            <p className="mt-1 text-xs text-text-secondary">
              Neue Stimmen starten „in Prüfung“. Editorial ist gekennzeichnet.
            </p>
          </div>
          <div className="rounded-xl border border-border bg-surface p-4 text-sm">
            <Share2 className="h-5 w-5 text-success" />
            <p className="mt-2 font-medium">Link statt Feed</p>
            <p className="mt-1 text-xs text-text-secondary">
              Sammlung oder Gruppe per Link. Wer ihn hat, ist dabei.
            </p>
          </div>
        </div>

        <section className="mt-12 rounded-2xl border border-border bg-surface p-6">
          <h2 className="text-lg font-semibold">Was Community hier nicht ist</h2>
          <ul className="mt-3 grid gap-2 text-sm text-text-secondary sm:grid-cols-2">
            {COMMUNITY_OUT.map((line) => (
              <li key={line}>· {line}</li>
            ))}
          </ul>
        </section>

        <section id="events" className="mt-12 scroll-mt-24">
          <h2 className="flex items-center gap-2 text-xl font-bold">
            <Calendar className="h-5 w-5 text-chrome" />
            Kommende Events
          </h2>
          <p className="mt-1 text-sm text-text-secondary">
            Redaktionell. Kein erfundenes RSVP.
          </p>
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
          <h2 className="flex items-center gap-2 text-xl font-bold">
            <Users className="h-5 w-5 text-chrome" />
            Clubs light
          </h2>
          <p className="mt-1 text-sm text-text-secondary">
            Orientierung — keine Live-Mitgliedschaftspflicht.
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

        <section className="mt-12 rounded-2xl border border-chrome/30 bg-chrome/10 p-6">
          <h2 className="text-lg font-semibold">So machst du mit</h2>
          <ol className="mt-4 list-decimal space-y-2 pl-5 text-sm text-text-secondary">
            <li>
              Tour auf der{" "}
              <Link href="/regions" className="text-chrome hover:underline">
                Karte oder Region
              </Link>{" "}
              öffnen und eine Stimme hinterlassen.
            </li>
            <li>
              Auf dem{" "}
              <Link href="/library" className="text-chrome hover:underline">
                Platz
              </Link>{" "}
              eine Sammlung teilen oder eine Gruppe mit Code starten.
            </li>
            <li>
              Optional ein{" "}
              <Link
                href="/profile#public-profile"
                className="text-chrome hover:underline"
              >
                Public Profile
              </Link>{" "}
              anlegen — Beispiel:{" "}
              <Link href="/u/mara_road" className="text-chrome hover:underline">
                mara_road
              </Link>
              .
            </li>
          </ol>
        </section>
      </div>
    </div>
  );
}
