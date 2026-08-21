"use client";

import { useChromeLang } from "@/hooks/useChromeLang";
import { homepageCopy } from "@/lib/i18n/homepageCopy";

/** Homepage chrome in the resolved UI language. */
export function useHomepageCopy() {
  return homepageCopy(useChromeLang());
}
