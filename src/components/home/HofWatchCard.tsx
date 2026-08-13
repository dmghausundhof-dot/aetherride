"use client";

import Link from "next/link";
import { Watch } from "lucide-react";
import { HOF_COPY } from "@/lib/home/hofCopy";

/**
 * Rider-level watch strip. BLE pairing is native-only — web stays honest.
 */
export function HofWatchCard() {
  return (
    <section
      data-testid="hof-watch"
      className="rounded-2xl border border-border bg-surface px-4 py-3"
    >
      <div className="flex items-start gap-3">
        <Watch className="mt-0.5 h-5 w-5 shrink-0 text-text-secondary" aria-hidden />
        <div className="min-w-0 flex-1">
          <h2 className="text-sm font-extrabold">{HOF_COPY.yourWatch}</h2>
          <p className="mt-0.5 text-[13px] text-text-secondary">
            {HOF_COPY.watchHint}
          </p>
          <Link
            href="/download"
            className="mt-1 inline-block text-xs text-text-secondary hover:underline"
          >
            {HOF_COPY.watchOpenApp}
          </Link>
        </div>
      </div>
    </section>
  );
}
