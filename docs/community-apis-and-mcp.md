# Community: vorhandene APIs & MCP-Vorbereitung

## 7. Kann man auf vorhandene API-Daten zugreifen?

**Ja — teilweise schon im Repo verdrahtet.** Für eine serverseitige Community (Reviews, geteilte Touren) sind das die nutzbaren Schichten:

| API | Pfad | Community-Nutzen | Auth |
|-----|------|------------------|------|
| **Sync snapshot** | `GET/POST /api/sync` | Bikes, Rides, savedRoutes, collections (LWW pro User) | Supabase JWT |
| **Heatmap cells** | `GET/POST /api/heatmap` | Aggregierte Popularität (k≥5, Consent) | Contribute: auth+consent |
| **OSM routes** | `GET /api/osm-routes?lat&lon` | Öffentliche relation-Geometrien (bicycle/mtb/hiking) | public |
| **OSM trails** | `GET /api/osm-trails` | Trail-Segmente | public |
| **Outdooractive** | `GET /api/outdooractive` | Enrichment-Touren (wenn Key) | API key |
| **Trailforks** | `GET /api/trailforks` | MTB conditions (hint) | optional |
| **Geocode** | `GET /api/geocode` | Ortssuche → Near-me | public Photon |
| **Route engine** | `GET/POST /api/route` | Live routing | public (rate limit) |
| **Tour geometry** | `GET /api/tours/geometry` | Catalog + near GPS | public |
| **Tour GPX** | `GET /api/tours/:id/gpx` | Export | public |
| **Weather** | `GET /api/weather` | Trail wetness hint | public |
| **Elevation** | `POST /api/elevation` | Profile | public |
| **Strava** | `/api/strava/*` | Upload after ride | OAuth |
| **Chat/AI** | `POST /api/chat` | Grok tools | rate limit |

### Was fehlt für echte Community (Backend)

- Tabelle `tour_reviews` (tour_id, user_id, rating, body, status, moderated_at)
- Tabelle `shared_collections` (short_id, payload, owner)
- Tabelle `public_profiles` (handle unique, user_id, bio)
- RLS: read approved only; write own pending
- Optional: moderate via service role / admin UI

**Heatmap + OSM** sind bereits „Community-artig“ ohne Social-Feed — gute Basis.

### Empfohlene Reihenfolge Community-Backend

1. `tour_reviews` auf Supabase + API mirror zu local Community store  
2. Short-link collections in DB (ersetzen base64)  
3. Public profiles table  
4. Optional: Strava/OA as enrichment only (not identity)

---

## MCP-Vorbereitung (KI-Interaktion)

### Zweck

MCP (Model Context Protocol) lässt Grok/andere Agents **strukturiert** auf AetherRide-Tools zugreifen: Tour suchen, Route berechnen, Sync-Status, Shop-Kompat — ohne HTML-Scraping.

### Vorgeschlagene MCP-Tools (Server `aetherride`)

| Tool | Maps to | Notes |
|------|---------|-------|
| `list_tours` | publicTours + filters | sport, region |
| `get_tour` | publicTours + geometry API | |
| `route_near` | `/api/tours/geometry?lat&lng` | |
| `geocode` | `/api/geocode` | |
| `routing_status` | `/api/routing/status?probe=1` | |
| `search_osm_routes` | `/api/osm-routes` | |
| `sync_status` | auth me + last sync | needs user token |
| `bike_compat` | catalog + engine | future |

### Config-Skizze (`~/.grok/config.toml`)

```toml
[mcp_servers.aetherride]
# Option A: HTTP tools against production API
command = "npx"
args = ["-y", "@modelcontextprotocol/server-fetch"]
# Better: custom server reading AETHERRIDE_API_BASE + optional user JWT
# env = { AETHERRIDE_API_BASE = "https://your-vercel.app", AETHERRIDE_TOKEN = "" }
```

### Minimal custom MCP (Node) — später

- Package `tools/mcp-aetherride/` with `stdio` server
- Tools call `process.env.AETHERRIDE_API_BASE`
- No secrets in tool results; respect rate limits
- For user data: pass bearer token from secure env, never log it

### Was jetzt schon ohne MCP geht

- Agent im Repo kann `scripts/smoke-web-sync-routing.mjs` und die Next APIs direkt nutzen
- `/api/chat` (Grok) hat Tool-Zugriff intern (Numeric-Guard) — app-internes AI, nicht Desktop-MCP

### Nächster Implementierungs-Schritt MCP

1. `tools/mcp-aetherride/package.json` + server mit 4 read-only tools (list_tours, route_near, geocode, routing_status)  
2. Eintrag in user `config.toml`  
3. Smoke: Grok list_tours → route_near Freiburg  

---

## Sync Smoke (manuell / CI)

```bash
# Dev-Server laufen lassen, dann:
node scripts/smoke-web-sync-routing.mjs http://127.0.0.1:3000

# Mit Login (Cookie/Token) separat:
# curl -H "Authorization: Bearer $TOKEN" https://…/api/sync
```

Erwartet: health OK, routing probe, geometry, geocode, osm-routes, sync **401** ohne Auth, sitemap.
