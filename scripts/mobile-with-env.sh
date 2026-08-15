#!/usr/bin/env bash
# Build/run Flutter Mobile mit dart-defines aus Repo-.env.local
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="${ENV_FILE:-$ROOT/.env.local}"
cd "$ROOT/mobile"

defines=()
add_define() {
  local key="$1" val="${2:-}"
  if [[ -n "$val" ]]; then
    defines+=("--dart-define=${key}=${val}")
  fi
}

if [[ -f "$ENV_FILE" ]]; then
  # shellcheck disable=SC1090
  set -a
  # shellcheck source=/dev/null
  source "$ENV_FILE"
  set +a
fi

# Default: emulator → host Next (often :3001). Prod smoke:
#   API_BASE_URL=https://aetherride.vercel.app ./scripts/mobile-with-env.sh run
default_api="http://10.0.2.2:3001"
if [[ -n "${NEXT_PUBLIC_APP_URL:-}" && -z "${API_BASE_URL:-}" ]]; then
  # Only use public app URL when it is not localhost (device cannot reach host localhost).
  case "${NEXT_PUBLIC_APP_URL}" in
    http://localhost*|http://127.*|http://0.0.0.0*) ;;
    *) default_api="${NEXT_PUBLIC_APP_URL%/}" ;;
  esac
fi
add_define API_BASE_URL "${API_BASE_URL:-$default_api}"
add_define STADIA_API_KEY "${STADIA_API_KEY:-${NEXT_PUBLIC_STADIA_API_KEY:-}}"
add_define PMTILES_URL "${PMTILES_URL:-${NEXT_PUBLIC_PMTILES_URL:-}}"
add_define SUPABASE_URL "${SUPABASE_URL:-${NEXT_PUBLIC_SUPABASE_URL:-}}"
add_define SUPABASE_ANON_KEY "${SUPABASE_ANON_KEY:-${NEXT_PUBLIC_SUPABASE_ANON_KEY:-}}"
add_define SENTRY_DSN "${SENTRY_DSN:-}"
add_define SHOPIFY_STOREFRONT_URL "${SHOPIFY_STOREFRONT_URL:-}"
add_define SHOPIFY_PARTS_COLLECTION "${SHOPIFY_PARTS_COLLECTION:-}"
add_define SHOPIFY_MERCH_COLLECTION "${SHOPIFY_MERCH_COLLECTION:-}"

cmd="${1:-run}"
shift || true

export PATH="${HOME}/flutter/bin:${PATH}"
export JAVA_HOME="${JAVA_HOME:-$HOME/.sdkman/candidates/java/17.0.9-tem}"

echo "mobile-with-env: API_BASE_URL dart-define → ${API_BASE_URL:-$default_api}"

case "$cmd" in
  run) flutter run "${defines[@]}" "$@" ;;
  apk) flutter build apk --debug "${defines[@]}" "$@" ;;
  release-apk) flutter build apk --release "${defines[@]}" "$@" ;;
  *) flutter "$cmd" "${defines[@]}" "$@" ;;
esac
