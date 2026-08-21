#!/usr/bin/env bash
# Cross-compile routing_core for Android with 16 KB ELF pages (S25 / Play).
#
# Graph-only by default (offline_graph Dijkstra). Valhalla:
#   FEATURES=valhalla source …/aetherride-env.sh && ./scripts/routing/build-routing-core-android.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
ABI="${1:-arm64-v8a}"
FEATURES="${FEATURES:-}"
API="${ANDROID_API:-35}"
NATIVE="$ROOT/mobile/packages/routing_core/native"

case "$ABI" in
  arm64-v8a) RUST_TARGET=aarch64-linux-android; NDK_TRIPLE=aarch64-linux-android ;;
  x86_64) RUST_TARGET=x86_64-linux-android; NDK_TRIPLE=x86_64-linux-android ;;
  *) echo "Unsupported ABI: $ABI" >&2; exit 1 ;;
esac

NDK="${ANDROID_NDK_HOME:-${ANDROID_NDK:-}}"
if [[ -z "$NDK" || ! -d "$NDK" ]]; then
  if [[ -f "$ROOT/mobile/android/local.properties" ]]; then
    sdk_dir=$(grep -E '^sdk\.dir=' "$ROOT/mobile/android/local.properties" | head -1 | cut -d= -f2- | tr -d '\r')
    if [[ -n "$sdk_dir" && -d "$sdk_dir/ndk" ]]; then
      NDK=$(ls -d "$sdk_dir"/ndk/*/ 2>/dev/null | sort -V | tail -1 | sed 's:/*$::')
    fi
  fi
fi
if [[ -z "$NDK" || ! -d "$NDK" ]]; then
  echo "Set ANDROID_NDK_HOME" >&2
  exit 1
fi

PREBUILT="$NDK/toolchains/llvm/prebuilt/linux-x86_64/bin"
CLANG="$PREBUILT/${NDK_TRIPLE}${API}-clang"
if [[ ! -x "$CLANG" ]]; then
  echo "Missing $CLANG" >&2
  exit 1
fi

export ANDROID_NDK_HOME="$NDK"
export PATH="$PREBUILT:$PATH"
export CC="$CLANG"
export CXX="${CLANG}++"
linker_var="CARGO_TARGET_$(echo "$RUST_TARGET" | tr 'a-z-' 'A-Z_')_LINKER"
export "$linker_var=$CLANG"

echo "NDK=$NDK"
echo "linker=$CLANG"
echo "target=$RUST_TARGET features=${FEATURES:-none}"

feat_args=()
if [[ -n "$FEATURES" ]]; then
  feat_args=(--features "$FEATURES")
fi

cd "$NATIVE"
cargo build --release --target "$RUST_TARGET" "${feat_args[@]}"

SO="$NATIVE/target/$RUST_TARGET/release/librouting_core.so"
align=$(readelf -W -l "$SO" | awk '/LOAD/ {print $NF; exit}')
echo "built $SO ($(du -h "$SO" | cut -f1)) LOAD align=$align"
if [[ "$align" != "0x4000" && "$align" != "16384" ]]; then
  echo "FAIL: expected 16 KB LOAD align" >&2
  exit 1
fi

GRAPH_FLAG=()
if [[ -z "$FEATURES" ]]; then
  GRAPH_FLAG=(--graph-only)
fi
bash "$ROOT/scripts/routing/install-android-jni.sh" "$ABI" "${GRAPH_FLAG[@]}"
