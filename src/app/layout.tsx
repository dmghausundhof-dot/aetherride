import type { Metadata, Viewport } from "next";
import { cookies, headers } from "next/headers";
import { Inter } from "next/font/google";
import "./globals.css";
import { Providers } from "@/components/Providers";
import { AppShell } from "@/components/app/AppShell";
import { DevStageBanner } from "@/components/app/DevStageBanner";
import { isPublicIndexable } from "@/lib/config/appStage";
import {
  CHROME_LANG_COOKIE,
  chromeLangOverrideFrom,
  chromeOgLocale,
  resolveChromeLang,
  type ChromeLang,
} from "@/lib/i18n/chromeLang";

const inter = Inter({
  subsets: ["latin"],
  variable: "--font-inter",
  display: "swap",
});

const siteUrl = (() => {
  const raw =
    process.env.NEXT_PUBLIC_APP_URL?.trim() ||
    process.env.NEXT_PUBLIC_SITE_URL?.trim() ||
    "https://aetherride.app";
  try {
    return new URL(raw);
  } catch {
    return new URL("https://aetherride.app");
  }
})();

async function requestChromeLang(): Promise<{
  lang: ChromeLang;
  override: ChromeLang | null;
}> {
  const cookieStore = await cookies();
  const hdrs = await headers();
  const override = chromeLangOverrideFrom(
    cookieStore.get(CHROME_LANG_COOKIE)?.value ?? null
  );
  const lang = resolveChromeLang({
    override,
    acceptLanguage: hdrs.get("accept-language"),
  });
  return { lang, override };
}

export async function generateMetadata(): Promise<Metadata> {
  const { lang } = await requestChromeLang();
  return {
    metadataBase: siteUrl,
    title: {
      default: "FlowLine – Outdoor Cycling",
      template: "%s · FlowLine",
    },
    description:
      "Outdoor Cycling, simplified. Hof, Karte, Touren, Rad — Rausfahren in der App.",
    keywords: [
      "FlowLine",
      "Radtouren",
      "Rennrad",
      "Gravel",
      "MTB",
      "E-Bike",
      "Rad",
      "Outdoor Cycling",
    ],
    openGraph: {
      title: "FlowLine – Outdoor Cycling",
      description:
        "Outdoor Cycling, simplified. Eine Stunde vor dem Tor. Rausfahren.",
      locale: chromeOgLocale(lang),
      type: "website",
      images: [
        {
          url: "/brand/og-banner.jpg",
          width: 1200,
          height: 630,
          alt: "FlowLine – Outdoor · Cycling · Flow",
        },
      ],
    },
    twitter: {
      card: "summary_large_image",
      images: ["/brand/og-banner.jpg"],
    },
    appleWebApp: {
      capable: true,
      statusBarStyle: "black-translucent",
      title: "FlowLine",
    },
    icons: {
      icon: "/brand/app-icon.png",
      apple: "/brand/app-icon.png",
    },
    robots: isPublicIndexable()
      ? { index: true, follow: true }
      : { index: false, follow: false, nocache: true },
  };
}

export const viewport: Viewport = {
  themeColor: "#121215",
  width: "device-width",
  initialScale: 1,
  // Web: Zoom erlauben (A11y). Native App steuert Viewport selbst.
  maximumScale: 5,
  userScalable: true,
  viewportFit: "cover",
};

export default async function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const { lang, override } = await requestChromeLang();
  return (
    <html lang={lang} className={`${inter.variable} h-full`} suppressHydrationWarning>
      <body className="min-h-full bg-background text-foreground antialiased">
        <Providers initialLang={lang} initialOverride={override}>
          <DevStageBanner />
          <AppShell>{children}</AppShell>
        </Providers>
      </body>
    </html>
  );
}
