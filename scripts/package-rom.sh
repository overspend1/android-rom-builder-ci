#!/bin/bash
set -euo pipefail

echo "📦 Packaging ROM artifacts..."

TARGET_DEVICE="${TARGET_DEVICE:-generic}"
OUT_DIR="/home/buildbot/android/out/target/product/$TARGET_DEVICE"
ARTIFACTS_DIR="/home/buildbot/artifacts"

# Create artifacts directory
mkdir -p "$ARTIFACTS_DIR"

echo "📁 Copying build artifacts..."

# Copy main ROM files
if [ -f "$OUT_DIR"/*.zip ]; then
    echo "📱 Copying ROM zip files..."
    cp "$OUT_DIR"/*.zip "$ARTIFACTS_DIR/" || true
fi

# Copy recovery image
if [ -f "$OUT_DIR/recovery.img" ]; then
    echo "🔧 Copying recovery image..."
    cp "$OUT_DIR/recovery.img" "$ARTIFACTS_DIR/" || true
fi

# Copy boot image  
if [ -f "$OUT_DIR/boot.img" ]; then
    echo "🥾 Copying boot image..."
    cp "$OUT_DIR/boot.img" "$ARTIFACTS_DIR/" || true
fi

# Copy system image
if [ -f "$OUT_DIR/system.img" ]; then
    echo "💿 Copying system image..."
    cp "$OUT_DIR/system.img" "$ARTIFACTS_DIR/" || true
fi

# Copy vendor image
if [ -f "$OUT_DIR/vendor.img" ]; then
    echo "🏪 Copying vendor image..."
    cp "$OUT_DIR/vendor.img" "$ARTIFACTS_DIR/" || true
fi

# Create build info JSON
echo "📋 Creating build information..."
cat > "$ARTIFACTS_DIR/build-info.json" << EOF
{
  "build_number": "${BUILDKITE_BUILD_NUMBER:-unknown}",
  "commit": "${BUILDKITE_COMMIT:-unknown}",
  "branch": "${BUILDKITE_BRANCH:-unknown}",
  "device": "$TARGET_DEVICE",
  "build_date": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "build_type": "${BUILD_TYPE:-userdebug}",
  "variant": "${BUILD_VARIANT:-lineage}"
}
EOF

# Create checksums
echo "🔐 Generating checksums..."
cd "$ARTIFACTS_DIR"
find . -name "*.zip" -o -name "*.img" | xargs -I {} sh -c 'md5sum "{}" > "{}.md5"'
find . -name "*.zip" -o -name "*.img" | xargs -I {} sh -c 'sha256sum "{}" > "{}.sha256"'

echo "📊 Artifact summary:"
ls -lh "$ARTIFACTS_DIR"

echo "✅ Packaging completed successfully!" 