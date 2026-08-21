import type { Metadata, Viewport } from "next";
import { Inter } from "next/font/google";
import "./globals.css";
import { Providers } from "@/components/Providers";
import { AppShell } from "@/components/app/AppShell";
import { DevStageBanner } from "@/components/app/DevStageBanner";
import { isPublicIndexable } from "@/lib/config/appStage";
import { chromeOgLocale } from "@/lib/i18n/chromeLang";
import { homepageCopy } from "@/lib/i18n/homepageCopy";
import { requestChromeLang } from "@/lib/i18n/requestChromeLang";
import { hofCopy } from "@/lib/home/hofCopy";

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

export async function generateMetadata(): Promise<Metadata> {
  const { lang } = await requestChromeLang();
  const rideOut = hofCopy(lang).rideOut;
  return {
    metadataBase: siteUrl,
    title: {
      default: "FlowLine – Outdoor Cycling",
      template: "%s · FlowLine",
    },
    description: homepageCopy(lang).ui.heroLead(rideOut),
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
      description: homepageCopy(lang).ui.heroLead(rideOut),
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
    <html
      lang={lang}
      className={`${inter.variable} h-full`}
      suppressHydrationWarning
    >
      <body className="min-h-full bg-background text-foreground antialiased">
        <Providers initialLang={lang} initialOverride={override}>
          <DevStageBanner />
          <AppShell>{children}</AppShell>
        </Providers>
      </body>
    </html>
  );
}
