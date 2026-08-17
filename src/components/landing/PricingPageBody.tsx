"use client";

import Link from "next/link";
import { Check, Minus } from "lucide-react";
import { AppDownloadButtons } from "@/components/landing/AppDownloadButtons";
import { useChromeLang } from "@/hooks/useChromeLang";
import { isCommerceOpen } from "@/lib/config/appStage";
import { publicPagesCopy } from "@/lib/i18n/publicPagesCopy";
import { webChrome } from "@/lib/i18n/webChrome";

function Cell({
  value,
  included,
  notIncluded,
}: {
  value: boolean | string;
  included: string;
  notIncluded: string;
}) {
  if (typeof value === "string") {
    return <span className="text-sm font-medium">{value}</span>;
  }
  return value ? (
    <Check className="mx-auto h-5 w-5 text-success" aria-label={included} />
  ) : (
    <Minus
      className="mx-auto h-5 w-5 text-text-secondary"
      aria-label={notIncluded}
    />
  );
}

export function PricingPageBody() {
  const lang = useChromeLang();
  const p = publicPagesCopy(lang).pricing;
  const chrome = webChrome(lang);
  const canBuy = isCommerceOpen();

  return (
    <div className="px-4 py-14 sm:px-6">
      <div className="mx-auto max-w-4xl text-center">
        <h1 className="text-3xl font-bold tracking-tight sm:text-4xl">
          {p.title}
        </h1>
        <p className="mx-auto mt-4 max-w-2xl text-text-secondary">{p.lead}</p>
      </div>

      <div className="mx-auto mt-12 grid max-w-4xl gap-6 md:grid-cols-2">
        <div className="rounded-2xl border border-border bg-surface p-6 text-left">
          <h2 className="text-xl font-bold">Free</h2>
          <p className="mt-1 text-3xl font-bold tabular-nums">0 €</p>
          <p className="mt-2 text-sm text-text-secondary">{p.freeHint}</p>
          <Link
            href="/home"
            className="mt-6 inline-flex w-full items-center justify-center rounded-xl border border-border py-3 text-sm font-semibold"
          >
            {chrome.toHof}
          </Link>
        </div>
        <div className="rounded-2xl border border-chrome/40 bg-chrome/10 p-6 text-left">
          <p className="text-xs font-semibold uppercase tracking-wide text-text-secondary">
            {p.recommended}
          </p>
          <h2 className="mt-1 text-xl font-bold">Pro</h2>
          <p className="mt-1 text-3xl font-bold tabular-nums">
            6,99 €
            <span className="text-base font-normal text-text-secondary">
              {p.perMonth}
            </span>
          </p>
          <p className="text-sm text-text-secondary">{p.yearHint}</p>
          {canBuy ? (
            <Link
              href="/anmelden?next=/profile"
              className="mt-6 inline-flex w-full items-center justify-center rounded-xl bg-chrome py-3 text-sm font-semibold text-on-accent"
            >
              {p.unlockPro}
            </Link>
          ) : (
            <p className="mt-6 rounded-xl border border-border bg-surface-elevated px-3 py-3 text-center text-sm text-text-secondary">
              {p.devClosed}
            </p>
          )}
          <p className="mt-2 text-center text-[11px] text-text-secondary">
            {canBuy ? p.checkoutHint : p.devClosed}
          </p>
        </div>
      </div>

      <div className="mx-auto mt-14 max-w-4xl overflow-x-auto rounded-2xl border border-border">
        <table className="w-full min-w-[320px] text-left text-sm">
          <thead>
            <tr className="border-b border-border bg-surface">
              <th className="px-4 py-3 font-semibold">{p.colFeature}</th>
              <th className="px-4 py-3 text-center font-semibold">Free</th>
              <th className="px-4 py-3 text-center font-semibold">Pro</th>
            </tr>
          </thead>
          <tbody>
            {p.rows.map((r) => (
              <tr key={r.feature} className="border-b border-border/80">
                <td className="px-4 py-3 text-text-secondary">{r.feature}</td>
                <td className="px-4 py-3 text-center">
                  <Cell
                    value={r.free}
                    included={p.included}
                    notIncluded={p.notIncluded}
                  />
                </td>
                <td className="px-4 py-3 text-center">
                  <Cell
                    value={r.pro}
                    included={p.included}
                    notIncluded={p.notIncluded}
                  />
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <div className="mx-auto mt-14 max-w-xl text-center">
        <h2 className="text-lg font-semibold">{p.appTitle}</h2>
        <p className="mt-2 text-sm text-text-secondary">{p.appLead}</p>
        <div className="mt-6 flex justify-center">
          <AppDownloadButtons size="lg" />
        </div>
        <p className="mt-6 text-xs text-text-secondary">
          {p.legalBefore}{" "}
          <Link href="/legal/agb" className="text-text-secondary hover:text-chrome hover:underline">
            {chrome.terms}
          </Link>
          {" · "}
          <Link href="/legal/widerruf" className="text-text-secondary hover:text-chrome hover:underline">
            {chrome.withdrawal}
          </Link>
          {" · "}
          <Link
            href="/legal/datenschutz"
            className="text-text-secondary hover:text-chrome hover:underline"
          >
            {chrome.privacyPolicy}
          </Link>
          {" · "}
          <Link href="/produkt" className="text-text-secondary hover:text-chrome hover:underline">
            {chrome.marketingNav["/produkt"]}
          </Link>
          {" · "}
          <Link href="/faq" className="text-text-secondary hover:text-chrome hover:underline">
            {chrome.faq}
          </Link>
        </p>
      </div>
    </div>
  );
}
