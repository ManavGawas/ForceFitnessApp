#!/bin/bash
echo "Building Flutter Web..."
flutter build web --release

echo "Building Android APK..."
flutter build apk --release --split-per-abi

echo "Building iOS (Requires macOS + Xcode)..."
# flutter build ios --release --no-codesign

echo "Builds complete! Check the /build folder."
