import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/device_info_service.dart';
import '../services/file_operations_service.dart';
import '../services/settings_service.dart';
import '../services/udp_discovery_service.dart';
import '../services/tcp_transfer_service.dart';
// New services disabled for build
// import '../services/integrated_discovery_service.dart';
// import '../services/enhanced_transfer_service.dart';
import '../core/discovery/discovery_engine.dart';
import '../core/platform/platform_adapter.dart';
import 'history_provider.dart';

// Device Info Service
final deviceInfoServiceProvider = Provider<DeviceInfoService>((ref) {
  final service = DeviceInfoService();
  service.startBatteryMonitoring();
  ref.onDispose(() => service.dispose());
  return service;
});

final deviceDetailsProvider = FutureProvider<DeviceDetails>((ref) async {
  final service = ref.watch(deviceInfoServiceProvider);
  return await service.getDeviceDetails();
});

final batteryStreamProvider = StreamProvider<BatteryInfo>((ref) {
  final service = ref.watch(deviceInfoServiceProvider);
  return service.batteryStream;
});

// File Operations Service
final fileOperationsServiceProvider = Provider<FileOperationsService>((ref) {
  return FileOperationsService();
});

final receivedFilesProvider = FutureProvider<List<ReceivedFileInfo>>((ref) async {
  final service = ref.watch(fileOperationsServiceProvider);
  return await service.getReceivedFiles();
});

final storageInfoProvider = FutureProvider<StorageInfo>((ref) async {
  final service = ref.watch(fileOperationsServiceProvider);
  return await service.getStorageInfo();
});

// Settings Service
final settingsServiceProvider = Provider<SettingsService>((ref) {
  final service = SettingsService();
  // Initialize asynchronously, don't await here
  service.initialize().catchError((error) {
    // Ignore initialization errors
  });
  ref.onDispose(() => service.dispose());
  return service;
});

final appSettingsProvider = StreamProvider<AppSettings>((ref) {
  final service = ref.watch(settingsServiceProvider);
  return service.settingsStream;
});

// UDP Discovery Service
final mdnsDiscoveryProvider = Provider<UdpDiscoveryService?>((ref) {
  try {
    final service = UdpDiscoveryService();
    service.start();
    ref.onDispose(() => service.stop());
    return service;
  } catch (e) {
    print('[Provider] Failed to start UDP discovery: $e');
    return null;
  }
});

final discoveredDevicesStreamProvider = StreamProvider<List<PeerDevice>>((ref) {
  final service = ref.watch(mdnsDiscoveryProvider);
  if (service == null) {
    return Stream.value([]);
  }
  return service.devicesStream;
});

// Convenience providers for UI
final isDiscoverableProvider = Provider<bool>((ref) {
  return ref.watch(appSettingsProvider).maybeWhen(
    data: (settings) => settings.isDiscoverable,
    orElse: () => true,
  );
});

final airdropEnabledProvider = Provider<bool>((ref) {
  return ref.watch(appSettingsProvider).maybeWhen(
    data: (settings) => settings.airdropEnabled,
    orElse: () => true,
  );
});

final currentThemeModeProvider = Provider((ref) {
  return ref.watch(appSettingsProvider).maybeWhen(
    data: (settings) => settings.themeMode,
    orElse: () => ThemeMode.system,
  );
});

// TCP Transfer Service
final tcpTransferServiceProvider = Provider<TcpTransferService>((ref) {
  final service = TcpTransferService();
  
  // Only initialize on supported platforms
  if (PlatformAdapter.supportsTCP) {
    // Inject history repository asynchronously
    ref.read(historyRepositoryProvider.future).then((historyRepo) {
      service.setHistoryRepository(historyRepo);
      print('[Provider] History repository injected into TCP service');
    }).catchError((e) {
      print('[Provider] Failed to inject history repository: $e');
    });
    
    // Auto-start server for receiving files
    service.startServer().catchError((error) {
      print('[Provider] Failed to start TCP server: $error');
    });
  } else {
    print('[Provider] TCP service not available on this platform');
  }
  
  ref.onDispose(() => service.dispose());
  return service;
});

final transferProgressStreamProvider = StreamProvider<TransferProgress>((ref) {
  final service = ref.watch(tcpTransferServiceProvider);
  return service.transferProgressStream;
});

// New providers disabled for build
// final integratedDiscoveryProvider = ...
// final enhancedTransferProvider = ...
