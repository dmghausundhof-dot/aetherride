import type { Metadata } from "next";
import { DownloadPageBody } from "@/components/landing/DownloadPageBody";

export const metadata: Metadata = {
  title: "App laden – FlowLine",
  description:
    "FlowLine für Android und iOS: Navigation, Offline und Sensoren. Der Hof bleibt im Browser.",
};

export default function DownloadPage() {
  return <DownloadPageBody />;
}
