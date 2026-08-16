"use client";

import { useState } from "react";
import { Link2, Check } from "lucide-react";
import { useAppStore } from "@/store/useAppStore";
import { useCommunityStore } from "@/store/useCommunityStore";
import {
  encodeSharePayload,
  shareCollectionPath,
} from "@/lib/community/shareCodec";
import type { SharedCollectionPayload } from "@/lib/community/types";
import { shareableRouteIds } from "@/lib/tours/routeVisibility";
import { useChromeLang } from "@/hooks/useChromeLang";
import { platzCopy } from "@/lib/i18n/platzCopy";

export function ShareCollectionButton({
  collectionId,
}: {
  collectionId: string;
}) {
  const collections = useAppStore((s) => s.routeCollections);
  const savedRoutes = useAppStore((s) => s.savedRoutes);
  const publicProfile = useCommunityStore((s) => s.publicProfile);
  const setToken = useCommunityStore((s) => s.setCollectionShareToken);
  const p = platzCopy(useChromeLang());
  const [copied, setCopied] = useState(false);
  const [url, setUrl] = useState<string | null>(null);
  const [serverId, setServerId] = useState<string | null>(null);
  const [err, setErr] = useState<string | null>(null);

  const collection = collections.find((c) => c.id === collectionId);
  if (!collection) return null;

  const createShare = async () => {
    if (collection.routeIds.length === 0) {
      setErr(p.shareEmpty);
      return;
    }
    const routeIds = shareableRouteIds(collection.routeIds, savedRoutes);
    if (routeIds.length === 0) {
      setErr(p.shareNoPublic);
      return;
    }
    const routeNames = routeIds.map((id) => {
      const r = savedRoutes.find((x) => x.id === id);
      return r?.name ?? id;
    });
    const payload: SharedCollectionPayload = {
      v: 1,
      name: collection.name,
      routeIds,
      routeNames,
      authorLabel: publicProfile.displayName || "FlowLine-Fahrer:in",
      authorHandle: publicProfile.enabled
        ? publicProfile.handle || undefined
        : undefined,
      createdAt: new Date().toISOString(),
    };
    let path = "";
    try {
      const res = await fetch("/api/community/collections", {
        method: "POST",
        credentials: "include",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ payload }),
      });
      if (res.ok) {
        const data = (await res.json()) as { path?: string; id?: string };
        path = data.path || (data.id ? `/share/c/${data.id}` : "");
        if (data.id) setServerId(data.id);
      }
    } catch {
      /* fall back to URL token */
    }
    if (!path) {
      const token = encodeSharePayload(payload);
      if (token.length > 1800) {
        setErr(p.shareTooBig);
        return;
      }
      setToken(collectionId, token);
      path = shareCollectionPath(token);
    }
    const full =
      typeof window !== "undefined"
        ? `${window.location.origin}${path}`
        : path;
    setUrl(full);
    try {
      await navigator.clipboard.writeText(full);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    } catch {
      /* show URL for manual copy */
    }
    setErr(null);
  };

  return (
    <div className="flex flex-col items-end gap-1">
      <button
        type="button"
        onClick={() => void createShare()}
        className="inline-flex items-center gap-1.5 rounded-lg border border-border px-2.5 py-1.5 text-[11px] font-medium hover:border-accent/40"
      >
        {copied ? (
          <Check className="h-3.5 w-3.5 text-success" />
        ) : (
          <Link2 className="h-3.5 w-3.5 text-accent" />
        )}
        {copied ? p.shareCopied : p.share}
      </button>
      {url && (
        <a
          href={url}
          className="max-w-[14rem] truncate text-[10px] text-accent hover:underline"
        >
          {url}
        </a>
      )}
      {err && <p className="text-[10px] text-warning">{err}</p>}
      {serverId ? (
        <button
          type="button"
          className="text-[10px] text-text-secondary underline"
          onClick={() => {
            void (async () => {
              const res = await fetch(
                `/api/community/collections?id=${encodeURIComponent(serverId)}`,
                { method: "DELETE", credentials: "include" }
              );
              if (res.ok) {
                setServerId(null);
                setUrl(null);
                setErr(null);
              } else {
                setErr(p.shareRevokeFail);
              }
            })();
          }}
        >
          {p.shareRevoke}
        </button>
      ) : null}
    </div>
  );
}
