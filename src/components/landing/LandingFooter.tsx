"use client";

import Link from "next/link";
import { AppDownloadButtons } from "./AppDownloadButtons";
import { HOF_NAV } from "@/lib/nav/hofNav";
import { MARKETING_NAV } from "@/lib/nav/marketingNav";
import { FlowLineWordmark } from "@/components/brand/FlowLineWordmark";
import { FLOWLINE_TAGLINE_DOTS } from "@/lib/content/brand";
import { legalContactEmail } from "@/lib/legal/siteLegal";
import { webChrome } from "@/lib/i18n/webChrome";
import { useChromeLang } from "@/hooks/useChromeLang";
import { useHofTitle } from "@/hooks/useHofTitle";
import { MAP_ATTRIBUTION_HREF } from "@/lib/map/onlineBasemap";

export function LandingFooter() {
  const email = legalContactEmail();
  const copy = webChrome(useChromeLang());
  const hofTitle = useHofTitle();

  return (
    <footer className="border-t border-border bg-surface py-12 pb-[calc(3rem+var(--safe-bottom))]">
      <div className="mx-auto max-w-6xl px-4">
        <div className="flex flex-col items-center justify-between gap-8 md:flex-row">
          <div>
            <FlowLineWordmark />
            <p className="mt-1 text-[11px] font-medium uppercase tracking-[0.14em] text-text-secondary">
              {FLOWLINE_TAGLINE_DOTS}
            </p>
            <p className="mt-2 text-sm text-text-secondary">
              {copy.footerTagline}
            </p>
          </div>

          <AppDownloadButtons size="md" />
        </div>

        <div className="mt-10 grid gap-8 sm:grid-cols-2 lg:grid-cols-4">
          <div>
            <p className="text-xs font-semibold uppercase tracking-wide text-text-secondary">
              {copy.footerWebsite}
            </p>
            <div className="mt-3 flex flex-col gap-2 text-sm">
              {MARKETING_NAV.map((item) => (
                <Link
                  key={item.href}
                  href={item.href}
                  className="text-text-secondary hover:text-foreground"
                >
                  {copy.marketingNav[item.href]}
                </Link>
              ))}
              <Link
                href="/anmelden"
                className="text-text-secondary hover:text-foreground"
              >
                {copy.signIn}
              </Link>
            </div>
          </div>
          <div>
            <p className="text-xs font-semibold uppercase tracking-wide text-text-secondary">
              {hofTitle}
            </p>
            <div className="mt-3 flex flex-col gap-2 text-sm">
              {HOF_NAV.map((item) => (
                <Link
                  key={item.href}
                  href={item.href}
                  className="text-text-secondary hover:text-foreground"
                >
                  {item.id === "hof" ? hofTitle : copy.hofNav[item.id]}
                </Link>
              ))}
              <Link
                href="/planner"
                className="text-text-secondary hover:text-foreground"
              >
                {copy.plan}
              </Link>
            </div>
          </div>
          <div>
            <p className="text-xs font-semibold uppercase tracking-wide text-text-secondary">
              {copy.footerMore}
            </p>
            <div className="mt-3 flex flex-col gap-2 text-sm">
              <Link
                href="/ueber"
                className="text-text-secondary hover:text-foreground"
              >
                {copy.aboutFlowLine}
              </Link>
              <Link
                href="/faq"
                className="text-text-secondary hover:text-foreground"
              >
                {copy.faq}
              </Link>
              <Link
                href="/share"
                className="text-text-secondary hover:text-foreground"
              >
                {copy.share}
              </Link>
              <Link
                href="/u/mara_road"
                className="text-text-secondary hover:text-foreground"
              >
                {copy.sampleProfile}
              </Link>
              <Link
                href="/produkt"
                className="text-text-secondary hover:text-foreground"
              >
                {copy.screensFlows}
              </Link>
              <Link
                href="/guides/web-vs-app"
                className="text-text-secondary hover:text-foreground"
              >
                {copy.webVsApp}
              </Link>
              <Link
                href="/activities"
                className="text-text-secondary hover:text-foreground"
              >
                {copy.whatCameIn}
              </Link>
              <Link
                href="/privacy"
                className="text-text-secondary hover:text-foreground"
              >
                {copy.dataPrivacy}
              </Link>
            </div>
          </div>
          <div>
            <p className="text-xs font-semibold uppercase tracking-wide text-text-secondary">
              {copy.footerLegal}
            </p>
            <div className="mt-3 flex flex-col gap-2 text-sm">
              <Link
                href="/legal/impressum"
                className="text-text-secondary hover:text-foreground"
              >
                {copy.imprint}
              </Link>
              <Link
                href="/legal/datenschutz"
                className="text-text-secondary hover:text-foreground"
              >
                {copy.privacyPolicy}
              </Link>
              <Link
                href="/legal/agb"
                className="text-text-secondary hover:text-foreground"
              >
                {copy.terms}
              </Link>
              <Link
                href="/legal/widerruf"
                className="text-text-secondary hover:text-foreground"
              >
                {copy.withdrawal}
              </Link>
              <Link
                href="/kontakt"
                className="text-text-secondary hover:text-foreground"
              >
                {copy.contact}
              </Link>
              <a
                href={`mailto:${email}`}
                className="text-text-secondary hover:text-foreground"
              >
                {email}
              </a>
            </div>
          </div>
        </div>

        <p className="mt-10 text-center text-xs text-text-secondary">
          © {new Date().getFullYear()} FlowLine. {copy.footerLegalLine}
        </p>
        <p className="mt-3 text-center text-xs text-text-secondary">
          Karten:{" "}
          <a
            href={MAP_ATTRIBUTION_HREF.osm}
            className="hover:text-foreground"
            rel="noreferrer"
          >
            © OpenStreetMap
          </a>
          {" · "}
          <a
            href={MAP_ATTRIBUTION_HREF.protomaps}
            className="hover:text-foreground"
            rel="noreferrer"
          >
            Protomaps
          </a>
          {" · "}
          <a
            href={MAP_ATTRIBUTION_HREF.terrain}
            className="hover:text-foreground"
            rel="noreferrer"
          >
            Terrain
          </a>
        </p>
      </div>
    </footer>
  );
}
