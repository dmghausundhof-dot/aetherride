import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Touren – MTB, Gravel, Rennrad, City & E-Bike",
  description:
    "Touren entdecken und planen für Rennrad, Gravel, MTB, E-Bike und City. Karte, Filter und Routing-Profile.",
};

export default function DiscoverLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  // Full-bleed: Karte + Side-Panel brauchen die gesamte Viewport-Breite
  return <div className="w-full">{children}</div>;
}
