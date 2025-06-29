# Android ROM Building with Buildkite

This repository contains everything you need to build Android ROMs using Buildkite CI/CD with Docker containers.

## 🚀 Quick Setup

### 1. Buildkite Pipeline Setup

1. Go to your Buildkite dashboard
2. Click "New Pipeline"
3. Connect this GitHub repository
4. Set the pipeline configuration to use `.buildkite/pipeline.yml`
5. Add your agent queue (usually "default")

### 2. Agent Configuration

Make sure your Buildkite agent has:
- Docker installed and running
- Sufficient disk space (200GB+ recommended)
- Good internet connection for source sync

### 3. Environment Configuration

Copy `.env.example` to `.env` and configure:

```bash
cp .env.example .env
# Edit .env with your specific settings
```

## 📋 Pipeline Steps

The pipeline includes these automated steps:

1. **🔧 Setup Environment** - Verify Docker and dependencies
2. **📦 Build Docker Image** - Create Android build environment
3. **🐙 Initialize Source** - Set up Android source repository
4. **🔄 Sync Source** - Download Android source code (~100GB)
5. **🔨 Build ROM** - Compile the Android ROM (2-8 hours)
6. **📦 Package ROM** - Prepare artifacts for download
7. **⬆️ Upload Artifacts** - Upload ROM files to Buildkite
8. **✅ Complete** - Build finished notification

## 🎯 Device Configuration

To build for a specific device, modify these environment variables:

```yaml
env:
  TARGET_DEVICE: "your_device_codename"
  BUILD_VARIANT: "lineage"  # or aosp, etc.
  BUILD_TYPE: "userdebug"   # or user, eng
```

## 🏗️ Supported ROM Types

- **LineageOS** (default configuration)
- **AOSP** (Android Open Source Project)
- **Custom ROMs** (modify manifest URL)

## 📱 Popular Device Examples

### OnePlus 9 Pro (lemonades)
```yaml
env:
  TARGET_DEVICE: "lemonades"
  MANIFEST_URL: "https://github.com/LineageOS/android.git"
  MANIFEST_BRANCH: "lineage-21.0"
```

### Pixel 7 Pro (cheetah)
```yaml
env:
  TARGET_DEVICE: "cheetah" 
  MANIFEST_URL: "https://github.com/PixelExperience/manifest.git"
  MANIFEST_BRANCH: "thirteen"
```

## 🔧 Manual Build Commands

If you want to run builds manually:

```bash
# Build Docker image
cd docker && docker build -t android-rom-builder .

# Run full build process
docker-compose up

# Run individual steps
docker run --rm -v $(pwd)/source:/home/buildbot/android/source android-rom-builder /home/buildbot/scripts/init-source.sh
docker run --rm -v $(pwd)/source:/home/buildbot/android/source android-rom-builder /home/buildbot/scripts/sync-source.sh
docker run --rm -v $(pwd)/source:/home/buildbot/android/source -v $(pwd)/out:/home/buildbot/android/out android-rom-builder /home/buildbot/scripts/build-rom.sh
```

## 📊 Build Requirements

### System Requirements
- **CPU**: 8+ cores recommended
- **RAM**: 32GB+ recommended  
- **Storage**: 200GB+ free space
- **Network**: Stable high-speed connection

### Build Times (approximate)
- **Source Sync**: 30-60 minutes
- **First Build**: 4-8 hours
- **Incremental**: 30-120 minutes

## 🗂️ Directory Structure

```
.
├── .buildkite/
│   └── pipeline.yml          # Buildkite pipeline configuration
├── docker/
│   ├── Dockerfile           # Android build environment
│   └── docker-compose.yml   # Container orchestration
├── scripts/
│   ├── init-source.sh       # Initialize Android source
│   ├── sync-source.sh       # Sync source code
│   ├── build-rom.sh         # Build ROM
│   └── package-rom.sh       # Package artifacts
├── source/                  # Android source code (auto-created)
├── out/                     # Build outputs (auto-created)
├── ccache/                  # Build cache (auto-created)
├── artifacts/               # Final ROM files (auto-created)
└── .env                     # Environment configuration
```

## 🎛️ Advanced Configuration

### Custom Manifest
To use a different ROM source:

```bash
# In .env file
MANIFEST_URL=https://github.com/YourROM/android.git
MANIFEST_BRANCH=your-branch-name
```

### Build Optimization
```bash
# Enable ccache for faster builds
USE_CCACHE=1

# Set build jobs (usually = CPU cores)
BUILD_JOBS=16

# Clean build (slower but ensures clean state)
CLEAN_BUILD=1
```

## 🔍 Troubleshooting

### Common Issues

1. **Out of disk space**: Ensure 200GB+ free space
2. **Build fails**: Check logs in Buildkite dashboard
3. **Sync errors**: Verify internet connection and manifest URL
4. **Docker issues**: Ensure Docker daemon is running

### Log Locations
- Buildkite logs: Available in web dashboard
- Docker logs: `docker logs android-rom-builder`
- Build logs: `out/verbose.log.gz`

## 📞 Support

- Check Buildkite documentation for CI/CD issues
- Android build issues: Check device-specific forums
- Docker problems: Verify container setup

## 🎉 Success!

Once your build completes, download artifacts from the Buildkite dashboard:
- `*.zip` - Flashable ROM package
- `*.img` - Individual partition images  
- `build-info.json` - Build metadata
- `*.md5`/`*.sha256` - Checksums for verification 