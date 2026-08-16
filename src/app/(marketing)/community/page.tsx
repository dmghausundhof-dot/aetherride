import type { Metadata } from "next";
import { CommunityPageBody } from "@/components/landing/CommunityPageBody";

export const metadata: Metadata = {
  title: "Community – Platz, Stimmen, Gruppen",
  description:
    "FlowLine-Community hängt an der Tour: Stimmen, Mappe, Gruppen und Public Profile. Kein Feed auf dem Hof.",
};

export default function CommunityPage() {
  return <CommunityPageBody />;
}
