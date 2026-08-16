"use client";

import {
  APP_STORE_URL,
  PLAY_STORE_URL,
  hasStoreLinks,
} from "@/lib/web/appLinks";
import { useChromeLang } from "@/hooks/useChromeLang";
import { webChrome } from "@/lib/i18n/webChrome";

interface Props {
  size?: "lg" | "md";
  className?: string;
}

export function AppDownloadButtons({ size = "md", className = "" }: Props) {
  const copy = webChrome(useChromeLang());
  const sizeClasses =
    size === "lg" ? "h-14 px-8 text-base" : "h-10 px-4 text-sm";

  const appStoreReady = APP_STORE_URL !== "#";
  const playReady = PLAY_STORE_URL !== "#";

  if (!hasStoreLinks()) {
    // Documented web entry — no placeholder / “coming soon” chrome
    return (
      <div className={`flex flex-col items-center ${className}`}>
        <a
          href="/download"
          className={`inline-flex items-center justify-center rounded-xl border border-border font-medium text-foreground transition hover:bg-surface-elevated ${sizeClasses}`}
        >
          {copy.discoverApp}
        </a>
      </div>
    );
  }

  return (
    <div
      className={`flex flex-col items-center gap-3 sm:flex-row ${className}`}
    >
      {appStoreReady ? (
        <a
          href={APP_STORE_URL}
          className={`inline-flex items-center justify-center gap-2 rounded-xl bg-foreground font-medium text-background transition hover:opacity-90 ${sizeClasses}`}
          aria-label={copy.loadAppStore}
          rel="noopener noreferrer"
        >
          App Store
        </a>
      ) : null}
      {playReady ? (
        <a
          href={PLAY_STORE_URL}
          className={`inline-flex items-center justify-center gap-2 rounded-xl border border-border font-medium text-foreground transition hover:bg-surface-elevated ${sizeClasses}`}
          aria-label={copy.loadPlayStore}
          rel="noopener noreferrer"
        >
          Google Play
        </a>
      ) : null}
    </div>
  );
}
