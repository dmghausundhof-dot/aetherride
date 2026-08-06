# routing_core

Valhalla C++/FFI offline routing (Spec §5.4).

## Status (S7 scaffold)

- C ABI: `routing_core_route`, `routing_core_tiles_ok`
- Stub returns `ROUTING_NOT_IMPLEMENTED` until linked against Valhalla
- Online path: Flutter `RoutingClient` → `/api/route` (already live)

## Next

1. Build Valhalla with mobile toolchains (iOS XCFramework / Android NDK)
2. Ship regional tile extracts with PMTiles for map_core
3. Use identical costing Lua as server for Spec-7 profiles

```bash
cd native && cargo test
```
