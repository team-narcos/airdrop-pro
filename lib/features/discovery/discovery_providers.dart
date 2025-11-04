import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/discovery/discovery_engine.dart';
import '../../core/discovery/mdns_discovery.dart';
import '../../core/discovery/ble_discovery.dart';
import '../../core/discovery/qr_pairing_discovery.dart';
import '../../core/discovery/device_registry.dart';

final mdnsDiscoveryProvider = Provider<DiscoveryEngine>((ref) => MdnsDiscovery());
final bleDiscoveryProvider = Provider<DiscoveryEngine>((ref) => BleDiscovery());
final qrDiscoveryProvider = Provider<QrPairingDiscovery>((ref) => QrPairingDiscovery());

final deviceRegistryProvider = Provider<DeviceRegistry>((ref) {
  final engines = <DiscoveryEngine>[
    ref.watch(mdnsDiscoveryProvider),
    ref.watch(bleDiscoveryProvider),
    ref.watch(qrDiscoveryProvider),
  ];
  return DeviceRegistry(engines);
});

/// Expose a stream of merged peers for the UI (radar, lists, etc.)
final peersStreamProvider = StreamProvider.autoDispose<List<PeerDevice>>((ref) {
  final registry = ref.watch(deviceRegistryProvider);
  // Ensure start/stop lifecycle
  registry.start();
  ref.onDispose(() => registry.stop());
  return registry.devices;
});
