#!/bin/zsh
# Captures de vérification iPad (09_IPAD.md) : chaque écran principal en portrait et en paysage,
# en clair et en sombre, en Dynamic Type standard et XXL.
# Simulateur dédié « Sagace iPad UX » (iPad Pro 11 pouces), créé au besoin ; app réinstallée à neuf.
# Sortie : docs/sagace/ipad/raw/ (non versionné ; les captures retenues pour la PR vont dans docs/sagace/ipad/).
# Usage : Scripts/ipad_screens.sh [série…]   séries : clair, sombre, clair-xxl, sombre-xxl (toutes par défaut).
set -euo pipefail

ROOT=${0:A:h:h}
OUT="${IPAD_SCREENS_OUT:-$ROOT/docs/sagace/ipad/raw}"
DERIVED="${TMPDIR:-/tmp}/sagace-ipad-screens"
NAME="Sagace iPad UX"

UDID=$(xcrun simctl list devices available -j | python3 -c "
import json, sys
devices = [d for runtime in json.load(sys.stdin)['devices'].values() for d in runtime]
print(next((d['udid'] for d in devices if d['name'] == '$NAME'), ''))")
if [[ -z "$UDID" ]]; then
  UDID=$(xcrun simctl create "$NAME" com.apple.CoreSimulator.SimDeviceType.iPad-Pro-11-inch-M5-12GB)
fi
xcrun simctl boot "$UDID" 2>/dev/null || true
xcrun simctl bootstatus "$UDID" -b >/dev/null
xcrun simctl status_bar "$UDID" override --time 9:41 --dataNetwork wifi --wifiMode active --wifiBars 3 \
  --batteryState discharging --batteryLevel 100
xcrun simctl uninstall "$UDID" com.cortex.VocabularyAppFramework 2>/dev/null || true

echo "Compilation…"
xcodebuild build-for-testing -scheme VocabularyAppFramework -destination "id=$UDID" -derivedDataPath "$DERIVED" -quiet

mkdir -p "$OUT"
# série:apparence:taille du texte
series=(
  "clair:light:large"
  "sombre:dark:large"
  "clair-xxl:light:extra-extra-large"
  "sombre-xxl:dark:extra-extra-large"
)
for serie in "${series[@]}"; do
  IFS=: read -r name appearance size <<< "$serie"
  if (( $# > 0 )) && (( ! ${@[(Ie)$name]} )); then continue; fi
  echo "Série $name…"
  xcrun simctl ui "$UDID" appearance "$appearance"
  xcrun simctl ui "$UDID" content_size "$size"
  TEST_RUNNER_IPAD_SCREENS_DIR="$OUT" TEST_RUNNER_IPAD_SCREENS_SUFFIX="-$name" xcodebuild test-without-building -scheme VocabularyAppFramework \
    -destination "id=$UDID" -derivedDataPath "$DERIVED" -only-testing:"SagaceAppUITests/IPadScreens" -quiet || echo "Série $name : échecs, voir ci-dessus"
done

xcrun simctl ui "$UDID" appearance light
xcrun simctl ui "$UDID" content_size large
xcrun simctl status_bar "$UDID" clear

# L'écran du simulateur est capturé dans son sens natif (portrait) : on redresse les captures en paysage.
for file in "$OUT"/*-paysage-*.png(N); do
  if (( $(sips -g pixelHeight "$file" | awk '/pixelHeight/ {print $2}') > $(sips -g pixelWidth "$file" | awk '/pixelWidth/ {print $2}') )); then
    sips -r 90 "$file" >/dev/null
  fi
done
echo "Captures prêtes dans $OUT."
