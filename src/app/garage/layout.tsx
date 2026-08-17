import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Rad",
  description:
    "Dein Rad: Setup nach Typ, Pflege, Komponenten. Uhr koppeln nur in der App.",
};

export default function GarageLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return children;
}
