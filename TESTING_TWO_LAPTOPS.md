# 🧪 Complete Testing Guide: Two Windows Laptops

## ✅ What You Need
- ✅ 2 Windows laptops
- ✅ Same WiFi network
- ✅ Flutter installed on both
- ✅ This project on both laptops

---

## 📦 Step 1: Share Project to Second Laptop

### Option A: Using USB Drive (Easiest)
**On Laptop 1 (Current):**
1. Copy entire `C:\airdrop_pro` folder to USB drive
2. Plug USB into Laptop 2
3. Copy folder to `C:\airdrop_pro`

**On Laptop 2:**
```powershell
cd C:\airdrop_pro
flutter pub get
```

### Option B: Using OneDrive/Google Drive
1. Upload `C:\airdrop_pro` to cloud
2. Download on Laptop 2 to `C:\airdrop_pro`
3. Run `flutter pub get`

### Option C: Using Network Share
**On Laptop 1:**
1. Right-click `C:\airdrop_pro` → Properties → Sharing → Share
2. Note the path (e.g., `\\LAPTOP1\airdrop_pro`)

**On Laptop 2:**
1. Open File Explorer
2. Type `\\LAPTOP1\airdrop_pro` in address bar
3. Copy entire folder to `C:\airdrop_pro`
4. Run `flutter pub get`

---

## 🌐 Step 2: Network Setup (CRITICAL)

### 1. Connect Both to Same WiFi
- Both laptops MUST be on same WiFi network
- Not guest WiFi - use main network

### 2. Check Network Connection
**On Both Laptops:**
```powershell
# Check WiFi name
netsh wlan show interfaces
# Look for "SSID" line - should be same on both

# Check IP address
ipconfig | findstr IPv4
# Note the IP (e.g., 192.168.1.10)
```

**Example:**
- Laptop 1: 192.168.1.10
- Laptop 2: 192.168.1.15
- WiFi SSID: "Home_WiFi" (same on both)

### 3. Test Network Connection
**On Laptop 1:**
```powershell
ping 192.168.1.15
# Should get replies
```

**On Laptop 2:**
```powershell
ping 192.168.1.10
# Should get replies
```

❌ **If ping fails:**
- Check firewall settings
- Make sure on same WiFi
- Try disabling VPN

### 4. Allow App Through Firewall
**On BOTH Laptops (as Administrator):**
```powershell
# Temporarily disable firewall for testing
netsh advfirewall set allprofiles state off

# ⚠️ REMEMBER TO TURN BACK ON AFTER TESTING:
# netsh advfirewall set allprofiles state on
```

OR manually add firewall rule:
1. Windows Security → Firewall & network protection
2. Advanced settings → Inbound Rules → New Rule
3. Program → Browse to `C:\airdrop_pro\build\windows\x64\runner\Debug\airdrop_app.exe`
4. Allow connection → Apply to all profiles

---

## 🚀 Step 3: Run App on Both Laptops

### On Laptop 1 (Sender):
```powershell
cd C:\airdrop_pro
flutter run -d windows
```

**Wait for these logs:**
```
[UDP Discovery] Listening on port 37778
[UDP Discovery] Broadcasted presence
[P2PManager] Started successfully
```

**In the UI, you should see:**
- 🟢 "Online" badge (green)
- "Looking for devices..." message

### On Laptop 2 (Receiver):
```powershell
cd C:\airdrop_pro
flutter run -d windows
```

**Wait for same logs:**
```
[UDP Discovery] Listening on port 37778
[UDP Discovery] Broadcasted presence
```

---

## 🔍 Step 4: Verify Device Discovery

**Within 3-10 seconds, you should see:**

**On Laptop 1:**
```
[UDP Discovery] Found device: AB at 192.168.1.15:57080
```
- In UI: Laptop 2 appears in "Nearby Devices" list
- Shows: Device name, "Windows", IP address, 🟢 green dot

**On Laptop 2:**
```
[UDP Discovery] Found device: AB at 192.168.1.10:57079
```
- In UI: Laptop 1 appears in "Nearby Devices" list

**❌ If devices DON'T appear:**
1. Check both are on same WiFi
2. Check firewall is disabled or app is allowed
3. Look for errors in console
4. Restart both apps

---

## 📤 Step 5: Send a File

### On Laptop 1 (Sender):

1. **Click "Share File" button** (big blue button)

2. **Select a test file**
   - Pick a small file first (e.g., image, document)
   - Multiple files supported

3. **Choose target device**
   - Action sheet appears
   - Shows Laptop 2 device
   - Click on it

4. **Watch the transfer**
   - "Connecting..." dialog appears
   - Changes to "Transferring..." with progress bar
   - Shows percentage (e.g., "45%") and speed (e.g., "12.5 MB/s")
   - "Transfer Complete!" with ✅ checkmark
   - Auto-dismisses after 2 seconds

### Console logs you'll see:
```
[P2PManager] Connecting to AB...
[P2PClient] Connected to 192.168.1.15:57080
[P2PManager] Handshake started
[P2PManager] Key exchange complete
[FileTransferCoordinator] Sending 1 files
[ChunkTransferEngine] Sending file: test.jpg
[ChunkTransferEngine] Chunk 1/10 sent
...
[FileTransferCoordinator] Transfer complete
```

