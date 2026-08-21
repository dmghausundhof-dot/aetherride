/**
 * Server-only: cookie override, then Accept-Language.
 * This browser — not a field on the rider profile.
 */
import { cookies, headers } from "next/headers";
import {
  CHROME_LANG_COOKIE,
  chromeLangOverrideFrom,
  resolveChromeLang,
  type ChromeLang,
} from "./chromeLang";

export async function requestChromeLang(): Promise<{
  lang: ChromeLang;
  override: ChromeLang | null;
}> {
  const cookieStore = await cookies();
  const hdrs = await headers();
  const override = chromeLangOverrideFrom(
    cookieStore.get(CHROME_LANG_COOKIE)?.value ?? null
  );
  const lang = resolveChromeLang({
    override,
    acceptLanguage: hdrs.get("accept-language"),
  });
  return { lang, override };
}
