"use client";

import { useChromeLang } from "@/hooks/useChromeLang";
import { hofCopy } from "@/lib/home/hofCopy";

/** Browser UI language after mount — DE until then. */
export function useHofCopy() {
  return hofCopy(useChromeLang());
}