---

## 📥 Step 6: Verify File Received

### On Laptop 2 (Receiver):

**Console logs:**
```
[P2PManager] Incoming connection
[P2PManager] Received file offer from Laptop1
[P2PManager] Auto-accepting file offer: 1 files
[FileTransferCoordinator] File offer accepted
[ChunkTransferEngine] Receiving chunk 1/10
...
[FileTransferCoordinator] File saved to: C:\Users\YourName\Downloads\test.jpg
```

**Check Downloads folder:**
```powershell
explorer C:\Users\$env:USERNAME\Downloads
```

**You should see:**
- ✅ Received file with same name
- ✅ Same file size
- ✅ File opens correctly

---

## 🧪 Test Scenarios

### Test 1: Single Small File (1-5 MB)
- ✅ Image (JPG, PNG)
- ✅ Document (PDF, DOCX)
- ✅ Should transfer in <10 seconds

### Test 2: Larger File (10-100 MB)
- ✅ Video file
- ✅ ZIP archive
- ✅ Progress updates smoothly

### Test 3: Multiple Files
- ✅ Select 2-3 files at once
- ✅ All transfer together
- ✅ All appear in Downloads

### Test 4: Error Handling
- **Test disconnection:**
  - Start transfer
  - Disconnect WiFi on receiver
  - Should show error message
  
- **Test retry:**
  - Turn off app on receiver
  - Try to connect from sender
  - Should show retry dialog

---

## 🐛 Troubleshooting

### Problem: Devices Not Appearing

**Solution 1: Check Network**
```powershell
# Verify same WiFi
netsh wlan show interfaces

# Test connectivity
ping <other-laptop-ip>
```

**Solution 2: Check Firewall**
```powershell
# Disable temporarily
netsh advfirewall set allprofiles state off
```

**Solution 3: Restart Apps**
- Close both apps (press 'q' in terminal)
- Run again on both laptops

### Problem: Connection Fails

**Check logs for:**
```
[P2PManager] Failed to connect
[P2PClient] Connection timeout
```

**Solutions:**
- Verify firewall allows connection
- Check antivirus isn't blocking
- Try port 57079 is not in use

### Problem: Transfer Fails

**Check logs for:**
```
[FileTransferCoordinator] Transfer failed
```

**Solutions:**
- Check disk space on receiver
- Verify file path exists
- Try smaller file first

### Problem: File Not in Downloads

**Check:**
```powershell
# List recent downloads
Get-ChildItem C:\Users\$env:USERNAME\Downloads | Sort-Object LastWriteTime -Descending | Select-Object -First 10
```

**Or check alternate location:**
```powershell
# App documents folder
echo $env:APPDATA
# Look in: C:\Users\YourName\AppData\Roaming\airdrop_app\downloads
```

---

## ✅ Success Checklist

- [ ] Both laptops on same WiFi
- [ ] Both apps running
- [ ] "Online" status on both
- [ ] Devices appear in list
- [ ] Can click on device
- [ ] File picker opens
- [ ] Transfer progress shows
- [ ] "Transfer Complete!" appears
- [ ] File in Downloads folder
- [ ] File opens correctly

---

## 📊 Expected Performance

| File Size | Transfer Time | Speed |
|-----------|---------------|-------|
| 1 MB      | < 1 second    | 10+ MB/s |
| 10 MB     | < 5 seconds   | 5-15 MB/s |
| 100 MB    | < 30 seconds  | 3-10 MB/s |
| 1 GB      | < 5 minutes   | 3-10 MB/s |

*Speeds depend on WiFi quality and laptop specs*

---

## 🎯 What to Expect

### ✅ Working Features
- Device discovery (3-10 seconds)
- Connection establishment (1-2 seconds)
- File transfer with progress
- Speed calculation
- Multiple file support
- Automatic file receiving
- Error messages with retry

### ⏳ Known Limitations
- Windows only (for now)
- Same WiFi network required
- Firewall must allow connection
- No pause/resume (yet)

---

## 🔒 Security Note

**After testing, remember to:**
```powershell
# Turn firewall back ON
netsh advfirewall set allprofiles state on
```

All file transfers are encrypted with:
- AES-256-GCM encryption
- ECDH key exchange
- SHA-256 file verification

---

## 📝 Quick Reference

### Start Testing
```powershell
# On BOTH laptops:
cd C:\airdrop_pro
flutter run -d windows
```

### Check Devices
```powershell
# Should see in logs:
[UDP Discovery] Found device: <name> at <ip>:<port>
```

### Find Received Files
```powershell
explorer C:\Users\$env:USERNAME\Downloads
```

### Stop App
Press `q` in the terminal where flutter run is running

---

## 💡 Tips

1. **First time testing?** Start with a small image file
2. **Keep terminals visible** to see transfer logs
3. **Test firewall first** - it's the #1 issue
4. **Close and restart** if something seems stuck
5. **Use same app version** on both laptops

---

## 🆘 Need Help?

If you encounter issues:
1. Check this guide's Troubleshooting section
2. Look at console logs for error messages
3. Verify all prerequisites are met
4. Try with firewall completely disabled first

Good luck with testing! 🚀
