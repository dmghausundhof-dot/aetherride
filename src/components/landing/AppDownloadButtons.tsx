import {
  APP_STORE_URL,
  PLAY_STORE_URL,
  hasStoreLinks,
} from "@/lib/web/appLinks";

interface Props {
  size?: "lg" | "md";
  className?: string;
}

export function AppDownloadButtons({ size = "md", className = "" }: Props) {
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
          App entdecken
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
          aria-label="Im App Store laden"
          rel="noopener noreferrer"
        >
          App Store
        </a>
      ) : null}
      {playReady ? (
        <a
          href={PLAY_STORE_URL}
          className={`inline-flex items-center justify-center gap-2 rounded-xl bg-accent font-medium text-white transition hover:bg-accent-hover ${sizeClasses}`}
          aria-label="Bei Google Play laden"
          rel="noopener noreferrer"
        >
          Google Play
        </a>
      ) : null}
    </div>
  );
}
