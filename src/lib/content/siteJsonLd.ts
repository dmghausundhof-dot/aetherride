import { FLOWLINE_NAME, FLOWLINE_TAGLINE } from "./brand";
import { DEFAULT_LEGAL_EMAIL } from "@/lib/legal/siteLegal";

export function siteOrigin(): string {
  return (
    process.env.NEXT_PUBLIC_APP_URL?.replace(/\/$/, "") ||
    process.env.NEXT_PUBLIC_SITE_URL?.replace(/\/$/, "") ||
    "https://aetherride.app"
  );
}

export function websiteJsonLd(origin: string) {
  return {
    "@context": "https://schema.org",
    "@graph": [
      {
        "@type": "WebSite",
        name: FLOWLINE_NAME,
        alternateName: "FlowLine Outdoor Cycling",
        url: origin,
        description: FLOWLINE_TAGLINE,
        inLanguage: "de-DE",
      },
      {
        "@type": "Organization",
        name: FLOWLINE_NAME,
        url: origin,
        email: DEFAULT_LEGAL_EMAIL,
        logo: `${origin}/brand/app-icon.png`,
        description: FLOWLINE_TAGLINE,
      },
    ],
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

export function breadcrumbJsonLd(
  origin: string,
  items: { name: string; path: string }[],
) {
  return {
    "@context": "https://schema.org",
    "@type": "BreadcrumbList",
    itemListElement: items.map((item, i) => ({
      "@type": "ListItem",
      position: i + 1,
      name: item.name,
      item: `${origin}${item.path}`,
    })),
  };
}

export function guideArticleJsonLd(
  origin: string,
  guide: { slug: string; title: string; teaser: string },
) {
  return {
    "@context": "https://schema.org",
    "@type": "Article",
    headline: guide.title,
    description: guide.teaser,
    inLanguage: "de-DE",
    url: `${origin}/guides/${guide.slug}`,
  };
}

export function editorialPersonJsonLd(
  origin: string,
  profile: {
    handle: string;
    displayName: string;
    bio: string;
    sports: string[];
  },
) {
  return {
    "@context": "https://schema.org",
    "@type": "Person",
    name: profile.displayName,
    url: `${origin}/u/${profile.handle}`,
    description: profile.bio,
    knowsAbout: profile.sports,
  };
}
