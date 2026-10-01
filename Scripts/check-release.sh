#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
version=$(xcodebuild -version | awk '/^Xcode / {print $2}')
major=${version%%.*}
if [ "$major" -lt 26 ]; then
    echo "App Store uploads require Xcode 26 or later with the iOS 26 SDK. Installed: $version."
    exit 1
fi
xcodebuild -project StateSwipe.xcodeproj -scheme StateSwipe -configuration Release -destination 'generic/platform=iOS' -showBuildSettings | awk '/IPHONEOS_DEPLOYMENT_TARGET|PRODUCT_BUNDLE_IDENTIFIER|DEVELOPMENT_TEAM|MARKETING_VERSION|CURRENT_PROJECT_VERSION/ {print}'
echo "Confirm the deployment target remains 16.0 and the signing team belongs to your Apple Developer account."
echo "Also verify public support/privacy URLs, screenshots, and App Store metadata before uploading."
