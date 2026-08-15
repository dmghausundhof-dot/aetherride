import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Platz",
  description:
    "Deine Touren, Stimmen und Gruppen auf dem Platz. Dieselben Touren wie auf der Karte.",
};

export default function LibraryLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return children;
}
