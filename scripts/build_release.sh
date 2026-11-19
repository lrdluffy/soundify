#!/usr/bin/env bash
# Builds a size-optimised arm64-v8a release APK -> build/app/outputs/flutter-apk/app-release.apk
set -euo pipefail

cd "$(dirname "$0")/.."

flutter build apk --release \
  --target-platform android-arm64 \
  --obfuscate --split-debug-info=build/symbols

ls -lh build/app/outputs/flutter-apk/app-release.apk
