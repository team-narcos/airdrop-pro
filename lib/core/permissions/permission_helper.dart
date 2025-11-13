import 'package:permission_handler/permission_handler.dart';

/// Helper class for requesting and checking permissions
class PermissionHelper {
  /// Request all permissions needed for WiFi Direct and Bluetooth
  static Future<bool> requestP2PPermissions() async {
    // Request location permission (required for WiFi Direct/Bluetooth discovery)
    final locationStatus = await Permission.locationWhenInUse.request();
    
    // Request nearby WiFi devices permission (Android 13+)
    Map<Permission, PermissionStatus> statuses = {};
    
    try {
      statuses = await [
        Permission.location,
        Permission.locationWhenInUse,
        Permission.bluetooth,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.bluetoothAdvertise,
        Permission.nearbyWifiDevices,
      ].request();
    } catch (e) {
      print('[Permissions] Error requesting permissions: $e');
      return false;
    }
    
    // Check if critical permissions are granted
    final hasLocation = locationStatus.isGranted;
    final hasBluetooth = statuses[Permission.bluetooth]?.isGranted ?? false;
    
    print('[Permissions] Location: $hasLocation, Bluetooth: $hasBluetooth');
    
    return hasLocation || hasBluetooth;
  }
  
  /// Check if all required permissions are granted
  static Future<bool> hasP2PPermissions() async {
    final locationStatus = await Permission.locationWhenInUse.status;
    final bluetoothStatus = await Permission.bluetooth.status;
    
    return locationStatus.isGranted && bluetoothStatus.isGranted;
  }
  
  /// Open app settings if permissions are permanently denied
  static Future<void> openSettings() async {
    await openAppSettings();
  }
  
  /// Request storage permissions for file access
  static Future<bool> requestStoragePermissions() async {
    final storageStatus = await Permission.storage.request();
    final manageStorageStatus = await Permission.manageExternalStorage.request();
    
    return storageStatus.isGranted || manageStorageStatus.isGranted;
  }
}
