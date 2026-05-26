#!/usr/bin/env bash
# Archive the Lastscrew iOS app and export an IPA suitable for TestFlight.
#
# Prerequisites:
#   1. Apple Developer Program membership (paid).
#   2. Your Team ID in ios/project.yml `DEVELOPMENT_TEAM` (or in the Xcode UI).
#   3. The bundle id `com.lastscrew.app` registered in App Store Connect.
#   4. Xcode signed in to your Apple ID with that team.
#   5. A 1024x1024 app icon in ios/Sources/Lastscrew/Assets.xcassets/AppIcon.appiconset/.
#   6. A deployed Worker URL (override `LASTSCREW_API_BASE` in scheme/Info.plist
#      with your https Cloudflare URL — TestFlight builds cannot reach
#      127.0.0.1 / your Mac's LAN IP).
#
# Usage:
#   bash scripts/archive-testflight.sh              # build + archive only
#   bash scripts/archive-testflight.sh --upload     # build + archive + upload to TestFlight
#
# Upload requires either Xcode signed in OR App Store Connect API key in env:
#   ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_PATH (path to .p8)

set -euo pipefail

cd "$(dirname "$0")/.."

PROJECT=ios/Lastscrew.xcodeproj
SCHEME=Lastscrew
ARCHIVE_PATH=ios/build/Lastscrew.xcarchive
EXPORT_DIR=ios/build/export
EXPORT_OPTIONS=ios/build/ExportOptions.plist

mkdir -p ios/build "$EXPORT_DIR"

# Make sure xcode-select points at the real Xcode, not just CLT.
DEV_DIR=$(xcode-select -p)
if [[ "$DEV_DIR" != *"Xcode.app"* ]]; then
  echo "ERROR: xcode-select points at $DEV_DIR. Run:" >&2
  echo "  sudo xcode-select -s /Applications/Xcode.app/Contents/Developer" >&2
  exit 1
fi

echo "==> Regenerating Xcode project"
( cd ios && xcodegen generate )

echo "==> Archiving"
xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath "$ARCHIVE_PATH" \
  archive \
  CODE_SIGN_STYLE=Automatic

# Write the ExportOptions plist used by xcodebuild -exportArchive.
cat > "$EXPORT_OPTIONS" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store-connect</string>
    <key>destination</key>
    <string>export</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>compileBitcode</key>
    <false/>
</dict>
</plist>
EOF

echo "==> Exporting IPA"
xcodebuild \
  -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_DIR" \
  -exportOptionsPlist "$EXPORT_OPTIONS"

ls -lh "$EXPORT_DIR"

if [[ "${1:-}" == "--upload" ]]; then
  IPA=$(ls "$EXPORT_DIR"/*.ipa | head -1)
  echo "==> Uploading $IPA to TestFlight"
  if [[ -n "${ASC_KEY_ID:-}" && -n "${ASC_ISSUER_ID:-}" && -n "${ASC_KEY_PATH:-}" ]]; then
    xcrun altool --upload-app -f "$IPA" -t ios \
      --apiKey "$ASC_KEY_ID" \
      --apiIssuer "$ASC_ISSUER_ID"
  else
    # Falls back to Xcode-stored credentials.
    xcrun altool --upload-app -f "$IPA" -t ios
  fi
fi

echo "Done. Archive: $ARCHIVE_PATH"
echo "       IPA:     $EXPORT_DIR"
