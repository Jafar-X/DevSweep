#!/bin/bash
set -e

echo "Building DevSweep..."
swift build -c release

echo "Packaging .app bundle..."
BIN=".build/release/DevSweep"
APP="DevSweep.app"

mkdir -p "$APP/Contents/MacOS"
cp "$BIN" "$APP/Contents/MacOS/DevSweep"
chmod +x "$APP/Contents/MacOS/DevSweep"

echo "Done. Launch with:"
echo "  open $APP"
