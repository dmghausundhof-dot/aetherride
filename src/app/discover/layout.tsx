import type { Metadata } from "next";

export const metadata: Metadata = {
    title: "Karte – OSM, Rundkurse, Nähe",
  description:
    "Vor dem Tor: OpenStreetMap, ~60-Min-Rundkurse. Kein Google-Layer. Rausfahren landet hier.",
};

export default function DiscoverLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  // Full-bleed: Karte + Side-Panel brauchen die gesamte Viewport-Breite
  return <div className="w-full">{children}</div>;
}
