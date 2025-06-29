#!/bin/bash
set -euo pipefail

echo "🔨 Starting Android ROM build..."

cd /home/buildbot/android/source

# Configuration - modify these for your target device
TARGET_DEVICE="${TARGET_DEVICE:-generic}"
BUILD_TYPE="${BUILD_TYPE:-userdebug}"
BUILD_VARIANT="${BUILD_VARIANT:-lineage}"

echo "🎯 Build configuration:"
echo "  Device: $TARGET_DEVICE"
echo "  Type: $BUILD_TYPE" 
echo "  Variant: $BUILD_VARIANT"

# Set up build environment
echo "⚙️ Setting up build environment..."
source build/envsetup.sh

# Setup ccache
if [ "${USE_CCACHE:-1}" = "1" ]; then
    echo "🚀 Configuring ccache..."
    export USE_CCACHE=1
    export CCACHE_DIR=/home/buildbot/android/ccache
    ccache -M 50G
    ccache -s
fi

# Clean previous builds if requested
if [ "${CLEAN_BUILD:-0}" = "1" ]; then
    echo "🧹 Cleaning previous build..."
    make clean
fi

# Select build target
echo "🎯 Selecting build target..."
lunch "${BUILD_VARIANT}_${TARGET_DEVICE}-${BUILD_TYPE}"

# Start build
echo "🔨 Starting compilation..."
START_TIME=$(date +%s)

# Build with appropriate number of parallel jobs
JOBS=${BUILD_JOBS:-$(nproc)}
echo "🚀 Building with $JOBS parallel jobs..."

if [ "$BUILD_VARIANT" = "lineage" ]; then
    # LineageOS specific build command
    brunch "$TARGET_DEVICE"
else
    # Generic AOSP build
    make -j"$JOBS" otapackage
fi

END_TIME=$(date +%s)
BUILD_TIME=$((END_TIME - START_TIME))

echo "✅ Build completed successfully!"
echo "⏱️ Build time: $(date -u -d @$BUILD_TIME +%H:%M:%S)"

# Display build artifacts
echo "📦 Build artifacts:"
find /home/buildbot/android/out/target/product/"$TARGET_DEVICE"/ -name "*.zip" -o -name "*.img" | head -10 