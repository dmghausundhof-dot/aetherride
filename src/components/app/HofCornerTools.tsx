"use client";

import Link from "next/link";
import { ChromeGlyph } from "@/components/chrome/ChromeGlyph";
import { CoachBell } from "@/components/chat/CoachBell";
import { useHofCopy } from "@/hooks/useHofCopy";
import { cn } from "@/lib/utils";
import { useCommunityStore } from "@/store/useCommunityStore";

/** Coach + Profil — Native sitzt das in der Hof-Titelzeile, nicht in einer AppBar. */
export function HofCornerTools({
  className,
  includeTestIds = true,
}: {
  className?: string;
  /** Desktop-Header bleibt im DOM — Test-IDs nur an der mobilen Hof-Zeile. */
  includeTestIds?: boolean;
}) {
  const copy = useHofCopy();
  const publicProfile = useCommunityStore((s) => s.publicProfile);
  const initials = profileInitials(
    publicProfile.displayName || publicProfile.handle
  );

  return (
    <div className={cn("flex shrink-0 items-center gap-1", className)}>
      <CoachBell includeTestIds={includeTestIds} />
      <Link
        href="/profile"
        aria-label={copy.profile}
        data-testid={includeTestIds ? "hof-profile" : undefined}
        className="flex h-8 w-8 items-center justify-center rounded-full bg-background/50 text-xs font-bold text-chrome hover:bg-background/70"
      >
        {initials || (
          <ChromeGlyph name="user" size={16} current className="text-text-secondary" />
        )}
      </Link>
    </div>
  );
}

export function profileInitials(name: string): string {
  const parts = name.trim().split(/\s+/).filter(Boolean);
  if (parts.length >= 2) {
    return `${parts[0]![0]!}${parts[parts.length - 1]![0]!}`.toUpperCase();
  }
  if (parts.length === 1 && parts[0]!.length >= 2) {
    return parts[0]!.slice(0, 2).toUpperCase();
  }
  if (parts.length === 1) return parts[0]![0]!.toUpperCase();
  return "";
}
