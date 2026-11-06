#!/bin/zsh
# Captures App Store 6,9 pouces (07_APP_STORE.md), en clair et en sombre alternés.
# Simulateur dédié « Sagace Captures » (iPhone 17 Pro Max), créé au besoin ; app réinstallée à neuf.
# Sortie : docs/sagace/store/screenshots/ (captures brutes dans raw/). La capture 5 (widgets) se fait à la main.
# Usage : Scripts/screenshots.sh [fichier…]   par exemple « Scripts/screenshots.sh 4-jeu » pour refaire une seule capture.
set -euo pipefail

ROOT=${0:A:h:h}
OUT="$ROOT/docs/sagace/store/screenshots"
RAW="$OUT/raw"
DERIVED="${TMPDIR:-/tmp}/sagace-screenshots"
NAME="Sagace Captures"

UDID=$(xcrun simctl list devices available -j | python3 -c "
import json, sys
devices = [d for runtime in json.load(sys.stdin)['devices'].values() for d in runtime]
print(next((d['udid'] for d in devices if d['name'] == '$NAME'), ''))")
if [[ -z "$UDID" ]]; then
  UDID=$(xcrun simctl create "$NAME" com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro-Max)
fi
xcrun simctl boot "$UDID" 2>/dev/null || true
xcrun simctl bootstatus "$UDID" -b >/dev/null
xcrun simctl status_bar "$UDID" override --time 9:41 --dataNetwork wifi --wifiMode active --wifiBars 3 \
  --cellularMode active --cellularBars 4 --batteryState discharging --batteryLevel 100
xcrun simctl uninstall "$UDID" com.cortex.VocabularyAppFramework 2>/dev/null || true

echo "Compilation…"
xcodebuild build-for-testing -scheme VocabularyAppFramework -destination "id=$UDID" -derivedDataPath "$DERIVED" -quiet

mkdir -p "$RAW"
# test:apparence:fichier:titre
shots=(
  "test1Fiche:light:1-fiche:Éminent ou imminent ?"
  "test2Auteur:dark:2-auteur:Le mot employé par les grands auteurs"
  "test3Tri:light:3-tri:Triez, révisez, retenez"
  "test4Jeu:dark:4-jeu:Deux minutes de jeu par jour"
  "test6Stats:dark:6-stats:Voyez vos progrès"
)
for shot in "${shots[@]}"; do
  IFS=: read -r test appearance file title <<< "$shot"
  if (( $# > 0 )) && (( ! ${@[(Ie)$file]} )); then continue; fi
  echo "Capture $file ($appearance)…"
  xcrun simctl ui "$UDID" appearance "$appearance"
  TEST_RUNNER_SCREENSHOTS_DIR="$RAW" xcodebuild test-without-building -scheme VocabularyAppFramework \
    -destination "id=$UDID" -derivedDataPath "$DERIVED" -only-testing:"SagaceAppUITests/AppStoreScreenshots/$test" -quiet
  swift "$ROOT/Scripts/frame_screenshots.swift" "$RAW/$file.png" "$OUT/$file.png" "$appearance" "$title"
done

xcrun simctl ui "$UDID" appearance light
xcrun simctl status_bar "$UDID" clear
echo "Captures prêtes dans $OUT (la 5, widgets sur l'écran d'accueil, est à faire à la main, en clair)."
