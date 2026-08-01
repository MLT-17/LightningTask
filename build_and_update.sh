#!/bin/bash
set -e

PROJECT_NAME="LightningTask"
SCHEME_NAME="LightningTask"
CONFIGURATION="Release"
BUILD_DIR="./build"
OUTPUT_DIR="./dist"
SERVER_PORT=8000
PLIST_PATH="LightningTask/Info.plist"
PRODUCTION_FEED_URL="https://raw.githubusercontent.com/MLT-17/LightningTask/main/appcast.xml"
LOCAL_FEED_URL="http://localhost:${SERVER_PORT}/appcast.xml"

GENERATE_APPCAST_BIN=$(which generate_appcast 2>/dev/null || find /opt/homebrew/Caskroom/sparkle -name "generate_appcast" -print -quit 2>/dev/null)

if [ -z "$GENERATE_APPCAST_BIN" ]; then
    echo "Error: 'generate_appcast' not found. Install Sparkle via Homebrew."
    exit 1
fi

# Restore production URL on exit (even on failure)
trap '/usr/libexec/PlistBuddy -c "Set :SUFeedURL $PRODUCTION_FEED_URL" "$PLIST_PATH"' EXIT

echo "→ 1. Patching SUFeedURL for local testing..."
/usr/libexec/PlistBuddy -c "Set :SUFeedURL $LOCAL_FEED_URL" "$PLIST_PATH"

echo "→ 2. Cleaning old builds..."
rm -rf "$BUILD_DIR" "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

echo "→ 3. Bumping build number and building..."
xcrun agvtool next-version -all

xcodebuild -project "${PROJECT_NAME}.xcodeproj" \
           -scheme "${SCHEME_NAME}" \
           -configuration "${CONFIGURATION}" \
           -derivedDataPath "$BUILD_DIR" \
           build

echo "→ 4. Creating ZIP archive..."
ZIP_NAME="${PROJECT_NAME}.zip"
cd "${BUILD_DIR}/Build/Products/${CONFIGURATION}"
zip -ry "../../../../${OUTPUT_DIR}/${ZIP_NAME}" "${PROJECT_NAME}.app"
cd - > /dev/null

echo "→ 5. Generating appcast.xml..."
"$GENERATE_APPCAST_BIN" "$OUTPUT_DIR"
cp "$OUTPUT_DIR/appcast.xml" "./appcast.xml" 2>/dev/null || cp "$OUTPUT_DIR/${PROJECT_NAME}.xml" "./appcast.xml" 2>/dev/null || true

echo "→ 6. Restoring production URL..."
/usr/libexec/PlistBuddy -c "Set :SUFeedURL $PRODUCTION_FEED_URL" "$PLIST_PATH"
trap - EXIT

echo "========================================="
echo "Done. Starting local server on port $SERVER_PORT..."
echo "Press Ctrl+C to stop."
echo "========================================="

OLD_PID=$(lsof -t -i:$SERVER_PORT || true)
if [ -n "$OLD_PID" ]; then
    echo "Port $SERVER_PORT in use (PID: $OLD_PID). Killing..."
    kill -9 $OLD_PID 2>/dev/null || true
    sleep 1
fi

python3 -m http.server $SERVER_PORT --directory "$OUTPUT_DIR"
