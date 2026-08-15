import type { Metadata, Viewport } from "next";
import { Inter } from "next/font/google";
import "./globals.css";
import { Providers } from "@/components/Providers";
import { AppShell } from "@/components/app/AppShell";

const inter = Inter({
  subsets: ["latin"],
  variable: "--font-geist-sans",
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

export const metadata: Metadata = {
  metadataBase: siteUrl,
  title: {
    default: "FlowLine – Outdoor Cycling",
    template: "%s · FlowLine",
  },
  description:
    "Outdoor Cycling, simplified. Hof, Karte, Platz, Werkstatt — Rausfahren in der App.",
  keywords: [
    "FlowLine",
    "Radtouren",
    "Rennrad",
    "Gravel",
    "MTB",
    "E-Bike",
    "Werkstatt",
    "Outdoor Cycling",
  ],
  openGraph: {
    title: "FlowLine – Outdoor Cycling",
    description:
      "Outdoor Cycling, simplified. Eine Stunde vor dem Tor. Rausfahren.",
    locale: "de_DE",
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
};

export const viewport: Viewport = {
  themeColor: "#121215",
  width: "device-width",
  initialScale: 1,
  // Web: Zoom erlauben (A11y). Native App steuert Viewport selbst.
  maximumScale: 5,
  userScalable: true,
  viewportFit: "cover",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="de" className={`${inter.variable} h-full`}>
      <body className="min-h-full bg-background text-foreground antialiased">
        <Providers>
          <AppShell>{children}</AppShell>
        </Providers>
      </body>
    </html>
  );
}
