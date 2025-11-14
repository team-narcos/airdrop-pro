import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// WiFi Direct / Hotspot service for offline P2P
/// Enables direct device-to-device communication without internet
class WiFiDirectService {
  bool _isHotspotMode = false;
  bool _isConnected = false;
  
  /// Check if device supports WiFi Direct
  Future<bool> isWiFiDirectSupported() async {
    // On Windows, we use Ad-Hoc network or Mobile Hotspot
    if (Platform.isWindows) {
      return await _checkWindowsWiFiDirect();
    }
    return false;
  }
  
  /// Check Windows WiFi Direct support
  Future<bool> _checkWindowsWiFiDirect() async {
    try {
      // Check if wireless adapter supports hosted network
      final result = await Process.run(
        'netsh',
        ['wlan', 'show', 'drivers'],
        runInShell: true,
      );
      
      return result.stdout.toString().contains('Hosted network supported  : Yes');
    } catch (e) {
      debugPrint('[WiFi Direct] Error checking support: $e');
      return false;
    }
  }
  
  /// Start WiFi Hotspot (Host Mode)
  Future<bool> startHotspot({
    required String ssid,
    required String password,
  }) async {
    if (Platform.isWindows) {
      return await _startWindowsHotspot(ssid, password);
    }
    return false;
  }
  
  /// Start Windows Mobile Hotspot
  Future<bool> _startWindowsHotspot(String ssid, String password) async {
    try {
      debugPrint('[WiFi Direct] Creating hotspot: $ssid');
      
      // Configure hosted network
      var result = await Process.run(
        'netsh',
        ['wlan', 'set', 'hostednetwork', 'mode=allow', 'ssid=$ssid', 'key=$password'],
        runInShell: true,
      );
      
      if (result.exitCode != 0) {
        debugPrint('[WiFi Direct] Failed to configure: ${result.stderr}');
        return false;
      }
      
      // Start hosted network
      result = await Process.run(
        'netsh',
        ['wlan', 'start', 'hostednetwork'],
        runInShell: true,
      );
      
      if (result.exitCode != 0) {
        debugPrint('[WiFi Direct] Failed to start: ${result.stderr}');
        return false;
      }
      
      _isHotspotMode = true;
      _isConnected = true;
      
      // Get hotspot IP
      await Future.delayed(const Duration(seconds: 2));
      final ip = await _getHotspotIP();
      
      debugPrint('[WiFi Direct] Hotspot started successfully');
      debugPrint('[WiFi Direct] SSID: $ssid');
      debugPrint('[WiFi Direct] IP: $ip');
      debugPrint('[WiFi Direct] Password: $password');
      
      return true;
    } catch (e) {
      debugPrint('[WiFi Direct] Error starting hotspot: $e');
      return false;
    }
  }
  
  /// Get hotspot IP address
  Future<String?> _getHotspotIP() async {
    try {
      final result = await Process.run(
        'ipconfig',
        [],
        runInShell: true,
      );
      
      final output = result.stdout.toString();
      final lines = output.split('\n');
      
      // Look for "Microsoft Wi-Fi Direct Virtual Adapter" or similar
      bool foundAdapter = false;
      for (var i = 0; i < lines.length; i++) {
        if (lines[i].contains('Local Area Connection') || 
            lines[i].contains('Microsoft Wi-Fi Direct')) {
          foundAdapter = true;
        }
        
        if (foundAdapter && lines[i].contains('IPv4 Address')) {
          final ipMatch = RegExp(r'(\d+\.\d+\.\d+\.\d+)').firstMatch(lines[i]);
          if (ipMatch != null) {
            return ipMatch.group(1);
          }
        }
      }
      
      // Default hotspot IP for Windows
      return '192.168.137.1';
    } catch (e) {
      debugPrint('[WiFi Direct] Error getting IP: $e');
      return null;
    }
  }
  
  /// Stop WiFi Hotspot
  Future<bool> stopHotspot() async {
    if (Platform.isWindows) {
      return await _stopWindowsHotspot();
    }
    return false;
  }
  
