import type { Metadata } from "next";
import { LandingHeader } from "@/components/landing/LandingHeader";
import { LandingFooter } from "@/components/landing/LandingFooter";
import { chromeRequestLang } from "@/lib/i18n/hofDoorMeta";
import { shareCopy } from "@/lib/i18n/shareCopy";

export async function generateMetadata(): Promise<Metadata> {
  const copy = shareCopy(await chromeRequestLang());
  return {
    title: copy.title,
    description: copy.lead,
  };
}

export default function ShareLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <div className="flex min-h-screen flex-col">
      <LandingHeader />
      <main className="flex-1">{children}</main>
      <LandingFooter />
    </div>
  );
}
