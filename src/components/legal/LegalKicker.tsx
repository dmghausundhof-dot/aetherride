"use client";

import { useHofCopy } from "@/hooks/useHofCopy";

export function LegalKicker() {
  const copy = useHofCopy();
  return (
    <p className="text-[11px] font-bold tracking-wide text-text-secondary">
      {copy.legalKicker}
    </p>
  );
}
