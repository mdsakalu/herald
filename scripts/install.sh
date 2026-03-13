#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
PREFIX="${PREFIX:-/usr/local}"
INSTALL_DIR="${PREFIX}/lib/herald"
BIN_DIR="${PREFIX}/bin"

usage() {
    echo "Usage: $0 [--prefix PREFIX] [--uninstall]"
    echo ""
    echo "Options:"
    echo "  --prefix PREFIX   Install prefix (default: /usr/local)"
    echo "  --uninstall       Remove herald installation"
    exit 0
}

do_uninstall() {
    echo "Uninstalling Herald..."
    local needs_sudo=false
    [ ! -w "$INSTALL_DIR" ] 2>/dev/null && needs_sudo=true

    if $needs_sudo; then
        sudo rm -rf "$INSTALL_DIR"
        sudo rm -f "$BIN_DIR/herald"
    else
        rm -rf "$INSTALL_DIR"
        rm -f "$BIN_DIR/herald"
    fi
    echo "Herald uninstalled."
    exit 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --prefix) PREFIX="$2"; INSTALL_DIR="${PREFIX}/lib/herald"; BIN_DIR="${PREFIX}/bin"; shift 2 ;;
        --uninstall) do_uninstall ;;
        --help|-h) usage ;;
        *) echo "Unknown option: $1"; usage ;;
    esac
done

# Build the app bundle
"$SCRIPT_DIR/build-app.sh"

echo "Installing Herald to ${PREFIX}..."

# Determine if sudo is needed
NEEDS_SUDO=false
if [ ! -w "${PREFIX}/lib" ] 2>/dev/null || [ ! -w "${PREFIX}/bin" ] 2>/dev/null; then
    NEEDS_SUDO=true
fi

run() {
    if $NEEDS_SUDO; then
        sudo "$@"
    else
        "$@"
    fi
}

run mkdir -p "$INSTALL_DIR"
run mkdir -p "$BIN_DIR"

run rm -rf "$INSTALL_DIR/Herald.app"
run cp -R "$PROJECT_DIR/.build/Herald.app" "$INSTALL_DIR/Herald.app"
run ln -sf "$INSTALL_DIR/Herald.app/Contents/MacOS/herald" "$BIN_DIR/herald"

echo ""
echo "Herald installed successfully."
echo "  App: $INSTALL_DIR/Herald.app"
echo "  CLI: $BIN_DIR/herald"
echo ""
echo "Uninstall: $0 --uninstall${PREFIX:+ --prefix $PREFIX}"
