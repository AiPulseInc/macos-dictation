#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/.dist"
BUNDLE_DIR="$ROOT_DIR/dist/QuickDictateMac.app"
CONTENTS_DIR="$BUNDLE_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
PLIST_SOURCE="$ROOT_DIR/packaging/Info.plist"
BACKEND_SOURCE_DIR="$ROOT_DIR/quickdictate-asr"
BACKEND_DEST_DIR="$RESOURCES_DIR/quickdictate-asr"
APP_ICON_PATH="$ROOT_DIR/packaging/AppIcon.icns"

if [[ ! -d "$BACKEND_SOURCE_DIR/.venv" ]]; then
  echo "Missing $BACKEND_SOURCE_DIR/.venv" >&2
  echo "Create the backend virtualenv and install its dependencies before building the app bundle." >&2
  exit 1
fi

zsh "$ROOT_DIR/scripts/build_app_icon.sh"

mkdir -p "$BUILD_DIR/ModuleCache"

CLANG_MODULE_CACHE_PATH="$BUILD_DIR/ModuleCache" \
SWIFTPM_MODULECACHE_OVERRIDE="$BUILD_DIR/ModuleCache" \
swift build -c release --package-path "$ROOT_DIR"

EXECUTABLE_PATH=""

for candidate in \
  "$ROOT_DIR/.build/release/QuickDictateMac" \
  "$ROOT_DIR/.build/arm64-apple-macosx/release/QuickDictateMac" \
  "$ROOT_DIR/.build/x86_64-apple-macosx/release/QuickDictateMac"
do
  if [[ -x "$candidate" ]]; then
    EXECUTABLE_PATH="$candidate"
    break
  fi
done

if [[ -z "$EXECUTABLE_PATH" ]]; then
  echo "Could not find the built QuickDictateMac executable." >&2
  exit 1
fi

rm -rf "$BUNDLE_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

cp "$EXECUTABLE_PATH" "$MACOS_DIR/QuickDictateMac"
cp "$PLIST_SOURCE" "$CONTENTS_DIR/Info.plist"
cp "$APP_ICON_PATH" "$RESOURCES_DIR/AppIcon.icns"

rsync -a \
  --exclude '__pycache__' \
  --exclude '.cache' \
  --exclude 'sample-en.aiff' \
  --exclude 'sample-en.wav' \
  "$BACKEND_SOURCE_DIR/" \
  "$BACKEND_DEST_DIR/"

chmod +x "$MACOS_DIR/QuickDictateMac"

echo "Built app bundle:"
echo "$BUNDLE_DIR"
