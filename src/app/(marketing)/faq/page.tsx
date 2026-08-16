import type { Metadata } from "next";
import { FAQ_ITEMS } from "@/lib/content/faq";
import { faqJsonLd, siteOrigin } from "@/lib/content/siteJsonLd";
import { FaqPageBody } from "@/components/landing/FaqPageBody";

export const metadata: Metadata = {
  title: "FAQ – Web, App, Preise, Community",
  description:
    "FlowLine kurz erklärt: was im Browser läuft, was in der App, Free und Pro, Community ohne Feed.",
};

export default function FaqPage() {
  return (
    <div className="px-4 py-12 sm:px-6">
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{
          __html: JSON.stringify(faqJsonLd(siteOrigin(), FAQ_ITEMS)),
        }}
      />
      <FaqPageBody />
    </div>
  );
}
