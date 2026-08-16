import type { Metadata } from "next";
import { RegionsIndexBody } from "@/components/landing/RegionsIndexBody";

export const metadata: Metadata = {
  title: "Regionen – Radtouren in DACH",
  description:
    "Touren-Ideen nach Region: Baden-Württemberg, Schwarzwald, Bayern, Bodensee, Elsass und mehr.",
};

export default function RegionsIndexPage() {
  return <RegionsIndexBody />;
}
