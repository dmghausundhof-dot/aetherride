import type { Metadata } from "next";
import { hofCopy, type HofCopy } from "@/lib/home/hofCopy";
import { requestChromeLang } from "./requestChromeLang";
import type { ChromeLang } from "./chromeLang";

export async function chromeRequestLang(): Promise<ChromeLang> {
  return (await requestChromeLang()).lang;
}

export async function hofDoorMeta(
  pick: (c: HofCopy) => { title: string; description: string }
): Promise<Metadata> {
  const lang = await chromeRequestLang();
  return pick(hofCopy(lang));
}
