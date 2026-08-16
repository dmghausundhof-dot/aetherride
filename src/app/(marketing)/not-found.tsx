"use client";

import Link from "next/link";
import { webChrome } from "@/lib/i18n/webChrome";
import { useChromeLang } from "@/hooks/useChromeLang";

export default function MarketingNotFound() {
  const copy = webChrome(useChromeLang());
  return (
    <div className="px-4 py-20 sm:px-6">
      <div className="mx-auto max-w-lg text-center">
        <p className="text-[11px] font-bold tracking-wide text-text-secondary">404</p>
        <h1 className="mt-2 text-3xl font-bold tracking-tight">
          {copy.marketingNotFoundTitle}
        </h1>
        <p className="mt-3 text-sm text-text-secondary">
          {copy.marketingNotFoundHint}
        </p>
        <div className="mt-8 flex flex-wrap justify-center gap-3">
          <Link
            href="/"
            className="inline-flex h-12 items-center rounded-xl bg-chrome px-6 text-sm font-semibold text-on-accent"
          >
            {copy.start}
          </Link>
          <Link
            href="/regions"
            className="inline-flex h-12 items-center rounded-xl border border-border px-6 text-sm font-semibold"
          >
            {copy.marketingNav["/regions"]}
          </Link>
          <Link
            href="/faq"
            className="inline-flex h-12 items-center rounded-xl border border-border px-6 text-sm font-semibold"
          >
            {copy.faq}
          </Link>
          <Link
            href="/home"
            className="inline-flex h-12 items-center rounded-xl border border-border px-6 text-sm font-semibold"
          >
            {copy.toHof}
          </Link>
        </div>
      </div>
    </div>
  );
}
