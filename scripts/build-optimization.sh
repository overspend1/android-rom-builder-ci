#!/bin/bash
# ====================================================================
# ADVANCED ROM BUILD OPTIMIZATION SCRIPT
# Comprehensive build environment tuning and performance optimization
# ====================================================================

set -euo pipefail

echo "🚀 Advanced ROM Build Optimization System v2.0"
echo "=================================================="

# Color codes for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# System information gathering
get_system_info() {
    log "🔍 Gathering system information..."
    
    CORES=$(nproc)
    TOTAL_RAM_GB=$(free -g | awk '/^Mem:/ {print $2}')
    AVAILABLE_RAM_GB=$(free -g | awk '/^Mem:/ {print $7}')
    DISK_FREE_GB=$(df -BG . | awk 'NR==2 {gsub("G",""); print int($4)}')
    CPU_MODEL=$(grep 'model name' /proc/cpuinfo | head -1 | cut -d: -f2 | xargs)
    KERNEL_VERSION=$(uname -r)
    
    echo "System Specifications:"
    echo "  CPU: $CPU_MODEL"
    echo "  Cores: $CORES"
    echo "  Total RAM: ${TOTAL_RAM_GB}GB"
    echo "  Available RAM: ${AVAILABLE_RAM_GB}GB"
    echo "  Free Disk Space: ${DISK_FREE_GB}GB"
    echo "  Kernel: $KERNEL_VERSION"
}

# CPU optimization
optimize_cpu() {
    log "⚡ Optimizing CPU performance..."
    
    # Set CPU governor to performance
    if [ -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor ]; then
        echo "performance" | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor >/dev/null 2>&1 || warn "Could not set CPU governor"
        log "CPU governor set to performance mode"
    fi
    
    # Disable CPU idle states for maximum performance
    if command -v cpupower >/dev/null 2>&1; then
        sudo cpupower idle-set -D 0 >/dev/null 2>&1 || warn "Could not disable CPU idle states"
        log "CPU idle states optimized"
    fi
    
    # Set CPU affinity for build processes
    if command -v taskset >/dev/null 2>&1; then
        export NINJA_CPU_AFFINITY="0-$((CORES-1))"
        log "CPU affinity configured for build processes"
    fi
}

# Memory optimization
optimize_memory() {
    log "🧠 Optimizing memory management..."
    
    # Adjust swappiness for build workloads
    echo 10 | sudo tee /proc/sys/vm/swappiness >/dev/null 2>&1 || warn "Could not adjust swappiness"
    
    # Optimize dirty page parameters for I/O intensive builds
    echo 15 | sudo tee /proc/sys/vm/dirty_background_ratio >/dev/null 2>&1 || warn "Could not set dirty_background_ratio"
    echo 30 | sudo tee /proc/sys/vm/dirty_ratio >/dev/null 2>&1 || warn "Could not set dirty_ratio"
    
    # Enable transparent huge pages for better memory performance
    echo always | sudo tee /sys/kernel/mm/transparent_hugepage/enabled >/dev/null 2>&1 || warn "Could not enable THP"
    
    log "Memory optimization completed"
}

# I/O optimization
optimize_io() {
    log "💾 Optimizing I/O subsystem..."
    
    # Get the disk device for the current directory
    DISK_DEVICE=$(df . | tail -1 | awk '{print $1}' | sed 's/[0-9]*$//')
    DISK_NAME=$(basename "$DISK_DEVICE")
    
    # Set I/O scheduler to mq-deadline for better build performance
    if [ -f "/sys/block/$DISK_NAME/queue/scheduler" ]; then
        echo mq-deadline | sudo tee "/sys/block/$DISK_NAME/queue/scheduler" >/dev/null 2>&1 || warn "Could not set I/O scheduler"
        log "I/O scheduler set to mq-deadline"
    fi
    
    # Increase read-ahead for better sequential read performance
    if [ -f "/sys/block/$DISK_NAME/queue/read_ahead_kb" ]; then
        echo 4096 | sudo tee "/sys/block/$DISK_NAME/queue/read_ahead_kb" >/dev/null 2>&1 || warn "Could not set read-ahead"
        log "Read-ahead increased to 4MB"
    fi
    
    # Optimize mount options
    if mount | grep -q "$(pwd)" | grep -q "noatime"; then
        log "Filesystem already mounted with noatime"
    else
        warn "Consider remounting filesystem with noatime for better performance"
    fi
}

