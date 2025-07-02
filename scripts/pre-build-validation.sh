#!/bin/bash
# ====================================================================
# INTELLIGENT PRE-BUILD VALIDATION & OPTIMIZATION
# Comprehensive build environment validation and automatic fixing
# ====================================================================

set -euo pipefail

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Counters
CHECKS_PASSED=0
CHECKS_FAILED=0
CHECKS_WARNED=0
FIXES_APPLIED=0

log() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
    ((CHECKS_WARNED++))
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    ((CHECKS_FAILED++))
}

success() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((CHECKS_PASSED++))
}

fix() {
    echo -e "${BLUE}[FIX]${NC} $1"
    ((FIXES_APPLIED++))
}

# Check system requirements
check_system_requirements() {
    log "🔍 Validating system requirements..."
    
    # CPU cores check
    CORES=$(nproc)
    if [ "$CORES" -ge 8 ]; then
        success "CPU cores: $CORES (sufficient)"
    elif [ "$CORES" -ge 4 ]; then
        warn "CPU cores: $CORES (minimum met, but 8+ recommended)"
    else
        error "CPU cores: $CORES (insufficient, minimum 4 required)"
    fi
    
    # RAM check
    TOTAL_RAM_GB=$(free -g | awk '/^Mem:/ {print $2}')
    AVAILABLE_RAM_GB=$(free -g | awk '/^Mem:/ {print $7}')
    
    if [ "$TOTAL_RAM_GB" -ge 16 ]; then
        success "Total RAM: ${TOTAL_RAM_GB}GB (excellent)"
    elif [ "$TOTAL_RAM_GB" -ge 8 ]; then
        success "Total RAM: ${TOTAL_RAM_GB}GB (sufficient)"
    else
        warn "Total RAM: ${TOTAL_RAM_GB}GB (low, 8GB+ recommended)"
    fi
    
    if [ "$AVAILABLE_RAM_GB" -ge 4 ]; then
        success "Available RAM: ${AVAILABLE_RAM_GB}GB (sufficient)"
    else
        warn "Available RAM: ${AVAILABLE_RAM_GB}GB (low, consider closing applications)"
    fi
    
    # Disk space check
    DISK_FREE_GB=$(df -BG . | awk 'NR==2 {gsub("G",""); print int($4)}')
    if [ "$DISK_FREE_GB" -ge 200 ]; then
        success "Free disk space: ${DISK_FREE_GB}GB (excellent)"
    elif [ "$DISK_FREE_GB" -ge 100 ]; then
        success "Free disk space: ${DISK_FREE_GB}GB (sufficient)"
    else
        error "Free disk space: ${DISK_FREE_GB}GB (insufficient, 100GB+ required)"
    fi
}

