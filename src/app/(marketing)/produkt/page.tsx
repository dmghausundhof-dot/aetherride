import type { Metadata } from "next";
import { ProduktPageBody } from "@/components/landing/ProduktPageBody";

export const metadata: Metadata = {
  title: "Produkt – Screens, Abläufe, Web und App",
  description:
    "FlowLine: fünf Türen am Hof, Fahrt in der App. Alle Screens, Prozesse und Workflows — ehrlich getrennt.",
};

export default function ProduktPage() {
  return <ProduktPageBody />;
}
