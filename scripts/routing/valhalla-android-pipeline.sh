#!/usr/bin/env bash
# End-to-end Valhalla Android pipeline:
#   1) build-valhalla-android.sh (or skip if NDK missing)
#   2) cargo build --features valhalla --target aarch64-linux-android
#   3) install-android-jni.sh
#
# Usage:
#   ./scripts/routing/valhalla-android-pipeline.sh
#   SKIP_VALHALLA_BUILD=1 ./scripts/routing/valhalla-android-pipeline.sh  # only cargo + jni
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
ABI="${1:-arm64-v8a}"
case "$ABI" in
  arm64-v8a) RUST_TARGET=aarch64-linux-android ;;
  *)
    echo "This pipeline currently supports arm64-v8a (got: $ABI)" >&2
    exit 1
    ;;
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

if [[ "${SKIP_VALHALLA_BUILD:-}" != "1" ]]; then
  if [[ -z "$NDK" || ! -d "$NDK" ]]; then
    echo "ANDROID_NDK_HOME missing — skipping Valhalla C++ build." >&2
    echo "Set ANDROID_NDK_HOME or install an NDK, then re-run." >&2
    echo "You can still install a graph-only .so via:" >&2
    echo "  ./scripts/routing/install-android-jni.sh --graph-only" >&2
    exit 0
  fi
  export ANDROID_NDK_HOME="$NDK"
  echo "==> build-valhalla-android.sh $ABI"
  bash "$ROOT/scripts/routing/build-valhalla-android.sh" "$ABI"
  ENV_SH="$ROOT/data/routing/dist/valhalla-build/prefix-android-$ABI/aetherride-env.sh"
  if [[ -f "$ENV_SH" ]]; then
    # shellcheck disable=SC1090
    source "$ENV_SH"
  else
    echo "Warning: $ENV_SH not found — cargo may fail to link Valhalla" >&2
  fi
else
  echo "==> SKIP_VALHALLA_BUILD=1 — using existing prefix if sourced"
fi

NATIVE="$ROOT/mobile/packages/routing_core/native"
echo "==> cargo build --release --features valhalla --target $RUST_TARGET"
(
  cd "$NATIVE"
  cargo build --release --features valhalla --target "$RUST_TARGET"
)

echo "==> install-android-jni.sh $ABI"
bash "$ROOT/scripts/routing/install-android-jni.sh" "$ABI"
echo "==> Valhalla Android pipeline done"