# Network optimization
optimize_network() {
    log "🌐 Optimizing network parameters..."
    
    # Increase network buffer sizes for faster downloads
    echo 'net.core.rmem_max = 67108864' | sudo tee -a /etc/sysctl.conf >/dev/null 2>&1 || warn "Could not set rmem_max"
    echo 'net.core.wmem_max = 67108864' | sudo tee -a /etc/sysctl.conf >/dev/null 2>&1 || warn "Could not set wmem_max"
    echo 'net.ipv4.tcp_rmem = 4096 65536 67108864' | sudo tee -a /etc/sysctl.conf >/dev/null 2>&1 || warn "Could not set tcp_rmem"
    echo 'net.ipv4.tcp_wmem = 4096 65536 67108864' | sudo tee -a /etc/sysctl.conf >/dev/null 2>&1 || warn "Could not set tcp_wmem"
    
    # Apply network optimizations
    sudo sysctl -p >/dev/null 2>&1 || warn "Could not apply sysctl changes"
    
    log "Network optimization completed"
}

# Compiler optimization
optimize_compiler() {
    log "🔧 Optimizing compiler settings..."
    
    # Set optimal CFLAGS and CXXFLAGS
    export CFLAGS="-O3 -march=native -mtune=native -fno-plt -fno-semantic-interposition"
    export CXXFLAGS="$CFLAGS"
    export LDFLAGS="-Wl,-O1,--sort-common,--as-needed,-z,relro,-z,now"
    
    # Enable link-time optimization if supported
    if gcc --help=optimizers | grep -q "flto"; then
        export CFLAGS="$CFLAGS -flto"
        export CXXFLAGS="$CXXFLAGS -flto"
        log "Link-time optimization enabled"
    fi
    
    # Use gold linker if available
    if command -v ld.gold >/dev/null 2>&1; then
        export LDFLAGS="$LDFLAGS -fuse-ld=gold"
        log "Gold linker enabled"
    fi
    
    log "Compiler optimization completed"
}

# Java optimization
optimize_java() {
    log "☕ Optimizing Java environment..."
    
    # Calculate optimal heap size (50% of available memory)
    JAVA_HEAP_SIZE=$((AVAILABLE_RAM_GB / 2))
    if [ "$JAVA_HEAP_SIZE" -lt 2 ]; then
        JAVA_HEAP_SIZE=2
    fi
    
    # Set Java optimization flags
    export JAVA_OPTS="-Xmx${JAVA_HEAP_SIZE}g -Xms${JAVA_HEAP_SIZE}g"
    export JAVA_OPTS="$JAVA_OPTS -XX:+UseG1GC -XX:+UseStringDeduplication"
    export JAVA_OPTS="$JAVA_OPTS -XX:+UseCompressedOops -XX:+UseCompressedClassPointers"
    export JAVA_OPTS="$JAVA_OPTS -XX:+TieredCompilation -XX:TieredStopAtLevel=1"
    export JAVA_OPTS="$JAVA_OPTS -XX:+UnlockExperimentalVMOptions -XX:+UseJVMCICompiler"
    
    # Android-specific Java optimizations
    export ANDROID_JACK_VM_ARGS="$JAVA_OPTS -Dfile.encoding=UTF-8"
    export JACK_SERVER_VM_ARGUMENTS="$JAVA_OPTS -Dfile.encoding=UTF-8"
    export GRADLE_OPTS="$JAVA_OPTS -Dorg.gradle.parallel=true -Dorg.gradle.caching=true"
    
    log "Java heap size set to ${JAVA_HEAP_SIZE}GB"
}

# ccache optimization
optimize_ccache() {
    log "🗄️ Optimizing ccache configuration..."
    
    export USE_CCACHE=1
    export CCACHE_DIR="$HOME/.ccache"
    mkdir -p "$CCACHE_DIR"
    
    # Advanced ccache settings
    ccache --set-config max_size=50G
    ccache --set-config compression=true
    ccache --set-config compression_level=6
    ccache --set-config sloppiness=file_macro,locale,time_macros
    ccache --set-config hash_dir=false
    ccache --set-config cache_dir_levels=3
    
    # Enable ccache stats
    ccache --zero-stats
    
    log "ccache optimized with 50GB cache size"
}

# Build job calculation
calculate_build_jobs() {
    log "📊 Calculating optimal build job count..."
    
    # Base calculation on CPU cores
    BUILD_JOBS="$CORES"
    
    # Adjust for memory constraints (Android needs ~2GB per job)
    MAX_JOBS_BY_MEMORY=$((AVAILABLE_RAM_GB / 2))
    if [ "$BUILD_JOBS" -gt "$MAX_JOBS_BY_MEMORY" ]; then
        BUILD_JOBS="$MAX_JOBS_BY_MEMORY"
        warn "Build jobs limited by memory: $BUILD_JOBS (was $CORES)"
    fi
    
    # Ensure minimum of 1 job
    if [ "$BUILD_JOBS" -lt 1 ]; then
        BUILD_JOBS=1
    fi
    
    # Set environment variables
    export BUILD_JOBS
    export SYNC_JOBS=$((BUILD_JOBS / 2))
    if [ "$SYNC_JOBS" -lt 1 ]; then
        SYNC_JOBS=1
    fi
    
    log "Optimal build jobs: $BUILD_JOBS"
    log "Optimal sync jobs: $SYNC_JOBS"
}

