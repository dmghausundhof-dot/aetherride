"use client";

import { useChromeLang } from "@/hooks/useChromeLang";
import { homepageCopy } from "@/lib/i18n/homepageCopy";

/** Browser UI language after mount — DE until then. */
export function useHomepageCopy() {
  return homepageCopy(useChromeLang());
}
