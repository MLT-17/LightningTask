#!/bin/bash
set -e

PROJECT_NAME="LightningTask"
SCHEME_NAME="LightningTask"
CONFIGURATION="Release"
BUILD_DIR="./build"
OUTPUT_DIR="./dist"
SERVER_PORT=8080

echo "➔ 1. Bereinige alte Builds..."
rm -rf "$BUILD_DIR" "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

echo "➔ 2. Xcode Build..."
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

echo "➔ 4. Generiere appcast.xml via Python..."
python3 - <<OPEOF
import os
import plistlib
import xml.etree.ElementTree as ET
from datetime import datetime

# Namensraum für Sparkle korrekt registrieren
SPARKLE_NS = "http://andymatuschak.org"
ET.register_namespace('sparkle', SPARKLE_NS)

app_path = "${BUILT_APP}"
info_plist_path = os.path.join(app_path, "Contents", "Info.plist")
zip_path = os.path.join("${OUTPUT_DIR}", "${ZIP_NAME}")

# Versionsdaten auslesen
with open(info_plist_path, 'rb') as f:
    plist = plistlib.load(f)
version = plist.get("CFBundleShortVersionString", "1.0")
build_num = plist.get("CFBundleVersion", "1")
zip_size = os.path.getsize(zip_path)
pub_date = datetime.now().strftime("%a, %d %b %Y %H:%M:%S +0100")

# XML Struktur aufbauen
rss = ET.Element("rss", version="2.0")
channel = ET.SubElement(rss, "channel")
ET.SubElement(channel, "title").text = "${PROJECT_NAME} Updates"

item = ET.SubElement(channel, "item")
ET.SubElement(item, "title").text = f"Version {version}"
ET.SubElement(item, "pubDate").text = pub_date

# Attribute mit dem registrierten Namensraum setzen
enclosure = ET.SubElement(item, "enclosure", 
                        url=f"http://localhost:${SERVER_PORT}/${ZIP_NAME}",
                        length=str(zip_size),
                        type="application/zip")
enclosure.set(f"{{{SPARKLE_NS}}}version", build_num)
enclosure.set(f"{{{SPARKLE_NS}}}shortVersionString", version)

# XML speichern
tree = ET.ElementTree(rss)
ET.indent(tree, space="    ")
tree.write(os.path.join("${OUTPUT_DIR}", "appcast.xml"), encoding="utf-8", xml_declaration=True)
print("➔ appcast.xml erfolgreich generiert!")
OPEOF

cp "${OUTPUT_DIR}/appcast.xml" "./appcast.xml"

echo "================================================="
echo " 🎉 Fertig! Möchtest du den Python-Server auf Port ${SERVER_PORT} starten? (y/n)"
echo "================================================="
read -r response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    python3 -m http.server ${SERVER_PORT} --directory "$OUTPUT_DIR"
fi
