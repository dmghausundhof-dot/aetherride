"use client";

import Link from "next/link";
import { useChromeLang } from "@/hooks/useChromeLang";
import { webChrome } from "@/lib/i18n/webChrome";

export function AnmeldenLoading() {
  return (
    <p className="text-sm text-text-secondary">
      {webChrome(useChromeLang()).loading}
    </p>
  );
}

export function AnmeldenFoot() {
  const chrome = webChrome(useChromeLang());
  return (
    <>
      <p className="mt-6 text-center text-xs text-text-secondary">
        {chrome.anmeldenLocal}{" "}
        <Link href="/home" className="text-chrome hover:underline">
          {chrome.stillToHof}
        </Link>
        {" · "}
        <Link href="/pricing" className="text-chrome hover:underline">
          {chrome.marketingNav["/pricing"]}
        </Link>
        {" · "}
        <Link href="/faq" className="text-chrome hover:underline">
          {chrome.faq}
        </Link>
      </p>
      <p className="mt-3 text-center text-xs text-text-secondary">
        <Link href="/legal/datenschutz" className="text-chrome hover:underline">
          {chrome.privacyPolicy}
        </Link>
        {" · "}
        <Link href="/legal/agb" className="text-chrome hover:underline">
          {chrome.terms}
        </Link>
      </p>
    </>
  );
}
