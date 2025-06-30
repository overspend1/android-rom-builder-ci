# 🤖 Advanced ROM Build Pipeline Setup Guide

## 🚀 New Features Added

### 1. **Full CPU Utilization**
- Uses all 12 CPU cores for maximum performance
- No more conservative resource management
- Build jobs automatically set to full power mode

### 2. **Multi-ROM Support**
Choose from multiple ROM types by setting `ROM_TYPE` in your config:
- `lineage` - LineageOS (default)
- `crdroid` - CRDroid Android
- `pixel` - PixelExperience  
- `aosp` - AOSP (Vanilla Android)
- `evolution` - Evolution-X

### 3. **Telegram Bot Notifications** 📱
Get real-time build updates directly to your Telegram!

#### Setup Instructions:
1. **Create a Telegram Bot:**
   - Message [@BotFather](https://t.me/botfather) on Telegram
   - Send `/newbot` and follow instructions
   - Save your `BOT_TOKEN`

2. **Get Your Chat ID:**
   - Message [@userinfobot](https://t.me/userinfobot) 
   - Copy your Chat ID (starts with `-` for groups)

3. **Configure Environment Variables:**
   Add to your `build-config-garnet.env`:
   ```bash
   TELEGRAM_BOT_TOKEN="your_bot_token_here"
   TELEGRAM_CHAT_ID="your_chat_id_here"  
   ENABLE_TELEGRAM="true"
   ```

### 4. **AI Self-Healing with Gemini 2.0** 🤖
Automatic error detection and fix suggestions!

#### Setup Instructions:
1. **Get Gemini API Key:**
   - Go to [Google AI Studio](https://aistudio.google.com/)
   - Create new API key
   - Copy the key

2. **Configure AI Settings:**
   Add to your `build-config-garnet.env`:
   ```bash
   GEMINI_API_KEY="your_api_key_here"
   GEMINI_BASE_URL="https://generativelanguage.googleapis.com"
   GEMINI_MODEL="gemini-2.0-flash-exp"
   ENABLE_AI_HEALING="true"
   AI_MAX_RETRIES="3"
   ```

3. **Custom Base URL (Optional):**
   If you have a custom Gemini endpoint:
   ```bash
   GEMINI_BASE_URL="https://your-custom-endpoint.com"
   ```

## 📋 Complete Configuration Example

Update your `build-config-garnet.env` with these new settings:

```bash
# ===== NEW FEATURES =====

# Multi-ROM Support
ROM_TYPE="lineage"  # Options: lineage, crdroid, pixel, aosp, evolution

# Full CPU Power
BUILD_JOBS="12"     # Use all cores
SYNC_JOBS="8"       # Optimized network sync

# Telegram Notifications  
TELEGRAM_BOT_TOKEN="1234567890:ABCDEF1234567890abcdef1234567890ABC"
TELEGRAM_CHAT_ID="1234567890"
ENABLE_TELEGRAM="true"

# AI Self-Healing
GEMINI_API_KEY="AIzaSyABC123def456GHI789jkl012MNO345pqr678"
GEMINI_BASE_URL="https://generativelanguage.googleapis.com"
GEMINI_MODEL="gemini-2.0-flash-exp"
ENABLE_AI_HEALING="true"
AI_MAX_RETRIES="3"
```

## 🎯 What You'll Get

### Telegram Notifications:
- 🚀 Build start notifications
- ⚙️ Status updates for each step
- 🤖 AI healing suggestions when errors occur
- 🎉 Success/failure notifications with direct links

### AI Healing Features:
- Automatic error analysis
- Intelligent fix suggestions
- Learning from common Android build issues
- Detailed error context for better solutions

### Multi-ROM Building:
- Easy ROM switching via `ROM_TYPE` variable
- Automatic manifest URL configuration
- Support for latest ROM versions
- Device tree compatibility checks

## 🔧 Testing Your Setup

1. **Test Telegram Bot:**
   ```bash
   curl -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
     -d "chat_id=$TELEGRAM_CHAT_ID" \
     -d "text=🧪 Test message from ROM build pipeline!"
   ```

2. **Test AI Healing:**
   The AI will automatically activate when build errors occur.

## 🚀 Ready to Build!

Your pipeline now features:
- ✅ **Full 12-core CPU utilization**
- ✅ **Real-time Telegram notifications** 
- ✅ **AI-powered error healing**
- ✅ **Multi-ROM support**
- ✅ **Enhanced build analytics**

Simply update your environment variables and start your next build to experience the new features!

## 📱 Notification Examples

**Build Start:**
```
🚀 Android ROM Build Started

📱 Device: Redmi Note 13 Pro 5G (garnet)
🎯 ROM: lineage
🌿 Branch: lineage-22.0  
💻 Build ID: #42
⏱️ Started: 2024-01-15 14:30:25
```

**AI Healing:**
```
🤖 AI Healing Activated
Step: Android ROM Build
Error: FAILED: ninja: build stopped...

💡 AI Suggestion:
Try running 'make clean' and reduce BUILD_JOBS to 8 to avoid memory issues.
```

**Build Success:**
```
🎉 ROM BUILD SUCCESSFUL! 🎉

📱 Device: lineage_garnet-userdebug  
🎯 ROM: lineage
🏗️ Build ID: #42
⏰ Completed: 2024-01-15 18:45:12

✅ Status: Build completed successfully!
📦 ROM files ready for download
🔐 Includes MD5/SHA256 checksums
``` 