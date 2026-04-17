#!/bin/bash
# Create a DMG for CuePrompt distribution

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.." || exit 1

VERSION=$(cat VERSION | tr -d '[:space:]')
APP_NAME="CuePrompt"
DMG_NAME="${APP_NAME}-${VERSION}.dmg"
STAGING_DIR="/tmp/${APP_NAME}-dmg-staging"

# Ensure the app bundle exists
if [ ! -d "${APP_NAME}.app" ]; then
  echo "Error: ${APP_NAME}.app not found. Run 'make build' first."
  exit 1
fi

echo "Creating DMG: ${DMG_NAME}"

# Clean staging
rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR"

# Copy app to staging
cp -R "${APP_NAME}.app" "$STAGING_DIR/"

# Create symlink to Applications
ln -s /Applications "$STAGING_DIR/Applications"

# Create DMG
hdiutil create -volname "$APP_NAME" \
  -srcfolder "$STAGING_DIR" \
  -ov -format UDZO \
  "$DMG_NAME"

# Clean staging
rm -rf "$STAGING_DIR"

echo "DMG created: ${DMG_NAME}"
ls -lh "$DMG_NAME"

# Notarize if a Developer ID was found
DETECTED_HASH=$(security find-identity -v -p codesigning | grep "Developer ID Application" | head -1 | awk '{print $2}')
if [ -n "$DETECTED_HASH" ]; then
  echo ""
  echo "To notarize, run:"
  echo "  xcrun notarytool submit ${DMG_NAME} --apple-id YOUR_APPLE_ID --password YOUR_APP_SPECIFIC_PASSWORD --team-id YOUR_TEAM_ID --wait"
  echo "  xcrun stapler staple ${DMG_NAME}"
fi
