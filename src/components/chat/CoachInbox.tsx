"use client";

import Link from "next/link";
import { useAppStore } from "@/store/useAppStore";
import { useCoachInbox } from "@/hooks/useCoachInbox";
import type { CoachInboxItem } from "@/lib/ai/coachInbox";
import { cn } from "@/lib/utils";

function severityLabel(s: CoachInboxItem["severity"]): string {
  if (s === "overdue") return "Überfällig";
  if (s === "due_soon") return "Bald";
  return "Hinweis";
}

export function CoachInbox({
  onAsk,
}: {
  onAsk?: (item: CoachInboxItem) => void;
}) {
  const { items } = useCoachInbox();
  const snooze = useAppStore((s) => s.snoozeCoachNotice);
  const markRead = useAppStore((s) => s.markCoachNoticesRead);

  if (items.length === 0) {
    return (
      <p className="rounded-2xl border border-border bg-surface px-3 py-2 text-sm text-text-secondary">
        Nichts steht an. Der Assistent schaut auf Wartung, Verschleiß, Setup und
        Kompatibilität.
      </p>
    );
  }

  return (
    <ul className="flex flex-col gap-2" data-testid="coach-inbox">
      {items.map((item) => (
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
                {severityLabel(item.severity)}
                {item.unread ? " · neu" : ""}
              </p>
              <p className="text-sm font-semibold">{item.title}</p>
              <p className="mt-0.5 text-xs text-text-secondary">{item.detail}</p>
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
                Assistent fragen
              </button>
            ) : (
              <Link
                href={item.href}
                className="rounded-full bg-chrome px-3 py-1 text-xs font-semibold text-on-accent"
                onClick={() => markRead([item])}
              >
                Öffnen
              </Link>
            )}
            <Link
              href={item.href}
              className="rounded-full border border-border px-3 py-1 text-xs font-medium"
              onClick={() => markRead([item])}
            >
              Zur Stelle
            </Link>
            <button
              type="button"
              className="rounded-full border border-border px-3 py-1 text-xs text-text-secondary"
              onClick={() => snooze(item.id, item.fingerprint)}
            >
              7 Tage still
            </button>
          </div>
        </li>
      ))}
    </ul>
  );
}
