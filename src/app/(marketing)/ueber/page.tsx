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

export const metadata: Metadata = {
  title: "Über FlowLine",
  description:
    "Outdoor Cycling, simplified. Hof im Browser, Fahrt in der App. Fünf Türen, kein Feed.",
};

export default function AboutPage() {
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
        <div className="mx-auto max-w-6xl">
          <h2 className="text-2xl font-bold">Drei Sätze aus dem Style Guide</h2>
          <div className="mt-8 grid gap-4 md:grid-cols-3">
            {FLOWLINE_ABOUT.pillars.map((p) => (
              <article
                key={p.title}
                className="rounded-2xl border border-border bg-surface p-6"
              >
                <h3 className="font-semibold">{p.title}</h3>
                <p className="mt-2 text-sm text-text-secondary">{p.body}</p>
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
    </div>
  );
}
