"use client";

import Link from "next/link";
import { HofEmpty } from "@/components/hof/HofEmpty";
import { MARKETING_NAV } from "@/lib/nav/marketingNav";
import { webChrome } from "@/lib/i18n/webChrome";
import { useChromeLang } from "@/hooks/useChromeLang";

export default function NotFound() {
  const copy = webChrome(useChromeLang());
  return (
    <div className="hof-safe-page mx-auto flex min-h-dvh max-w-lg flex-col justify-center px-5 py-16">
      <HofEmpty
        title={copy.notFoundTitle}
        hint={copy.notFoundHint}
        showDoors
      />
      <div className="mt-6 flex flex-col gap-3">
        <Link
          href="/home"
          className="inline-flex h-12 items-center justify-center rounded-xl bg-chrome text-sm font-semibold text-on-accent"
        >
          {copy.toHof}
        </Link>
        <Link
          href="/"
          className="inline-flex h-12 items-center justify-center rounded-xl border border-border text-sm font-semibold"
        >
          {copy.toWebsite}
        </Link>
      </div>
      <nav
        className="mt-6 flex flex-wrap justify-center gap-3 text-xs font-semibold text-chrome"
        aria-label={copy.websiteAria}
      >
        {MARKETING_NAV.slice(0, 4).map((item) => (
          <Link key={item.href} href={item.href} className="hover:underline">
            {copy.marketingNav[item.href]}
          </Link>
        ))}
        <Link href="/faq" className="hover:underline">
          {copy.faq}
        </Link>
      </nav>
    </div>
  );
}
