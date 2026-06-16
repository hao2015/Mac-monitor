#!/bin/bash
set -e

APP_NAME="MacMonitor"
BUILD_DIR="build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"

echo "=== Clean and prepare build directories ==="
rm -rf "$BUILD_DIR"
mkdir -p "$APP_BUNDLE/Contents/MacOS"

echo "=== Compiling Swift files ==="
swiftc src/TemperatureReader.swift src/CPUReader.swift src/DiskReader.swift src/ExternalDiskReader.swift src/MenuBarApp.swift src/main.swift \
    -o "$APP_BUNDLE/Contents/MacOS/$APP_NAME" \
    -target arm64-apple-macos11.0 \
    -O

echo "=== Copying Info.plist ==="
cp src/Info.plist "$APP_BUNDLE/Contents/Info.plist"

echo "=== Codesigning the app bundle (ad-hoc) ==="
codesign --force --deep --sign - "$APP_BUNDLE"

echo "=== Build succeeded! ==="
echo "You can find your app at: $(pwd)/$APP_BUNDLE"
echo "Launching the app now..."
open "$APP_BUNDLE"
echo "=== App launched successfully! ==="
