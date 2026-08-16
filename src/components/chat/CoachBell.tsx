"use client";

import Link from "next/link";
import { Bell } from "lucide-react";
import { useCoachInbox } from "@/hooks/useCoachInbox";
import { useHofCopy } from "@/hooks/useHofCopy";

export function CoachBell({
  includeTestIds = true,
}: {
  includeTestIds?: boolean;
}) {
  const copy = useHofCopy();

  const { unread } = useCoachInbox();
  if (unread <= 0) return null;
  return (
    <Link
      href="/chat"
      className="relative rounded-full p-2 text-text-secondary hover:bg-surface-elevated hover:text-chrome"
      aria-label={`${copy.coachBell} · ${copy.coachUnread(unread)}`}
      data-testid={includeTestIds ? "coach-bell" : undefined}
    >
      <Bell className="h-5 w-5" strokeWidth={1.75} />
      {unread > 0 ? (
        <span className="absolute right-0.5 top-0.5 flex h-4 min-w-4 items-center justify-center rounded-full bg-error px-0.5 text-[9px] font-bold text-foreground">
          {unread > 9 ? "9+" : unread}
        </span>
      ) : null}
    </Link>
  );
}
