"use client";

import { useEffect, useMemo, useState } from "react";
import { ArrowLeft } from "lucide-react";
import { ChromeGlyph } from "@/components/chrome/ChromeGlyph";
import { useAppStore } from "@/store/useAppStore";
import { type ChatToolName } from "@/lib/ai/chat";
import { CoachInbox } from "@/components/chat/CoachInbox";
import { useCoachInbox } from "@/hooks/useCoachInbox";
import type { CoachInboxItem } from "@/lib/ai/coachInbox";
import Link from "next/link";
import { useHofLocation } from "@/hooks/useHofLocation";
import { profileForBikeCategory } from "@/lib/routing/profiles";
import { useHofCopy } from "@/hooks/useHofCopy";
import { chatCopy } from "@/lib/i18n/chatCopy";
import { webChrome } from "@/lib/i18n/webChrome";

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

export default function ChatPage() {
  const lang = useChromeLang();
  const c = chatCopy(lang);
  const hof = useHofCopy();
  const chrome = webChrome(lang);
  const bikes = useAppStore((s) => s.bikes);
  const activeBikeId = useAppStore((s) => s.activeBikeId);
  const rides = useAppStore((s) => s.rides);
  const profile = useAppStore((s) => s.riderProfile);
  const calibration = useAppStore((s) => s.rangeCalibration);
  const intervals = useAppStore((s) => s.maintenanceIntervals);
  const rideFeedbacks = useAppStore((s) => s.rideFeedbacks);
  const isRiding = useAppStore((s) => s.isRiding);
  const subscriptionTier = useAppStore((s) => s.subscriptionTier);
  const bike = bikes.find((b) => b.id === activeBikeId) || bikes[0];
  const { geo } = useHofLocation();
  const { items: coachItems } = useCoachInbox();
  const markRead = useAppStore((s) => s.markCoachNoticesRead);

  const [input, setInput] = useState("");
  const [tool, setTool] = useState<ChatToolName | "auto">("auto");
  const [busy, setBusy] = useState(false);
  const [quota, setQuota] = useState<QuotaInfo | null>(null);
  const [messages, setMessages] = useState<Msg[]>(() => [
    {
      id: "sys",
      role: "assistant",
      text: chatCopy(lang).welcome,
    },
  ]);

  useEffect(() => {
    const welcome = chatCopy(lang).welcome;
    setMessages((m) => {
      if (m.length === 1 && m[0].id === "sys" && m[0].role === "assistant") {
        return [{ ...m[0], text: welcome }];
      }
      return m;
    });
  }, [lang]);

  const ctx = useMemo(
    () => ({
      bike,
      bikes,
      rides,
      profile,
      calibration,
      intervals,
      rideFeedbacks,
      notices: coachItems,
    }),
    [bike, bikes, rides, profile, calibration, intervals, rideFeedbacks, coachItems]
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
          lang,
          lat: geo?.lat,
          lon: geo?.lng,
          routingProfile: bike?.category
            ? profileForBikeCategory(bike.category)
            : undefined,
        }),
      });
      const data = await res.json();
      if (data.quota) setQuota(data.quota);

      let text = data.text || data.error || c.noAnswer;
      if (res.status === 429) {
        text = `${text}\n\n${c.limitReached} ${
          data.quota?.tier === "free" ? c.limitFreeMore : c.limitTomorrow
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
          text: e instanceof Error ? e.message : c.networkError,
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
          className="mb-2 inline-flex items-center gap-1 text-sm text-chrome"
        >
          <ArrowLeft className="h-4 w-4" /> {hof.profile}
        </Link>
        <h1 className="flex items-center gap-2 text-2xl font-bold">
          <ChromeGlyph name="stimmen" size={24} current className="text-chrome" /> {c.title}
        </h1>
        <p className="text-sm text-text-secondary">
          {hof.chatHint}
        </p>
        {quota && (
          <p className="mt-1 text-xs text-text-secondary">
            {c.quotaToday(
              quota.tier,
              quota.dayUsed,
              quota.dayLimit,
              quota.remaining,
            )}
            {quota.reason === "login_required_for_grok"
              ? ` · ${c.loginForCloud}`
              : ""}
          </p>
        )}
        {!quota && (
          <p className="mt-1 text-xs text-text-secondary">
            {c.tariffLine(subscriptionTier)}
          </p>
        )}
      </header>

      {isRiding && (
        <div className="rounded-xl border border-error/40 bg-error/10 px-3 py-2 text-sm text-error">
          {c.lockedRiding}
        </div>
      )}

      {quota && quota.remaining === 0 && quota.tier === "free" && (
        <div className="rounded-xl border border-accent/40 bg-accent/10 px-3 py-2 text-sm">
          {c.freeLimit}{" "}
          <Link href="/profile" className="font-semibold text-accent">
            {c.upgradePro}
          </Link>
        </div>
      )}

      <div className="flex flex-wrap gap-2">
        {c.prompts.map((p) => (
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

      {coachItems.length > 0 ? (
        <CoachInbox
          onAsk={(item: CoachInboxItem) => {
            markRead([item]);
            void send({ query: item.query, tool: item.tool as ChatToolName });
          }}
        />
      ) : null}

      {process.env.NODE_ENV === "development" && (
      <details className="text-xs text-text-secondary">
        <summary className="cursor-pointer text-accent">
          Debug: Tool manuell wählen
        </summary>
        <div className="mt-2 flex flex-wrap gap-1">
          {(
            [
              "auto",
              "watch",
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
                tool === t ? "bg-chrome text-on-accent" : "bg-surface-elevated"
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
                <ChromeGlyph name="care" size={12} current /> {m.tool}
                {m.usedGrok ? " · Cloud-KI" : " · lokal"}
                {m.guarded && (
                  <span className="inline-flex items-center gap-0.5 text-warning">
                    <ChromeGlyph name="shield" size={12} current /> Zahlen geprüft
                    {m.rejected?.length
                      ? ` (verwirft ${m.rejected.join(", ")})`
                      : ""}
                  </span>
                )}
              </p>
            )}
            {m.guarded && process.env.NODE_ENV !== "development" && (
              <p className="mt-1 text-[10px] text-text-secondary">
                {c.checkedOnData}
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
          placeholder={c.hint}
          className="flex-1 rounded-xl border border-border bg-surface-elevated px-3 py-2 text-sm"
        />
        <button
          type="button"
          disabled={isRiding || busy}
          onClick={() => void send()}
          className="rounded-xl bg-chrome px-4 py-2 text-sm font-semibold text-on-accent disabled:opacity-40"
        >
          {busy ? "…" : c.send}
        </button>
      </div>

      <p className="text-center text-xs text-text-secondary">
        <Link href="/home" className="text-chrome">
          {chrome.toHof}
        </Link>
        {" · "}
        {c.freeProFoot}
      </p>
    </div>
  );
}
