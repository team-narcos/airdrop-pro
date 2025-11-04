import 'dart:async';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:battery_plus/battery_plus.dart';

class DeviceInfoService {
  final _deviceInfo = DeviceInfoPlugin();
  final _battery = Battery();
  
  final _batteryController = StreamController<BatteryInfo>.broadcast();
  Stream<BatteryInfo> get batteryStream => _batteryController.stream;
  
  Timer? _batteryTimer;
  
  void startBatteryMonitoring() {
    _batteryTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      await _updateBatteryInfo();
    });
    _updateBatteryInfo();
  }
  
  void stopBatteryMonitoring() {
    _batteryTimer?.cancel();
  }
  
  Future<void> _updateBatteryInfo() async {
    try {
      final level = await _battery.batteryLevel;
      final state = await _battery.batteryState;
      
      _batteryController.add(BatteryInfo(
        level: level,
        isCharging: state == BatteryState.charging,
        state: state.toString().split('.').last,
      ));
    } catch (e) {
      // Battery info not available (web/desktop)
      _batteryController.add(BatteryInfo(level: 100, isCharging: false, state: 'unknown'));
    }
  }
  
  Future<DeviceDetails> getDeviceDetails() async {
    try {
      if (Platform.isAndroid) {
        final info = await _deviceInfo.androidInfo;
        return DeviceDetails(
          name: '${info.brand} ${info.model}',
          platform: 'Android',
          osVersion: info.version.release,
          model: info.model,
          identifier: info.id,
        );
      } else if (Platform.isIOS) {
        final info = await _deviceInfo.iosInfo;
        return DeviceDetails(
          name: info.name,
          platform: 'iOS',
          osVersion: info.systemVersion,
          model: info.model,
          identifier: info.identifierForVendor ?? 'unknown',
        );
      } else if (Platform.isWindows) {
        final info = await _deviceInfo.windowsInfo;
        return DeviceDetails(
          name: info.computerName,
          platform: 'Windows',
          osVersion: '${info.majorVersion}.${info.minorVersion}',
          model: info.computerName,
          identifier: info.computerName,
        );
      } else if (Platform.isMacOS) {
        final info = await _deviceInfo.macOsInfo;
        return DeviceDetails(
          name: info.computerName,
          platform: 'macOS',
          osVersion: info.osRelease,
          model: info.model,
          identifier: info.systemGUID ?? 'unknown',
        );
      } else if (Platform.isLinux) {
        final info = await _deviceInfo.linuxInfo;
        return DeviceDetails(
          name: info.name,
          platform: 'Linux',
          osVersion: info.versionId ?? 'unknown',
          model: info.name,
          identifier: info.machineId ?? 'unknown',
        );
      }
    } catch (e) {
      // Fallback for web or errors
      return DeviceDetails(
        name: 'Web Browser',
        platform: 'Web',
        osVersion: 'Unknown',
        model: 'Browser',
        identifier: 'web-device',
      );
    }
    
    return DeviceDetails(
      name: 'Unknown Device',
      platform: 'Unknown',
      osVersion: 'Unknown',
      model: 'Unknown',
      identifier: 'unknown',
    );
  }
  
  void dispose() {
    _batteryTimer?.cancel();
    _batteryController.close();
  }
}

class BatteryInfo {
  final int level;
  final bool isCharging;
  final String state;
  
  BatteryInfo({
    required this.level,
    required this.isCharging,
    required this.state,
  });
}

class DeviceDetails {
  final String name;
  final String platform;
  final String osVersion;
  final String model;
  final String identifier;
  
  DeviceDetails({
    required this.name,
    required this.platform,
    required this.osVersion,
    required this.model,
    required this.identifier,
  });
}
