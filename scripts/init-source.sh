#!/bin/bash
set -euo pipefail

echo "🚀 Initializing Android source repository..."

cd /home/buildbot/android/source

# Configuration - you can modify these
MANIFEST_URL="https://github.com/LineageOS/android.git"
MANIFEST_BRANCH="lineage-21.0"
MANIFEST_NAME="default.xml"

# Check if source is already initialized
if [ ! -d ".repo" ]; then
    echo "📁 Initializing repo with manifest: $MANIFEST_URL"
    echo "📋 Branch: $MANIFEST_BRANCH"
    
    repo init \
        -u "$MANIFEST_URL" \
        -b "$MANIFEST_BRANCH" \
        -m "$MANIFEST_NAME" \
        --depth=1 \
        --no-clone-bundle
        
    echo "✅ Repository initialized successfully!"
else
    echo "📁 Repository already initialized, skipping..."
fi

# Display repo info
echo "📊 Repository information:"
repo info | head -10 