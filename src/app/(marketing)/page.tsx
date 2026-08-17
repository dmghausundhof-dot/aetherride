import type { Metadata } from "next";
import { Suspense } from "react";
import { LandingHero } from "@/components/landing/LandingHero";
import { ServiceCheckSection } from "@/components/landing/ServiceCheckSection";
import { ScreenGallery } from "@/components/landing/ScreenGallery";
import {
  HomePageBody,
  HomePageCta,
} from "@/components/landing/HomePageBody";
import {
  KartenCoverageFallback,
  KartenCoverageSection,
} from "@/components/landing/KartenCoverageSection";
import { websiteJsonLd, siteOrigin } from "@/lib/content/siteJsonLd";

export const metadata: Metadata = {
  title: {
    absolute: "FlowLine – Outdoor Cycling",
  },
  description:
    "Outdoor Cycling, simplified. Hof im Browser: planen, pflegen, teilen. Fahrt in der App. Vier Türen, kein Feed, keine zweite Kasse.",
};

export default function LandingPage() {
  const origin = siteOrigin();

  return (
    <>
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{
          __html: JSON.stringify(websiteJsonLd(origin)),
        }}
      />
      <LandingHero />
      <HomePageBody
        mapsCoverage={
          <Suspense fallback={<KartenCoverageFallback />}>
            <KartenCoverageSection />
          </Suspense>
        }
      />
      <ScreenGallery />
      <ServiceCheckSection />
      <HomePageCta />
    </>
  );
}
