import { NextResponse } from "next/server";
import {
  emptyReceiptScan,
  parseReceiptScanContent,
} from "@/lib/garage/receiptScan";

export const dynamic = "force-dynamic";

/**
 * POST /api/garage/receipt-scan
 * Same Grok vision stack as /api/catalog/identify — receipt fields, not bikes.
 */
export async function POST(req: Request) {
  let body: { imageBase64?: string };
  try {
    body = (await req.json()) as { imageBase64?: string };
  } catch {
    return NextResponse.json({ error: "invalid_json" }, { status: 400 });
  }
  const image = String(body.imageBase64 || "").trim();
  if (!image) {
    return NextResponse.json({ error: "image_required" }, { status: 400 });
  }

  const key = process.env.XAI_API_KEY;
  if (!key) {
    return NextResponse.json(emptyReceiptScan("no_key"));
  }

  const model = process.env.XAI_VISION_MODEL || "grok-2-vision-1212";
  try {
    const res = await fetch("https://api.x.ai/v1/chat/completions", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${key}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model,
        temperature: 0,
        max_tokens: 280,
        messages: [
          {
            role: "system",
            content:
              "Du liest Fahrrad-Belege (Werkstatt, Ersatzteil, Shop, Garantie). " +
              "Antworte NUR mit JSON: " +
              '{"merchant":"","date":"yyyy-mm-dd","amountEur":0,"title":"","kind":"workshop|parts|warranty|other","items":["..."]}. ' +
              "Unleserliche Felder weglassen oder null. Kein Fließtext.",
          },
          {
            role: "user",
            content: [
              {
                type: "text",
                text: "Lies den Beleg. Händler, Datum, Betrag, was gekauft oder gemacht wurde.",
              },
              {
                type: "image_url",
                image_url: {
                  url: image.startsWith("data:")
                    ? image
                    : `data:image/jpeg;base64,${image}`,
                },
              },
            ],
          },
        ],
      }),
    });
    if (res.status === 429) {
      return NextResponse.json(emptyReceiptScan("quota"));
    }
    if (!res.ok) {
      console.error("[receipt-scan]", res.status, await res.text());
      return NextResponse.json(emptyReceiptScan("failed"));
    }
    const data = (await res.json()) as {
      choices?: { message?: { content?: string } }[];
    };
    const raw = data?.choices?.[0]?.message?.content?.trim() ?? "";
    return NextResponse.json(parseReceiptScanContent(raw));
  } catch (e) {
    console.error("[receipt-scan]", e);
    return NextResponse.json(emptyReceiptScan("failed"));
  }
}
