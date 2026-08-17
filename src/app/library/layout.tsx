import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Touren",
  description:
    "Gespeicherte Strecken, Tipps, Freunde per Link. Dieselben Touren wie auf der Karte.",
};

export default function LibraryLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return children;
}
