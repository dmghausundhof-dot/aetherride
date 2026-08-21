"use client";

import { useContext } from "react";
import { ChromeLangContext } from "@/components/i18n/ChromeLangProvider";
import type { ChromeLang } from "@/lib/i18n/chromeLang";

/** Hof UI language. Server seeds from cookie / Accept-Language. */
export function useChromeLang(): ChromeLang {
  return useContext(ChromeLangContext).lang;
}

/** Device (auto) vs this-browser override. Not synced to the phone app. */
export function useChromeLangPreference() {
  return useContext(ChromeLangContext);
}
