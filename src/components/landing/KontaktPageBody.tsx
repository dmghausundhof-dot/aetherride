"use client";

import Link from "next/link";
import { legalContactEmail, hasTmgImprint } from "@/lib/legal/siteLegal";
import { useChromeLang } from "@/hooks/useChromeLang";
import { publicPagesCopy } from "@/lib/i18n/publicPagesCopy";
import { webChrome } from "@/lib/i18n/webChrome";

export function KontaktPageBody() {
  const lang = useChromeLang();
  const c = publicPagesCopy(lang).contact;
  const chrome = webChrome(lang);
  const email = legalContactEmail();
  const complete = hasTmgImprint();

  return (
    <div className="px-4 py-12 sm:px-6">
      <div className="mx-auto max-w-lg">
        <p className="text-[11px] font-bold tracking-wide text-text-secondary">
          {c.kicker}
        </p>
        <h1 className="mt-2 text-3xl font-bold tracking-tight sm:text-4xl">
          {c.title}
        </h1>
        <p className="mt-3 text-text-secondary">{c.lead}</p>

        <div className="mt-8 rounded-2xl border border-border bg-surface p-6">
          <p className="text-sm text-text-secondary">{c.emailLabel}</p>
          <a
            href={`mailto:${email}`}
            className="mt-1 inline-block text-lg font-semibold text-text-secondary hover:text-chrome hover:underline"
          >
            {email}
          </a>
          <p className="mt-4 text-sm text-text-secondary">{c.workshopHint}</p>
        </div>

        <ul className="mt-8 space-y-2 text-sm text-text-secondary">
          <li>
            <Link href="/legal/impressum" className="text-text-secondary hover:text-chrome hover:underline">
              {chrome.imprint}
            </Link>
            {!complete ? c.imprintPending : null}
          </li>
          <li>
            <Link
              href="/legal/datenschutz"
              className="text-text-secondary hover:text-chrome hover:underline"
            >
              {chrome.privacyPolicy}
            </Link>
          </li>
          <li>
            <Link href="/legal/agb" className="text-text-secondary hover:text-chrome hover:underline">
              {chrome.terms}
            </Link>
            {" · "}
            <Link href="/legal/widerruf" className="text-text-secondary hover:text-chrome hover:underline">
              {chrome.withdrawal}
            </Link>
          </li>
          <li>
            <Link href="/faq" className="text-text-secondary hover:text-chrome hover:underline">
              {chrome.faq}
            </Link>
          </li>
        </ul>
      </div>
    </div>
  );
}
