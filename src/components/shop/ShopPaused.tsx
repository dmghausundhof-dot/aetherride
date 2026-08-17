"use client";

import Link from "next/link";
import { HofPageHeader } from "@/components/hof/HofPageHeader";
import { useHofCopy } from "@/hooks/useHofCopy";

/** Web-Laden-UI aus (`NEXT_PUBLIC_SHOP_ENABLED=false`) — Katalog und Kasse pausiert. */
export function ShopPaused() {
  const copy = useHofCopy();
  return (
    <div className="mx-auto max-w-lg px-5 py-10">
      <HofPageHeader
        kicker={copy.shopKicker}
        title={copy.shopPausedTitle}
        hint={copy.shopPausedHint}
      />
      <Link
        href="/garage"
        className="mt-6 inline-flex h-12 w-full items-center justify-center rounded-xl bg-chrome text-sm font-semibold text-on-accent"
      >
        {copy.workshopTitle}
      </Link>
    </div>
  );
}
