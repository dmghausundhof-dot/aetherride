import type { Metadata } from "next";
import Image from "next/image";
import Link from "next/link";
import {
  FLOWLINE_ABOUT,
  FLOWLINE_PILLAR,
  FLOWLINE_TAGLINE,
  FLOWLINE_TAGLINE_DOTS,
} from "@/lib/content/brand";
import { PRODUCT_DOORS } from "@/lib/content/productMap";
import {
  ABOUT_REFUSALS,
  ABOUT_STATUS,
  ABOUT_STORY,
} from "@/lib/content/aboutPage";
import { legalContactEmail } from "@/lib/legal/siteLegal";

export const metadata: Metadata = {
  title: "Über FlowLine",
  description:
    "Warum FlowLine einen Hof hat und keinen Feed. Outdoor Cycling im Browser planen, in der App fahren. Fünf Türen, ehrlicher Stand.",
};

export default function AboutPage() {
  const email = legalContactEmail();

  return (
    <div>
      <section className="border-b border-border bg-surface px-4 py-16 sm:px-6">
        <div className="mx-auto grid max-w-6xl items-center gap-10 lg:grid-cols-2">
          <div>
            <p className="text-[11px] font-bold tracking-wide text-chrome">
              {FLOWLINE_ABOUT.kicker}
            </p>
            <h1 className="mt-2 text-3xl font-bold tracking-tight sm:text-4xl">
              {FLOWLINE_ABOUT.title}
            </h1>
            <p className="mt-2 text-[0.7rem] font-medium uppercase tracking-[0.16em] text-text-secondary">
              {FLOWLINE_TAGLINE_DOTS}
            </p>
            <p className="mt-4 max-w-xl text-text-secondary">
              {FLOWLINE_ABOUT.lead}
            </p>
            <p className="mt-4 text-sm font-medium text-foreground/90">
              {FLOWLINE_PILLAR}
            </p>
            <p className="mt-2 text-sm text-text-secondary">{FLOWLINE_TAGLINE}</p>
            <p className="mt-3 max-w-xl text-sm text-text-secondary">
              Gebaut für Fahrerinnen und Fahrer. Gezeichnet für Fokus. Gemacht
              für die Fahrt — nicht für die Timeline.
            </p>
            <div className="mt-8 flex flex-wrap gap-3">
              <Link
                href="/home"
                className="inline-flex h-12 items-center rounded-xl bg-chrome px-6 text-sm font-semibold text-background"
              >
                Zum Hof
              </Link>
              <Link
                href="/produkt"
                className="inline-flex h-12 items-center rounded-xl border border-border px-6 text-sm font-semibold"
              >
                Produkt
              </Link>
              <Link
                href="/kontakt"
                className="inline-flex h-12 items-center rounded-xl border border-border px-6 text-sm font-semibold"
              >
                Kontakt
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
            <p className="text-[11px] font-bold tracking-wide text-chrome">
              {ABOUT_STORY.kicker}
            </p>
            <h2 className="mt-2 text-2xl font-bold tracking-tight sm:text-3xl">
              {ABOUT_STORY.title}
            </h2>
          </div>
          <div className="space-y-4 text-sm leading-relaxed text-text-secondary lg:col-span-8">
            {ABOUT_STORY.paragraphs.map((p) => (
              <p key={p.slice(0, 28)}>{p}</p>
            ))}
          </div>
        </div>
      </section>

      <section className="border-t border-border bg-surface px-4 py-16 sm:px-6">
        <div className="mx-auto max-w-6xl">
          <h2 className="text-2xl font-bold">Drei Sätze aus dem Style Guide</h2>
          <div className="mt-8 grid gap-4 md:grid-cols-3">
            {FLOWLINE_ABOUT.pillars.map((p) => (
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
          <h2 className="text-2xl font-bold">Was wir nicht bauen</h2>
          <p className="mt-2 max-w-2xl text-sm text-text-secondary">
            Absicht, kein Feature-Rückstand. Die Homepage sagt das in Klartext.
          </p>
          <div className="mt-8 grid gap-4 md:grid-cols-3">
            {ABOUT_REFUSALS.map((item) => (
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
          <h2 className="text-2xl font-bold">Fünf Türen, keine sechste</h2>
          <p className="mt-2 max-w-xl text-sm text-text-secondary">
            Dieselbe IA wie in der App. Ride bleibt der Knopf, nicht der Tab.
          </p>
          <ul className="mt-8 grid gap-3 sm:grid-cols-2 lg:grid-cols-5">
            {PRODUCT_DOORS.map((door) => (
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
          <h2 className="text-2xl font-bold">{ABOUT_STATUS.title}</h2>
          <p className="mt-4 text-sm leading-relaxed text-text-secondary">
            {ABOUT_STATUS.body}
          </p>
          <p className="mt-4 text-sm text-text-secondary">
            E-Mail:{" "}
            <a href={`mailto:${email}`} className="font-semibold text-chrome hover:underline">
              {email}
            </a>
            {" · "}
            <Link href="/legal/impressum" className="text-chrome hover:underline">
              Impressum
            </Link>
            {" · "}
            <Link href="/faq" className="text-chrome hover:underline">
              FAQ
            </Link>
          </p>
        </div>
      </section>
    </div>
  );
}
