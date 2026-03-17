#!/bin/bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: scripts/generate-app-icon.sh SOURCE_PNG [MASTER_PNG] [OUTPUT_ICNS] [APPICONSET_DIR]

Creates a full-bleed 1024px master PNG, a macOS AppIcon.appiconset, and a
multi-size .icns fallback bundle.

Defaults:
  MASTER_PNG  resources/AppIcon-1024.png
  OUTPUT_ICNS resources/AppIcon.icns
  APPICONSET_DIR resources/Assets.xcassets/AppIcon.appiconset
EOF
}

if [[ $# -lt 1 || $# -gt 4 ]]; then
  usage >&2
  exit 1
fi

SOURCE_PNG="$1"
MASTER_PNG="${2:-resources/AppIcon-1024.png}"
OUTPUT_ICNS="${3:-resources/AppIcon.icns}"
APPICONSET_DIR="${4:-resources/Assets.xcassets/AppIcon.appiconset}"

if [[ ! -f "$SOURCE_PNG" ]]; then
  echo "Source image not found: $SOURCE_PNG" >&2
  exit 1
fi

mkdir -p "$(dirname "$MASTER_PNG")" "$(dirname "$OUTPUT_ICNS")" "$APPICONSET_DIR"

ICONSET_DIR="/tmp/herald-app-icon.$$.$RANDOM.iconset"
mkdir -p "$ICONSET_DIR"
trap 'rm -rf "$ICONSET_DIR"' EXIT

sips -z 1024 1024 "$SOURCE_PNG" --out "$MASTER_PNG" >/dev/null

sips -z 16 16 "$MASTER_PNG" --out "$ICONSET_DIR/icon_16x16.png" >/dev/null
sips -z 32 32 "$MASTER_PNG" --out "$ICONSET_DIR/icon_16x16@2x.png" >/dev/null
sips -z 32 32 "$MASTER_PNG" --out "$ICONSET_DIR/icon_32x32.png" >/dev/null
sips -z 64 64 "$MASTER_PNG" --out "$ICONSET_DIR/icon_32x32@2x.png" >/dev/null
sips -z 128 128 "$MASTER_PNG" --out "$ICONSET_DIR/icon_128x128.png" >/dev/null
sips -z 256 256 "$MASTER_PNG" --out "$ICONSET_DIR/icon_128x128@2x.png" >/dev/null
sips -z 256 256 "$MASTER_PNG" --out "$ICONSET_DIR/icon_256x256.png" >/dev/null
sips -z 512 512 "$MASTER_PNG" --out "$ICONSET_DIR/icon_256x256@2x.png" >/dev/null
sips -z 512 512 "$MASTER_PNG" --out "$ICONSET_DIR/icon_512x512.png" >/dev/null
cp "$MASTER_PNG" "$ICONSET_DIR/icon_512x512@2x.png"

cp "$ICONSET_DIR"/icon_16x16.png "$APPICONSET_DIR"/icon_16x16.png
cp "$ICONSET_DIR"/icon_16x16@2x.png "$APPICONSET_DIR"/icon_16x16@2x.png
cp "$ICONSET_DIR"/icon_32x32.png "$APPICONSET_DIR"/icon_32x32.png
cp "$ICONSET_DIR"/icon_32x32@2x.png "$APPICONSET_DIR"/icon_32x32@2x.png
cp "$ICONSET_DIR"/icon_128x128.png "$APPICONSET_DIR"/icon_128x128.png
cp "$ICONSET_DIR"/icon_128x128@2x.png "$APPICONSET_DIR"/icon_128x128@2x.png
cp "$ICONSET_DIR"/icon_256x256.png "$APPICONSET_DIR"/icon_256x256.png
cp "$ICONSET_DIR"/icon_256x256@2x.png "$APPICONSET_DIR"/icon_256x256@2x.png
cp "$ICONSET_DIR"/icon_512x512.png "$APPICONSET_DIR"/icon_512x512.png
cp "$ICONSET_DIR"/icon_512x512@2x.png "$APPICONSET_DIR"/icon_512x512@2x.png

iconutil -c icns "$ICONSET_DIR" -o "$OUTPUT_ICNS"

echo "Master PNG: $MASTER_PNG"
echo "App icon set: $APPICONSET_DIR"
echo "App icon:   $OUTPUT_ICNS"
