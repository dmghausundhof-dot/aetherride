import type { Metadata } from "next";
import { AboutPageBody } from "@/components/landing/AboutPageBody";

export const metadata: Metadata = {
  title: "Über FlowLine",
  description:
    "Warum FlowLine einen Hof hat und keinen Feed. Outdoor Cycling im Browser planen, in der App fahren. Fünf Türen, ehrlicher Stand.",
};

export default function AboutPage() {
  return <AboutPageBody />;
}
