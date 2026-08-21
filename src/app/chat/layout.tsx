import type { Metadata } from "next";
import { hofCopy } from "@/lib/home/hofCopy";
import { chromeRequestLang } from "@/lib/i18n/hofDoorMeta";
import { chatCopy } from "@/lib/i18n/chatCopy";

export async function generateMetadata(): Promise<Metadata> {
  const lang = await chromeRequestLang();
  return {
    title: chatCopy(lang).title,
    description: hofCopy(lang).chatHint,
  };
}

export default function ChatLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return children;
}
