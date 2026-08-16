"use client";

import Link from "next/link";
import { CheckCircle2, Mail, Wrench } from "lucide-react";
import { useChromeLang } from "@/hooks/useChromeLang";
import { publicPagesCopy } from "@/lib/i18n/publicPagesCopy";

const WORKSHOP_MAIL =
  "mailto:hello@aetherride.app?subject=Werkstatt-Interesse%20Service-Check&body=Hallo%20FlowLine-Team%2C%0A%0Awir%20sind%20eine%20Werkstatt%20und%20interessieren%20uns%20f%C3%BCr%20den%20Service-Check.%0A%0AName%3A%0AOrt%3A%0AWebsite%3A%0A";

export function ServiceCheckSection() {
  const s = publicPagesCopy(useChromeLang()).serviceCheck;

  return (
    <section
      id="service-check"
      className="border-t border-border bg-surface py-16 px-4"
      aria-labelledby="service-check-heading"
    >
      <div className="mx-auto grid max-w-6xl items-center gap-10 lg:grid-cols-2 lg:gap-14">
        <div>
          <p className="text-sm font-medium uppercase tracking-wider text-text-secondary">
            {s.kicker}
          </p>
          <h2
            id="service-check-heading"
            className="mt-2 text-2xl font-bold sm:text-3xl"
          >
            {s.title}
          </h2>
          <p className="mt-4 text-text-secondary">{s.lead}</p>
          <ul className="mt-5 space-y-2 text-sm text-text-secondary">
            <li className="flex gap-2">
              <CheckCircle2 className="mt-0.5 h-4 w-4 shrink-0 text-success" />
              {s.free}
            </li>
            <li className="flex gap-2">
              <CheckCircle2 className="mt-0.5 h-4 w-4 shrink-0 text-success" />
              {s.sources}
            </li>
            <li className="flex gap-2">
              <CheckCircle2 className="mt-0.5 h-4 w-4 shrink-0 text-success" />
              {s.deepLink}
            </li>
          </ul>
          <div className="mt-8 flex flex-wrap gap-3">
            <Link
              href="/garage"
              className="inline-flex h-12 items-center justify-center rounded-xl border border-chrome/40 bg-chrome/10 px-6 text-sm font-semibold text-chrome hover:border-chrome"
            >
              {s.toWorkshop}
            </Link>
            <Link
              href="/garage?tab=maintenance"
              className="inline-flex h-12 items-center justify-center rounded-xl border border-border px-6 text-sm font-semibold hover:bg-background"
            >
              {s.toMaintenance}
            </Link>
          </div>
        </div>

        <div className="mx-auto w-full max-w-md">
          <div className="rounded-2xl border border-warning/40 bg-background p-5 shadow-lg shadow-black/20">
            <div className="flex items-start gap-3">
              <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-warning/15 text-warning">
                <Wrench className="h-5 w-5" />
              </div>
              <div>
                <p className="text-[10px] font-semibold uppercase tracking-wide text-text-secondary">
                  {s.demoKicker}
                </p>
                <h3 className="mt-0.5 text-lg font-semibold">{s.demoTitle}</h3>
                <p className="mt-1 text-sm text-text-secondary">{s.demoBody}</p>
              </div>
            </div>
            <div className="mt-4 h-1.5 overflow-hidden rounded-full bg-muted">
              <div className="h-full w-[82%] rounded-full bg-warning" />
            </div>
            <p className="mt-2 text-[11px] text-text-secondary">{s.demoFoot}</p>
            <Link
              href="/garage?tab=maintenance"
              className="mt-4 flex w-full items-center justify-center rounded-xl border border-chrome/40 bg-chrome/10 py-2.5 text-sm font-semibold text-chrome hover:border-chrome"
            >
              {s.ownStatus}
            </Link>
          </div>

          <div className="mt-6 rounded-2xl border border-border bg-background/60 p-5">
            <h3 className="flex items-center gap-2 font-semibold">
              <Mail className="h-4 w-4 text-accent" />
              {s.shopsTitle}
            </h3>
            <p className="mt-2 text-sm text-text-secondary">
              {s.shopsBodyBefore}{" "}
              <strong className="font-medium text-foreground">
                {s.shopsBodyStrong}
              </strong>{" "}
              {s.shopsBodyAfter}
            </p>
            <a
              href={WORKSHOP_MAIL}
              className="mt-4 inline-flex h-11 items-center justify-center rounded-xl border border-border px-5 text-sm font-semibold hover:border-accent/40 hover:bg-surface"
            >
              {s.shopsMail}
            </a>
          </div>
        </div>
      </div>
    </section>
  );
}
