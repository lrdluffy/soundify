#!/usr/bin/env bash
# One-time setup: generates the Android Gradle scaffolding with the Flutter SDK
# you have installed, then applies Soundify's manifest / activity / themes.
# Usage (from the project root):  bash scripts/setup_android.sh
set -euo pipefail

cd "$(dirname "$0")/.."

command -v flutter >/dev/null || { echo "flutter not found in PATH"; exit 1; }

# 1. Generate android/ (does not touch existing lib/ or pubspec.yaml).
flutter create --platforms=android --project-name soundify --org ir.soundify .

APP=android/app/src/main

# 2. Manifest, activity (replaces the generated one), themes.
cp android_overrides/AndroidManifest.xml "$APP/AndroidManifest.xml"
rm -f "$APP"/kotlin/ir/soundify/soundify/MainActivity.kt "$APP"/java/ir/soundify/soundify/MainActivity.java
mkdir -p "$APP/kotlin/ir/soundify/soundify"
cp android_overrides/MainActivity.kt "$APP/kotlin/ir/soundify/soundify/MainActivity.kt"
cp android_overrides/styles.xml "$APP/res/values/styles.xml"
mkdir -p "$APP/res/values-night"
cp android_overrides/styles-night.xml "$APP/res/values-night/styles.xml"

# 3. minSdk 23: required by local_auth / audio plugins.
for f in android/app/build.gradle.kts android/app/build.gradle; do
  [ -f "$f" ] || continue
  sed -i 's/minSdk = flutter.minSdkVersion/minSdk = 23/; s/minSdkVersion flutter.minSdkVersion/minSdkVersion 23/' "$f"
done

flutter pub get
echo
echo "Done. Build the release APK with:  bash scripts/build_release.sh"
