"use client";

import { useMemo, useState } from "react";
import { MessageSquare, ShieldAlert, Wrench, ArrowLeft } from "lucide-react";
import { useAppStore } from "@/store/useAppStore";
import { type ChatToolName } from "@/lib/ai/chat";
import Link from "next/link";

type Msg = {
  id: string;
  role: "user" | "assistant";
  text: string;
  tool?: ChatToolName;
  guarded?: boolean;
  rejected?: string[];
  usedGrok?: boolean;
};

type QuotaInfo = {
  tier: string;
  dayUsed: number;
  dayLimit: number;
  remaining: number;
  resetAt?: string;
  reason?: string;
};

const SUGGESTED_PROMPTS: { label: string; query: string; tool: ChatToolName }[] =
  [
    {
      label: "Garage-Überblick",
      query: "Was steckt in meiner Garage?",
      tool: "garage",
    },
    {
      label: "Reichweite",
      query: "Welche Reichweite habe ich mit aktuellem Akku?",
      tool: "range",
    },
    {
      label: "Setup-Historie",
      query: "Welche Setups hatte ich und was hat sich geändert?",
      tool: "setup_history",
    },
    {
      label: "Ride-Stats",
      query: "Zusammenfassung meiner letzten Rides",
      tool: "ride_stats",
    },
    {
      label: "Routen",
      query: "Welche Routen passen zu mir?",
      tool: "route_search",
    },
    {
      label: "Verschleiß / Shop",
      query: "Brauche ich bald neue Verschleißteile?",
      tool: "product_search",
    },
  ];