# Check and install missing dependencies
check_dependencies() {
    log "📦 Validating build dependencies..."
    
    local missing_packages=()
    local essential_packages=(
        "git" "curl" "wget" "python3" "python3-pip" "build-essential"
        "openjdk-8-jdk" "openjdk-11-jdk" "ccache" "zip" "unzip"
        "libncurses5" "libxml2-utils" "xsltproc" "bc" "bison" "flex"
    )
    
    for package in "${essential_packages[@]}"; do
        if ! dpkg-query -W -f='${Status}' "$package" 2>/dev/null | grep -q "ok installed"; then
            if apt-cache show "$package" >/dev/null 2>&1; then
                missing_packages+=("$package")
            else
                warn "Package $package not found in repositories"
            fi
        fi
    done
    
    if [ ${#missing_packages[@]} -eq 0 ]; then
        success "All essential packages are installed"
    else
        warn "Missing packages detected: ${missing_packages[*]}"
        if [ "${AUTO_FIX:-false}" = "true" ]; then
            fix "Installing missing packages: ${missing_packages[*]}"
            sudo apt-get update -qq
            sudo apt-get install -y "${missing_packages[@]}"
        else
            error "Run with AUTO_FIX=true to automatically install missing packages"
        fi
    fi
}

# Validate Java environment
check_java_environment() {
    log "☕ Validating Java environment..."
    
    if java -version >/dev/null 2>&1; then
        JAVA_VERSION=$(java -version 2>&1 | head -1 | cut -d'"' -f2)
        success "Java is available: $JAVA_VERSION"
        
        # Check if correct version for Android
        if java -version 2>&1 | grep -q "1.8\|11\."; then
            success "Java version is compatible with Android builds"
        else
            warn "Java version may not be optimal for Android builds"
        fi
    else
        error "Java is not available or not in PATH"
        if [ "${AUTO_FIX:-false}" = "true" ]; then
            fix "Installing OpenJDK 8 and 11"
            sudo apt-get install -y openjdk-8-jdk openjdk-11-jdk
        fi
    fi
    
    # Check JAVA_HOME
    if [ -n "${JAVA_HOME:-}" ] && [ -d "$JAVA_HOME" ]; then
        success "JAVA_HOME is set: $JAVA_HOME"
    else
        warn "JAVA_HOME is not set or invalid"
        if [ "${AUTO_FIX:-false}" = "true" ]; then
            fix "Setting JAVA_HOME to OpenJDK 8"
            export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
            echo "export JAVA_HOME=$JAVA_HOME" >> ~/.bashrc
        fi
    fi
}

# Check Git configuration
check_git_config() {
    log "🔧 Validating Git configuration..."
    
    if git config --global user.name >/dev/null 2>&1; then
        success "Git user.name is configured: $(git config --global user.name)"
    else
        warn "Git user.name is not configured"
        if [ "${AUTO_FIX:-false}" = "true" ]; then
            fix "Setting Git user.name"
            git config --global user.name "Android Builder"
        fi
    fi
    
    if git config --global user.email >/dev/null 2>&1; then
        success "Git user.email is configured: $(git config --global user.email)"
    else
        warn "Git user.email is not configured"
        if [ "${AUTO_FIX:-false}" = "true" ]; then
            fix "Setting Git user.email"
            git config --global user.email "builder@buildkite.local"
        fi
    fi
}

# Check ccache configuration
check_ccache() {
    log "🗄️ Validating ccache configuration..."
    
    if command -v ccache >/dev/null 2>&1; then
        success "ccache is available: $(ccache --version | head -1)"
        
        # Check ccache configuration
        CCACHE_DIR="${CCACHE_DIR:-$HOME/.ccache}"
        if [ -d "$CCACHE_DIR" ]; then
            success "ccache directory exists: $CCACHE_DIR"
            
            # Check ccache size
            CCACHE_SIZE=$(ccache -s | grep "cache size" | awk '{print $3 " " $4}' || echo "unknown")
            success "ccache size: $CCACHE_SIZE"
        else
            warn "ccache directory does not exist"
            if [ "${AUTO_FIX:-false}" = "true" ]; then
                fix "Creating ccache directory and setting size"
                mkdir -p "$CCACHE_DIR"
                ccache -M 30G
            fi
        fi
    else
        error "ccache is not available"
        if [ "${AUTO_FIX:-false}" = "true" ]; then
            fix "Installing ccache"
            sudo apt-get install -y ccache
        fi
    fi
}

# Check repo tool
check_repo_tool() {
    log "🔄 Validating repo tool..."
    
    if command -v repo >/dev/null 2>&1; then
        success "repo tool is available"
        
        # Test repo functionality
        if repo --version >/dev/null 2>&1; then
            REPO_VERSION=$(repo --version | head -1)
            success "repo tool is functional: $REPO_VERSION"
        else
            warn "repo tool is installed but may not be functional"
        fi
    else
        error "repo tool is not available"
        if [ "${AUTO_FIX:-false}" = "true" ]; then
            fix "Installing repo tool"
            curl -o /tmp/repo https://storage.googleapis.com/git-repo-downloads/repo
            sudo mv /tmp/repo /usr/local/bin/repo
            sudo chmod a+x /usr/local/bin/repo
        fi
    fi
}

# Check network connectivity
check_network() {
    log "🌐 Validating network connectivity..."
    
    # Test basic internet connectivity
    if curl -s --connect-timeout 10 https://google.com >/dev/null; then
        success "Internet connectivity is working"
    else
        error "Internet connectivity test failed"
        return
    fi
    
    # Test Android source repositories
    local test_urls=(
        "https://android.googlesource.com"
        "https://github.com"
        "https://storage.googleapis.com"
    )
    
    for url in "${test_urls[@]}"; do
        if curl -s --connect-timeout 10 --head "$url" >/dev/null; then
            success "Access to $url is working"
        else
            warn "Cannot access $url (may affect source downloads)"
        fi
    done
}

# Check filesystem and mount options
check_filesystem() {
    log "💾 Validating filesystem configuration..."
    
    # Check filesystem type
    FS_TYPE=$(df -T . | tail -1 | awk '{print $2}')
    case "$FS_TYPE" in
        ext4|xfs|btrfs)
            success "Filesystem type: $FS_TYPE (good for builds)"
            ;;
        ntfs|fat32|exfat)
            warn "Filesystem type: $FS_TYPE (not optimal for builds)"
            ;;
        *)
            warn "Filesystem type: $FS_TYPE (unknown compatibility)"
            ;;
    esac
    
    # Check mount options
    MOUNT_OPTS=$(mount | grep "$(df . | tail -1 | awk '{print $1}')" | head -1)
    if echo "$MOUNT_OPTS" | grep -q "noatime"; then
        success "Filesystem mounted with noatime (optimal)"
    else
        warn "Filesystem not mounted with noatime (may affect performance)"
    fi
    
    # Check for case sensitivity (important for Android builds)
    TEST_FILE="/tmp/case_test_$$"
    touch "$TEST_FILE"
    if [ -f "${TEST_FILE^^}" ] 2>/dev/null; then
        error "Filesystem is case-insensitive (will cause build issues)"
    else
        success "Filesystem is case-sensitive (required for Android)"
    fi
    rm -f "$TEST_FILE" 2>/dev/null || true
}

