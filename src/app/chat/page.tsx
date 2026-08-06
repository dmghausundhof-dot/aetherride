"use client";

import { useMemo, useState } from "react";
import { MessageSquare, ShieldAlert, Wrench } from "lucide-react";
import { useAppStore } from "@/store/useAppStore";
import { detectTool, runChatTool, type ChatToolName } from "@/lib/ai/chat";
import Link from "next/link";

type Msg = {
  id: string;
  role: "user" | "assistant";
  text: string;
  tool?: ChatToolName;
  guarded?: boolean;
  rejected?: string[];
};

export default function ChatPage() {
  const bikes = useAppStore((s) => s.bikes);
  const activeBikeId = useAppStore((s) => s.activeBikeId);
  const rides = useAppStore((s) => s.rides);
  const profile = useAppStore((s) => s.riderProfile);
  const calibration = useAppStore((s) => s.rangeCalibration);
  const isRiding = useAppStore((s) => s.isRiding);
  const bike = bikes.find((b) => b.id === activeBikeId) || bikes[0];

  const [input, setInput] = useState("");
  const [tool, setTool] = useState<ChatToolName | "auto">("auto");
  const [messages, setMessages] = useState<Msg[]>([
    {
      id: "sys",
      role: "assistant",
      text: "Fragen zu Garage, Kompatibilität, Setup, Rides, Routen oder Produkten. Zahlen kommen nur aus Engines (Numeric-Guard, F-AI-001/004).",
    },
  ]);

  const ctx = useMemo(
    () => ({
      bike,
      bikes,
      rides,
      profile,
      calibration,
    }),
    [bike, bikes, rides, profile, calibration]
  );

  const send = () => {
    if (!input.trim() || isRiding) return;
    const q = input.trim();
    const chosen = tool === "auto" ? detectTool(q) : tool;
    const result = runChatTool(chosen, q, ctx);
    setMessages((m) => [
      ...m,
      { id: `u-${Date.now()}`, role: "user", text: q },
      {
        id: `a-${Date.now()}`,
        role: "assistant",
        text: result.text,
        tool: chosen,
        guarded: result.usedFallback,
        rejected: result.rejectedNumbers,
      },
    ]);
    setInput("");
  };

  return (
    <div className="flex flex-col gap-4 p-4 pt-6">
      <header>
        <h1 className="flex items-center gap-2 text-2xl font-bold">
          <MessageSquare className="h-6 w-6 text-accent" /> KI-Chat
        </h1>
        <p className="text-sm text-text-secondary">
          F-AI-004 · Werkzeuge · Numeric-Guard · keine Fahrt-Bedienung
        </p>
      </header>

      {isRiding && (
        <div className="rounded-xl border border-error/40 bg-error/10 px-3 py-2 text-sm text-error">
          Chat während der Fahrt gesperrt (Spec F-AI-004).
        </div>
      )}

      <div className="flex flex-wrap gap-1 text-[10px]">
        {(
          [
            "auto",
            "garage",
            "compat",
            "setup_history",
            "ride_stats",
            "route_search",
            "product_search",
            "range",
          ] as const
        ).map((t) => (
          <button
            key={t}
            type="button"
            onClick={() => setTool(t)}
            className={`rounded-full px-2 py-1 ${
              tool === t ? "bg-accent text-white" : "bg-surface-elevated"
            }`}
          >
            {t}
          </button>
        ))}
      </div>

      <div className="flex max-h-[50vh] flex-col gap-2 overflow-y-auto rounded-2xl border border-border bg-surface p-3">
        {messages.map((m) => (
          <div
            key={m.id}
            className={`rounded-xl px-3 py-2 text-sm ${
              m.role === "user"
                ? "ml-8 bg-accent/20"
                : "mr-4 bg-surface-elevated"
            }`}
          >
            <p>{m.text}</p>
            {m.tool && (
              <p className="mt-1 flex items-center gap-1 text-[10px] text-text-secondary">
                <Wrench className="h-3 w-3" /> {m.tool}
                {m.guarded && (
                  <span className="inline-flex items-center gap-0.5 text-warning">
                    <ShieldAlert className="h-3 w-3" /> Guard → Fallback
                    {m.rejected?.length
                      ? ` (verwirft ${m.rejected.join(", ")})`
                      : ""}
                  </span>
                )}
              </p>
            )}
          </div>
        ))}
      </div>

      <div className="flex gap-2">
        <input
          value={input}
          disabled={isRiding}
          onChange={(e) => setInput(e.target.value)}
          onKeyDown={(e) => e.key === "Enter" && send()}
          placeholder="z. B. Passt die Kassette? / Reichweite?"
          className="flex-1 rounded-xl border border-border bg-surface-elevated px-3 py-2 text-sm"
        />
        <button
          type="button"
          disabled={isRiding}
          onClick={send}
          className="rounded-xl bg-accent px-4 py-2 text-sm font-semibold text-white disabled:opacity-40"
        >
          Senden
        </button>
      </div>

      <p className="text-center text-xs text-text-secondary">
        <Link href="/profile" className="text-accent">
          Profil / Einwilligungen
        </Link>
        {" · "}
        Tipp: „erfinde 999 km“ testet den Numeric-Guard
      </p>
    </div>
  );
}
