"use client";

import { hofTitleFor } from "@/lib/home/hofTitle";
import { useChromeLang } from "@/hooks/useChromeLang";

/** Job word for Home — follows chrome language, not a separate navigator read. */
export function useHofTitle(): string {
  return hofTitleFor(null, useChromeLang());
}
