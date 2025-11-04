import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

/// Platform adapter to handle web vs mobile differences
class PlatformAdapter {
  static bool get isWeb => kIsWeb;
  
  static bool get isAndroid {
    try {
      return !kIsWeb && Platform.isAndroid;
    } catch (e) {
      return false;
    }
  }
  
  static bool get isIOS {
    try {
      return !kIsWeb && Platform.isIOS;
    } catch (e) {
      return false;
    }
  }
  
  static bool get isDesktop {
    try {
      return !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);
    } catch (e) {
      return false;
    }
  }
  
  static bool get isMobile => isAndroid || isIOS;
  
  static bool get supportsP2P => !isWeb && isMobile;
  
  static bool get supportsWiFiDirect => isAndroid;
  
  static bool get supportsBluetooth => !isWeb && (isAndroid || isIOS);
  
  static bool get supportsSQLite => !isWeb;
  
  static bool get supportsTCP => !isWeb;
  
  static bool get supportsFileSystem => !isWeb;
  
  static String get platformName {
    if (isWeb) return 'Web';
    try {
      if (Platform.isAndroid) return 'Android';
      if (Platform.isIOS) return 'iOS';
      if (Platform.isWindows) return 'Windows';
      if (Platform.isMacOS) return 'macOS';
      if (Platform.isLinux) return 'Linux';
    } catch (e) {
      // Ignore
    }
    return 'Unknown';
  }
}
