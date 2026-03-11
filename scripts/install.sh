#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
INSTALL_DIR="/usr/local/lib/herald"
BIN_DIR="/usr/local/bin"

# Build the app bundle
"$SCRIPT_DIR/build-app.sh"

echo "Installing Herald..."

# Create install directory
sudo mkdir -p "$INSTALL_DIR"
sudo mkdir -p "$BIN_DIR"

# Copy app bundle
sudo rm -rf "$INSTALL_DIR/Herald.app"
sudo cp -R "$PROJECT_DIR/.build/Herald.app" "$INSTALL_DIR/Herald.app"

# Create symlink
sudo ln -sf "$INSTALL_DIR/Herald.app/Contents/MacOS/herald" "$BIN_DIR/herald"

echo "Herald installed successfully."
echo "  App: $INSTALL_DIR/Herald.app"
echo "  CLI: $BIN_DIR/herald"
echo ""
echo "Run 'herald --help' to get started."
