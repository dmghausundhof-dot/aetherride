import { NextResponse } from "next/server";
import {
  catalogNameIndex,
  parseVisionParts,
  searchCatalogBikes,
  type VisionPartHint,
} from "@/lib/catalog/identify";

export const dynamic = "force-dynamic";

type Body = {
  q?: string;
  imageBase64?: string;
};


async function visionHints(
  imageBase64: string
): Promise<{ queries: string[]; parts: VisionPartHint[] }> {
  const key = process.env.XAI_API_KEY;
  if (!key) return { queries: [], parts: [] };
  const model = process.env.XAI_VISION_MODEL || "grok-2-vision-1212";
  const catalog = catalogNameIndex();
  const res = await fetch("https://api.x.ai/v1/chat/completions", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${key}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model,
      temperature: 0,
      max_tokens: 400,
      messages: [
        {
          role: "system",
          content:
            "Du erkennst Fahrräder. Antworte NUR mit JSON: " +
            '{"queries":["Hersteller Modell"],"parts":[{"slot":"fork","manufacturer":"Fox","model":"36 Grip2"}]}. ' +
            "queries: maximal 3, Marke und Modell wie am Rad lesbar — auch ohne Katalogtreffer. " +
            "Katalogliste nur als Hilfe, nicht als Pflicht. " +
            "parts: nur wenn am Foto klar sichtbar. slot = snake_case " +
            "(fork, rear_shock, chain, cassette, crankset, brake_front, tire_front, motor, battery, …). " +
            "Keine SKUs, keine Seriennummer, kein Druck, kein km, keine erfundenen Modellnummern. Unsicher → weglassen.",
        },
        {
          role: "user",
          content: [
            {
              type: "text",
              text: `Katalog:\n${catalog}\n\nWelches Bike ist auf dem Foto? Sichtbare Teile nur wenn eindeutig.`,
            },
            {
              type: "image_url",
              image_url: {
                url: imageBase64.startsWith("data:")
                  ? imageBase64
                  : `data:image/jpeg;base64,${imageBase64}`,
              },
            },
          ],
        },
      ],
    }),
  });
  if (!res.ok) {
    console.error("[identify/vision]", res.status, await res.text());
    return { queries: [], parts: [] };
  }
  const data = (await res.json()) as {
    choices?: { message?: { content?: string } }[];
  };
  const raw = data?.choices?.[0]?.message?.content?.trim() ?? "";
  const jsonStart = raw.indexOf("{");
  const jsonEnd = raw.lastIndexOf("}");
  if (jsonStart < 0 || jsonEnd <= jsonStart) return { queries: [], parts: [] };
  try {
    const parsed = JSON.parse(raw.slice(jsonStart, jsonEnd + 1)) as {
      queries?: unknown;
      parts?: unknown;
    };
    const queries = Array.isArray(parsed.queries)
      ? parsed.queries
          .filter((q): q is string => typeof q === "string" && q.trim().length > 1)
          .map((q) => q.trim())
          .slice(0, 3)
      : [];
    return { queries, parts: parseVisionParts(parsed.parts) };
  } catch {
    return { queries: [], parts: [] };
  }
}

export async function POST(req: Request) {
  let body: Body;
  try {
    body = (await req.json()) as Body;
  } catch {
    return NextResponse.json({ error: "invalid_json" }, { status: 400 });
  }
  const q = String(body.q || "").trim();
  const image = String(body.imageBase64 || "").trim();
  if (!q && !image) {
    return NextResponse.json({ error: "q_or_image_required" }, { status: 400 });
  }

  const searchQueries = new Set<string>();
  if (q) searchQueries.add(q);
  let source: "catalog" | "vision+catalog" = "catalog";
  let reason: "ok" | "no_key" | "failed" | "unreadable" | "no_catalog" | undefined;
  let parts: VisionPartHint[] = [];
  let visionQueries: string[] = [];
  if (image) {
    if (!process.env.XAI_API_KEY) {
      reason = "no_key";
    } else {
      try {
        const hints = await visionHints(image);
        parts = hints.parts;
        visionQueries = hints.queries;
        if (hints.queries.length > 0 || hints.parts.length > 0) {
          source = "vision+catalog";
          for (const h of hints.queries) searchQueries.add(h);
        } else {
          reason = "unreadable";
        }
      } catch (e) {
        console.error("[identify/vision]", e);
        reason = "failed";
      }
    }
  }

  const byId = new Map<string, ReturnType<typeof searchCatalogBikes>[number]>();
  for (const query of searchQueries) {
    for (const hit of searchCatalogBikes(query, 8)) {
      const prev = byId.get(hit.id);
      if (!prev || hit.score > prev.score) byId.set(hit.id, hit);
    }
  }
  const matches = [...byId.values()]
    .sort((a, b) => b.score - a.score)
    .slice(0, 8);

  const hasVision = visionQueries.length > 0 || parts.length > 0;
  return NextResponse.json({
    matches,
    source,
    vision: source === "vision+catalog",
    reason:
      reason ??
      (matches.length > 0 ? "ok" : hasVision ? "no_catalog" : undefined),
    parts,
    queries: visionQueries,
  });
}
