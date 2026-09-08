#!/bin/bash
set -euo pipefail

echo "========================================="
echo " TruckLink AI - Flutter Web Vercel Build "
echo "========================================="

FLUTTER_VERSION="3.38.7"
FLUTTER_TAR="flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"
FLUTTER_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/${FLUTTER_TAR}"

echo "Step 1: Checking / Installing Flutter SDK ${FLUTTER_VERSION}..."

if [ ! -d "$HOME/flutter/bin" ]; then
  echo "Downloading Flutter SDK ${FLUTTER_VERSION} from official archive..."
  mkdir -p "$HOME"
  cd "$HOME"
  curl -fsSL "$FLUTTER_URL" -o "$FLUTTER_TAR"
  tar -xf "$FLUTTER_TAR"
  rm -f "$FLUTTER_TAR"
  cd - > /dev/null
else
  echo "Flutter SDK directory found in cache: $HOME/flutter"
fi

export PATH="$PATH:$HOME/flutter/bin"

echo "Step 2: Verifying Flutter installation..."
flutter --version

echo "Step 3: Enabling Web Support..."
flutter config --enable-web

echo "Step 4: Installing dependencies..."
flutter pub get

echo "Step 5: Building Flutter Web release bundle..."
flutter build web --release

echo "Step 6: Verifying build artifact..."
if [ ! -f "build/web/index.html" ]; then
  echo "ERROR: build/web/index.html was not generated!"
  exit 1
fi

echo "========================================="
echo " Flutter Web Build Succeeded for Vercel! "
echo "========================================="
