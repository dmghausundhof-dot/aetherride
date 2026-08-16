"use client";

import { useEffect, useState } from "react";
import { chromeLangFrom, type ChromeLang } from "@/lib/i18n/chromeLang";

/** Browser UI language after mount — DE until then, like [useHofTitle]. */
export function useChromeLang(): ChromeLang {
  const [lang, setLang] = useState<ChromeLang>("de");
  useEffect(() => {
    setLang(chromeLangFrom(navigator.language));
  }, []);
  return lang;
}
