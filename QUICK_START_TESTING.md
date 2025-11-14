# ⚡ Quick Start: Test on Two Laptops

## 🎯 Goal
Transfer a file from Laptop 1 to Laptop 2 using AirDrop Pro

---

## ✅ 5-Minute Setup

### 1. Copy Project to Second Laptop
**Easiest Method: USB Drive**
- Copy `C:\airdrop_pro` folder to USB
- Plug into Laptop 2
- Copy to `C:\airdrop_pro`
- Run: `flutter pub get`

### 2. Network Setup (CRITICAL)
**On BOTH laptops:**
```powershell
# Disable firewall temporarily
netsh advfirewall set allprofiles state off
```
⚠️ **Turn back on after testing!**

### 3. Run App on BOTH Laptops
```powershell
cd C:\airdrop_pro
flutter run -d windows
```

### 4. Wait for Discovery (10 seconds)
Look for this in console:
```
[UDP Discovery] Found device: AB at 192.168.1.15:57080
```

And in UI:
- Laptop appears in "Nearby Devices" list

### 5. Send a File
**On Laptop 1:**
1. Click "Share File" button
2. Pick a file
3. Select Laptop 2 from list
4. Watch progress bar
5. "Transfer Complete!" ✅

### 6. Check Received File
**On Laptop 2:**
```powershell
explorer C:\Users\$env:USERNAME\Downloads
```

---

## 🐛 Not Working?

### Devices not appearing?
```powershell
# Check same WiFi
netsh wlan show interfaces

# Test connection (use other laptop's IP)
ping 192.168.1.15
```

### Still not working?
1. Close both apps (press `q`)
2. Restart WiFi on both
3. Run apps again
4. Wait 10-15 seconds

---

## 📚 Full Guide
See `TESTING_TWO_LAPTOPS.md` for complete details

---

## ⚠️ Remember
**After testing:**
```powershell
# Turn firewall back ON
netsh advfirewall set allprofiles state on
```

That's it! 🚀
