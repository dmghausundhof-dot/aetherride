import type { Metadata } from "next";
import { GuidesIndexBody } from "@/components/landing/GuidesIndexBody";

export const metadata: Metadata = {
  title: "Guides – Planung, Setup & E-Bike",
  description:
    "Ratgeber für Rennrad, Gravel, MTB und E-Bike: Touren planen, Reichweite, Setup, Hof und Platz — ehrlich erklärt.",
};

export default function GuidesIndexPage() {
  return (
    <div className="px-4 py-12 sm:px-6">
      <GuidesIndexBody />
    </div>
  );
}
