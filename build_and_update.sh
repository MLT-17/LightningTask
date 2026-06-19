#!/bin/bash
set -e

PROJECT_NAME="LightningTask"
SCHEME_NAME="LightningTask"
CONFIGURATION="Release"
BUILD_DIR="./build"
OUTPUT_DIR="./dist"
SERVER_PORT=8000

# Dynamisch das installierte Sparkle-Tool auf dem Mac finden
GENERATE_APPCAST_BIN=$(which generate_appcast || find /opt/homebrew/Caskroom/sparkle -name "generate_appcast" -print -quit 2>/dev/null)

if [ -z "$GENERATE_APPCAST_BIN" ]; then
    echo "❌ Fehler: 'generate_appcast' wurde nicht gefunden. Bitte installiere Sparkle via Homebrew."
    exit 1
fi

echo "➔ 1. Bereinige alte Builds..."
rm -rf "$BUILD_DIR" "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

echo "➔ 2. Erhöhe Build-Nummer und starte Xcode Build..."
xcrun agvtool next-version -all

xcodebuild -project "${PROJECT_NAME}.xcodeproj" \
           -scheme "${SCHEME_NAME}" \
           -configuration "${CONFIGURATION}" \
           -derivedDataPath "$BUILD_DIR" \
           build

BUILT_APP="${BUILD_DIR}/Build/Products/${CONFIGURATION}/${PROJECT_NAME}.app"

echo "➔ 3. Erstelle ZIP-Archiv..."
ZIP_NAME="${PROJECT_NAME}.zip"
cd "${BUILD_DIR}/Build/Products/${CONFIGURATION}"
zip -ry "../../../../${OUTPUT_DIR}/${ZIP_NAME}" "${PROJECT_NAME}.app"
cd - > /dev/null

echo "➔ 4. Generiere korrekte appcast.xml via Sparkle Tool..."
"$GENERATE_APPCAST_BIN" "$OUTPUT_DIR"

# Kopiere die generierte XML ins Hauptverzeichnis für Git
cp "$OUTPUT_DIR/appcast.xml" "./appcast.xml" 2>/dev/null || cp "$OUTPUT_DIR/${PROJECT_NAME}.xml" "./appcast.xml" 2>/dev/null || true

echo "================================================="
echo " 🎉 Fertig! Überprüfe und starte Python-Server..."
echo "================================================="

# Da der LaunchAgent jetzt weg ist, killt das hier zuverlässig alte Reste
OLD_PID=$(lsof -t -i:$SERVER_PORT || true)
if [ ! -z "$OLD_PID" ]; then
    echo "➔ Port $SERVER_PORT ist belegt (PID: $OLD_PID). Beende alten Prozess..."
    kill -9 $OLD_PID 2>/dev/null || true
    sleep 1
fi

echo "➔ Starte Python-Server auf Port $SERVER_PORT..."
echo " Drücke STRG+C zum Beenden des Servers."
python3 -m http.server $SERVER_PORT --directory "$OUTPUT_DIR"
