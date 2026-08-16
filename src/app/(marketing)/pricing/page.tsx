import type { Metadata } from "next";
import { PricingPageBody } from "@/components/landing/PricingPageBody";

export const metadata: Metadata = {
  title: "Preise – Free & Pro",
  description:
    "FlowLine Free und Pro: Touren und Planen für alle. Multi-Bike, Bracketing, Reichweite und Offline-Packs mit Pro.",
};

export default function PricingPage() {
  return <PricingPageBody />;
}
