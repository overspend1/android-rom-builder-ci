#!/bin/bash
set -euo pipefail

echo "🔄 Syncing Android source code..."

cd /home/buildbot/android/source

# Check if repo is initialized
if [ ! -d ".repo" ]; then
    echo "❌ Repository not initialized! Run init-source.sh first."
    exit 1
fi

# Sync with multiple jobs for faster download
echo "⬇️ Starting source sync..."
repo sync \
    -c \
    -j$(nproc) \
    --force-sync \
    --no-clone-bundle \
    --no-tags \
    --optimized-fetch \
    --prune

echo "✅ Source sync completed successfully!"

# Display sync statistics
echo "📊 Sync statistics:"
echo "Total repositories: $(find .repo/projects -name "*.git" | wc -l)"
echo "Disk usage: $(du -sh . | cut -f1)"

# Check for any missing projects
echo "🔍 Checking for missing projects..."
if repo status | grep -q "project.*dirty\|project.*not up-to-date"; then
    echo "⚠️ Some projects may need attention:"
    repo status | grep -E "project.*dirty|project.*not up-to-date" || true
else
    echo "✅ All projects are clean and up-to-date"
fi 