#!/usr/bin/env bash
# Cross-compile libvalhalla (+ AetherRide C shim) for Android NDK.
# Based on community recipes (Valhalla issues #1860 / #4704, Rallista POC).
#
# Prerequisites:
#   ANDROID_NDK_HOME, cmake, ninja, git
#   Boost headers (auto-downloaded) + Protobuf host+android (auto-built)
#   Plenty of disk (~8GB) and time (first build 30–90 min)
#
# Usage:
#   export ANDROID_NDK_HOME=~/Android/Sdk/ndk/<ver>
#   export PATH=~/tools/cmake/bin:~/tools:$PATH
#   ./scripts/routing/build-valhalla-android.sh arm64-v8a
#   source data/routing/dist/valhalla-build/prefix-android-arm64-v8a/aetherride-env.sh
#   cd mobile/packages/routing_core/native && cargo build --features valhalla --target aarch64-linux-android
set -euo pipefail

ABI="${1:-arm64-v8a}"
API="${ANDROID_API:-24}"
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
WORK="${VALHALLA_MOBILE_BUILD:-$ROOT/data/routing/dist/valhalla-build}"
TOOLS="${VALHALLA_TOOLS_DIR:-$HOME/tools}"
NDK="${ANDROID_NDK_HOME:-${ANDROID_NDK:-}}"
if [[ -z "$NDK" || ! -d "$NDK" ]]; then
  echo "Set ANDROID_NDK_HOME to your NDK root" >&2
  exit 1
fi
if ! command -v cmake >/dev/null || ! command -v ninja >/dev/null; then
  echo "Need cmake + ninja on PATH (e.g. ~/tools/cmake/bin and ~/tools/ninja)" >&2
  exit 1
fi

mkdir -p "$WORK" "$TOOLS"
cd "$WORK"

if [[ ! -d valhalla/.git ]]; then
  git clone --depth 1 --recurse-submodules https://github.com/valhalla/valhalla.git
fi

# Boost headers
BOOST_VER="${BOOST_VER:-1.85.0}"
BOOST_DIR="$TOOLS/boost_${BOOST_VER}"
if [[ ! -d "$BOOST_DIR/boost" ]]; then
  echo "==> Fetch Boost $BOOST_VER"
  curl -fsSL -o /tmp/boost.tgz \
    "https://archives.boost.io/release/${BOOST_VER}/source/boost_${BOOST_VER//./_}.tar.gz"
  tar -xzf /tmp/boost.tgz -C "$TOOLS"
fi

# Protobuf host (protoc) + Android lib
PB_VER="${PROTOBUF_VER:-21.12}"
PB_SRC="$TOOLS/protobuf-$PB_VER"
PB_HOST="$TOOLS/protobuf-host"
PB_AND="$TOOLS/protobuf-android-$ABI"
if [[ ! -d "$PB_SRC" ]]; then
  echo "==> Fetch Protobuf $PB_VER"
  curl -fsSL -o /tmp/pb.tgz \
    "https://github.com/protocolbuffers/protobuf/releases/download/v${PB_VER}/protobuf-all-${PB_VER}.tar.gz"
  tar -xzf /tmp/pb.tgz -C "$TOOLS"
fi
if [[ ! -x "$PB_HOST/bin/protoc" ]]; then
  echo "==> Build host protoc"
  cmake -S "$PB_SRC/cmake" -B "$TOOLS/protobuf-host-build" -G Ninja \
    -Dprotobuf_BUILD_TESTS=OFF -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="$PB_HOST"
  cmake --build "$TOOLS/protobuf-host-build" --parallel "$(nproc)"
  cmake --install "$TOOLS/protobuf-host-build"
fi
if [[ ! -f "$PB_AND/lib/libprotobuf.so" && ! -f "$PB_AND/lib/libprotobuf.a" ]]; then
  echo "==> Build Android protobuf ($ABI)"
  cmake -S "$PB_SRC/cmake" -B "$TOOLS/protobuf-android-build-$ABI" -G Ninja \
    -DCMAKE_TOOLCHAIN_FILE="$NDK/build/cmake/android.toolchain.cmake" \
    -DANDROID_ABI="$ABI" -DANDROID_PLATFORM="android-$API" \
    -Dprotobuf_BUILD_TESTS=OFF -Dprotobuf_BUILD_PROTOC_BINARIES=OFF \
    -Dprotobuf_BUILD_SHARED_LIBS=ON \
    -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$PB_AND"
  cmake --build "$TOOLS/protobuf-android-build-$ABI" --parallel "$(nproc)"
  cmake --install "$TOOLS/protobuf-android-build-$ABI"
fi

BUILD_DIR="$WORK/build-android-$ABI"
PREFIX="$WORK/prefix-android-$ABI"
mkdir -p "$BUILD_DIR" "$PREFIX"

TOOLCHAIN="$NDK/build/cmake/android.toolchain.cmake"
echo "==> Configure Valhalla ($ABI)"
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
  -DENABLE_TESTS=OFF \
  -DBUILD_SHARED_LIBS=ON \
  -DENABLE_STATIC_LIBRARY_MODULES=ON \
  -DBoost_INCLUDE_DIR="$BOOST_DIR" \
  -DProtobuf_INCLUDE_DIR="$PB_AND/include" \
  -DProtobuf_LIBRARY="$PB_AND/lib/libprotobuf.so" \
  -DProtobuf_PROTOC_EXECUTABLE="$PB_HOST/bin/protoc" \
  -Dprotobuf_MODULE_COMPATIBLE=ON

echo "==> Build Valhalla"
cmake --build "$BUILD_DIR" --parallel "$(nproc)"
cmake --install "$BUILD_DIR"

# Compile AetherRide C shim against installed headers (NDK clang)
CXX="$NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/clang++"
SHIM_OUT="$PREFIX/lib/libvalhalla_actor_c.a"
"$CXX" --target=aarch64-linux-android$API -std=c++17 -fPIC -O2 \
  -DAETHER_VALHALLA_LINKED \
  -I"$PREFIX/include" \
  -I"$ROOT/mobile/packages/routing_core/native/cpp" \
  -c "$ROOT/mobile/packages/routing_core/native/cpp/valhalla_actor_c.cpp" \
  -o "$WORK/valhalla_actor_c.o"
llvm-ar rcs "$SHIM_OUT" "$WORK/valhalla_actor_c.o" 2>/dev/null || \
  "$NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-ar" rcs "$SHIM_OUT" "$WORK/valhalla_actor_c.o"

cat > "$PREFIX/aetherride-env.sh" <<EOF
export VALHALLA_LIB_DIR="$PREFIX/lib"
export VALHALLA_INCLUDE_DIR="$PREFIX/include"
export VALHALLA_LINK_LIB=valhalla
export VALHALLA_LINK_KIND=dylib
export ANDROID_NDK_HOME="$NDK"
# After sourcing, from native/:
#   cargo build --features valhalla --target aarch64-linux-android
EOF

echo "Installed to $PREFIX"
echo "source $PREFIX/aetherride-env.sh"
