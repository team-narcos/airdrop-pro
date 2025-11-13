# WiFi Direct Testing Guide - AirDrop Pro

## ✅ What's Fixed

1. **WiFi Direct Plugin Registered**: The native Android plugin is now properly registered in MainActivity
2. **Permission Handling**: App now requests Location, Bluetooth, and WiFi permissions at runtime
3. **Real Device Discovery**: Demo devices removed - uses actual WiFi Direct/Bluetooth discovery
4. **Offline Connectivity**: Works WITHOUT internet or same WiFi network!

## 📱 How to Test

### Prerequisites
- 2 Android phones (Android 7.0+)
- APK Location: `C:\airdrop_pro\build\app\outputs\flutter-apk\app-release.apk`
- WiFi and Bluetooth turned ON (but NOT connected to any WiFi network!)

### Step-by-Step Testing:

#### 1. Install APK on Both Phones
```bash
adb install app-release.apk
```
OR transfer APK to phones and install manually

#### 2. Grant Permissions (IMPORTANT!)
When you open the app for the first time:
- Tap "Allow" for Location permission
- Tap "Allow" for Nearby Devices permission
- Tap "Allow" for Bluetooth permission
- Tap "Allow" for Storage permission

**Why Location?**: Android requires Location permission for WiFi Direct device discovery, even though it works completely offline!

#### 3. Test Device Discovery

**On Phone 1:**
- Open AirDrop Pro
- You should see "Nearby Devices" section
- It will automatically start scanning
- You should see "Looking for devices..." 

**On Phone 2:**
- Open AirDrop Pro
- Also starts scanning automatically

**Expected Result**: After 5-10 seconds, you should see:
- Phone 1 discovers Phone 2 (shows device name)
- Phone 2 discovers Phone 1 (shows device name)

#### 4. Test File Transfer

**On Phone 1 (Sender):**
1. Tap "Share File" button
2. Select a file (photo, video, document, anything!)
3. Tap the discovered device (Phone 2)
4. You should see:
   - File icon with preview
   - Progress bar
   - Percentage (0% → 100%)
   - Transfer speed (MB/s)
   - Estimated time remaining

**On Phone 2 (Receiver):**
- Should receive a connection request
- Accept the transfer
- File automatically downloads

**Expected Speed**: 100-250 Mbps (way faster than Bluetooth!)

#### 5. Test Sent/Received History

**On both phones:**
- Go to "History" tab
- Use filter tabs:
  - **All**: Shows all transfers
  - **Sent**: Shows only sent files (blue arrow)
  - **Received**: Shows only received files (green arrow)
  - **Failed**: Shows failed transfers

Each file should show:
- File type icon with gradient
- File name
- File size (supports unlimited size - GB+)
- Timestamp
- Direction indicator

## 🔧 Troubleshooting

### Problem: No Devices Discovered

**Solution 1 - Check Permissions:**
```
Settings → Apps → AirDrop Pro → Permissions
```
Make sure ALL of these are granted:
- Location: Always/While using app
- Nearby devices: Allowed
- Bluetooth: Allowed
- Storage: Allowed

**Solution 2 - Enable Location Services:**
```
Settings → Location → Turn ON
```

**Solution 3 - Check WiFi and Bluetooth:**
- WiFi must be ON (but don't connect to any network!)
- Bluetooth must be ON
- Airplane mode OFF

### Problem: Permission Dialog Doesn't Appear

**Solution:**
- Uninstall the app completely
- Reinstall
- First launch will show permission requests

### Problem: Transfer Fails

**Solution:**
- Make sure both devices are connected (check connection status)
- Check if file exists and is accessible
- Try smaller file first (< 10MB) for testing
- Check logcat for error messages:
```bash
adb logcat | grep "WiFi\|Discovery\|Transfer"
```

## 🎯 Expected Behavior

### WiFi Direct Mode (Primary):
- **Discovery Time**: 5-15 seconds
- **Connection Time**: 3-5 seconds
- **Transfer Speed**: 100-250 Mbps
- **Range**: Up to 200 meters
- **Requirements**: WiFi ON (no network needed!)

### Bluetooth Mode (Fallback):
- **Discovery Time**: 10-20 seconds
- **Connection Time**: 5-10 seconds
- **Transfer Speed**: 2-3 Mbps
- **Range**: Up to 100 meters
- **Requirements**: Bluetooth ON

## 📊 Testing Checklist

- [ ] App installs successfully on both phones
- [ ] Permissions are granted on both phones
- [ ] Device discovery works (sees other device)
- [ ] Can connect to discovered device
- [ ] Can select and send file
- [ ] Transfer progress shows correctly
- [ ] File receives successfully
- [ ] History shows sent files (with blue arrow)
- [ ] History shows received files (with green arrow)
- [ ] File size displays correctly (no limits)
- [ ] File icons show correct type/color
- [ ] Transfer speed displayed
- [ ] Percentage updates in real-time

## 🐛 Debug Information

### View Logs:
```bash
# On sender device
adb logcat -s flutter,WiFiDirectPlugin,Discovery

# Filter for important events
adb logcat | grep -E "Discovery|WiFi|Transfer|Permission"
```

### Check Native Plugin:
```kotlin
// WiFiDirectPlugin.kt should be loaded
// Look for: "WiFi Direct initialized successfully"
```

### Check Flutter Side:
```dart
// Should see in console:
// [Discovery] Requesting permissions...
// [Discovery] Permissions granted
// [Discovery] Starting device discovery...
// [Discovery] Found X devices
```

## 💡 Tips

1. **First Time Setup**: Give permissions immediately when asked
2. **Discovery**: Wait 10-15 seconds for devices to appear
3. **Connection**: First connection might take longer (network setup)
4. **Large Files**: For files > 1GB, WiFi Direct is 50-100x faster than Bluetooth!
5. **Offline**: Works completely offline - no WiFi network or internet needed

## 🎉 Success Indicators

You'll know it's working when:
- ✅ You see real device names (not "Demo Device")
- ✅ Signal strength indicator shows (green/yellow/red dot)
- ✅ Progress bar moves smoothly during transfer
- ✅ Transfer completes with green success notification
- ✅ File appears in History with correct icon and size
- ✅ Transfer speed shows MB/s (not just loading)

## 📞 If Still Not Working

Check these logs specifically:
```bash
adb logcat -s WiFiDirectPlugin:V flutter:V
```

Look for:
- "WiFi Direct initialized successfully" ✅
- "Discovery started successfully" ✅
- "Device found: [device name]" ✅
- "Connected to [device name]" ✅

If you see "PERMISSION_ERROR" or "NOT_INITIALIZED":
- Permissions issue - go back to Step 2
- Try reinstalling app