  /// Stop Windows Mobile Hotspot
  Future<bool> _stopWindowsHotspot() async {
    try {
      debugPrint('[WiFi Direct] Stopping hotspot...');
      
      final result = await Process.run(
        'netsh',
        ['wlan', 'stop', 'hostednetwork'],
        runInShell: true,
      );
      
      if (result.exitCode != 0) {
        debugPrint('[WiFi Direct] Failed to stop: ${result.stderr}');
        return false;
      }
      
      _isHotspotMode = false;
      _isConnected = false;
      
      debugPrint('[WiFi Direct] Hotspot stopped');
      return true;
    } catch (e) {
      debugPrint('[WiFi Direct] Error stopping hotspot: $e');
      return false;
    }
  }
  
  /// Connect to a WiFi network (Client Mode)
  Future<bool> connectToNetwork({
    required String ssid,
    required String password,
  }) async {
    if (Platform.isWindows) {
      return await _connectWindowsWiFi(ssid, password);
    }
    return false;
  }
  
  /// Connect to WiFi on Windows
  Future<bool> _connectWindowsWiFi(String ssid, String password) async {
    try {
      debugPrint('[WiFi Direct] Connecting to: $ssid');
      
      // Create profile XML
      final profileXml = '''<?xml version="1.0"?>
<WLANProfile xmlns="http://www.microsoft.com/networking/WLAN/profile/v1">
  <name>$ssid</name>
  <SSIDConfig>
    <SSID>
      <name>$ssid</name>
    </SSID>
  </SSIDConfig>
  <connectionType>ESS</connectionType>
  <connectionMode>manual</connectionMode>
  <MSM>
    <security>
      <authEncryption>
        <authentication>WPA2PSK</authentication>
        <encryption>AES</encryption>
        <useOneX>false</useOneX>
      </authEncryption>
      <sharedKey>
        <keyType>passPhrase</keyType>
        <protected>false</protected>
        <keyMaterial>$password</keyMaterial>
      </sharedKey>
    </security>
  </MSM>
</WLANProfile>''';
      
      // Save profile to temp file
      final tempFile = File('${Directory.systemTemp.path}\\wifi_profile.xml');
      await tempFile.writeAsString(profileXml);
      
      // Add profile
      var result = await Process.run(
        'netsh',
        ['wlan', 'add', 'profile', 'filename=${tempFile.path}'],
        runInShell: true,
      );
      
      if (result.exitCode != 0) {
        debugPrint('[WiFi Direct] Failed to add profile: ${result.stderr}');
      }
      
      // Connect
      result = await Process.run(
        'netsh',
        ['wlan', 'connect', 'name=$ssid'],
        runInShell: true,
      );
      
      // Clean up temp file
      try {
        await tempFile.delete();
      } catch (_) {}
      
      if (result.exitCode != 0) {
        debugPrint('[WiFi Direct] Failed to connect: ${result.stderr}');
        return false;
      }
      
      // Wait for connection
      await Future.delayed(const Duration(seconds: 3));
      
      _isConnected = true;
      debugPrint('[WiFi Direct] Connected to $ssid');
      
      return true;
    } catch (e) {
      debugPrint('[WiFi Direct] Error connecting: $e');
      return false;
    }
  }
  
  /// Scan for available WiFi networks
  Future<List<String>> scanNetworks() async {
    if (Platform.isWindows) {
      return await _scanWindowsNetworks();
    }
    return [];
  }
  
  /// Scan WiFi networks on Windows
  Future<List<String>> _scanWindowsNetworks() async {
    try {
      final result = await Process.run(
        'netsh',
        ['wlan', 'show', 'networks'],
        runInShell: true,
      );
      
      final output = result.stdout.toString();
      final lines = output.split('\n');
      final networks = <String>[];
      
      for (var line in lines) {
        if (line.contains('SSID')) {
          final ssid = line.split(':').last.trim();
          if (ssid.isNotEmpty && ssid != 'SSID') {
            networks.add(ssid);
          }
        }
      }
      
      return networks;
    } catch (e) {
      debugPrint('[WiFi Direct] Error scanning: $e');
      return [];
    }
  }
  
  /// Get current WiFi status
  Future<Map<String, dynamic>> getStatus() async {
    return {
      'isHotspotMode': _isHotspotMode,
      'isConnected': _isConnected,
      'ip': await _getHotspotIP(),
    };
  }
  
  bool get isHotspotMode => _isHotspotMode;
  bool get isConnected => _isConnected;
}
