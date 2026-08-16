"use client";

import Link from "next/link";
import { useChromeLang } from "@/hooks/useChromeLang";
import { useHomepageCopy } from "@/hooks/useHomepageCopy";
import { faqItems } from "@/lib/i18n/faqCopy";
import { webChrome } from "@/lib/i18n/webChrome";

export function FaqPageBody() {
  const lang = useChromeLang();
  const h = useHomepageCopy();
  const chrome = webChrome(lang);
  const items = faqItems(lang);

  return (
    <div className="mx-auto max-w-3xl">
      <p className="text-[11px] font-bold tracking-wide text-text-secondary">
        {h.ui.faqKicker}
      </p>
      <h1 className="mt-2 text-3xl font-bold tracking-tight sm:text-4xl">
        {h.ui.faqTitle}
      </h1>
      <p className="mt-3 max-w-2xl text-text-secondary">{h.ui.faqPageLead}</p>

      <dl className="mt-10 space-y-4">
        {items.map((item) => (
          <div
            key={item.id}
            className="rounded-2xl border border-border bg-surface p-5"
          >
            <dt className="font-semibold">{item.q}</dt>
            <dd className="mt-2 text-sm text-text-secondary">{item.a}</dd>
            {item.links && item.links.length > 0 ? (
              <dd className="mt-3 flex flex-wrap gap-3">
                {item.links.map((link) => (
                  <Link
                    key={link.href}
                    href={link.href}
                    className="text-xs font-semibold text-text-secondary hover:text-chrome hover:underline"
                  >
                    {link.label} →
                  </Link>
                ))}
              </dd>
            ) : null}
          </div>
        ))}
      </dl>

      <p className="mt-10 text-sm text-text-secondary">
        {h.ui.faqPageMoreBefore}{" "}
        <Link href="/produkt" className="font-semibold text-text-secondary hover:text-chrome hover:underline">
          {chrome.marketingNav["/produkt"]}
        </Link>
        .
      </p>
    </div>
  );
}
