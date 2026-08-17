import { NextResponse } from "next/server";
import { createAuthedClient } from "@/lib/supabase/authed";
import { createAdminClient } from "@/lib/supabase/admin";
import {
  buildChatRecommendation,
  detectTool,
  formulateDeterministic,
  numericGuard,
  type ChatToolName,
} from "@/lib/ai/chat";
import {
  dayResetAt,
  limitsForTier,
  utcDay,
  utcMonthPrefix,
  type ChatTier,
} from "@/lib/ai/chatLimits";
import {
  clientIpFromRequest,
  consumeAnonIpQuota,
} from "@/lib/ai/anonIpQuota";
import type { Bike, Ride, RiderProfile } from "@/types";
import type { RangeCalibration } from "@/lib/ebike/range";
import {
  chatLangFromBody,
  chatSystemPrompt,
  chatUserMessage,
} from "@/lib/i18n/chatPrompt";

async function callGrok(params: {
  system: string;
  user: string;
  maxTokens: number;
}): Promise<string | null> {
  const key = process.env.XAI_API_KEY;
  if (!key) return null;
  const model = process.env.XAI_MODEL || "grok-3-mini";

  const res = await fetch("https://api.x.ai/v1/chat/completions", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${key}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model,
      temperature: 0.2,
      max_tokens: params.maxTokens,
      messages: [
        { role: "system", content: params.system },
        { role: "user", content: params.user },
      ],
    }),
  });

  if (!res.ok) {
    console.error("[grok]", res.status, await res.text());
    return null;
  }
  const data = await res.json();
  return data?.choices?.[0]?.message?.content?.trim() ?? null;
}

