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

add_define API_BASE_URL "${API_BASE_URL:-http://10.0.2.2:3001}"
add_define STADIA_API_KEY "${STADIA_API_KEY:-${NEXT_PUBLIC_STADIA_API_KEY:-}}"
add_define PMTILES_URL "${PMTILES_URL:-${NEXT_PUBLIC_PMTILES_URL:-}}"
add_define SUPABASE_URL "${SUPABASE_URL:-${NEXT_PUBLIC_SUPABASE_URL:-}}"
add_define SUPABASE_ANON_KEY "${SUPABASE_ANON_KEY:-${NEXT_PUBLIC_SUPABASE_ANON_KEY:-}}"

cmd="${1:-run}"
shift || true

export PATH="${HOME}/flutter/bin:${PATH}"
export JAVA_HOME="${JAVA_HOME:-$HOME/.sdkman/candidates/java/17.0.9-tem}"

case "$cmd" in
  run) flutter run "${defines[@]}" "$@" ;;
  apk) flutter build apk --debug "${defines[@]}" "$@" ;;
  *) flutter "$cmd" "${defines[@]}" "$@" ;;
esac
