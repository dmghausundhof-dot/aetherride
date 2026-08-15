import type { MetadataRoute } from "next";
import { listPublicTourIds } from "@/lib/catalog/publicTours";
import { listRegions } from "@/lib/catalog/regions";
import { listGuideSlugs } from "@/lib/content/guides";

function base(): string {
  return (
    process.env.NEXT_PUBLIC_APP_URL?.replace(/\/$/, "") ||
    process.env.NEXT_PUBLIC_SITE_URL?.replace(/\/$/, "") ||
    "https://aetherride.app"
  );
}

export default function sitemap(): MetadataRoute.Sitemap {
  const origin = base();
  const now = new Date();

  const staticPages: MetadataRoute.Sitemap = [
    "",
    "/produkt",
    "/home",
    "/discover",
    "/regions",
    "/guides",
    "/community",
    "/pricing",
    "/download",
    "/anmelden",
    "/garage",
    "/shop",
    "/legal/impressum",
    "/legal/datenschutz",
    "/legal/agb",
    "/legal/widerruf",
  ].map((path) => ({
    url: `${origin}${path || "/"}`,
    lastModified: now,
    changeFrequency: path === "" || path === "/discover" ? "daily" : "weekly",
    priority:
      path === ""
        ? 1
        : path === "/discover" || path === "/produkt"
          ? 0.9
          : 0.7,
  }));

  const tours = listPublicTourIds().map((id) => ({
    url: `${origin}/tours/${id}`,
    lastModified: now,
    changeFrequency: "weekly" as const,
    priority: 0.8,
  }));

  const regions = listRegions().map((r) => ({
    url: `${origin}/regions/${r.slug}`,
    lastModified: now,
    changeFrequency: "weekly" as const,
    priority: 0.75,
  }));

  const guides = listGuideSlugs().map((slug) => ({
    url: `${origin}/guides/${slug}`,
    lastModified: now,
    changeFrequency: "monthly" as const,
    priority: 0.65,
  }));

  return [...staticPages, ...tours, ...regions, ...guides];
}
