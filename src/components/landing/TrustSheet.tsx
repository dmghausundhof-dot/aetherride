"use client";

import { useEffect, useId, useRef } from "react";

type TrustSheetProps = {
  open: boolean;
  onClose: () => void;
};

/**
 * L-TRUST-01 — Fairness Trust-Sheet (locked copy 1:1).
 * Calm dismiss — no PRO / urgency chrome.
 */
export function TrustSheet({ open, onClose }: TrustSheetProps) {
  const titleId = useId();
  const closeRef = useRef<HTMLButtonElement>(null);

  useEffect(() => {
    if (!open) return;
    const prev = document.body.style.overflow;
    document.body.style.overflow = "hidden";
    closeRef.current?.focus();

    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") onClose();
    };
    window.addEventListener("keydown", onKey);
    return () => {
      document.body.style.overflow = prev;
      window.removeEventListener("keydown", onKey);
    };
  }, [open, onClose]);

  if (!open) return null;

  return (
    <div
      className="fixed inset-0 z-[80] flex items-end justify-center sm:items-center"
      role="presentation"
    >
      <button
        type="button"
        aria-label="Schließen"
        className="absolute inset-0 bg-background/55 backdrop-blur-[1px] animate-hero-fade"
        onClick={onClose}
      />
      <div
        role="dialog"
        aria-modal="true"
        aria-labelledby={titleId}
        className="relative z-10 m-0 w-full max-w-[22rem] rounded-t-2xl border border-border/70 bg-surface px-7 pb-[max(1.75rem,env(safe-area-inset-bottom))] pt-6 shadow-xl shadow-black/25 animate-trust-sheet sm:m-4 sm:rounded-2xl sm:px-8 sm:pt-8"
      >
        <div className="mx-auto mb-5 h-0.5 w-8 rounded-full bg-border/80 sm:hidden" />
        <h2
          id={titleId}
          className="text-xl font-semibold tracking-[-0.02em] text-foreground sm:text-[1.35rem]"
        >
          Fair von Anfang an.
        </h2>
        <p className="mt-3.5 text-sm leading-relaxed text-text-secondary sm:text-[0.95rem] sm:leading-[1.55]">
          Sync, Navigation und Export bleiben frei — ohne Überraschungen mitten
          in der Tour.
        </p>
        <p className="mt-5 inline-flex items-center text-xs font-medium tracking-[0.01em] text-foreground/80">
          Offline ✓ frei
        </p>
        <button
          ref={closeRef}
          type="button"
          onClick={onClose}
          className="mt-8 inline-flex h-11 w-full items-center justify-center rounded-lg border border-foreground/20 bg-foreground/[0.06] text-sm font-medium text-foreground transition hover:bg-foreground/[0.1] focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-accent"
        >
          Verstanden
        </button>
      </div>
    </div>
  );
}
