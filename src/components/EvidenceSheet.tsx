"use client";

import { useId, useState, type ReactNode } from "react";
import { ChevronDown } from "lucide-react";
import { cn } from "@/lib/utils";

/**
 * Inline „Warum?“ / Evidence — ersetzt Chat-Öffnen für Erklärungen.
 */
export function EvidenceSheet({
  title = "Warum?",
  children,
  className,
  defaultOpen = false,
}: {
  title?: string;
  children: ReactNode;
  className?: string;
  defaultOpen?: boolean;
}) {
  const [open, setOpen] = useState(defaultOpen);
  const panelId = useId();

  return (
    <div className={cn("text-sm", className)}>
      <button
        type="button"
        aria-expanded={open}
        aria-controls={panelId}
        onClick={() => setOpen((v) => !v)}
        className="inline-flex items-center gap-1 text-xs font-medium text-accent"
      >
        {title}
        <ChevronDown
          className={cn("h-3.5 w-3.5 transition", open && "rotate-180")}
        />
      </button>
      {open && (
        <div
          id={panelId}
          className="mt-2 rounded-xl bg-surface-elevated px-3 py-2 text-xs text-text-secondary leading-relaxed"
        >
          {children}
        </div>
      )}
    </div>
  );
}
