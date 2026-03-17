#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="${PROJECT_DIR}/.build"
APP_DIR="${BUILD_DIR}/Herald.app"
ASSET_CATALOG_DIR="${PROJECT_DIR}/resources/Assets.xcassets"
STATIC_ICON_FILE="${PROJECT_DIR}/resources/AppIcon.icns"

echo "Building Herald CLI..."
cd "$PROJECT_DIR"
swift build -c release

echo "Creating app bundle..."
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

# Copy binary
cp "${BUILD_DIR}/release/Herald" "$APP_DIR/Contents/MacOS/herald"

# Stamp version from binary into Info.plist
VERSION=$("$APP_DIR/Contents/MacOS/herald" --version 2>&1 || true)
INFO_PLIST="$APP_DIR/Contents/Info.plist"
sed "s/__VERSION__/${VERSION}/g" "$PROJECT_DIR/resources/Info.plist" > "$INFO_PLIST"

if [[ -d "$ASSET_CATALOG_DIR" ]]; then
  echo "Compiling asset catalog..."
  ICON_BUILD_DIR="$(mktemp -d /tmp/herald-assets.XXXXXX)"
  trap 'rm -rf "$ICON_BUILD_DIR"' EXIT

  xcrun actool \
    --compile "$ICON_BUILD_DIR" \
    --platform macosx \
    --minimum-deployment-target 13.0 \
    --app-icon AppIcon \
    --standalone-icon-behavior all \
    --output-partial-info-plist "$ICON_BUILD_DIR/partial-info.plist" \
    "$ASSET_CATALOG_DIR"

  shopt -s nullglob
  for item in "$ICON_BUILD_DIR"/*; do
    if [[ "$(basename "$item")" == "partial-info.plist" ]]; then
      continue
    fi
    cp -R "$item" "$APP_DIR/Contents/Resources/"
  done
  shopt -u nullglob

  ICON_FILE=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIconFile" "$ICON_BUILD_DIR/partial-info.plist" 2>/dev/null || true)
  ICON_NAME=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIconName" "$ICON_BUILD_DIR/partial-info.plist" 2>/dev/null || true)

  if [[ -n "$ICON_FILE" ]]; then
    /usr/libexec/PlistBuddy -c "Delete :CFBundleIconFile" "$INFO_PLIST" >/dev/null 2>&1 || true
    /usr/libexec/PlistBuddy -c "Add :CFBundleIconFile string $ICON_FILE" "$INFO_PLIST"
  fi

  if [[ -n "$ICON_NAME" ]]; then
    /usr/libexec/PlistBuddy -c "Delete :CFBundleIconName" "$INFO_PLIST" >/dev/null 2>&1 || true
    /usr/libexec/PlistBuddy -c "Add :CFBundleIconName string $ICON_NAME" "$INFO_PLIST"
  fi
elif [[ -f "$STATIC_ICON_FILE" ]]; then
  cp "$STATIC_ICON_FILE" "$APP_DIR/Contents/Resources/AppIcon.icns"
else
  echo "No app icon source found. Expected $ASSET_CATALOG_DIR or $STATIC_ICON_FILE" >&2
  exit 1
fi

# Ad-hoc sign (required for UNUserNotificationCenter authorization)
echo "Signing app bundle..."
codesign --force --deep --sign - "$APP_DIR"

echo "App bundle created at: $APP_DIR"
echo "Binary: $APP_DIR/Contents/MacOS/herald"
echo "Version: $VERSION"
