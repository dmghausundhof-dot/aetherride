"use client";

import Link from "next/link";
import {
  COMMUNITY_CLUBS,
  COMMUNITY_EVENTS,
} from "@/lib/community/seed";
import { EDITORIAL_PROFILES } from "@/lib/community/editorialProfiles";
import { getRegion } from "@/lib/catalog/regions";
import { getPublicTour } from "@/lib/catalog/publicTours";
import { tourHrefForEvent } from "@/lib/tours/tourFunctions";
import { ChromeGlyph } from "@/components/chrome/ChromeGlyph";
import { useChromeLang } from "@/hooks/useChromeLang";
import { communityCopy } from "@/lib/i18n/communityCopy";

export function CommunityPageBody() {
  const c = communityCopy(useChromeLang());

  return (
    <div className="px-4 py-12 sm:px-6">
      <div className="mx-auto max-w-4xl">
        <p className="text-[11px] font-bold tracking-wide text-text-secondary">{c.kicker}</p>
        <h1 className="mt-2 text-3xl font-bold tracking-tight sm:text-4xl">
          {c.title}
        </h1>
        <p className="mt-3 max-w-2xl text-text-secondary">{c.lead}</p>

        <div className="mt-8 grid gap-3 sm:grid-cols-2">
          {c.features.map((f) => (
            <Link
              key={f.href}
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
            <ChromeGlyph name="shield" size={20} current className="text-sage" />
            <p className="mt-2 font-medium">{c.privacyTitle}</p>
            <p className="mt-1 text-xs text-text-secondary">{c.privacyBody}</p>
          </div>
          <div className="rounded-xl border border-border bg-surface p-4 text-sm">
            <ChromeGlyph name="stimmen" size={20} current className="text-sage" />
            <p className="mt-2 font-medium">{c.moderationTitle}</p>
            <p className="mt-1 text-xs text-text-secondary">{c.moderationBody}</p>
          </div>
          <div className="rounded-xl border border-border bg-surface p-4 text-sm">
            <ChromeGlyph name="share" size={20} current className="text-success" />
            <p className="mt-2 font-medium">{c.linkTitle}</p>
            <p className="mt-1 text-xs text-text-secondary">{c.linkBody}</p>
          </div>
        </div>

        <section className="mt-12 rounded-2xl border border-border bg-surface p-6">
          <h2 className="text-lg font-semibold">{c.outTitle}</h2>
          <ul className="mt-3 grid gap-2 text-sm text-text-secondary sm:grid-cols-2">
            {c.out.map((line) => (
              <li key={line}>· {line}</li>
            ))}
          </ul>
        </section>

        <section id="events" className="mt-12 scroll-mt-24">
          <h2 className="flex items-center gap-2 text-xl font-bold">
            <ChromeGlyph name="calendar" size={20} current className="text-sage" />
            {c.eventsTitle}
          </h2>
          <p className="mt-1 text-sm text-text-secondary">{c.eventsLead}</p>
          <ul className="mt-4 space-y-3">
            {COMMUNITY_EVENTS.map((e) => {
              const region = getRegion(e.regionSlug);
              const tour = e.catalogTourId ? getPublicTour(e.catalogTourId) : null;
              return (
                <li
                  key={e.id}
                  className="rounded-2xl border border-border bg-surface p-5"
                >
                  <p className="text-[11px] font-medium uppercase tracking-wide text-text-secondary">
                    {e.sport} · {region?.name ?? e.regionSlug}
                  </p>
                  <h3 className="mt-1 text-lg font-semibold">{e.title}</h3>
                  <p className="mt-1 text-xs text-text-secondary">{e.dateLabel}</p>
                  <p className="mt-2 text-sm text-text-secondary">{e.blurb}</p>
                  <div className="mt-3 flex flex-wrap gap-3">
                    <Link
                      href={tourHrefForEvent(e)}
                      className="inline-block text-xs font-semibold text-chrome hover:underline"
                    >
                      {tour ? tour.name : c.regionCta} →
                    </Link>
                    {e.href && e.href !== tourHrefForEvent(e) ? (
                      <Link
                        href={e.href}
                        className="inline-block text-xs font-semibold text-chrome hover:underline"
                      >
                        {c.regionCta} →
                      </Link>
                    ) : null}
                  </div>
                </li>
              );
            })}
          </ul>
        </section>

        <section className="mt-12">
          <h2 className="flex items-center gap-2 text-xl font-bold">
            <ChromeGlyph name="users" size={20} current className="text-sage" />
            {c.clubsTitle}
          </h2>
          <p className="mt-1 text-sm text-text-secondary">{c.clubsLead}</p>
          <div className="mt-4 grid gap-3 sm:grid-cols-2">
            {COMMUNITY_CLUBS.map((club) => {
              const region = getRegion(club.regionSlug);
              return (
                <div
                  key={club.id}
                  className="rounded-2xl border border-border bg-surface p-5"
                >
                  <h3 className="font-semibold">{club.name}</h3>
                  <p className="mt-0.5 text-xs text-text-secondary">
                    {region?.name} · {club.sports.join(" · ")}
                  </p>
                  <p className="mt-2 text-sm text-text-secondary">{club.blurb}</p>
                  {club.href && (
                    <Link
                      href={club.href}
                      className="mt-3 inline-block text-xs font-semibold text-chrome hover:underline"
                    >
                      {c.clubsCta} →
                    </Link>
                  )}
                </div>
              );
            })}
          </div>
        </section>

        <section
          id="gruppen"
          className="mt-12 scroll-mt-24 rounded-2xl border border-border bg-surface p-6"
        >
          <h2 className="text-lg font-semibold">{c.groupsTitle}</h2>
          <p className="mt-2 text-sm text-text-secondary">{c.groupsBody}</p>
          <div className="mt-4 flex flex-wrap gap-3 text-sm font-semibold">
            <Link href="/library" className="text-text-secondary hover:text-chrome hover:underline">
              {c.toPlatz} →
            </Link>
            <Link href="/share" className="text-text-secondary hover:text-chrome hover:underline">
              {c.shareLinks} →
            </Link>
          </div>
        </section>

        <section id="profile" className="mt-12 scroll-mt-24">
          <h2 className="text-lg font-semibold">{c.profilesTitle}</h2>
          <p className="mt-1 text-sm text-text-secondary">{c.profilesLead}</p>
          <ul className="mt-4 grid gap-3 sm:grid-cols-2">
            {EDITORIAL_PROFILES.map((p) => (
              <li key={p.handle}>
                <Link
                  href={`/u/${p.handle}`}
                  className="block rounded-2xl border border-border bg-surface p-5 transition hover:border-chrome/40"
                >
                  <p className="font-semibold">{p.displayName}</p>
                  <p className="text-xs text-text-secondary">@{p.handle}</p>
                  <p className="mt-2 text-sm text-text-secondary">{p.bio}</p>
                  <p className="mt-3 text-xs font-semibold text-chrome">
                    {c.openProfile} →
                  </p>
                </Link>
              </li>
            ))}
          </ul>
        </section>

        <section className="mt-12 rounded-2xl border border-chrome/30 bg-chrome/10 p-6">
          <h2 className="text-lg font-semibold">{c.joinTitle}</h2>
          <ol className="mt-4 list-decimal space-y-2 pl-5 text-sm text-text-secondary">
            <li>
              {c.join1Before}{" "}
              <Link href="/regions" className="text-text-secondary hover:text-chrome hover:underline">
                {c.join1Link}
              </Link>{" "}
              {c.join1After}
            </li>
            <li>
              {c.join2Before}{" "}
              <Link href="/library" className="text-text-secondary hover:text-chrome hover:underline">
                Platz
              </Link>{" "}
              {c.join2After}
            </li>
            <li>
              {c.join3Before}{" "}
              <Link
                href="/profile#public-profile"
                className="text-text-secondary hover:text-chrome hover:underline"
              >
                Public Profile
              </Link>{" "}
              {c.join3Mid}{" "}
              <Link href="/u/mara_road" className="text-text-secondary hover:text-chrome hover:underline">
                mara_road
              </Link>
              {" · "}
              <Link href="/community#profile" className="text-text-secondary hover:text-chrome hover:underline">
                {c.join3All}
              </Link>
              .
            </li>
          </ol>
        </section>
      </div>
    </div>
  );
}
