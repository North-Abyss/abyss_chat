#!/bin/bash

# Extract the version number and build number (e.g., 1.1.5+2026072801) from pubspec.yaml
VERSION_FULL=$(grep '^version:' pubspec.yaml | awk '{print $2}')
VERSION=$(echo $VERSION_FULL | cut -d '+' -f 1)
BUILD=$(echo $VERSION_FULL | cut -d '+' -f 2)

echo "🛠️ Building App Bundle for Abyss Chat v$VERSION (Build $BUILD)..."
flutter build appbundle --release

# Ensure the releases directory exists
mkdir -p releases

# Move and rename the generated .aab file
cp build/app/outputs/bundle/release/app-release.aab "releases/Abyss-Chat-v${VERSION}-${BUILD}.aab"

echo ""
echo "✅ Success! Your App Bundle is ready at: releases/Abyss-Chat-v${VERSION}-${BUILD}.aab"
