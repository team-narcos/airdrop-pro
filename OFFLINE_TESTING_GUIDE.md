# 🔌 Offline P2P Transfer Guide (No Internet/WiFi Required)

## 🎯 Goal
Transfer files between two laptops **WITHOUT internet or WiFi router** using:
- ✅ Windows Mobile Hotspot
- ✅ Direct laptop-to-laptop connection
- ✅ No router needed
- ✅ No internet needed

---

## 📋 What's Implemented

### ✅ Real Discovery System
- **UDP Broadcast Discovery** - Finds devices on same network (port 37778)
- Broadcasts every 3 seconds
- Auto-detects devices within 10 seconds

### ✅ Real File Transfer
- **TCP Connection** - Direct socket communication
- **Encryption** - AES-256-GCM end-to-end
- **Chunking** - 4MB chunks with progress tracking
- **Verification** - SHA-256 hash checking

### ✅ Offline Modes
- **Hotspot Mode** - One laptop creates WiFi, other connects
- **Direct Connection** - No internet required
- **Works on LAN** - Any local network

---

## 🚀 Method 1: Using Windows Mobile Hotspot (Easiest)

### Step 1: Setup Laptop 1 (Host)

**Turn on Mobile Hotspot:**
1. Open Windows Settings
2. Network & Internet → Mobile hotspot
3. Turn ON "Mobile hotspot"
4. Note the SSID and Password shown

**Example:**
```
Network name: DESKTOP-ABC123
Password: 12345678
```

**OR use Command Line:**
```powershell
# Run as Administrator
netsh wlan set hostednetwork mode=allow ssid=AirDropPro key=AirDrop123
netsh wlan start hostednetwork
```

### Step 2: Connect Laptop 2 (Client)

**Connect to Hotspot:**
1. Click WiFi icon in taskbar
2. Find "DESKTOP-ABC123" (or "AirDropPro")
3. Connect with password
4. Wait for "Connected"

**OR use Command Line:**
```powershell
# Connect to the hotspot
netsh wlan connect name=AirDropPro
```

### Step 3: Verify Connection

**On Both Laptops:**
```powershell
# Check IP addresses
ipconfig | findstr IPv4
```

**Expected:**
- Laptop 1 (Hotspot): 192.168.137.1
- Laptop 2 (Client): 192.168.137.xxx (e.g., 192.168.137.100)

**Test Ping:**
```powershell
# On Laptop 2, ping Laptop 1
ping 192.168.137.1

# Should get replies
```

### Step 4: Run Apps

**On BOTH Laptops:**
```powershell
cd C:\airdrop_pro
flutter run -d windows
```

**Wait 10 seconds** - devices will discover each other via UDP broadcast

### Step 5: Transfer Files

1. Click "Share File" on either laptop
2. Select file
3. Choose other device
4. Watch transfer complete!

---

## 🔌 Method 2: Using Ethernet Cable (Fastest)

If you have an Ethernet cable:

### Step 1: Connect Cable
- Connect Ethernet cable between two laptops

### Step 2: Configure Static IPs

**On Laptop 1:**
```powershell
# Run as Administrator
netsh interface ip set address "Ethernet" static 192.168.100.1 255.255.255.0
```

**On Laptop 2:**
```powershell
# Run as Administrator
netsh interface ip set address "Ethernet" static 192.168.100.2 255.255.255.0
```

### Step 3: Test Connection
```powershell
# On Laptop 1
ping 192.168.100.2

# On Laptop 2
ping 192.168.100.1
```

### Step 4: Run Apps
Same as Method 1 - both apps will discover each other

---

## 🌐 Method 3: Using Existing WiFi Router (With Internet)

If you have WiFi router:

### Just Connect Both to Same WiFi
1. Connect both laptops to same WiFi network
2. Run apps on both
3. Devices discover each other automatically

**Note:** Internet not required, just the local network

---

## ⚙️ What Happens Behind the Scenes

### 1. UDP Discovery (Port 37778)
```
Laptop 1 → Broadcasts: "I'm here! IP: 192.168.137.1, Port: 57079"
           ↓
Laptop 2 ← Receives: "Found device at 192.168.137.1"
```

### 2. TCP Connection (Dynamic Port)
```
Laptop 1: Opens TCP server on port 57079
           ↓
Laptop 2: Connects to 192.168.137.1:57079
           ↓
Handshake: Exchange device info + capabilities
```

### 3. File Transfer
```
1. Sender: "I want to send file.jpg (5MB)"
2. Receiver: "Accept, save to Downloads"
3. Key Exchange: ECDH P-256
4. Transfer: Encrypted 4MB chunks
5. Verify: SHA-256 hash
6. Complete: File saved
```

---

## 🧪 Complete Testing Steps

### Setup (5 minutes)

**1. Copy project to Laptop 2:**
```powershell
# Use USB drive or network share
# Place in C:\airdrop_pro
cd C:\airdrop_pro
flutter pub get
```

**2. Start Hotspot on Laptop 1:**
```powershell
# Windows Settings → Mobile hotspot → ON
# Or command line (as Admin):
netsh wlan set hostednetwork mode=allow ssid=AirDropTest key=Test1234
netsh wlan start hostednetwork
```

