import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Bibliothek",
  description:
    "Gespeicherte Touren, GPX-Import, Sammlungen und Offline-Packs für AetherRide.",
};

export default function LibraryLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return children;
}
