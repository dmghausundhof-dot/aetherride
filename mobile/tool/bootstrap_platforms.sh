#!/usr/bin/env bash
# Erzeugt android/ + ios/ im bestehenden Dart-Gerüst (einmalig).
set -euo pipefail
cd "$(dirname "$0")/.."

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter CLI nicht gefunden. PATH setzen, z. B.:"
  echo '  export PATH="$HOME/flutter/bin:$PATH"'
  exit 1
fi

flutter create . \
  --project-name aetherride_mobile \
  --org com.aetherride \
  --platforms=android,ios \
  --empty

echo "Plattformen angelegt. Weiter: flutter pub get && flutter run"
