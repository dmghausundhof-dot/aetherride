"use client";

import { useEffect, useId, useRef } from "react";

type TrustSheetProps = {
  open: boolean;
  onClose: () => void;
};

/**
 * L-TRUST-01 — Fairness Trust-Sheet (locked copy 1:1).
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
        className="absolute inset-0 bg-black/55 backdrop-blur-[2px] animate-hero-fade"
        onClick={onClose}
      />
      <div
        role="dialog"
        aria-modal="true"
        aria-labelledby={titleId}
        className="relative z-10 m-0 w-full max-w-md rounded-t-2xl border border-border bg-surface px-6 pb-[max(1.5rem,env(safe-area-inset-bottom))] pt-5 shadow-2xl shadow-black/40 animate-trust-sheet sm:m-4 sm:rounded-2xl"
      >
        <div className="mx-auto mb-4 h-1 w-10 rounded-full bg-border sm:hidden" />
        <h2
          id={titleId}
          className="text-xl font-bold tracking-tight text-foreground sm:text-2xl"
        >
          Fair von Anfang an.
        </h2>
        <p className="mt-3 text-sm leading-relaxed text-text-secondary sm:text-base">
          Sync, Navigation und Export bleiben frei — ohne Überraschungen mitten
          in der Tour.
        </p>
        <p className="mt-4 inline-flex items-center rounded-lg border border-border bg-background/70 px-3 py-1.5 text-xs font-medium text-foreground">
          Offline ✓ frei
        </p>
        <button
          ref={closeRef}
          type="button"
          onClick={onClose}
          className="mt-6 inline-flex h-12 w-full items-center justify-center rounded-xl bg-accent text-sm font-semibold text-white transition hover:bg-accent-hover focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-accent"
        >
          Verstanden
        </button>
      </div>
    </div>
  );
}
