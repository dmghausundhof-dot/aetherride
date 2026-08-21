import type { Metadata } from "next";
import { LandingHeader } from "@/components/landing/LandingHeader";
import { LandingFooter } from "@/components/landing/LandingFooter";
import { chromeRequestLang } from "@/lib/i18n/hofDoorMeta";
import { profileCopy } from "@/lib/i18n/profileCopy";

export async function generateMetadata(): Promise<Metadata> {
  const copy = profileCopy(await chromeRequestLang());
  return {
    title: copy.publicTitle,
    description: copy.publicHint,
  };
}

export default function PublicProfileLayout({
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
