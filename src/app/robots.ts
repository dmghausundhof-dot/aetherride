import type { MetadataRoute } from "next";

function base(): string {
  return (
    process.env.NEXT_PUBLIC_APP_URL?.replace(/\/$/, "") ||
    process.env.NEXT_PUBLIC_SITE_URL?.replace(/\/$/, "") ||
    "https://aetherride.app"
  );
}

export default function robots(): MetadataRoute.Robots {
  const origin = base();
  return {
    rules: [
      {
        userAgent: "*",
        allow: "/",
        disallow: [
          "/api/",
          "/checkout",
          "/profile",
          "/privacy",
          "/post-ride",
          "/chat",
          "/library",
          "/activities",
        ],
      },
    ],
    sitemap: `${origin}/sitemap.xml`,
    host: origin,
  };
}
