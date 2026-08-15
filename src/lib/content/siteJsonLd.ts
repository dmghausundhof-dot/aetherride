import { FLOWLINE_NAME, FLOWLINE_TAGLINE } from "./brand";

export function websiteJsonLd(origin: string) {
  return {
    "@context": "https://schema.org",
    "@type": "WebSite",
    name: FLOWLINE_NAME,
    alternateName: "FlowLine Outdoor Cycling",
    url: origin,
    description: FLOWLINE_TAGLINE,
    inLanguage: "de-DE",
  };
}

export function faqJsonLd(
  origin: string,
  items: { q: string; a: string }[],
) {
  return {
    "@context": "https://schema.org",
    "@type": "FAQPage",
    mainEntity: items.map((item) => ({
      "@type": "Question",
      name: item.q,
      acceptedAnswer: {
        "@type": "Answer",
        text: item.a,
      },
    })),
    url: `${origin}/faq`,
  };
}
