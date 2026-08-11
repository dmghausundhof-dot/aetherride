"use client";

import { useEffect, useState } from "react";
import type { RoutingStatusPayload } from "@/lib/routing/routingStatus";

export function RoutingStatusBanner({ className = "" }: { className?: string }) {
  const [status, setStatus] = useState<
    (RoutingStatusPayload & {
      publicOsrm?: boolean;
      probe?: { ok: boolean; detail?: string };
    }) | null
  >(null);

  useEffect(() => {
    let cancelled = false;
    void fetch("/api/routing/status?probe=1")
      .then((r) => r.json())
      .then((j) => {
        if (!cancelled) setStatus(j);
      })
      .catch(() => {
        if (!cancelled)
          setStatus({
            configured: false,
            engine: "demo",
            liveVerified: false,
            notice: "Routing-Status nicht erreichbar",
          });
      });
    return () => {
      cancelled = true;
    };
  }, []);

  if (!status?.notice && status?.liveVerified && status.configured) {
    return (
      <p
        className={`rounded-lg border border-success/30 bg-success/10 px-2.5 py-1.5 text-[11px] text-text-secondary ${className}`}
      >
        Live-Routing: {status.engine}
        {status.probe?.detail ? ` · Probe ${status.probe.detail}` : " · OK"}
      </p>
    );
  }

  if (!status?.notice) return null;

  return (
    <p
      className={`rounded-lg border border-border bg-surface-elevated px-2.5 py-1.5 text-[11px] text-text-secondary ${className}`}
    >
      {status.notice}
      {status.engine ? ` · Engine: ${status.engine}` : ""}
      {status.probe && !status.probe.ok
        ? ` · Probe: ${status.probe.detail ?? "fehlgeschlagen"}`
        : ""}
    </p>
  );
}
