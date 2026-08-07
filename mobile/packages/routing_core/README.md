# routing_core

Offline routing via C FFI (Spec §5.1 / §5.4).

## Engines

| Bundle | Status |
|---|---|
| `offline_graph.json` | **Production-ready interim** — Dijkstra, Spec-7 profiles |
| Valhalla tiles + `valhalla.json` | Needs libvalhalla link (`--features valhalla` + NDK/iOS build) |

## Build offline packs (same OSM coverage)

Region configs: `data/routing/regions/*.json`

```bash
# Graph only (Overpass → offline_graph), ships Flutter asset separately
npm run routing:region:graph-only -- data/routing/regions/schwarzwald-nord.json

# Full pack: graph + Valhalla tiles (Docker + osmium recommended)
npm run routing:region -- data/routing/regions/schwarzwald-nord.json
```

Outputs under `data/routing/dist/<id>/` (gitignored). Manifests: `data/routing/manifests/`.

## Valhalla Android JNI

```bash
# Build libvalhalla for NDK (needs ANDROID_NDK_HOME)
npm run routing:valhalla:android

# Then cargo --features valhalla + copy into jniLibs:
./scripts/routing/install-android-jni.sh
# Or one-shot (build + cargo + jni):
./scripts/routing/valhalla-android-pipeline.sh
```

Bundled demo graph (OSM-derived, **single copy in git**): `mobile/assets/routing/offline_graph.json`.

After a region build, refresh the asset:

```bash
./scripts/routing/sync-demo-graph.sh
# or: ./scripts/routing/sync-demo-graph.sh data/routing/dist/<id>/offline_graph.json
```

Rust tests load the same asset path (no duplicate under `native/testdata/`).

## Link libvalhalla (Android NDK / iOS)

```bash
# Android (Linux CI / workstation with NDK)
export ANDROID_NDK_HOME=…
./scripts/routing/build-valhalla-android.sh arm64-v8a
source data/routing/dist/valhalla-build/prefix-android-arm64-v8a/aetherride-env.sh
cd mobile/packages/routing_core/native
cargo build --release --features valhalla --target aarch64-linux-android
# Produces librouting_core.so (~9 MB) with Valhalla statically linked; package
# libprotobuf.so (+ libc++_shared.so) from the NDK/protobuf prefix into the APK:
#   ./scripts/routing/install-android-jni.sh
# Flutter loads `librouting_core.so` from `android/app/src/main/jniLibs/<abi>/`
# (preBuild copies when the cargo artifact exists).

# iOS (macOS + Xcode)
./scripts/routing/build-valhalla-ios.sh
source data/routing/dist/valhalla-build/aetherride-ios-env.sh
cargo build --release --features valhalla --target aarch64-apple-ios
```

C shim: `native/cpp/valhalla_actor_c.{h,cpp}` — real `tyr::actor_t` when `AETHER_VALHALLA_LINKED`, else stub.

```bash
cd native && cargo test && cargo test --features valhalla
```

## Smoke

```bash
# Host FFI
cd mobile/packages/routing_core/native && cargo build
cd ../../.. && ROUTING_CORE_LIB=$PWD/packages/routing_core/native/target/debug/librouting_core.so \
  flutter test test/routing_core_ffi_smoke_test.dart

# Android emulator (x86_64 graph-only jniLibs)
./scripts/routing/install-android-jni.sh --graph-only x86_64   # after cargo --target x86_64-linux-android
# or push jniLibs + scripts/routing/android_ffi_smoke.c via NDK clang (see PR notes)
```

## Flutter

- `RoutingClient` → FFI offline graph / Valhalla, fallback HTTP `/api/route`
- `--dart-define=OFFLINE_TILES_PATH=…` for regional extract dir
- `--dart-define=PREFER_OFFLINE_ROUTING=true`
