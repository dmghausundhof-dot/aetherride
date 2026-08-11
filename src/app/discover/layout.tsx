import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Explore – Touren & Planner",
  description:
    "Touren entdecken für Rennrad, Gravel, MTB, E-Bike und City. Desktop-Planer mit Karte, Filtern und Profilen.",
};

export default function DiscoverLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  // Full-bleed: Karte + Side-Panel brauchen die gesamte Viewport-Breite
  return <div className="w-full">{children}</div>;
}
