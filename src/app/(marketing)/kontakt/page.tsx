import type { Metadata } from "next";
import { KontaktPageBody } from "@/components/landing/KontaktPageBody";

export const metadata: Metadata = {
  title: "Kontakt",
  description:
    "FlowLine per E-Mail erreichen. Keine erfundene Anschrift, kein Chat-Bot.",
};

export default function KontaktPage() {
  return <KontaktPageBody />;
}
