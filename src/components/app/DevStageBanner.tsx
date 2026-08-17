"use client";

import { isDevSurface } from "@/lib/config/appStage";

/** Visible on every page until NEXT_PUBLIC_APP_STAGE=launched. */
export function DevStageBanner() {
  if (!isDevSurface()) return null;

  return (
    <div
      role="status"
      className="border-b border-warning/40 bg-warning/15 px-4 py-2 text-center text-xs font-medium text-foreground"
    >
      Entwicklungsstand — kein öffentliches Angebot, keine Käufe, nicht
      indexiert.
    </div>
  );
}
