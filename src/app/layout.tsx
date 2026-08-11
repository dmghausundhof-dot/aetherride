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
    default: "AetherRide – Touren planen. Bike verstehen.",
    template: "%s · AetherRide",
  },
  description:
    "Rennrad, Gravel, MTB, E-Bike & City: Touren entdecken, Desktop-Planer, Multi-Bike-Garage und Setup. Navigation in der nativen App.",
  keywords: [
    "Radtouren",
    "Rennrad",
    "Gravel",
    "MTB",
    "E-Bike",
    "Route Planner",
    "Bike Garage",
    "AetherRide",
  ],
  openGraph: {
    title: "AetherRide – Touren planen. Bike verstehen.",
    description:
      "Für alle Fahrradfahrer: Explore, Garage & Setup im Web. Navigation in der App.",
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
