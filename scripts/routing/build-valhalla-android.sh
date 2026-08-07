#!/usr/bin/env bash
# Cross-compile libvalhalla (+ AetherRide C shim) for Android NDK.
# Based on community recipes (Valhalla issues #1860 / #4704, Rallista POC).
#
# Prerequisites:
#   ANDROID_NDK_HOME, cmake, ninja, git
#   Plenty of disk (~8GB) and time (first build 30–90 min)
#
# Usage:
#   ./scripts/routing/build-valhalla-android.sh arm64-v8a
#   export VALHALLA_LIB_DIR=... VALHALLA_INCLUDE_DIR=...
#   cd mobile/packages/routing_core/native && cargo build --features valhalla --target aarch64-linux-android
set -euo pipefail

ABI="${1:-arm64-v8a}"
API="${ANDROID_API:-24}"
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
WORK="${VALHALLA_MOBILE_BUILD:-$ROOT/data/routing/dist/valhalla-build}"
NDK="${ANDROID_NDK_HOME:-${ANDROID_NDK:-}}"
if [[ -z "$NDK" || ! -d "$NDK" ]]; then
  echo "Set ANDROID_NDK_HOME to your NDK root" >&2
  exit 1
fi

mkdir -p "$WORK"
cd "$WORK"

if [[ ! -d valhalla/.git ]]; then
  git clone --depth 1 --recurse-submodules https://github.com/valhalla/valhalla.git
fi

BUILD_DIR="$WORK/build-android-$ABI"
PREFIX="$WORK/prefix-android-$ABI"
mkdir -p "$BUILD_DIR" "$PREFIX"

TOOLCHAIN="$NDK/build/cmake/android.toolchain.cmake"
cmake -S "$WORK/valhalla" -B "$BUILD_DIR" -G Ninja \
  -DCMAKE_TOOLCHAIN_FILE="$TOOLCHAIN" \
  -DANDROID_ABI="$ABI" \
  -DANDROID_PLATFORM="android-$API" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="$PREFIX" \
  -DENABLE_TOOLS=OFF \
  -DENABLE_DATA_TOOLS=OFF \
  -DENABLE_HTTP=OFF \
  -DENABLE_SERVICES=OFF \
  -DENABLE_PYTHON_BINDINGS=OFF \
  -DENABLE_NODE_BINDINGS=OFF \
  -DENABLE_BENCHMARKS=OFF \
  -DENABLE_TESTS=OFF \
  -DENABLE_GDAL=OFF \
  -DBUILD_SHARED_LIBS=ON \
  -DENABLE_STATIC_LIBRARY_MODULES=ON \
  -DPREFER_SYSTEM_DEPS=OFF

cmake --build "$BUILD_DIR" --parallel "$(nproc)"
cmake --install "$BUILD_DIR"

# Compile AetherRide C shim against installed headers
SHIM_OUT="$PREFIX/lib/libvalhalla_actor_c.a"
c++ -std=c++17 -fPIC -O2 \
  -DAETHER_VALHALLA_LINKED \
  -I"$PREFIX/include" \
  -I"$ROOT/mobile/packages/routing_core/native/cpp" \
  -c "$ROOT/mobile/packages/routing_core/native/cpp/valhalla_actor_c.cpp" \
  -o "$WORK/valhalla_actor_c.o"
ar rcs "$SHIM_OUT" "$WORK/valhalla_actor_c.o" || true

cat > "$PREFIX/aetherride-env.sh" <<EOF
export VALHALLA_LIB_DIR="$PREFIX/lib"
export VALHALLA_INCLUDE_DIR="$PREFIX/include"
export VALHALLA_LINK_LIB=valhalla
export VALHALLA_LINK_KIND=dylib
# After sourcing, from native/:
#   cargo build --features valhalla --target aarch64-linux-android
EOF

echo "Installed to $PREFIX"
echo "source $PREFIX/aetherride-env.sh"
