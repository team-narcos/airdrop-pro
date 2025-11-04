# AirDrop App - Complete Testing Guide

## 🔧 CRITICAL FIXES IMPLEMENTED

### 1. **File Transfer Core Fixes**
- ✅ Changed storage from internal to external storage (Android-compatible)
- ✅ Added FileProvider configuration for secure file sharing
- ✅ Added comprehensive TCP transfer logging
- ✅ Added file sink flushing before close (prevents 0-byte files)
- ✅ Added buffer verification and file size checks
- ✅ Increased transmission delay for reliable network transfer

### 2. **History & Statistics**
- ✅ Fixed database initialization (now properly awaited)
- ✅ History saves to SQLite and persists across restarts
- ✅ History screen shows real transfer data
- ✅ Success rate calculated from actual transfers

### 3. **UI Improvements**
- ✅ Device cards show online/offline status (green/red badge)
- ✅ Send button only enabled for online devices
- ✅ Removed "Queue" button for simpler flow
- ✅ Files can be opened directly from the app
- ✅ File preview dialog with native file opener

---

## 📱 INSTALLATION

1. **Install the APK:**
   ```
   adb install -r build\app\outputs\flutter-apk\app-release.apk
   ```

2. **Grant Permissions:**
   - Open app
   - Allow all requested permissions:
     - Storage/Files
     - Location (for device discovery)
     - Bluetooth (for scanning)
     - Notifications

---

## 🧪 TESTING STEPS

### Test 1: Device Discovery & Connection Status
1. Open app on BOTH devices
2. Go to "Devices" tab
3. **VERIFY:**
   - ✓ Discovered devices show up
   - ✓ Green badge = Online (has IP address)
   - ✓ Red badge = Offline (no IP)
   - ✓ Signal strength indicator shows
   - ✓ "Send" button only active for online devices

### Test 2: File Transfer (MOST IMPORTANT)
**On Sender Device:**
1. Go to Devices tab
2. Tap "Send" on an online device
3. Select a test file (image/document/video)
4. Wait for "Sending..." dialog

**On Receiver Device:**
1. Keep app open or in background
2. Wait for file to arrive

**VERIFY:**
3. Capture logs:
   ```
   adb logcat | grep "TCP Transfer"
   ```

**What to check in logs:**
```
[TCP Transfer] Server started on port 37777
[TCP Transfer] Received metadata: {fileName: xxx, fileSize: xxx}
[TCP Transfer] Using storage directory: /storage/emulated/0/Android/data/.../files/ReceivedFiles
[TCP Transfer] Sent ACCEPT, waiting for file data...
[TCP Transfer] Received: xxx / xxx bytes (xx%)
[TCP Transfer] Closing file sink...
[TCP Transfer] File sink closed
[TCP Transfer] Expected size: xxx, Actual size: xxx
[TCP Transfer] File received successfully
```

**CRITICAL:**
- File size should NOT be 0 bytes
- "Actual size" should match "Expected size"
- File should exist at the logged path

### Test 3: File Opening
1. Go to "Files" tab on receiver
2. Tap on a received file
3. **VERIFY:**
   - ✓ File opens in appropriate app (Gallery for images, etc.)
   - ✓ NO "FileUriExposedException" error
   - ✓ File displays correctly

### Test 4: History Tracking
1. After sending/receiving files, go to "History" tab
2. **VERIFY:**
   - ✓ Transfer shows up in list
   - ✓ File name, size, timestamp correct
   - ✓ Success rate updates
   - ✓ Sent/Received/Failed counters update

3. **Close and reopen app**
4. **VERIFY:**
   - ✓ History still shows previous transfers (persisted!)

### Test 5: Storage Statistics
1. Go to "Files" tab
2. **VERIFY:**
   - ✓ Storage usage shows correct total MB
   - ✓ File count matches actual files
   - ✓ Storage visualization updates
   - ✓ Category breakdowns (Images/Docs/Videos)

---

## 🐛 TROUBLESHOOTING

### Issue: Files still show 0 bytes
**Diagnosis:**
```bash
# Capture full transfer logs
adb logcat -c  # Clear logs
adb logcat | grep "TCP Transfer" > transfer_debug.txt
# Perform file transfer
# Check transfer_debug.txt
```

**Look for:**
- Is sender reading file bytes? Check "Read xxx bytes from file"
- Is receiver getting data? Check "Received: xxx / xxx bytes"
- Is file being flushed? Check "File sink closed"
- Does file exist? Check "File exists: true"

### Issue: Can't open files
**Check:**
1. FileProvider configured?
   ```bash
   adb shell dumpsys package com.example.airdrop_app | grep FileProvider
   ```
2. Files in external storage?
   ```bash
   adb shell ls -la /storage/emulated/0/Android/data/com.example.airdrop_app/files/ReceivedFiles/
   ```

### Issue: History not saving
**Check:**
```bash
# Check if database exists
adb shell run-as com.example.airdrop_app ls -la databases/
# Should see airdrop_history.db
```

### Issue: Devices not discovering
**Check:**
1. Both devices on same WiFi network
2. Location permission granted
3. WiFi Direct / Hotspot not enabled (causes conflicts)

---

## 📊 EXPECTED RESULTS

### ✅ SUCCESS Criteria:
1. ✅ Files transfer completely (not 0 bytes)
2. ✅ Files can be opened from app
3. ✅ History persists across app restarts
4. ✅ Device connection status accurate
5. ✅ Storage statistics update correctly

### ❌ FAILURE Indicators:
- ❌ File size = 0 B after transfer
- ❌ "FileUriExposedException" when opening files
- ❌ History empty after app restart
- ❌ All devices show offline when they're online

---

## 🔍 ADVANCED DEBUGGING

### Get Full Device File System
```bash
adb shell run-as com.example.airdrop_app
cd files
ls -laR
```

### Check Actual File Content
```bash
# Pull file from device to computer
adb pull /storage/emulated/0/Android/data/com.example.airdrop_app/files/ReceivedFiles/<filename>

# Check file size on computer
dir <filename>  # Windows
ls -lh <filename>  # Linux/Mac
```

### Monitor Live Transfer
```bash
# Terminal 1: Monitor logs
adb logcat | grep -E "(TCP Transfer|FileProvider)"

# Terminal 2: Monitor file system
adb shell
watch -n 1 "ls -lh /storage/emulated/0/Android/data/com.example.airdrop_app/files/ReceivedFiles/"
```

---

## 📧 REPORTING ISSUES

If you encounter problems, provide:

1. **Logs during transfer:**
   ```
   adb logcat | grep "TCP Transfer" > issue_logs.txt
   ```

2. **File sizes:**
   ```
   adb shell ls -lh /storage/emulated/0/Android/data/com.example.airdrop_app/files/ReceivedFiles/
   ```

3. **What you expected vs. what happened**

4. **Screenshots of error messages**

---

## ✨ NEW FEATURES TO TEST

1. **Simplified Send Flow**: No more queue - just tap Send on online devices
2. **File Previews**: Files show with type-specific icons
3. **Auto-open capability**: Files can be opened directly
4. **Persistent History**: Survives app restarts
5. **Connection Indicators**: Clear online/offline status

---

**GOOD LUCK WITH TESTING!** 🚀

If files still show 0 bytes after this build, I'll need the TCP Transfer logs to diagnose the exact issue in the network layer or file I/O operations.
