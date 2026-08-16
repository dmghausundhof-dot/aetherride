"use client";

import { useState } from "react";
import { Check, Link2 } from "lucide-react";
import { encodeTourShareToken, shareTourPath } from "@/lib/community/shareCodec";
import { useChromeLang } from "@/hooks/useChromeLang";
import { platzCopy } from "@/lib/i18n/platzCopy";
import type { SavedRoute } from "@/types/route";

export function ShareTourButton({ route }: { route: SavedRoute }) {
  const p = platzCopy(useChromeLang());
  const [copied, setCopied] = useState(false);
  const [url, setUrl] = useState<string | null>(null);
  const [note, setNote] = useState<string | null>(null);

  const copy = async () => {
    const { token, includeTrack, droppedTrack } = encodeTourShareToken(route);
    const path = shareTourPath(token);
    const full =
      typeof window !== "undefined" ? `${window.location.origin}${path}` : path;
    setUrl(full);
    if (droppedTrack) {
      setNote(p.linkNoTrackLong);
    } else if (includeTrack) {
      setNote(p.linkHasTrack);
    } else {
      setNote(p.linkNoTrack);
    }
    try {
      await navigator.clipboard.writeText(full);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    } catch {
      /* URL bleibt sichtbar */
    }
  };

  return (
    <div className="space-y-1">
      <button
        type="button"
        onClick={() => void copy()}
        className="inline-flex items-center gap-1.5 rounded-lg border border-border px-2.5 py-1.5 text-xs font-medium hover:border-accent/40"
      >
        {copied ? (
          <Check className="h-3.5 w-3.5 text-success" />
        ) : (
          <Link2 className="h-3.5 w-3.5 text-accent" />
        )}
        {copied ? p.shareCopied : p.copyLink}
      </button>
      {url ? (
        <a
          href={url}
          className="block max-w-full truncate text-[10px] text-accent hover:underline"
        >
          {url}
        </a>
      ) : null}
      {note ? <p className="text-[11px] text-text-secondary">{note}</p> : null}
    </div>
  );
}
