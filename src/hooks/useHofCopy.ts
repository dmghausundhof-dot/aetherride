"use client";

import { useChromeLang } from "@/hooks/useChromeLang";
import { hofCopy } from "@/lib/home/hofCopy";

/** Hof chrome in the resolved UI language. */
export function useHofCopy() {
  return hofCopy(useChromeLang());
}
