"use client";

import Image from "next/image";
import Link from "next/link";
import {
  FLOWLINE_PILLAR,
  FLOWLINE_TAGLINE,
  FLOWLINE_TAGLINE_DOTS,
} from "@/lib/content/brand";
import { legalContactEmail } from "@/lib/legal/siteLegal";
import { useChromeLang } from "@/hooks/useChromeLang";
import { aboutCopy } from "@/lib/i18n/aboutCopy";
import { productCopy } from "@/lib/i18n/productCopy";
import { webChrome } from "@/lib/i18n/webChrome";

export function AboutPageBody() {
  const lang = useChromeLang();
  const a = aboutCopy(lang);
  const doors = productCopy(lang).doors;
  const chrome = webChrome(lang);
  const email = legalContactEmail();

  return (
    <div>
      <section className="border-b border-border bg-surface px-4 py-16 sm:px-6">
        <div className="mx-auto grid max-w-6xl items-center gap-10 lg:grid-cols-2">
          <div>
            <p className="text-[11px] font-bold tracking-wide text-text-secondary">
              {a.brand.kicker}
            </p>
            <h1 className="mt-2 text-3xl font-bold tracking-tight sm:text-4xl">
              {a.brand.title}
            </h1>
            <p className="mt-2 text-[0.7rem] font-medium uppercase tracking-[0.16em] text-text-secondary">
              {FLOWLINE_TAGLINE_DOTS}
            </p>
            <p className="mt-4 max-w-xl text-text-secondary">{a.brand.lead}</p>
            <p className="mt-4 text-sm font-medium text-foreground/90">
              {FLOWLINE_PILLAR}
            </p>
            <p className="mt-2 text-sm text-text-secondary">{FLOWLINE_TAGLINE}</p>
            <p className="mt-3 max-w-xl text-sm text-text-secondary">
              {a.brand.madeFor}
            </p>
            <div className="mt-8 flex flex-wrap gap-3">
              <Link
                href="/home"
                className="inline-flex h-12 items-center rounded-xl bg-chrome px-6 text-sm font-semibold text-on-accent"
              >
                {chrome.toHof}
              </Link>
              <Link
                href="/produkt"
                className="inline-flex h-12 items-center rounded-xl border border-border px-6 text-sm font-semibold"
              >
                {chrome.marketingNav["/produkt"]}
              </Link>
              <Link
                href="/kontakt"
                className="inline-flex h-12 items-center rounded-xl border border-border px-6 text-sm font-semibold"
              >
                {chrome.contact}
              </Link>
            </div>
          </div>
          <div className="relative aspect-[16/10] overflow-hidden rounded-2xl border border-border bg-background">
            <Image
              src="/brand/logo-lockup.jpg"
              alt="FlowLine Lockup: Outdoor · Cycling · Flow"
              fill
              className="object-cover"
              sizes="(min-width: 1024px) 50vw, 100vw"
              priority
            />
          </div>
        </div>
      </section>

      <section className="px-4 py-16 sm:px-6">
        <div className="mx-auto grid max-w-6xl gap-10 lg:grid-cols-12">
          <div className="lg:col-span-4">
            <p className="text-[11px] font-bold tracking-wide text-text-secondary">
              {a.story.kicker}
            </p>
            <h2 className="mt-2 text-2xl font-bold tracking-tight sm:text-3xl">
              {a.story.title}
            </h2>
          </div>
          <div className="space-y-4 text-sm leading-relaxed text-text-secondary lg:col-span-8">
            {a.story.paragraphs.map((p, i) => (
              <p key={i}>{p}</p>
            ))}
          </div>
        </div>
      </section>

      <section className="border-t border-border bg-surface px-4 py-16 sm:px-6">
        <div className="mx-auto max-w-6xl">
          <h2 className="text-2xl font-bold">{a.brand.pillarsTitle}</h2>
          <div className="mt-8 grid gap-4 md:grid-cols-3">
            {a.brand.pillars.map((p) => (
              <article
                key={p.title}
                className="rounded-2xl border border-border bg-background/60 p-6"
              >
                <h3 className="font-semibold">{p.title}</h3>
                <p className="mt-2 text-sm text-text-secondary">{p.body}</p>
              </article>
            ))}
          </div>
        </div>
      </section>

      <section className="px-4 py-16 sm:px-6">
        <div className="mx-auto max-w-6xl">
          <h2 className="text-2xl font-bold">{a.refusalsTitle}</h2>
          <p className="mt-2 max-w-2xl text-sm text-text-secondary">
            {a.refusalsLead}
          </p>
          <div className="mt-8 grid gap-4 md:grid-cols-3">
            {a.refusals.map((item) => (
              <article
                key={item.title}
                className="rounded-2xl border border-border bg-surface p-6"
              >
                <h3 className="font-semibold">{item.title}</h3>
                <p className="mt-2 text-sm leading-relaxed text-text-secondary">
                  {item.body}
                </p>
              </article>
            ))}
          </div>
        </div>
      </section>

      <section className="border-t border-border bg-surface px-4 py-16 sm:px-6">
        <div className="mx-auto max-w-6xl">
          <h2 className="text-2xl font-bold">{a.doorsTitle}</h2>
          <p className="mt-2 max-w-xl text-sm text-text-secondary">{a.doorsLead}</p>
          <ul className="mt-8 grid gap-3 sm:grid-cols-2 lg:grid-cols-5">
            {doors.map((door) => (
              <li key={door.href}>
                <Link
                  href={door.href}
                  className="block h-full rounded-2xl border border-border bg-background/60 p-5 transition hover:border-chrome/40"
                >
                  <p className="font-semibold">{door.title}</p>
                  <p className="mt-2 text-sm text-text-secondary">{door.body}</p>
                </Link>
              </li>
            ))}
          </ul>
        </div>
      </section>

      <section className="px-4 py-16 sm:px-6">
        <div className="mx-auto max-w-3xl">
          <h2 className="text-2xl font-bold">{a.status.title}</h2>
          <p className="mt-4 text-sm leading-relaxed text-text-secondary">
            {a.status.body}
          </p>
          <p className="mt-4 text-sm text-text-secondary">
            {chrome.contact}:{" "}
            <a
              href={`mailto:${email}`}
              className="font-semibold text-text-secondary hover:text-chrome hover:underline"
            >
              {email}
            </a>
            {" · "}
            <Link href="/legal/impressum" className="text-text-secondary hover:text-chrome hover:underline">
              {chrome.imprint}
            </Link>
            {" · "}
            <Link href="/faq" className="text-text-secondary hover:text-chrome hover:underline">
              {chrome.faq}
            </Link>
          </p>
        </div>
      </section>
    </div>
  );
}
