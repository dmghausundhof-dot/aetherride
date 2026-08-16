"use client";

import Link from "next/link";
import { useChromeLang } from "@/hooks/useChromeLang";
import { useHomepageCopy } from "@/hooks/useHomepageCopy";
import { guideCategoryLabel, guideFor } from "@/lib/i18n/guidesCopy";
import { webChrome } from "@/lib/i18n/webChrome";

export function GuideArticleBody({ slug }: { slug: string }) {
  const lang = useChromeLang();
  const h = useHomepageCopy();
  const chrome = webChrome(lang);
  const g = guideFor(slug, lang);
  if (!g) return null;
  const category = guideCategoryLabel(lang)[g.category];

  return (
    <>
      <div className="text-xs text-text-secondary">
        <Link href="/guides" className="hover:text-chrome">
          {chrome.marketingNav["/guides"]}
        </Link>
        <span className="mx-1.5">/</span>
        <span>{category}</span>
      </div>
      <h1 className="mt-4 text-3xl font-bold tracking-tight sm:text-4xl">
        {g.title}
      </h1>
      <p className="mt-3 text-text-secondary">{g.teaser}</p>
      <p className="mt-2 text-[11px] text-text-secondary">
        {h.ui.readMinLong(g.readMin)}
      </p>
      <div className="mt-10 space-y-5 text-sm leading-relaxed text-foreground/95">
        {g.body.map((p, i) => (
          <p key={i} className="text-text-secondary">
            {p}
          </p>
        ))}
      </div>
      {g.relatedHrefs && g.relatedHrefs.length > 0 && (
        <div className="mt-12 rounded-2xl border border-border bg-surface p-5">
          <h2 className="text-sm font-semibold">{h.ui.related}</h2>
          <ul className="mt-3 space-y-2">
            {g.relatedHrefs.map((r) => (
              <li key={r.href}>
                <Link
                  href={r.href}
                  className="text-sm font-medium text-text-secondary hover:text-chrome hover:underline"
                >
                  {r.label} →
                </Link>
              </li>
            ))}
          </ul>
        </div>
      )}
    </>
  );
}
