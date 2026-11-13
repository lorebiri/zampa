#!/usr/bin/env bash
# Build della web app installabile (PWA), pronta per qualunque hosting statico.
#
#   tool/build_web.sh                     # sito alla radice del dominio
#   BASE_HREF=/pellovi/ tool/build_web.sh    # sito in una sottocartella
#   APK=percorso/app-release.apk tool/build_web.sh   # include l'APK da scaricare
#
# Il risultato è in build/web: basta caricarne il contenuto sull'hosting.
# Altri argomenti passano a `flutter build web` (es. --dart-define-from-file=...).
set -euo pipefail
cd "$(dirname "$0")/.."

BASE_HREF="${BASE_HREF:-/}"
case "$BASE_HREF" in
  /*/|/) ;;
  *) echo "BASE_HREF deve iniziare e finire con / (ricevuto: $BASE_HREF)" >&2; exit 2 ;;
esac

# --no-web-resources-cdn: il motore grafico (CanvasKit) viene servito dal
# nostro sito e non da gstatic.com, così l'app si apre anche offline e non
# contatta Google a ogni avvio.
flutter build web --release --base-href "$BASE_HREF" --no-web-resources-cdn "$@"

if [[ -n "${APK:-}" ]]; then
  cp "$APK" build/web/pellovi.apk
fi

VERSIONE="$(grep -E '^version:' pubspec.yaml | awk '{print $2}' | cut -d+ -f1)"
python3 tool/pwa_finalize.py build/web "${LULU_VERSION:-$VERSIONE}"
