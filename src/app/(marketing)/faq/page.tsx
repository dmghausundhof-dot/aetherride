import type { Metadata } from "next";
import Link from "next/link";
import { FAQ_ITEMS } from "@/lib/content/faq";
import { faqJsonLd, siteOrigin } from "@/lib/content/siteJsonLd";

export const metadata: Metadata = {
  title: "FAQ – Web, App, Preise, Community",
  description:
    "FlowLine kurz erklärt: was im Browser läuft, was in der App, Free und Pro, Community ohne Feed.",
};

export default function FaqPage() {
  return (
    <div className="px-4 py-12 sm:px-6">
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{
          __html: JSON.stringify(faqJsonLd(siteOrigin(), FAQ_ITEMS)),
        }}
      />
      <div className="mx-auto max-w-3xl">
        <p className="text-[11px] font-bold tracking-wide text-chrome">FAQ</p>
        <h1 className="mt-2 text-3xl font-bold tracking-tight sm:text-4xl">
          Kurz und ehrlich
        </h1>
        <p className="mt-3 max-w-2xl text-text-secondary">
          Keine Store-Versprechen, keine erfundenen Adressen, kein Feed auf dem
          Hof.
        </p>

        <dl className="mt-10 space-y-4">
          {FAQ_ITEMS.map((item) => (
            <div
              key={item.id}
              className="rounded-2xl border border-border bg-surface p-5"
            >
              <dt className="font-semibold">{item.q}</dt>
              <dd className="mt-2 text-sm text-text-secondary">{item.a}</dd>
              {item.links && item.links.length > 0 ? (
                <dd className="mt-3 flex flex-wrap gap-3">
                  {item.links.map((link) => (
                    <Link
                      key={link.href}
                      href={link.href}
                      className="text-xs font-semibold text-chrome hover:underline"
                    >
                      {link.label} →
                    </Link>
                  ))}
                </dd>
              ) : null}
            </div>
          ))}
        </dl>

        <p className="mt-10 text-sm text-text-secondary">
          Mehr Screens und Abläufe stehen unter{" "}
          <Link href="/produkt" className="font-semibold text-chrome hover:underline">
            Produkt
          </Link>
          .
        </p>
      </div>
    </div>
  );
}
