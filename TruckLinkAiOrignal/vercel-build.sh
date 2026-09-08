#!/bin/bash
set -euo pipefail

echo "========================================="
echo " TruckLink AI - Flutter Web Vercel Build "
echo "========================================="

FLUTTER_VERSION="3.38.7"
FLUTTER_DIR="$HOME/flutter"

git config --global --add safe.directory "*" || true

if [ ! -d "$FLUTTER_DIR/bin" ]; then
  echo "Cloning official Flutter SDK version ${FLUTTER_VERSION}..."
  git clone -b "${FLUTTER_VERSION}" --depth 1 https://github.com/flutter/flutter.git "$FLUTTER_DIR"
else
  echo "Flutter SDK found in cache: $FLUTTER_DIR"
fi

export PATH="$FLUTTER_DIR/bin:$PATH"

echo "Disabling analytics..."
flutter config --no-analytics

echo "Verifying Flutter version..."
flutter --version

echo "Enabling Flutter Web..."
flutter config --enable-web

echo "Fetching Flutter dependencies..."
flutter pub get

echo "Building Flutter Web release..."
flutter build web --release --no-wasm-dry-run

echo "Verifying build output..."
if [ ! -f "build/web/index.html" ]; then
  echo "ERROR: build/web/index.html was not generated!"
  exit 1
fi

echo "========================================="
echo " Flutter Web Build Succeeded for Vercel! "
echo "========================================="
