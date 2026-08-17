import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Platz",
  description:
    "Touren merken, kurz schreiben, Freunde per Link mitnehmen. Dieselben Touren wie auf der Karte.",
};

export default function LibraryLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return children;
}
