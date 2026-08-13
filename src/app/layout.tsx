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

export const metadata: Metadata = {
  title: {
    default: "AetherRide – Der Hof",
    template: "%s · AetherRide",
  },
  description:
    "Das Rad wohnt hier. Karte, Werkstatt und Shop — Rausfahren in der App.",
  keywords: [
    "Der Hof",
    "Radtouren",
    "Rennrad",
    "Gravel",
    "MTB",
    "E-Bike",
    "Werkstatt",
    "AetherRide",
  ],
  openGraph: {
    title: "AetherRide – Der Hof",
    description:
      "Das Rad wohnt hier. Eine Stunde vor dem Tor. Rausfahren.",
    locale: "de_DE",
    type: "website",
  },
  appleWebApp: {
    capable: true,
    statusBarStyle: "black-translucent",
    title: "AetherRide",
  },
};

export const viewport: Viewport = {
  themeColor: "#0A1210",
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
