#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="${PROJECT_DIR}/.build"
APP_DIR="${BUILD_DIR}/Herald.app"

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
sed "s/__VERSION__/${VERSION}/g" "$PROJECT_DIR/resources/Info.plist" > "$APP_DIR/Contents/Info.plist"

# Copy icon
cp "$PROJECT_DIR/resources/AppIcon.icns" "$APP_DIR/Contents/Resources/AppIcon.icns"

# Ad-hoc sign (required for UNUserNotificationCenter authorization)
echo "Signing app bundle..."
codesign --force --deep --sign - "$APP_DIR"

echo "App bundle created at: $APP_DIR"
echo "Binary: $APP_DIR/Contents/MacOS/herald"
echo "Version: $VERSION"