# Validate environment variables
check_environment() {
    log "🔧 Validating environment variables..."
    
    # Check essential variables
    local env_vars=(
        "TARGET_DEVICE:Build target device"
        "ROM_TYPE:ROM type selection"
        "BUILD_JOBS:Parallel build jobs"
        "CCACHE_SIZE:ccache size limit"
    )
    
    for env_var in "${env_vars[@]}"; do
        var_name=$(echo "$env_var" | cut -d: -f1)
        var_desc=$(echo "$env_var" | cut -d: -f2)
        
        if [ -n "${!var_name:-}" ]; then
            success "$var_desc is set: ${!var_name}"
        else
            warn "$var_desc ($var_name) is not set"
        fi
    done
    
    # Check PATH
    if echo "$PATH" | grep -q "/usr/local/bin"; then
        success "PATH includes /usr/local/bin"
    else
        warn "PATH may not include /usr/local/bin (required for repo tool)"
        if [ "${AUTO_FIX:-false}" = "true" ]; then
            fix "Adding /usr/local/bin to PATH"
            export PATH="/usr/local/bin:$PATH"
        fi
    fi
}

# Security checks
check_security() {
    log "🔒 Running security validations..."
    
    # Check if running as root (not recommended)
    if [ "$(id -u)" -eq 0 ]; then
        warn "Running as root is not recommended for Android builds"
    else
        success "Running as non-root user (recommended)"
    fi
    
    # Check sudo access
    if sudo -n true 2>/dev/null; then
        success "Passwordless sudo is available (convenient for automation)"
    else
        warn "Passwordless sudo is not configured (may require manual intervention)"
    fi
    
    # Check for suspicious files in PATH
    for dir in $(echo "$PATH" | tr ':' '\n'); do
        if [ -d "$dir" ] && [ -w "$dir" ]; then
            warn "Directory in PATH is world-writable: $dir"
        fi
    done
}

# Performance optimization checks
check_performance() {
    log "⚡ Validating performance settings..."
    
    # Check CPU governor
    if [ -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor ]; then
        GOVERNOR=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)
        if [ "$GOVERNOR" = "performance" ]; then
            success "CPU governor is set to performance"
        else
            warn "CPU governor is set to $GOVERNOR (performance recommended)"
            if [ "${AUTO_FIX:-false}" = "true" ]; then
                fix "Setting CPU governor to performance"
                echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor >/dev/null
            fi
        fi
    fi
    
    # Check swappiness
    SWAPPINESS=$(cat /proc/sys/vm/swappiness)
    if [ "$SWAPPINESS" -le 10 ]; then
        success "Swappiness is optimized: $SWAPPINESS"
    else
        warn "Swappiness is high: $SWAPPINESS (10 or lower recommended for builds)"
        if [ "${AUTO_FIX:-false}" = "true" ]; then
            fix "Setting swappiness to 10"
            echo 10 | sudo tee /proc/sys/vm/swappiness >/dev/null
        fi
    fi
    
    # Check I/O scheduler
    DISK_DEVICE=$(df . | tail -1 | awk '{print $1}' | sed 's/[0-9]*$//')
    DISK_NAME=$(basename "$DISK_DEVICE")
    if [ -f "/sys/block/$DISK_NAME/queue/scheduler" ]; then
        SCHEDULER=$(cat "/sys/block/$DISK_NAME/queue/scheduler" | sed 's/.*\[\(.*\)\].*/\1/')
        if [ "$SCHEDULER" = "mq-deadline" ] || [ "$SCHEDULER" = "deadline" ]; then
            success "I/O scheduler is optimized: $SCHEDULER"
        else
            warn "I/O scheduler is: $SCHEDULER (mq-deadline recommended for builds)"
        fi
    fi
}

