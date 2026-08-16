"use client";

import Link from "next/link";
import { SHARE_DEMO_TOKEN } from "@/lib/community/shareCodec";
import { useChromeLang } from "@/hooks/useChromeLang";
import { shareCopy } from "@/lib/i18n/shareCopy";
import { webChrome } from "@/lib/i18n/webChrome";

export function ShareIndexBody() {
  const lang = useChromeLang();
  const s = shareCopy(lang);
  const chrome = webChrome(lang);

  return (
    <div className="px-4 py-12 sm:px-6">
      <div className="mx-auto max-w-3xl">
        <p className="text-[11px] font-bold tracking-wide text-text-secondary">
          {s.kicker}
        </p>
        <h1 className="mt-2 text-3xl font-bold tracking-tight sm:text-4xl">
          {s.title}
        </h1>
        <p className="mt-3 max-w-2xl text-text-secondary">{s.lead}</p>

        <div className="mt-10 grid gap-4 sm:grid-cols-2">
          <article className="rounded-2xl border border-border bg-surface p-6">
            <h2 className="font-semibold">{s.tourTitle}</h2>
            <p className="mt-2 text-sm text-text-secondary">{s.tourBody}</p>
            <Link
              href={`/share/t/${SHARE_DEMO_TOKEN}`}
              className="mt-4 inline-block text-sm font-semibold text-text-secondary hover:text-chrome hover:underline"
            >
              {s.openSampleTour}
            </Link>
          </article>
          <article className="rounded-2xl border border-border bg-surface p-6">
            <h2 className="font-semibold">{s.mappeTitle}</h2>
            <p className="mt-2 text-sm text-text-secondary">{s.mappeBody}</p>
            <Link
              href={`/share/c/${SHARE_DEMO_TOKEN}`}
              className="mt-4 inline-block text-sm font-semibold text-text-secondary hover:text-chrome hover:underline"
            >
              {s.openSampleMappe}
            </Link>
          </article>
        </div>

        <ol className="mt-12 list-decimal space-y-3 pl-5 text-sm text-text-secondary">
          <li>
            {s.step1Before}{" "}
            <Link href="/regions" className="text-text-secondary hover:text-chrome hover:underline">
              {s.step1Regions}
            </Link>{" "}
            {s.step1Mid}{" "}
            <Link href="/library" className="text-text-secondary hover:text-chrome hover:underline">
              Platz
            </Link>
            {s.step1After}
          </li>
          <li>{s.step2}</li>
          <li>{s.step3}</li>
        </ol>

        <p className="mt-8 text-sm text-text-secondary">
          {s.foot}{" "}
          <Link
            href="/guides/teilen-per-link"
            className="text-text-secondary hover:text-chrome hover:underline"
          >
            {s.guideShare}
          </Link>
          {" · "}
          <Link href="/community" className="text-text-secondary hover:text-chrome hover:underline">
            {chrome.marketingNav["/community"]}
          </Link>
          {" · "}
          <Link href="/u/mara_road" className="text-text-secondary hover:text-chrome hover:underline">
            {chrome.sampleProfile}
          </Link>
          {" · "}
          <Link href="/faq" className="text-text-secondary hover:text-chrome hover:underline">
            {chrome.faq}
          </Link>
        </p>
      </div>
    </div>
  );
}
