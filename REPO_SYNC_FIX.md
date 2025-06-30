# 🔧 Repo Sync Fix Guide

## Issue: Repo Sync Failed
If you're experiencing repo sync failures, here are the most common fixes:

### 1. **Network Issues**
```bash
# Test connectivity to LineageOS
curl -I https://github.com/LineageOS/android.git

# If blocked, try with different manifest URL
export MANIFEST_URL="https://github.com/LineageOS/android.git"
```

### 2. **Git Configuration**  
```bash
# Ensure git is properly configured
git config --global user.email "your-email@example.com"
git config --global user.name "Your Name"
git config --global init.defaultBranch master
```

### 3. **Repo Tool Issues**
```bash
# Reinstall repo tool
sudo rm -f /usr/local/bin/repo
curl https://storage.googleapis.com/git-repo-downloads/repo > /tmp/repo
sudo mv /tmp/repo /usr/local/bin/repo
sudo chmod +x /usr/local/bin/repo
```

### 4. **Sync Recovery**
If sync is partially broken:
```bash
cd android-workspace
repo forall -c 'git reset --hard HEAD; git clean -fd'
repo sync --force-sync --no-clone-bundle -j8
```

### 5. **Full Reset** (Nuclear Option)
```bash
rm -rf android-workspace
mkdir android-workspace
cd android-workspace
repo init -u $MANIFEST_URL -b $MANIFEST_BRANCH --depth=1
repo sync -c -j8 --force-sync --no-tags --no-clone-bundle
```

## The Pipeline Fixes These Automatically:
- ✅ **Automatic retry** with progressive backoff
- ✅ **Network validation** before sync
- ✅ **Corrupted state cleanup**
- ✅ **Multiple sync strategies**
- ✅ **AI-powered error analysis**

## Current Status
The script works for the most part but sync occasionally fails due to:
- Network timeouts
- Repository corruption  
- Git LFS issues
- Manifest branch changes

The updated pipeline now includes enhanced error recovery and AI healing to automatically fix these issues! 