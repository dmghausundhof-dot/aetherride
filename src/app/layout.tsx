import type { Metadata, Viewport } from "next";
import { Inter } from "next/font/google";
import "./globals.css";
import { BottomTabBar } from "@/components/BottomTabBar";
import { Providers } from "@/components/Providers";

const inter = Inter({
  subsets: ["latin"],
  variable: "--font-geist-sans",
  display: "swap",
});

export const metadata: Metadata = {
  title: "AetherRide – Tourenapp, die dein Bike kennt",
  description:
    "MTB, Enduro, Gravel & E-MTB: Garage, Setup, Navigation und Fahrwerks-Feedback in einer App.",
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
  maximumScale: 1,
  userScalable: false,
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
          <div className="mx-auto flex min-h-dvh max-w-lg flex-col">
            <main className="flex-1 pb-safe">{children}</main>
            <BottomTabBar />
          </div>
        </Providers>
      </body>
    </html>
  );
}
