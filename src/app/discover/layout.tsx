import { hofDoorMeta } from "@/lib/i18n/hofDoorMeta";

export const generateMetadata = () =>
  hofDoorMeta((c) => ({
    title: c.mapTitle,
    description: c.mapJustRideHint,
  }));

export default function DiscoverLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  // Full-bleed: Karte + Side-Panel brauchen die gesamte Viewport-Breite
  return <div className="w-full">{children}</div>;
}
