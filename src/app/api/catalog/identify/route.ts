import { NextResponse } from "next/server";
import { catalogNameIndex, searchCatalogBikes } from "@/lib/catalog/identify";

export const dynamic = "force-dynamic";

type Body = {
  q?: string;
  imageBase64?: string;
};

async function visionHints(imageBase64: string): Promise<string[]> {
  const key = process.env.XAI_API_KEY;
  if (!key) return [];
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
      max_tokens: 200,
      messages: [
        {
          role: "system",
          content:
            "Du erkennst Fahrräder. Antworte NUR mit JSON: " +
            '{"queries":["Hersteller Modell", "..."]}. Maximal 3 Treffer. ' +
            "Nur Namen aus der Katalogliste, sonst den nächsten ähnlichen Eintrag.",
        },
        {
          role: "user",
          content: [
            {
              type: "text",
              text: `Katalog:\n${catalog}\n\nWelches Bike ist auf dem Foto?`,
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
    return [];
  }
  const data = (await res.json()) as {
    choices?: { message?: { content?: string } }[];
  };
  const raw = data?.choices?.[0]?.message?.content?.trim() ?? "";
  const jsonStart = raw.indexOf("{");
  const jsonEnd = raw.lastIndexOf("}");
  if (jsonStart < 0 || jsonEnd <= jsonStart) return [];
  try {
    const parsed = JSON.parse(raw.slice(jsonStart, jsonEnd + 1)) as {
      queries?: unknown;
    };
    if (!Array.isArray(parsed.queries)) return [];
    return parsed.queries
      .filter((q): q is string => typeof q === "string" && q.trim().length > 1)
      .map((q) => q.trim())
      .slice(0, 3);
  } catch {
    return [];
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

  const queries = new Set<string>();
  if (q) queries.add(q);
  let source: "catalog" | "vision+catalog" = "catalog";
  if (image) {
    try {
      const hints = await visionHints(image);
      if (hints.length > 0) {
        source = "vision+catalog";
        for (const h of hints) queries.add(h);
      }
    } catch (e) {
      console.error("[identify/vision]", e);
    }
  }

  const byId = new Map<string, ReturnType<typeof searchCatalogBikes>[number]>();
  for (const query of queries) {
    for (const hit of searchCatalogBikes(query, 8)) {
      const prev = byId.get(hit.id);
      if (!prev || hit.score > prev.score) byId.set(hit.id, hit);
    }
  }
  const matches = [...byId.values()]
    .sort((a, b) => b.score - a.score)
    .slice(0, 8);

  return NextResponse.json({
    matches,
    source,
    vision: source === "vision+catalog",
  });
}
