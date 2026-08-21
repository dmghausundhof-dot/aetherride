import type { Metadata } from "next";
import { LandingHeader } from "@/components/landing/LandingHeader";
import { LandingFooter } from "@/components/landing/LandingFooter";
import { hofCopy } from "@/lib/home/hofCopy";
import { chromeRequestLang } from "@/lib/i18n/hofDoorMeta";
import { openRideCopy } from "@/lib/i18n/openRideCopy";

export async function generateMetadata(): Promise<Metadata> {
  const lang = await chromeRequestLang();
  return {
    title: openRideCopy(lang).title,
    description: hofCopy(lang).rideBridgeHint,
    robots: { index: false, follow: true },
  };
}

export default function OpenLayout({
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
