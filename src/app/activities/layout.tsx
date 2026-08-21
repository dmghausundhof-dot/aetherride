import type { Metadata } from "next";
import { headers } from "next/headers";
import { chromeLangFromAcceptLanguage } from "@/lib/i18n/chromeLang";
import { hofCopy } from "@/lib/home/hofCopy";

export async function generateMetadata(): Promise<Metadata> {
  const lang = chromeLangFromAcceptLanguage(
    (await headers()).get("accept-language")
  );
  const copy = hofCopy(lang);
  return {
    title: copy.activitiesTitle,
    description: copy.activitiesHint,
  };
}

export default function ActivitiesLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return children;
}
