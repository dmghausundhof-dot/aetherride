"use client";

import Link from "next/link";
import { useChromeLang } from "@/hooks/useChromeLang";
import { useHomepageCopy } from "@/hooks/useHomepageCopy";
import { listGuidesGroupedFor } from "@/lib/i18n/guidesCopy";
import { webChrome } from "@/lib/i18n/webChrome";

export function GuidesIndexBody() {
  const lang = useChromeLang();
  const h = useHomepageCopy();
  const chrome = webChrome(lang);
  const groups = listGuidesGroupedFor(lang);

  return (
    <div className="mx-auto max-w-3xl">
      <h1 className="text-3xl font-bold tracking-tight sm:text-4xl">
        {chrome.marketingNav["/guides"]}
      </h1>
      <p className="mt-3 text-text-secondary">{h.ui.guidesIndexLead}</p>
      <div className="mt-10 space-y-10">
        {groups.map((group) => (
          <section key={group.category}>
            <h2 className="text-sm font-semibold uppercase tracking-wide text-text-secondary">
              {group.label}
            </h2>
            <ul className="mt-3 space-y-3">
              {group.guides.map((g) => (
                <li key={g.slug}>
                  <Link
                    href={`/guides/${g.slug}`}
                    className="block rounded-2xl border border-border bg-surface p-5 transition hover:border-chrome/40"
                  >
                    <p className="text-[11px] text-text-secondary">
                      {h.ui.readMinLong(g.readMin)}
                    </p>
                    <h3 className="mt-1 text-lg font-semibold">{g.title}</h3>
                    <p className="mt-1 text-sm text-text-secondary">{g.teaser}</p>
                  </Link>
                </li>
              ))}
            </ul>
          </section>
        ))}
      </div>
    </div>
  );
}
