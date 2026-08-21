"use client";

import { useLayoutEffect, useRef, useState, type ReactNode } from "react";

/** Horizontal scroller with a fade when more chips sit past the edge. */
export function FadeEdgeRow({
  children,
  className = "",
  fadeFromClass = "from-surface-elevated",
  testId,
}: {
  children: ReactNode;
  className?: string;
  fadeFromClass?: string;
  testId?: string;
}) {
  const ref = useRef<HTMLDivElement>(null);
  const [edge, setEdge] = useState({ start: false, end: false });

  useLayoutEffect(() => {
    const el = ref.current;
    if (!el) return;
    const update = () => {
      const max = el.scrollWidth - el.clientWidth;
      if (max <= 2) {
        setEdge({ start: false, end: false });
        return;
      }
      setEdge({
        start: el.scrollLeft > 2,
        end: el.scrollLeft < max - 2,
      });
    };
    update();
    const ro = new ResizeObserver(update);
    ro.observe(el);
    el.addEventListener("scroll", update, { passive: true });
    return () => {
      ro.disconnect();
      el.removeEventListener("scroll", update);
    };
  }, [children]);

  return (
    <div className="relative" data-testid={testId}>
      <div ref={ref} className={className}>
        {children}
      </div>
      {edge.start ? (
        <div
          aria-hidden
          className={`pointer-events-none absolute inset-y-0 left-0 w-8 bg-gradient-to-r ${fadeFromClass} to-transparent`}
        />
      ) : null}
      {edge.end ? (
        <div
          aria-hidden
          className={`pointer-events-none absolute inset-y-0 right-0 w-8 bg-gradient-to-l ${fadeFromClass} to-transparent`}
        />
      ) : null}
    </div>
  );
}
