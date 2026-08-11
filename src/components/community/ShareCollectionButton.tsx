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

export function ShareCollectionButton({
  collectionId,
}: {
  collectionId: string;
}) {
  const collections = useAppStore((s) => s.routeCollections);
  const savedRoutes = useAppStore((s) => s.savedRoutes);
  const publicProfile = useCommunityStore((s) => s.publicProfile);
  const setToken = useCommunityStore((s) => s.setCollectionShareToken);
  const [copied, setCopied] = useState(false);
  const [url, setUrl] = useState<string | null>(null);
  const [err, setErr] = useState<string | null>(null);

  const collection = collections.find((c) => c.id === collectionId);
  if (!collection) return null;

  const createShare = async () => {
    if (collection.routeIds.length === 0) {
      setErr("Sammlung ist leer — zuerst Touren hinzufügen.");
      return;
    }
    const routeNames = collection.routeIds.map((id) => {
      const r = savedRoutes.find((x) => x.id === id);
      return r?.name ?? id;
    });
    const payload: SharedCollectionPayload = {
      v: 1,
      name: collection.name,
      routeIds: collection.routeIds,
      routeNames,
      authorLabel: publicProfile.displayName || "AetherRide-Fahrer:in",
      authorHandle: publicProfile.enabled
        ? publicProfile.handle || undefined
        : undefined,
      createdAt: new Date().toISOString(),
    };
    const token = encodeSharePayload(payload);
    if (token.length > 1800) {
      setErr("Sammlung zu groß für URL-Share — weniger Touren wählen.");
      return;
    }
    setToken(collectionId, token);
    const path = shareCollectionPath(token);
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
        {copied ? "Kopiert" : "Teilen"}
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
    </div>
  );
}
