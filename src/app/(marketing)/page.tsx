import type { Metadata } from "next";
import { LandingHero } from "@/components/landing/LandingHero";
import { HomePageBody } from "@/components/landing/HomePageBody";
import { websiteJsonLd, siteOrigin } from "@/lib/content/siteJsonLd";

export const metadata: Metadata = {
  title: {
    absolute: "FlowLine – Outdoor Cycling",
  },
  description:
    "Das Rad wohnt hier. Web pflanzt, die App fährt. Garage, Setup, ehrliches Routing. Closed Test, frei.",
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
      <HomePageBody />
    </>
  );
}
