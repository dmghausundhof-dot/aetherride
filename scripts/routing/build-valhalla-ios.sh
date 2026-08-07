#!/usr/bin/env bash
# Build libvalhalla as static libs / XCFramework skeleton for iOS + simulator.
# Requires: Xcode, cmake, ninja, git (run on macOS).
#
# Usage:
#   ./scripts/routing/build-valhalla-ios.sh
set -euo pipefail

if [[ "$(uname)" != "Darwin" ]]; then
  echo "iOS builds require macOS/Xcode. On Linux, use the Android NDK script or CI macOS runner." >&2
  echo "Scaffold outputs env file template only." >&2
fi

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
WORK="${VALHALLA_MOBILE_BUILD:-$ROOT/data/routing/dist/valhalla-build}"
mkdir -p "$WORK"
cd "$WORK"

if [[ ! -d valhalla/.git ]]; then
  git clone --depth 1 --recurse-submodules https://github.com/valhalla/valhalla.git
fi

build_ios() {
  local sdk="$1"   # iphoneos | iphonesimulator
  local archs="$2" # arm64 | arm64;x86_64
  local out="$WORK/build-ios-$sdk"
  local prefix="$WORK/prefix-ios-$sdk"
  mkdir -p "$out" "$prefix"
  cmake -S "$WORK/valhalla" -B "$out" -G Ninja \
    -DCMAKE_SYSTEM_NAME=iOS \
    -DCMAKE_OSX_SYSROOT="$sdk" \
    -DCMAKE_OSX_ARCHITECTURES="$archs" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="$prefix" \
    -DENABLE_TOOLS=OFF \
    -DENABLE_DATA_TOOLS=OFF \
    -DENABLE_HTTP=OFF \
    -DENABLE_SERVICES=OFF \
    -DENABLE_PYTHON_BINDINGS=OFF \
    -DENABLE_TESTS=OFF \
    -DBUILD_SHARED_LIBS=OFF \
    -DENABLE_STATIC_LIBRARY_MODULES=ON \
    -DPREFER_SYSTEM_DEPS=OFF
  cmake --build "$out" --parallel "$(sysctl -n hw.ncpu 2>/dev/null || echo 4)"
  cmake --install "$out"
}

if [[ "$(uname)" == "Darwin" ]]; then
  build_ios iphoneos arm64
  build_ios iphonesimulator "arm64;x86_64"
  # Optional: xcodebuild -create-xcframework ...
fi

PREFIX_IOS="$WORK/prefix-ios-iphoneos"
cat > "$WORK/aetherride-ios-env.sh" <<EOF
export VALHALLA_LIB_DIR="${PREFIX_IOS}/lib"
export VALHALLA_INCLUDE_DIR="${PREFIX_IOS}/include"
export VALHALLA_LINK_LIB=valhalla
export VALHALLA_LINK_KIND=static
# cd mobile/packages/routing_core/native && cargo build --features valhalla --target aarch64-apple-ios
EOF

echo "Env template: $WORK/aetherride-ios-env.sh"
