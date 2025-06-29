#!/bin/bash
set -euo pipefail

echo "🚀 Setting up Android ROM building environment..."

# Create necessary directories
echo "📁 Creating directory structure..."
mkdir -p source out ccache artifacts

# Create environment file if it doesn't exist
if [ ! -f ".env" ]; then
    echo "⚙️ Creating environment configuration..."
    cat > .env << 'EOF'
# Buildkite Agent Configuration
BUILDKITE_AGENT_TOKEN=your_buildkite_agent_token_here

# Android Build Configuration
TARGET_DEVICE=generic
BUILD_TYPE=userdebug
BUILD_VARIANT=lineage
BUILD_JOBS=8

# Build Options
USE_CCACHE=1
CLEAN_BUILD=0

# Manifest Configuration
MANIFEST_URL=https://github.com/LineageOS/android.git
MANIFEST_BRANCH=lineage-21.0
MANIFEST_NAME=default.xml

# Storage Paths (adjust these for your system)
SOURCE_DIR=./source
OUT_DIR=./out
CCACHE_DIR=./ccache
ARTIFACTS_DIR=./artifacts
EOF
    echo "✅ Created .env file - please edit it with your configuration!"
else
    echo "⚠️ .env file already exists, skipping..."
fi

# Check Docker installation
echo "🐳 Checking Docker installation..."
if command -v docker &> /dev/null; then
    echo "✅ Docker is installed"
    docker --version
else
    echo "❌ Docker is not installed! Please install Docker first."
    exit 1
fi

# Check Docker Compose
if command -v docker-compose &> /dev/null; then
    echo "✅ Docker Compose is installed"
    docker-compose --version
else
    echo "❌ Docker Compose is not installed! Please install Docker Compose first."
    exit 1
fi

# Check available disk space
echo "💾 Checking available disk space..."
AVAILABLE_SPACE=$(df -BG . | tail -1 | awk '{print $4}' | sed 's/G//')
if [ "$AVAILABLE_SPACE" -lt 200 ]; then
    echo "⚠️ Warning: Only ${AVAILABLE_SPACE}GB available. Android builds need 200GB+!"
else
    echo "✅ ${AVAILABLE_SPACE}GB available - sufficient for ROM building"
fi

# Build Docker image
echo "🔨 Building Docker image (this may take a while)..."
cd docker
docker build -t android-rom-builder:latest .
cd ..

echo ""
echo "🎉 Setup completed successfully!"
echo ""
echo "Next steps:"
echo "1. Edit .env file with your device and ROM configuration"
echo "2. Set up your Buildkite pipeline using .buildkite/pipeline.yml"
echo "3. Push this repository to GitHub/GitLab"
echo "4. Connect the repository to Buildkite"
echo "5. Trigger your first build!"
echo ""
echo "For manual builds, run: docker-compose up"
echo "" 