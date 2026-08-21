"use client";

import Link from "next/link";
import { ChevronRight } from "lucide-react";
import { ChromeGlyph } from "@/components/chrome/ChromeGlyph";
import { useHofCopy } from "@/hooks/useHofCopy";

/**
 * Rider-level watch strip. BLE pairing is native-only — web stays honest.
 * Layout matches native unpaired HofWatchCard: title, hint, chevron.
 */
export function HofWatchCard() {
  const copy = useHofCopy();

  return (
    <Link
      href="/download"
      data-testid="hof-watch"
      className="mt-3 flex items-center gap-2 py-2 text-text-secondary hover:text-chrome"
    >
      <ChromeGlyph name="watch" size={18} current className="shrink-0" />
      <span className="min-w-0 flex-1">
        <span className="block text-[13px] font-bold">{copy.watchOpenApp}</span>
        <span className="block truncate text-xs">{copy.watchHint}</span>
      </span>
      <ChevronRight className="h-[18px] w-[18px] shrink-0" aria-hidden />
    </Link>
  );
}
