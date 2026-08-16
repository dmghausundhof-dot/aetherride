import type { Metadata } from "next";
import { ShareIndexBody } from "@/components/landing/ShareIndexBody";

export const metadata: Metadata = {
  title: "Teilen – Tour-Link und Mappe",
  description:
    "FlowLine teilt per Link: eine Tour oder eine Mappe. Kein Feed, kein Account-Zwang, GPS nur mit Opt-in.",
};

export default function ShareIndexPage() {
  return <ShareIndexBody />;
}
