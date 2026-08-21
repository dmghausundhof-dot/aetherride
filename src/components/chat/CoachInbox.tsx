"use client";

import Link from "next/link";
import { useAppStore } from "@/store/useAppStore";
import { useCoachInbox } from "@/hooks/useCoachInbox";
import type { CoachInboxItem } from "@/lib/ai/coachInbox";
import { localizeCoachNotice } from "@/lib/ai/coachWatch";
import { cn } from "@/lib/utils";
import { useChromeLang } from "@/hooks/useChromeLang";
import { chatCopy } from "@/lib/i18n/chatCopy";

export function CoachInbox({
  onAsk,
}: {
  onAsk?: (item: CoachInboxItem) => void;
}) {
  const lang = useChromeLang();
  const copy = chatCopy(lang);
  const { items } = useCoachInbox();
  const snooze = useAppStore((s) => s.snoozeCoachNotice);
  const markRead = useAppStore((s) => s.markCoachNoticesRead);

  if (items.length === 0) {
    return (
      <p className="rounded-2xl border border-border bg-surface px-3 py-2 text-sm text-text-secondary">
        {copy.inboxEmpty}
      </p>
    );
  }

  return (
    <ul className="flex flex-col gap-2" data-testid="coach-inbox">
      {items.map((item) => {
        const loc = localizeCoachNotice(item, lang);
        const sev =
          item.severity === "overdue"
            ? copy.sevOverdue
            : item.severity === "due_soon"
              ? copy.sevSoon
              : copy.sevInfo;
        return (
          <li
            key={item.id}
            className={cn(
              "rounded-2xl border bg-surface px-3 py-2",
              item.severity === "overdue"
                ? "border-error/40"
                : item.unread
                  ? "border-accent/40"
                  : "border-border"
            )}
          >
            <div className="flex items-start justify-between gap-2">
              <div className="min-w-0">
                <p className="text-[10px] font-bold uppercase tracking-wide text-text-secondary">
                  {sev}
                  {item.unread ? ` · ${copy.sevNew}` : ""}
                </p>
                <p className="text-sm font-semibold">{loc.title}</p>
                <p className="mt-0.5 text-xs text-text-secondary">{loc.detail}</p>
              </div>
            </div>
            <div className="mt-2 flex flex-wrap gap-2">
              {onAsk ? (
                <button
                  type="button"
                  className="rounded-full bg-chrome px-3 py-1 text-xs font-semibold text-on-accent"
                  onClick={() => {
                    markRead([item]);
                    onAsk(item);
                  }}
                >
                  {copy.inboxAsk}
                </button>
              ) : (
                <Link
                  href={item.href}
                  className="rounded-full bg-chrome px-3 py-1 text-xs font-semibold text-on-accent"
                  onClick={() => markRead([item])}
                >
                  {copy.inboxOpen}
                </Link>
              )}
              <Link
                href={item.href}
                className="rounded-full border border-border px-3 py-1 text-xs font-medium"
                onClick={() => markRead([item])}
              >
                {copy.inboxPlace}
              </Link>
              <button
                type="button"
                className="rounded-full border border-border px-3 py-1 text-xs text-text-secondary"
                onClick={() => snooze(item.id, item.fingerprint)}
              >
                {copy.inboxSnooze}
              </button>
            </div>
          </li>
        );
      })}
    </ul>
  );
}
