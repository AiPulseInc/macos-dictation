#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/.dist/appicon"
ICONSET_DIR="$BUILD_DIR/AppIcon.iconset"
SVG_PATH="$ROOT_DIR/packaging/AppIcon.svg"
BASE_PNG="$BUILD_DIR/AppIcon-1024.png"
OUTPUT_ICNS="$ROOT_DIR/packaging/AppIcon.icns"

mkdir -p "$ICONSET_DIR"

magick -background none "$SVG_PATH" -resize 1024x1024 "$BASE_PNG"

for size in 16 32 64 128 256 512; do
  sips -z "$size" "$size" "$BASE_PNG" --out "$ICONSET_DIR/icon_${size}x${size}.png" >/dev/null
done

sips -z 32 32 "$BASE_PNG" --out "$ICONSET_DIR/icon_16x16@2x.png" >/dev/null
sips -z 64 64 "$BASE_PNG" --out "$ICONSET_DIR/icon_32x32@2x.png" >/dev/null
sips -z 256 256 "$BASE_PNG" --out "$ICONSET_DIR/icon_128x128@2x.png" >/dev/null
sips -z 512 512 "$BASE_PNG" --out "$ICONSET_DIR/icon_256x256@2x.png" >/dev/null
sips -z 1024 1024 "$BASE_PNG" --out "$ICONSET_DIR/icon_512x512@2x.png" >/dev/null

iconutil -c icns "$ICONSET_DIR" -o "$OUTPUT_ICNS"

echo "Built icon:"
echo "$OUTPUT_ICNS"
