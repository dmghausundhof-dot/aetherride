#!/usr/bin/env node
/**
 * AetherRide MCP (stdio) — read-only tools for catalog, tours, geocode.
 * Env: AETHERRIDE_API_BASE (default https://aetherride.vercel.app)
 */
const BASE = (
  process.env.AETHERRIDE_API_BASE || "https://aetherride.vercel.app"
).replace(/\/$/, "");

const TOOLS = [
  {
    name: "search_bikes",
    description:
      "Search the AetherRide OEM bike catalog by manufacturer or model name.",
    inputSchema: {
      type: "object",
      properties: {
        q: { type: "string", description: "e.g. Focus SAM, Canyon Grizl" },
      },
      required: ["q"],
    },
  },
  {
    name: "identify_bike",
    description:
      "Match a bike from a text description (and optional JPEG base64 photo) to the catalog.",
    inputSchema: {
      type: "object",
      properties: {
        q: { type: "string" },
        imageBase64: { type: "string", description: "JPEG/PNG as base64" },
      },
    },
  },
  {
    name: "list_tours",
    description: "Nearby or catalog tours via geometry API (lat/lng).",
    inputSchema: {
      type: "object",
      properties: {
        lat: { type: "number" },
        lng: { type: "number" },
      },
      required: ["lat", "lng"],
    },
  },
  {
    name: "geocode",
    description: "Place search (Photon) via AetherRide geocode API.",
    inputSchema: {
      type: "object",
      properties: { q: { type: "string" } },
      required: ["q"],
    },
  },
];

async function callTool(name, args = {}) {
  if (name === "search_bikes") {
    const q = String(args.q || "").trim();
    const res = await fetch(
      `${BASE}/api/catalog/bikes?q=${encodeURIComponent(q)}`
    );
    return await res.json();
  }
  if (name === "identify_bike") {
    const res = await fetch(`${BASE}/api/catalog/identify`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        q: args.q || "",
        imageBase64: args.imageBase64 || "",
      }),
    });
    return await res.json();
  }
  if (name === "list_tours") {
    const lat = args.lat;
    const lng = args.lng;
    const res = await fetch(
      `${BASE}/api/tours/geometry?lat=${encodeURIComponent(lat)}&lng=${encodeURIComponent(lng)}`
    );
    return await res.json();
  }
  if (name === "geocode") {
    const q = String(args.q || "").trim();
    const res = await fetch(
      `${BASE}/api/geocode?q=${encodeURIComponent(q)}`
    );
    return await res.json();
  }
  throw new Error(`unknown tool ${name}`);
}

function send(msg) {
  const json = JSON.stringify(msg);
  process.stdout.write(`Content-Length: ${Buffer.byteLength(json, "utf8")}\r\n\r\n${json}`);
}

// MCP stdio uses newline-delimited JSON in many hosts; Cursor/Claude also accept LSP-style.
// Support both: if a line is JSON, parse it; else Content-Length framing.
let buf = "";
process.stdin.setEncoding("utf8");
process.stdin.on("data", (chunk) => {
  buf += chunk;
  // Newline-delimited JSON (Cursor / many MCP clients)
  let idx;
  while ((idx = buf.indexOf("\n")) >= 0) {
    const line = buf.slice(0, idx).trim();
    buf = buf.slice(idx + 1);
    if (!line || line.startsWith("Content-Length:")) continue;
    try {
      handle(JSON.parse(line));
    } catch {
      /* ignore partial */
    }
  }
});

async function handle(msg) {
  const id = msg.id;
  const method = msg.method;
  try {
    if (method === "initialize") {
      respond(id, {
        protocolVersion: "2024-11-05",
        capabilities: { tools: {} },
        serverInfo: { name: "aetherride", version: "0.1.0" },
      });
      return;
    }
    if (method === "notifications/initialized" || method === "initialized") {
      return;
    }
    if (method === "tools/list") {
      respond(id, { tools: TOOLS });
      return;
    }
    if (method === "tools/call") {
      const name = msg.params?.name;
      const args = msg.params?.arguments || {};
      const result = await callTool(name, args);
      respond(id, {
        content: [{ type: "text", text: JSON.stringify(result, null, 2) }],
      });
      return;
    }
    if (method === "ping") {
      respond(id, {});
      return;
    }
    if (id != null) {
      respond(id, undefined, { code: -32601, message: `Unknown method ${method}` });
    }
  } catch (e) {
    if (id != null) {
      respond(id, undefined, { code: -32000, message: String(e?.message || e) });
    }
  }
}

function respond(id, result, error) {
  const msg = error
    ? { jsonrpc: "2.0", id, error }
    : { jsonrpc: "2.0", id, result };
  process.stdout.write(`${JSON.stringify(msg)}\n`);
}