export async function POST(req: Request) {
  try {
    const body = await req.json();
    const query = String(body.query || "").trim();
    const lang = chatLangFromBody(body.lang);
    const toolHint = body.tool as ChatToolName | "auto" | undefined;
    const bikes = (body.bikes || []) as Bike[];
    const rides = (body.rides || []) as Ride[];
    const profile = body.profile as RiderProfile;
    const bike = body.bike as Bike | undefined;
    const calibration = (body.calibration ?? null) as RangeCalibration | null;
    const intervals = body.intervals;
    const rideFeedbacks = body.rideFeedbacks;
    const notices = body.notices;

    if (!query || !profile) {
      return NextResponse.json({ error: "invalid_body" }, { status: 400 });
    }

    let tier: ChatTier = "anonymous";
    let userId: string | null = null;
    let supabaseOk = false;

    try {
      const supabase = await createAuthedClient(req);
      const {
        data: { user },
      } = await supabase.auth.getUser();
      if (user) {
        userId = user.id;
        supabaseOk = true;
        const { data: profileRow } = await supabase
          .from("profiles")
          .select("subscription_tier")
          .eq("id", user.id)
          .maybeSingle();
        tier =
          profileRow?.subscription_tier === "pro" ? "pro" : "free";
      }
    } catch {
      tier = "anonymous";
    }

    const limits = limitsForTier(tier);
    if (query.length > limits.maxInputChars) {
      return NextResponse.json(
        {
          error: "input_too_long",
          maxInputChars: limits.maxInputChars,
        },
        { status: 400 }
      );
    }

    const tool =
      toolHint && toolHint !== "auto" ? toolHint : detectTool(query);
    const set = buildChatRecommendation(tool, query, {
      bike,
      bikes,
      rides,
      profile,
      calibration,
      intervals,
      rideFeedbacks,
      notices,
    });

    // Anonymous: never call Grok; IP soft-cap on deterministic fallback
    if (tier === "anonymous" || limits.maxTokensOut === 0) {
      const ip = clientIpFromRequest(req);
      const ipQuota = consumeAnonIpQuota(ip, limits.day);
      if (!ipQuota.ok) {
        const guarded = numericGuard(formulateDeterministic(set), set);
        return NextResponse.json(
          {
            ...guarded,
            tool,
            usedGrok: false,
            code: "chat_limit",
            quota: {
              tier: "anonymous",
              dayUsed: ipQuota.used,
              dayLimit: ipQuota.limit,
              remaining: 0,
              resetAt: dayResetAt(),
              reason: "anon_ip_limit",
            },
          },
          { status: 429 }
        );
      }

      const guarded = numericGuard(formulateDeterministic(set), set);
      return NextResponse.json({
        ...guarded,
        tool,
        usedGrok: false,
        quota: {
          tier: "anonymous",
          dayUsed: ipQuota.used,
          dayLimit: ipQuota.limit,
          remaining: Math.max(0, ipQuota.limit - ipQuota.used),
          resetAt: dayResetAt(),
          reason: "login_required_for_grok",
        },
      });
    }

    // Quota check (authenticated)
    let dayUsed = 0;
    let monthUsed = 0;
    if (userId && supabaseOk && process.env.SUPABASE_SERVICE_ROLE_KEY) {
      const admin = createAdminClient();
      const today = utcDay();
      const monthPrefix = utcMonthPrefix();

      const { data: dayRow } = await admin
        .from("chat_usage")
        .select("count")
        .eq("user_id", userId)
        .eq("day", today)
        .maybeSingle();
      dayUsed = dayRow?.count ?? 0;

      const { data: monthRows } = await admin
        .from("chat_usage")
        .select("count, day")
        .eq("user_id", userId)
        .gte("day", `${monthPrefix}-01`);
      monthUsed = (monthRows || []).reduce(
        (s, r) => s + (r.count as number),
        0
      );

      if (dayUsed >= limits.day || monthUsed >= limits.month) {
        const guarded = numericGuard(formulateDeterministic(set), set);
        return NextResponse.json(
          {
            ...guarded,
            tool,
            usedGrok: false,
            code: "chat_limit",
            quota: {
              tier,
              dayUsed,
              dayLimit: limits.day,
              monthUsed,
              monthLimit: limits.month,
              remaining: 0,
              resetAt: dayResetAt(),
            },
          },
          { status: 429 }
        );
      }
    }

    const whitelist = set.numbers
      .map((n) => `${n.value}${n.unit ? " " + n.unit : ""} (${n.source})`)
      .join(", ");

    const system = chatSystemPrompt(
      lang,
      whitelist,
      set.facts.join(" | "),
    );

    const grokText = await callGrok({
      system,
      user: chatUserMessage(lang, query, set.rawAnswer),
      maxTokens: limits.maxTokensOut,
    });

    let usedGrok = false;
    let drafted = formulateDeterministic(set);
    if (grokText) {
      usedGrok = true;
      drafted = grokText;
    }

    const guarded = numericGuard(drafted, set);

    if (
      usedGrok &&
      userId &&
      !guarded.usedFallback &&
      process.env.SUPABASE_SERVICE_ROLE_KEY
    ) {
      try {
        const admin = createAdminClient();
        const today = utcDay();
        const { data: existing } = await admin
          .from("chat_usage")
          .select("count")
          .eq("user_id", userId)
          .eq("day", today)
          .maybeSingle();
        const next = (existing?.count ?? 0) + 1;
        await admin.from("chat_usage").upsert(
          { user_id: userId, day: today, count: next },
          { onConflict: "user_id,day" }
        );
        dayUsed = next;
        monthUsed += 1;
      } catch (e) {
        console.error("[chat_usage]", e);
      }
    }

    return NextResponse.json({
      ...guarded,
      tool,
      usedGrok,
      quota: {
        tier,
        dayUsed,
        dayLimit: limits.day,
        monthUsed,
        monthLimit: limits.month,
        remaining: Math.max(0, limits.day - dayUsed),
        resetAt: dayResetAt(),
      },
    });
  } catch (e) {
    console.error("[chat]", e);
    return NextResponse.json({ error: "unavailable" }, { status: 503 });
  }
}
