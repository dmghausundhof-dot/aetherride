"use client";

import Link from "next/link";
import Image from "next/image";
import { AppDownloadButtons } from "@/components/landing/AppDownloadButtons";
import { ChromeGlyph, type ChromeMarkName } from "@/components/chrome/ChromeGlyph";
import { hasStoreLinks } from "@/lib/web/appLinks";
import { useChromeLang } from "@/hooks/useChromeLang";
import { useHomepageCopy } from "@/hooks/useHomepageCopy";
import { productCopy } from "@/lib/i18n/productCopy";
import { publicPagesCopy } from "@/lib/i18n/publicPagesCopy";
import { webChrome } from "@/lib/i18n/webChrome";

const REASON_MARKS: ChromeMarkName[] = ["karte", "offline", "nav", "phone"];

export function DownloadPageBody() {
  const lang = useChromeLang();
  const d = publicPagesCopy(lang).download;
  const product = productCopy(lang);
  const chrome = webChrome(lang);
  const h = useHomepageCopy();

  return (
    <div className="px-4 py-16 sm:px-6">
      <div className="mx-auto max-w-3xl text-center">
        <div className="relative mx-auto mb-8 h-40 w-full max-w-sm overflow-hidden rounded-2xl border border-border">
          <Image
            src="/brand/splash.jpg"
            alt="FlowLine Splash"
            fill
            className="object-cover"
            sizes="384px"
            priority
          />
        </div>
        <h1 className="text-3xl font-bold tracking-tight sm:text-4xl">
          {d.title}
        </h1>
        <p className="mt-4 text-lg text-text-secondary">{d.lead}</p>
        <div className="mt-10 flex justify-center">
          {hasStoreLinks() ? (
            <AppDownloadButtons size="lg" />
          ) : (
            <div className="mx-auto flex max-w-md flex-col items-center gap-4 text-sm text-text-secondary">
              <p>{d.noStore}</p>
              <Link
                href="/home"
                className="inline-flex h-12 items-center justify-center rounded-xl bg-accent px-7 text-[0.95rem] font-semibold text-on-accent"
              >
                {chrome.toHof}
              </Link>
            </div>
          )}
        </div>
      </div>

      <div className="mx-auto mt-16 grid max-w-4xl gap-4 sm:grid-cols-2">
        {d.reasons.map((r, i) => {
          const mark = REASON_MARKS[i] ?? "phone";
          return (
            <div
              key={r.title}
              className="rounded-2xl border border-border bg-surface p-6 text-left"
            >
              <ChromeGlyph name={mark} size={24} current className="text-sage" />
              <h2 className="mt-3 font-semibold">{r.title}</h2>
              <p className="mt-1 text-sm text-text-secondary">{r.body}</p>
            </div>
          );
        })}
      </div>

      <div className="mx-auto mt-16 max-w-4xl">
        <h2 className="text-xl font-bold">{d.splitTitle}</h2>
        <div className="mt-6 overflow-x-auto rounded-2xl border border-border">
          <table className="w-full min-w-[420px] text-left text-sm">
            <thead>
              <tr className="border-b border-border bg-surface">
                <th className="px-4 py-3 font-semibold">{product.ui.colSurface}</th>
                <th className="px-4 py-3 font-semibold">{product.ui.colWeb}</th>
                <th className="px-4 py-3 font-semibold">{product.ui.colApp}</th>
              </tr>
            </thead>
            <tbody>
              {product.matrix.map((row) => (
                <tr key={row.feature} className="border-b border-border/80">
                  <td className="px-4 py-3 text-text-secondary">{row.feature}</td>
                  <td className="px-4 py-3">{row.web}</td>
                  <td className="px-4 py-3">{row.app}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      <div className="mx-auto mt-12 max-w-xl text-center">
        <Link
          href="/discover"
          className="text-sm font-semibold text-text-secondary hover:text-chrome hover:underline"
        >
          {d.openMap} →
        </Link>
        <span className="mx-2 text-text-secondary">·</span>
        <Link
          href="/guides/web-vs-app"
          className="text-sm font-semibold text-text-secondary hover:text-chrome hover:underline"
        >
          {chrome.webVsApp} →
        </Link>
        <span className="mx-2 text-text-secondary">·</span>
        <Link
          href="/produkt"
          className="text-sm font-semibold text-text-secondary hover:text-chrome hover:underline"
        >
          {h.ui.productMap} →
        </Link>
      </div>
    </div>
  );
}