# Generate validation report
generate_report() {
    log "📋 Generating validation report..."
    
    local total_checks=$((CHECKS_PASSED + CHECKS_FAILED + CHECKS_WARNED))
    local pass_percentage=$((CHECKS_PASSED * 100 / total_checks))
    
    cat > pre-build-validation-report.txt << EOF
Pre-Build Validation Report
===========================
Generated: $(date -Iseconds)

Summary:
- Total Checks: $total_checks
- Passed: $CHECKS_PASSED ($pass_percentage%)
- Failed: $CHECKS_FAILED
- Warnings: $CHECKS_WARNED
- Fixes Applied: $FIXES_APPLIED

System Information:
- CPU Cores: $(nproc)
- Total RAM: $(free -g | awk '/^Mem:/ {print $2}')GB
- Available RAM: $(free -g | awk '/^Mem:/ {print $7}')GB
- Free Disk: $(df -BG . | awk 'NR==2 {gsub("G",""); print int($4)}')GB
- Filesystem: $(df -T . | tail -1 | awk '{print $2}')

Build Readiness:
$([ "$CHECKS_FAILED" -eq 0 ] && echo "✓ Ready for build" || echo "✗ Issues need resolution")
$([ "$CHECKS_WARNED" -eq 0 ] && echo "✓ No warnings" || echo "⚠ $CHECKS_WARNED warnings detected")

Recommendations:
$([ "$CHECKS_FAILED" -gt 0 ] && echo "- Resolve all failed checks before proceeding")
$([ "$CHECKS_WARNED" -gt 0 ] && echo "- Address warnings for optimal performance")
- Consider running with AUTO_FIX=true to apply automatic fixes
- Monitor system resources during builds
- Ensure stable network connection for source downloads
EOF
    
    success "Validation report saved to pre-build-validation-report.txt"
}

# Main validation routine
main() {
    echo "🔍 Android ROM Build Environment Validation"
    echo "==========================================="
    echo
    
    check_system_requirements
    check_dependencies
    check_java_environment
    check_git_config
    check_ccache
    check_repo_tool
    check_network
    check_filesystem
    check_environment
    check_security
    check_performance
    
    echo
    generate_report
    
    echo
    if [ "$CHECKS_FAILED" -eq 0 ]; then
        echo -e "${GREEN}🎉 Build environment validation completed successfully!${NC}"
        echo -e "${GREEN}✓ Your system is ready for Android ROM builds${NC}"
    else
        echo -e "${RED}❌ Build environment validation found issues${NC}"
        echo -e "${YELLOW}⚠️  Please resolve the failed checks before proceeding${NC}"
    fi
    
    if [ "$CHECKS_WARNED" -gt 0 ]; then
        echo -e "${YELLOW}⚠️  $CHECKS_WARNED warnings detected - review for optimal performance${NC}"
    fi
    
    if [ "${AUTO_FIX:-false}" = "true" ] && [ "$FIXES_APPLIED" -gt 0 ]; then
        echo -e "${BLUE}🔧 $FIXES_APPLIED automatic fixes were applied${NC}"
    fi
    
    echo
    echo "💡 Tip: Run with AUTO_FIX=true to automatically fix common issues"
    echo "📖 Review pre-build-validation-report.txt for detailed results"
    
    # Exit with error if critical issues found
    [ "$CHECKS_FAILED" -eq 0 ]
}

# Run validation if script is executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi