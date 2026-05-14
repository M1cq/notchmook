#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$ROOT_DIR/build/NotchDesk.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
ICON_PNG="$ROOT_DIR/Resources/AppIcon.png"
ICONSET_DIR="$ROOT_DIR/Resources/AppIcon.iconset"
ICON_ICNS="$ROOT_DIR/Resources/AppIcon.icns"

cd "$ROOT_DIR"

if [[ -f "$ICON_PNG" ]]; then
    rm -rf "$ICONSET_DIR"
    mkdir -p "$ICONSET_DIR"

    sips -s format png -z 16 16 "$ICON_PNG" --out "$ICONSET_DIR/icon_16x16.png" >/dev/null
    sips -s format png -z 32 32 "$ICON_PNG" --out "$ICONSET_DIR/icon_16x16@2x.png" >/dev/null
    sips -s format png -z 32 32 "$ICON_PNG" --out "$ICONSET_DIR/icon_32x32.png" >/dev/null
    sips -s format png -z 64 64 "$ICON_PNG" --out "$ICONSET_DIR/icon_32x32@2x.png" >/dev/null
    sips -s format png -z 128 128 "$ICON_PNG" --out "$ICONSET_DIR/icon_128x128.png" >/dev/null
    sips -s format png -z 256 256 "$ICON_PNG" --out "$ICONSET_DIR/icon_128x128@2x.png" >/dev/null
    sips -s format png -z 256 256 "$ICON_PNG" --out "$ICONSET_DIR/icon_256x256.png" >/dev/null
    sips -s format png -z 512 512 "$ICON_PNG" --out "$ICONSET_DIR/icon_256x256@2x.png" >/dev/null
    sips -s format png -z 512 512 "$ICON_PNG" --out "$ICONSET_DIR/icon_512x512.png" >/dev/null
    sips -s format png -z 1024 1024 "$ICON_PNG" --out "$ICONSET_DIR/icon_512x512@2x.png" >/dev/null

    iconutil -c icns "$ICONSET_DIR" -o "$ICON_ICNS"
fi

swift build -c release

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"
cp ".build/release/NotchDesk" "$MACOS_DIR/NotchDesk"
cp "Resources/Info.plist" "$CONTENTS_DIR/Info.plist"
if [[ -f "$ICON_ICNS" ]]; then
    cp "$ICON_ICNS" "$RESOURCES_DIR/AppIcon.icns"
fi

chmod +x "$MACOS_DIR/NotchDesk"

echo "Built $APP_DIR"
