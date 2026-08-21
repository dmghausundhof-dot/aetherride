"use client";

import Link from "next/link";
import { ChromeGlyph } from "@/components/chrome/ChromeGlyph";
import { DoorIcon } from "@/components/landing/DoorIcon";
import { ScreenGallery } from "@/components/landing/ScreenGallery";
import { useChromeLang } from "@/hooks/useChromeLang";
import { useHomepageCopy } from "@/hooks/useHomepageCopy";
import { productCopy } from "@/lib/i18n/productCopy";
import { webChrome } from "@/lib/i18n/webChrome";

export function ProduktPageBody() {
  const lang = useChromeLang();
  const p = productCopy(lang);
  const h = useHomepageCopy();
  const chrome = webChrome(lang);

  return (
    <div>
      <section className="border-b border-border bg-surface px-4 py-16 sm:px-6">
        <div className="mx-auto max-w-6xl">
          <p className="text-[11px] font-bold tracking-wide text-text-secondary">
            {p.ui.kicker}
          </p>
          <h1 className="mt-2 max-w-3xl text-3xl font-bold tracking-tight sm:text-4xl">
            {p.ui.title}
          </h1>
          <p className="mt-4 max-w-2xl text-text-secondary">{p.ui.lead}</p>
          <div className="mt-8 flex flex-wrap gap-3">
            <Link
              href="/home"
              className="inline-flex h-12 items-center rounded-xl bg-chrome px-6 text-sm font-semibold text-on-accent"
            >
              {chrome.toHof}
            </Link>
            <Link
              href="/download"
              className="inline-flex h-12 items-center rounded-xl border border-border px-6 text-sm font-semibold"
            >
              {chrome.loadApp}
            </Link>
            <Link
              href="/anmelden"
              className="inline-flex h-12 items-center rounded-xl border border-border px-6 text-sm font-semibold"
            >
              {chrome.signIn}
            </Link>
          </div>
        </div>
      </section>

      <section className="px-4 py-16 sm:px-6">
        <div className="mx-auto max-w-6xl">
          <h2 className="text-2xl font-bold">{h.ui.doorsTitle}</h2>
          <p className="mt-2 max-w-xl text-sm text-text-secondary">{p.ui.doorsLead}</p>
          <div className="mt-8 grid gap-3 sm:grid-cols-2 lg:grid-cols-5">
            {p.doors.map((door, i) => {
              return (
                <Link
                  key={door.href}
                  href={door.href}
                  className="rounded-2xl border border-border bg-surface p-5 transition hover:border-chrome/50"
                >
                  <DoorIcon index={i} />
                  <h3 className="mt-3 font-semibold">{door.title}</h3>
                  <p className="mt-1 text-sm text-text-secondary">{door.body}</p>
                </Link>
              );
            })}
          </div>
        </div>
      </section>

      <ScreenGallery heading={p.ui.galleryHeading} hint={p.ui.galleryHint} />

      <section className="border-t border-border bg-surface px-4 py-16 sm:px-6">
        <div className="mx-auto grid max-w-6xl gap-6 md:grid-cols-2">
          <div className="rounded-2xl border border-border bg-background/60 p-8">
            <ChromeGlyph name="karte" size={32} current className="text-sage" />
            <h2 className="mt-4 text-xl font-bold">{h.ui.onWebsite}</h2>
            <ul className="mt-4 space-y-3 text-sm text-text-secondary">
              {h.webSurfaces.map((s) => (
                <li key={s.title}>
                  <span className="font-medium text-foreground">{s.title}.</span>{" "}
                  {s.body}
                </li>
              ))}
            </ul>
          </div>
          <div className="rounded-2xl border border-border bg-background/60 p-8">
            <ChromeGlyph name="phone" size={32} current className="text-sage" />
            <h2 className="mt-4 text-xl font-bold">{h.ui.inApp}</h2>
            <ul className="mt-4 space-y-3 text-sm text-text-secondary">
              {h.appSurfaces.map((s) => (
                <li key={s.title}>
                  <span className="font-medium text-foreground">{s.title}.</span>{" "}
                  {s.body}
                </li>
              ))}
            </ul>
          </div>
        </div>
      </section>

      <section className="px-4 py-16 sm:px-6">
        <div className="mx-auto max-w-6xl">
          <h2 className="text-2xl font-bold">{p.ui.whereRuns}</h2>
          <div className="mt-8 overflow-x-auto rounded-2xl border border-border">
            <table className="w-full min-w-[420px] text-left text-sm">
              <thead>
                <tr className="border-b border-border bg-surface">
                  <th className="px-4 py-3 font-semibold">{p.ui.colSurface}</th>
                  <th className="px-4 py-3 font-semibold">{p.ui.colWeb}</th>
                  <th className="px-4 py-3 font-semibold">{p.ui.colApp}</th>
                </tr>
              </thead>
              <tbody>
                {p.matrix.map((row) => (
                  <tr key={row.feature} className="border-b border-border/80">
                    <td className="px-4 py-3 text-text-secondary">{row.feature}</td>
                    <td className="px-4 py-3">{row.web}</td>
                    <td className="px-4 py-3">{row.app}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </section>

      <section className="border-t border-border bg-surface px-4 py-16 sm:px-6">
        <div className="mx-auto max-w-3xl">
          <h2 className="text-center text-2xl font-bold">{p.ui.journeyTitle}</h2>
          <ol className="mt-12 space-y-8">
            {h.journeySteps.map((s) => (
              <li key={s.n} className="flex gap-4">
                <span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full border border-border text-lg font-bold text-foreground">
                  {s.n}
                </span>
                <div>
                  <h3 className="font-semibold">{s.title}</h3>
                  <p className="mt-1 text-sm text-text-secondary">{s.body}</p>
                </div>
              </li>
            ))}
          </ol>
        </div>
      </section>

      <section className="px-4 py-16 sm:px-6">
        <div className="mx-auto max-w-6xl">
          <h2 className="text-2xl font-bold">{p.ui.processes}</h2>
          <p className="mt-2 max-w-xl text-sm text-text-secondary">
            {p.ui.processesLead}
          </p>
          <div className="mt-8 grid gap-4 lg:grid-cols-2">
            {p.workflows.map((flow) => (
              <article
                key={flow.id}
                className="rounded-2xl border border-border bg-surface p-6"
              >
                <h3 className="font-semibold">{flow.title}</h3>
                <p className="mt-1 text-sm text-text-secondary">{flow.hint}</p>
                <ol className="mt-4 flex flex-wrap gap-2">
                  {flow.steps.map((step, i) => (
                    <li key={step.href} className="flex items-center gap-2">
                      {i > 0 ? (
                        <span className="text-text-secondary" aria-hidden>
                          →
                        </span>
                      ) : null}
                      <Link
                        href={step.href}
                        className="rounded-full border border-border px-3 py-1 text-xs font-semibold hover:border-chrome hover:text-chrome"
                      >
                        {step.label}
                      </Link>
                    </li>
                  ))}
                </ol>
              </article>
            ))}
          </div>
        </div>
      </section>

      <section className="border-t border-border bg-surface px-4 py-16 sm:px-6">
        <div className="mx-auto max-w-6xl">
          <h2 className="text-2xl font-bold">{p.ui.allScreens}</h2>
          <p className="mt-2 max-w-xl text-sm text-text-secondary">
            {p.ui.allScreensLead}
          </p>
          <div className="mt-10 space-y-10">
            {p.screenGroups.map((group) => (
              <div key={group.title}>
                <h3 className="text-lg font-semibold">{group.title}</h3>
                <p className="mt-1 text-sm text-text-secondary">{group.hint}</p>
                <ul className="mt-4 grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
                  {group.screens.map((screen) => (
                    <li key={`${group.title}-${screen.href}`}>
                      <Link
                        href={screen.href}
                        className="block rounded-2xl border border-border bg-background/60 p-4 transition hover:border-chrome/40"
                      >
                        <p className="font-medium">{screen.name}</p>
                        <p className="mt-1 text-xs text-text-secondary">
                          {screen.role}
                        </p>
                      </Link>
                    </li>
                  ))}
                </ul>
              </div>
            ))}
          </div>
        </div>
      </section>

      <section className="px-4 py-16 sm:px-6">
        <div className="mx-auto max-w-2xl text-center">
          <h2 className="text-2xl font-bold">{h.cta.title}</h2>
          <p className="mt-4 text-text-secondary">{p.ui.ctaLead}</p>
          <div className="mt-8 flex flex-wrap justify-center gap-3">
            <Link
              href="/home"
              className="inline-flex h-12 items-center rounded-xl bg-chrome px-8 text-sm font-semibold text-on-accent"
            >
              {chrome.toHof}
            </Link>
            <Link
              href="/download"
              className="inline-flex h-12 items-center rounded-xl border border-border px-6 text-sm font-semibold"
            >
              {chrome.loadApp}
            </Link>
          </div>
        </div>
      </section>
    </div>
  );
}
