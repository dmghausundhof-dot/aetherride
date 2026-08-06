import type { Metadata, Viewport } from "next";
import { Inter } from "next/font/google";
import "./globals.css";
import { BottomTabBar } from "@/components/BottomTabBar";
import { Providers } from "@/components/Providers";
import { SyncStatusChip } from "@/components/SyncStatusChip";

const inter = Inter({
  subsets: ["latin"],
  variable: "--font-geist-sans",
  display: "swap",
});

export const metadata: Metadata = {
  title: "AetherRide – Intelligent Outdoor & Bike App",
  description:
    "All-in-One App für Mountainbike, Enduro, Gravel, E-Bike & Wandern. Garage, Sensor-Setup, Navigation, Bosch Live Data & KI.",
  appleWebApp: {
    capable: true,
    statusBarStyle: "black-translucent",
    title: "AetherRide",
  },
};

/** NFR-13: keine userScalable:false — Schriftskalierung bis 200 % */
export const viewport: Viewport = {
  themeColor: "#0A1210",
  width: "device-width",
  initialScale: 1,
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
          <a
            href="#main"
            className="sr-only focus:not-sr-only focus:absolute focus:left-2 focus:top-2 focus:z-[100] focus:rounded-lg focus:bg-accent focus:px-3 focus:py-2 focus:text-sm focus:text-white"
          >
            Zum Inhalt springen
          </a>
          <div className="mx-auto flex min-h-dvh max-w-lg flex-col">
            <div className="sticky top-0 z-40 border-b border-border/60 bg-background/90 px-3 py-1.5 backdrop-blur-md">
              <SyncStatusChip />
            </div>
            <main id="main" className="flex-1 pb-safe" tabIndex={-1}>
              {children}
            </main>
            <BottomTabBar />
          </div>
        </Providers>
      </body>
    </html>
  );
}