**3. Connect Laptop 2 to Hotspot:**
```powershell
# WiFi settings → Connect to "AirDropTest"
# Password: Test1234
```

**4. Disable Firewall on BOTH:**
```powershell
# Run as Administrator
netsh advfirewall set allprofiles state off
```

### Testing (2 minutes)

**1. Run on BOTH laptops:**
```powershell
cd C:\airdrop_pro
flutter run -d windows
```

**2. Watch console logs:**
```
[UDP Discovery] Listening on port 37778
[UDP Discovery] Broadcasted presence
[UDP Discovery] Found device: AB at 192.168.137.xxx:57080
```

**3. Check UI:**
- "Online" badge (green) ✅
- Device appears in list ✅

**4. Send file:**
- Click "Share File"
- Select file
- Choose device
- Watch progress

**5. Verify received:**
```powershell
explorer C:\Users\$env:USERNAME\Downloads
```

---

## 🐛 Troubleshooting

### Problem: Hotspot Won't Start

**Error: "Hosted network couldn't be started"**

**Solution:**
```powershell
# Run as Administrator

# Reset adapter
netsh wlan stop hostednetwork
netsh wlan set hostednetwork mode=disallow
netsh wlan set hostednetwork mode=allow ssid=AirDropTest key=Test1234

# Restart WiFi adapter
Get-NetAdapter | Where-Object {$_.Name -like "*Wi-Fi*"} | Restart-NetAdapter
```

### Problem: Devices Not Discovering

**Check firewall:**
```powershell
# Disable temporarily
netsh advfirewall set allprofiles state off
```

**Check connection:**
```powershell
# Verify same network
ipconfig | findstr IPv4

# Ping each other
ping <other-laptop-ip>
```

**Restart discovery:**
- Close both apps (press 'q')
- Wait 5 seconds
- Run again

### Problem: Connection Fails

**Check ports:**
```powershell
# Make sure ports are free
netstat -ano | findstr "37778"
netstat -ano | findstr "57079"
```

**Check TCP server:**
- Look for log: `[P2PServer] Server started on port 57079`
- If missing, restart app

---

## 📊 Performance Expectations

### Via Hotspot (Method 1)
| File Size | Time | Speed |
|-----------|------|-------|
| 1 MB | <1 sec | 10-50 MB/s |
| 10 MB | 2-5 sec | 5-20 MB/s |
| 100 MB | 10-30 sec | 3-15 MB/s |
| 1 GB | 1-5 min | 3-10 MB/s |

### Via Ethernet (Method 2)
| File Size | Time | Speed |
|-----------|------|-------|
| 1 MB | <1 sec | 50-100 MB/s |
| 10 MB | <1 sec | 50-100 MB/s |
| 100 MB | 1-3 sec | 30-100 MB/s |
| 1 GB | 10-30 sec | 30-100 MB/s |

*Ethernet is 5-10x faster than WiFi*

---

## ✅ What Works Offline

- ✅ Device discovery (UDP broadcast)
- ✅ File transfer (TCP direct)
- ✅ Progress tracking
- ✅ Encryption (AES-256-GCM)
- ✅ Hash verification
- ✅ Multiple files
- ✅ Error handling
- ✅ Retry logic

---

## ❌ What Requires Internet

- ❌ Nothing! Everything works offline
- ❌ (Just need local connection between laptops)

---

## 🔒 Security

**All transfers are encrypted:**
- ECDH P-256 key exchange
- AES-256-GCM encryption
- SHA-256 file verification
- No data leaves local network
- No internet = no external exposure

---

## 💡 Pro Tips

1. **Ethernet is fastest** - Use if available
2. **Hotspot works great** - No router needed
3. **Keep laptops close** - Better WiFi signal
4. **Disable firewall** - For testing only
5. **Use small files first** - Test before large transfers

---

## 🆘 Quick Reference

### Start Hotspot (Laptop 1)
```powershell
netsh wlan set hostednetwork mode=allow ssid=AirDropTest key=Test1234
netsh wlan start hostednetwork
```

### Connect to Hotspot (Laptop 2)
```powershell
netsh wlan connect name=AirDropTest
```

### Check Connection
```powershell
ipconfig | findstr IPv4
ping <other-laptop-ip>
```

### Run App
```powershell
cd C:\airdrop_pro
flutter run -d windows
```

### Stop Hotspot (When Done)
```powershell
netsh wlan stop hostednetwork
```

### Re-enable Firewall
```powershell
netsh advfirewall set allprofiles state on
```

---

## ✅ Success Checklist

- [ ] Hotspot created on Laptop 1
- [ ] Laptop 2 connected to hotspot
- [ ] Both can ping each other
- [ ] Both apps running
- [ ] "Online" status on both
- [ ] Devices appear in lists
- [ ] File transfer works
- [ ] File in Downloads folder

---

## 🎯 Bottom Line

**YES, it works completely offline!**

✅ Real UDP discovery
✅ Real TCP file transfer  
✅ Real encryption
✅ No internet needed
✅ No WiFi router needed
✅ Just two laptops!

The P2P system is **fully implemented** and ready for offline testing! 🚀