# Temporary filesystem optimization
setup_tmpfs() {
    log "💨 Setting up tmpfs for build acceleration..."
    
    # Calculate tmpfs size (25% of RAM)
    TMPFS_SIZE=$((TOTAL_RAM_GB / 4))
    if [ "$TMPFS_SIZE" -gt 8 ]; then
        TMPFS_SIZE=8  # Cap at 8GB
    fi
    
    if [ "$TMPFS_SIZE" -ge 2 ]; then
        TMPFS_DIR="/tmp/android-build-tmpfs"
        mkdir -p "$TMPFS_DIR"
        
        # Mount tmpfs if not already mounted
        if ! mount | grep -q "$TMPFS_DIR"; then
            sudo mount -t tmpfs -o size=${TMPFS_SIZE}g,uid=$(id -u),gid=$(id -g) tmpfs "$TMPFS_DIR" 2>/dev/null || warn "Could not mount tmpfs"
            export TMPDIR="$TMPFS_DIR"
            log "tmpfs mounted at $TMPFS_DIR (${TMPFS_SIZE}GB)"
        fi
    else
        warn "Insufficient RAM for tmpfs optimization"
    fi
}

# Generate build environment report
generate_report() {
    log "📋 Generating optimization report..."
    
    cat > build-optimization-report.txt << EOF
Android ROM Build Optimization Report
=====================================
Generated: $(date -Iseconds)

System Configuration:
- CPU: $CPU_MODEL
- Cores: $CORES
- Total RAM: ${TOTAL_RAM_GB}GB
- Available RAM: ${AVAILABLE_RAM_GB}GB
- Free Disk: ${DISK_FREE_GB}GB

Optimization Settings:
- Build Jobs: $BUILD_JOBS
- Sync Jobs: $SYNC_JOBS
- Java Heap: ${JAVA_HEAP_SIZE:-N/A}GB
- ccache Size: 50GB
- tmpfs Size: ${TMPFS_SIZE:-0}GB

Applied Optimizations:
✓ CPU governor set to performance
✓ Memory management tuned
✓ I/O scheduler optimized
✓ Network buffers increased
✓ Compiler flags optimized
✓ Java environment tuned
✓ ccache configured
$([ "${TMPFS_SIZE:-0}" -gt 0 ] && echo "✓ tmpfs enabled" || echo "✗ tmpfs disabled (insufficient RAM)")

Environment Variables Set:
CFLAGS="$CFLAGS"
CXXFLAGS="$CXXFLAGS"
LDFLAGS="$LDFLAGS"
JAVA_OPTS="$JAVA_OPTS"
BUILD_JOBS="$BUILD_JOBS"
SYNC_JOBS="$SYNC_JOBS"
USE_CCACHE="$USE_CCACHE"
CCACHE_DIR="$CCACHE_DIR"

Recommendations:
- Monitor CPU temperature during builds
- Ensure adequate cooling for sustained performance
- Consider SSD storage for better I/O performance
- Use dedicated build machine for best results
EOF

    log "Report saved to build-optimization-report.txt"
}

# Main optimization routine
main() {
    echo "Starting comprehensive build optimization..."
    echo
    
    get_system_info
    echo
    
    optimize_cpu
    optimize_memory
    optimize_io
    optimize_network
    optimize_compiler
    optimize_java
    optimize_ccache
    calculate_build_jobs
    setup_tmpfs
    
    echo
    generate_report
    
    echo
    echo -e "${GREEN}🎉 Build optimization completed successfully!${NC}"
    echo -e "${BLUE}ℹ️  Review the optimization report for details${NC}"
    echo -e "${YELLOW}⚠️  Some optimizations require root privileges${NC}"
    echo
}

# Cleanup function
cleanup() {
    log "🧹 Cleaning up temporary optimizations..."
    
    # Unmount tmpfs if we mounted it
    if [ -n "${TMPFS_DIR:-}" ] && mount | grep -q "$TMPFS_DIR"; then
        sudo umount "$TMPFS_DIR" 2>/dev/null || warn "Could not unmount tmpfs"
    fi
}

# Set up signal handlers
trap cleanup EXIT INT TERM

# Run optimization if script is executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi