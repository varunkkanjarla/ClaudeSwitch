#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
[[ "$(uname -s)" == "Darwin" ]] || { echo "Run this packaging script on macOS." >&2; exit 2; }

VERSION="${VERSION:-1.0.0-beta.2}"
BUILD_NUMBER="${BUILD_NUMBER:-2}"
CONFIG="${CONFIG:-release}"
APP="$ROOT/build/ClaudeSwitch.app"
DMG="$ROOT/build/ClaudeSwitch-${VERSION}.dmg"
IDENTITY="${DEVELOPER_ID_APPLICATION:-}"
NOTARY_PROFILE="${NOTARY_PROFILE:-}"
ARCHS="${ARCHS:-arm64 x86_64}"

rm -rf "$APP" "$DMG"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" "$ROOT/build"
# One build per architecture, merged with lipo: multi-arch `swift build` needs full Xcode, this works with Command Line Tools too.
SLICES=()
for ARCH in $ARCHS; do
  swift build -c "$CONFIG" --arch "$ARCH"
  BIN="$(swift build -c "$CONFIG" --arch "$ARCH" --show-bin-path)/ClaudeSwitch"
  [[ -x "$BIN" ]] || { echo "Build executable not found: $BIN" >&2; exit 3; }
  SLICES+=("$BIN")
done
lipo -create "${SLICES[@]}" -output "$APP/Contents/MacOS/ClaudeSwitch"
cp "$ROOT/Distribution/macOS/Info.plist" "$APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD_NUMBER" "$APP/Contents/Info.plist"

if [[ -n "$IDENTITY" ]]; then
  codesign --force --options runtime --timestamp --sign "$IDENTITY" "$APP"
  codesign --verify --deep --strict --verbose=2 "$APP"
else
  # Without Developer ID, seal the whole bundle ad hoc. A bundle carrying only the linker's signature fails
  # strict verification, which Gatekeeper reports to users as "damaged and can't be opened".
  codesign --force --sign - "$APP"
  codesign --verify --deep --strict --verbose=2 "$APP"
  echo "WARNING: ad-hoc signed, not notarized. Users must allow it once in System Settings > Privacy & Security > Open Anyway." >&2
fi

hdiutil create -volname "ClaudeSwitch" -srcfolder "$APP" -ov -format UDZO "$DMG"
if [[ -n "$IDENTITY" ]]; then
  codesign --force --timestamp --sign "$IDENTITY" "$DMG"
  codesign --verify --verbose=2 "$DMG"
fi

if [[ -n "$NOTARY_PROFILE" ]]; then
  [[ -n "$IDENTITY" ]] || { echo "Notarization requires DEVELOPER_ID_APPLICATION." >&2; exit 4; }
  xcrun notarytool submit "$DMG" --keychain-profile "$NOTARY_PROFILE" --wait
  xcrun stapler staple "$DMG"
  xcrun stapler validate "$DMG"
fi

shasum -a 256 "$DMG" | tee "$DMG.sha256"
echo "App: $APP"
echo "DMG: $DMG"
echo "SHA256: $DMG.sha256"
