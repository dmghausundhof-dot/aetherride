"use client";

import Link from "next/link";
import { HofPageHeader } from "@/components/hof/HofPageHeader";
import { useHofCopy } from "@/hooks/useHofCopy";

/** In-app cart retired — kasse is Shopify. */
export default function CheckoutPage() {
  const copy = useHofCopy();
  return (
    <div className="mx-auto max-w-lg px-5 py-10">
      <HofPageHeader
        kicker={copy.shopKicker}
        title={copy.checkoutTitle}
        hint={copy.checkoutHint}
      />
      <Link
        href="/shop"
        className="mt-6 inline-flex h-12 w-full items-center justify-center rounded-xl bg-chrome text-sm font-semibold text-on-accent"
      >
        {copy.shopTitle}
      </Link>
    </div>
  );
}
