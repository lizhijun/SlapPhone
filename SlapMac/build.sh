#!/bin/bash
# Build and bundle SlapMac as a macOS .app

set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$PROJECT_DIR/.build/release"
APP_NAME="SlapMac"
APP_BUNDLE="$PROJECT_DIR/$APP_NAME.app"

echo "Building $APP_NAME in release mode..."
cd "$PROJECT_DIR"
swift build -c release

echo "Creating app bundle..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Copy executable
cp "$BUILD_DIR/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

# Copy app icon
if [ -f "$PROJECT_DIR/Resources/AppIcon.icns" ]; then
    cp "$PROJECT_DIR/Resources/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
    echo "App icon copied."
fi

# Copy bundled sound pack
if [ -d "$PROJECT_DIR/soundpack" ]; then
    cp "$PROJECT_DIR/soundpack/"* "$APP_BUNDLE/Contents/Resources/"
    echo "Sound pack copied ($(ls "$PROJECT_DIR/soundpack/" | wc -l | tr -d ' ') files)."
fi

# Create Info.plist
cat > "$APP_BUNDLE/Contents/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>SlapMac</string>
    <key>CFBundleDisplayName</key>
    <string>SlapMac</string>
    <key>CFBundleIdentifier</key>
    <string>com.slapmac.app</string>
    <key>CFBundleVersion</key>
    <string>1.0.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleExecutable</key>
    <string>SlapMac</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.6</string>
    <key>LSUIElement</key>
    <true/>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.entertainment</string>
</dict>
</plist>
PLIST

echo ""
echo "Done! App bundle created at: $APP_BUNDLE"
echo "Run with: open $APP_BUNDLE"