export default function ChatPage() {
  const bikes = useAppStore((s) => s.bikes);
  const activeBikeId = useAppStore((s) => s.activeBikeId);
  const rides = useAppStore((s) => s.rides);
  const profile = useAppStore((s) => s.riderProfile);
  const calibration = useAppStore((s) => s.rangeCalibration);
  const isRiding = useAppStore((s) => s.isRiding);
  const subscriptionTier = useAppStore((s) => s.subscriptionTier);
  const bike = bikes.find((b) => b.id === activeBikeId) || bikes[0];

  const [input, setInput] = useState("");
  const [tool, setTool] = useState<ChatToolName | "auto">("auto");
  const [busy, setBusy] = useState(false);
  const [quota, setQuota] = useState<QuotaInfo | null>(null);
  const [messages, setMessages] = useState<Msg[]>([
    {
      id: "sys",
      role: "assistant",
      text: "Frag nach Garage, Setup, Reichweite, Routen oder Teilen. Zahlen kommen aus deinen App-Daten — nicht aus dem Chat-Modell. Für die meisten Entscheidungen reichen Home und Post-Ride.",
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

  const send = async (override?: { query: string; tool?: ChatToolName | "auto" }) => {
    const q = (override?.query ?? input).trim();
    if (!q || isRiding || busy) return;
    const toolHint = override?.tool ?? tool;
    setBusy(true);
    setMessages((m) => [...m, { id: `u-${Date.now()}`, role: "user", text: q }]);
    if (!override) setInput("");

    try {
      const res = await fetch("/api/chat", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          query: q,
          tool: toolHint,
          ...ctx,
        }),
      });
      const data = await res.json();
      if (data.quota) setQuota(data.quota);

      let text = data.text || data.error || "Keine Antwort.";
      if (res.status === 429) {
        text = `${text}\n\nLimit erreicht (${data.quota?.tier || "free"}). ${
          data.quota?.tier === "free"
            ? "Upgrade auf Pro für mehr KI-Antworten."
            : "Morgen wieder verfügbar."
        }`;
      }

      setMessages((m) => [
        ...m,
        {
          id: `a-${Date.now()}`,
          role: "assistant",
          text,
          tool: data.tool,
          guarded: data.usedFallback,
          rejected: data.rejectedNumbers,
          usedGrok: data.usedGrok,
        },
      ]);
    } catch (e) {
      setMessages((m) => [
        ...m,
        {
          id: `a-${Date.now()}`,
          role: "assistant",
          text: e instanceof Error ? e.message : "Netzwerkfehler",
        },
      ]);
    } finally {
      setBusy(false);
    }
  };

  return (
    <div className="flex flex-col gap-4 p-4 pt-6">
      <header>
        <Link
          href="/profile"
          className="mb-2 inline-flex items-center gap-1 text-sm text-accent"
        >
          <ArrowLeft className="h-4 w-4" /> Profil
        </Link>
        <h1 className="flex items-center gap-2 text-2xl font-bold">
          <MessageSquare className="h-6 w-6 text-accent" /> Mehr fragen
        </h1>
        <p className="text-sm text-text-secondary">
          KI-Coach zu Bike, Setup und Touren
        </p>
        {quota && (
          <p className="mt-1 text-xs text-text-secondary">
            Kontingent ({quota.tier}): {quota.dayUsed}/{quota.dayLimit} heute
            {quota.remaining != null ? ` · ${quota.remaining} übrig` : ""}
            {quota.reason === "login_required_for_grok"
              ? " · Anmeldung für Cloud-KI nötig"
              : ""}
          </p>
        )}
        {!quota && (
          <p className="mt-1 text-xs text-text-secondary">
            Tarif: {subscriptionTier} — Tageslimits nach Anmeldung
          </p>
        )}
      </header>

      {isRiding && (
        <div className="rounded-xl border border-error/40 bg-error/10 px-3 py-2 text-sm text-error">
          Chat während der Fahrt gesperrt — Sicherheit zuerst.
        </div>
      )}

      {quota && quota.remaining === 0 && quota.tier === "free" && (
        <div className="rounded-xl border border-accent/40 bg-accent/10 px-3 py-2 text-sm">
          Free-Limit ausgeschöpft.{" "}
          <Link href="/profile" className="font-semibold text-accent">
            Pro upgraden
          </Link>
        </div>
      )}

      <div className="flex flex-wrap gap-2">
        {SUGGESTED_PROMPTS.map((p) => (
          <button
            key={p.label}
            type="button"
            disabled={isRiding || busy}
            onClick={() => void send({ query: p.query, tool: p.tool })}
            className="rounded-full border border-border bg-surface px-3 py-1.5 text-xs font-medium disabled:opacity-40"
          >
            {p.label}
          </button>
        ))}
      </div>

      {process.env.NODE_ENV === "development" && (
      <details className="text-xs text-text-secondary">
        <summary className="cursor-pointer text-accent">
          Debug: Tool manuell wählen
        </summary>
        <div className="mt-2 flex flex-wrap gap-1">
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
      </details>
      )}

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
            <p className="whitespace-pre-wrap">{m.text}</p>
            {m.tool && process.env.NODE_ENV === "development" && (
              <p className="mt-1 flex flex-wrap items-center gap-1 text-[10px] text-text-secondary">
                <Wrench className="h-3 w-3" /> {m.tool}
                {m.usedGrok ? " · Cloud-KI" : " · lokal"}
                {m.guarded && (
                  <span className="inline-flex items-center gap-0.5 text-warning">
                    <ShieldAlert className="h-3 w-3" /> Zahlen geprüft
                    {m.rejected?.length
                      ? ` (verwirft ${m.rejected.join(", ")})`
                      : ""}
                  </span>
                )}
              </p>
            )}
            {m.guarded && process.env.NODE_ENV !== "development" && (
              <p className="mt-1 text-[10px] text-text-secondary">
                Antwort anhand deiner Garage-/Ride-Daten geprüft
              </p>
            )}
          </div>
        ))}
      </div>

      <div className="flex gap-2">
        <input
          value={input}
          disabled={isRiding || busy}
          onChange={(e) => setInput(e.target.value)}
          onKeyDown={(e) => e.key === "Enter" && void send()}
          placeholder="z. B. Passt die Kassette? / Reichweite?"
          className="flex-1 rounded-xl border border-border bg-surface-elevated px-3 py-2 text-sm"
        />
        <button
          type="button"
          disabled={isRiding || busy}
          onClick={() => void send()}
          className="rounded-xl bg-accent px-4 py-2 text-sm font-semibold text-white disabled:opacity-40"
        >
          {busy ? "…" : "Senden"}
        </button>
      </div>

      <p className="text-center text-xs text-text-secondary">
        <Link href="/" className="text-accent">
          Zurück zu Home
        </Link>
        {" · "}
        Free 5/Tag · Pro 50/Tag
      </p>
    </div>
  );
}
