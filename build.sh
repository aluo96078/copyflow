#!/bin/bash
set -e

echo "Building ClipFlow..."
go build -o clipflow .

echo "Packaging ClipFlow.app..."
mkdir -p ClipFlow.app/Contents/MacOS
mkdir -p ClipFlow.app/Contents/Resources
cp clipflow ClipFlow.app/Contents/MacOS/clipflow

# Ensure Info.plist exists
cat > ClipFlow.app/Contents/Info.plist << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>clipflow</string>
    <key>CFBundleIdentifier</key>
    <string>com.clipflow.app</string>
    <key>CFBundleName</key>
    <string>ClipFlow</string>
    <key>CFBundleDisplayName</key>
    <string>ClipFlow</string>
    <key>CFBundleVersion</key>
    <string>1.0.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>12.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

echo "Signing ClipFlow.app..."
codesign --force --deep --sign - ClipFlow.app

echo "Installing to /Applications..."
cp -R ClipFlow.app /Applications/ClipFlow.app
codesign --force --deep --sign - /Applications/ClipFlow.app

echo "Done! Run with: open /Applications/ClipFlow.app"
