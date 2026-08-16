"use client";

import { useHofCopy } from "@/hooks/useHofCopy";

export function AnmeldenIntro() {
  const copy = useHofCopy();
  return (
    <>
      <p className="text-[11px] font-bold tracking-wide text-text-secondary">
        {copy.profileKicker}
      </p>
      <h1 className="mt-2 text-3xl font-bold tracking-tight">
        {copy.profileArrive}
      </h1>
      <p className="mt-3 text-sm text-text-secondary">{copy.profileHint}</p>
    </>
  );
}
