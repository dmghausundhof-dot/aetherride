"use client";

import { useState } from "react";

type QueueItem = {
  id: string;
  tour_id?: string;
  body?: string;
  caption?: string;
  rating?: number;
  author_label?: string;
  url?: string | null;
  ai_labels?: string[];
  ai_confidence?: number;
  moderation_note?: string;
};

export default function CommunityModerationPage() {
  const [key, setKey] = useState("");
  const [reviews, setReviews] = useState<QueueItem[]>([]);
  const [photos, setPhotos] = useState<QueueItem[]>([]);
  const [msg, setMsg] = useState("");

  async function load() {
    setMsg("Lade …");
    const res = await fetch("/api/community/moderate?status=pending", {
      credentials: "include",
      headers: key ? { "x-moderation-key": key } : {},
    });
    const data = await res.json();
    if (!res.ok) {
      setMsg(data.error || "unauthorized");
      return;
    }
    setReviews(data.reviews || []);
    setPhotos(data.photos || []);
    setMsg(
      `${(data.reviews || []).length} Reviews, ${(data.photos || []).length} Fotos`
    );
  }

  async function act(
    kind: "review" | "photo",
    id: string,
    action: "approved" | "rejected"
  ) {
    const res = await fetch("/api/community/moderate", {
      method: "POST",
      credentials: "include",
      headers: {
        "Content-Type": "application/json",
        ...(key ? { "x-moderation-key": key } : {}),
      },
      body: JSON.stringify({ kind, id, action, note: "human ui" }),
    });
    if (!res.ok) {
      setMsg("Aktion fehlgeschlagen");
      return;
    }
    await load();
  }

  async function drainAi() {
    setMsg("AI-Lauf …");
    const res = await fetch("/api/community/moderate", {
      method: "POST",
      credentials: "include",
      headers: {
        "Content-Type": "application/json",
        ...(key ? { "x-moderation-key": key } : {}),
      },
      body: JSON.stringify({ drainAi: true }),
    });
    const data = await res.json();
    setMsg(
      res.ok
        ? `AI: ${(data.processed || []).length} verarbeitet`
        : data.error || "fail"
    );
    if (res.ok) await load();
  }

  return (
    <main className="mx-auto max-w-3xl px-4 py-10">
      <h1 className="text-2xl font-bold">Community-Moderation</h1>
      <p className="mt-2 text-sm text-text-secondary">
        Queue für pending Reviews/Fotos. AI kann vorentscheiden; Fotos werden
        nie automatisch veröffentlicht.
      </p>
      <div className="mt-4 flex flex-wrap gap-2">
        <input
          type="password"
          className="min-w-[12rem] flex-1 rounded-lg border border-border bg-surface px-3 py-2 text-sm"
          placeholder="Key optional, wenn deine Mail in COMMUNITY_MODERATOR_EMAILS steht"
          value={key}
          onChange={(e) => setKey(e.target.value)}
        />
        <button
          type="button"
          className="rounded-xl bg-accent px-3 py-2 text-sm font-semibold text-on-accent"
          onClick={() => void load()}
        >
          Laden
        </button>
        <button
          type="button"
          className="rounded-lg border border-border px-3 py-2 text-sm"
          onClick={() => void drainAi()}
        >
          AI-Queue
        </button>
      </div>
      {msg ? <p className="mt-3 text-sm text-text-secondary">{msg}</p> : null}

      <h2 className="mt-8 text-lg font-semibold">Reviews</h2>
      <ul className="mt-3 space-y-3">
        {reviews.map((r) => (
          <li key={r.id} className="rounded-xl border border-border p-4 text-sm">
            <p className="font-medium">
              ★ {r.rating} · {r.author_label} · {r.tour_id}
            </p>
            <p className="mt-1 text-text-secondary">{r.body}</p>
            <p className="mt-1 text-xs text-text-secondary">
              {(r.ai_labels || []).join(", ")}{" "}
              {r.ai_confidence != null
                ? `· ${Math.round(r.ai_confidence * 100)}%`
                : ""}
            </p>
            <div className="mt-2 flex gap-2">
              <button
                type="button"
                className="text-xs font-semibold text-accent"
                onClick={() => void act("review", r.id, "approved")}
              >
                Freigeben
              </button>
              <button
                type="button"
                className="text-xs font-semibold text-error"
                onClick={() => void act("review", r.id, "rejected")}
              >
                Ablehnen
              </button>
            </div>
          </li>
        ))}
      </ul>

      <h2 className="mt-8 text-lg font-semibold">Fotos</h2>
      <ul className="mt-3 space-y-3">
        {photos.map((p) => (
          <li key={p.id} className="rounded-xl border border-border p-4 text-sm">
            {p.url ? (
              // eslint-disable-next-line @next/next/no-img-element
              <img
                src={p.url}
                alt=""
                className="mb-2 h-32 w-auto rounded-lg object-cover"
              />
            ) : null}
            <p className="text-text-secondary">{p.caption || p.tour_id}</p>
            <div className="mt-2 flex gap-2">
              <button
                type="button"
                className="text-xs font-semibold text-accent"
                onClick={() => void act("photo", p.id, "approved")}
              >
                Freigeben
              </button>
              <button
                type="button"
                className="text-xs font-semibold text-error"
                onClick={() => void act("photo", p.id, "rejected")}
              >
                Ablehnen
              </button>
            </div>
          </li>
        ))}
      </ul>
    </main>
  );
}
