"use client";

import { useHofCopy } from "@/hooks/useHofCopy";

export function ShopLoading() {
  const copy = useHofCopy();
  return (
    <div className="mx-auto max-w-2xl p-4 pt-6 text-sm text-text-secondary">
      {copy.shopTitle}…
    </div>
  );
}
