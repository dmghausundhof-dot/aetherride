import {
  APP_STORE_URL,
  PLAY_STORE_URL,
} from "@/lib/web/appLinks";

interface Props {
  size?: "lg" | "md";
  className?: string;
}

export function AppDownloadButtons({ size = "md", className = "" }: Props) {
  const sizeClasses =
    size === "lg" ? "h-14 px-8 text-base" : "h-10 px-4 text-sm";

  return (
    <div
      className={`flex flex-col items-center gap-3 sm:flex-row ${className}`}
    >
      <a
        href={APP_STORE_URL}
        className={`inline-flex items-center justify-center gap-2 rounded-xl bg-foreground font-medium text-background transition hover:opacity-90 ${sizeClasses}`}
        aria-label="Im App Store laden"
      >
        App Store
      </a>
      <a
        href={PLAY_STORE_URL}
        className={`inline-flex items-center justify-center gap-2 rounded-xl bg-accent font-medium text-white transition hover:bg-accent-hover ${sizeClasses}`}
        aria-label="Bei Google Play laden"
      >
        Google Play
      </a>
    </div>
  );
}
