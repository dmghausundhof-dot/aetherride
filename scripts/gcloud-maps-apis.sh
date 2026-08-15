#!/usr/bin/env bash
# Enable Google Maps Platform APIs — only on a clearly AetherRide GCP project.
# Does NOT create projects or billing. Does NOT print API keys.
#
# Usage:
#   bash scripts/gcloud-maps-apis.sh
#   AETHER_GCP_PROJECT=aetherride-prod bash scripts/gcloud-maps-apis.sh
set -euo pipefail

APIS=(
  places.googleapis.com
  geocoding-backend.googleapis.com
  maps-backend.googleapis.com
  elevation-backend.googleapis.com
)

if ! command -v gcloud >/dev/null 2>&1; then
  echo "gcloud fehlt. Install:"
  echo "  curl -sS https://sdk.cloud.google.com | bash"
  echo "  exec -l \$SHELL"
  echo "  gcloud init"
  echo "  gcloud auth login"
  exit 1
fi

ACCOUNT="$(gcloud config get-value account 2>/dev/null || true)"
PROJECT="${AETHER_GCP_PROJECT:-$(gcloud config get-value project 2>/dev/null || true)}"

echo "gcloud account: ${ACCOUNT:-none}"
echo "gcloud project: ${PROJECT:-none}"

if [[ -z "${ACCOUNT}" || "${ACCOUNT}" == "(unset)" ]]; then
  echo "Nicht eingeloggt:"
  echo "  gcloud auth login"
  echo "  gcloud config set project PROJECT_ID   # nur AetherRide-Projekt"
  exit 1
fi

if [[ -z "${PROJECT}" || "${PROJECT}" == "(unset)" ]]; then
  echo "Kein aktives Projekt. AetherRide-Projekt setzen, dann:"
  echo "  gcloud services enable ${APIS[*]}"
  exit 1
fi

NAME="$(gcloud projects describe "$PROJECT" --format='value(name)' 2>/dev/null || true)"
ID_LC="$(echo "$PROJECT" | tr '[:upper:]' '[:lower:]')"
NAME_LC="$(echo "${NAME:-}" | tr '[:upper:]' '[:lower:]')"

if [[ "$ID_LC" != *aether* && "$NAME_LC" != *aether* ]]; then
  echo "BLOCKED: Projekt '$PROJECT' (${NAME:-?}) ist nicht klar AetherRide."
  echo "Kein Enable, kein Billing, kein neues Projekt."
  echo "Wenn du ein AetherRide-GCP-Projekt hast:"
  echo "  gcloud config set project aetherride-XXXX"
  echo "  gcloud services enable ${APIS[*]}"
  echo "  # Key in Google Cloud Console → APIs & Services → Credentials"
  echo "  # dann:  echo 'GOOGLE_MAPS_API_KEY=…' >> .env.local"
  echo "  #        vercel env add GOOGLE_MAPS_API_KEY"
  exit 2
fi

echo "Enable Maps APIs on $PROJECT …"
gcloud services enable "${APIS[@]}" --project="$PROJECT"
echo "OK. Key nicht hier erzeugen — Console oder:"
echo "  gcloud services api-keys list --project=$PROJECT"
echo "Key nur in .env.local / Vercel GOOGLE_MAPS_API_KEY (nie NEXT_PUBLIC_)."
