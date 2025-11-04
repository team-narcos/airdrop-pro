import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/transfer_service.dart';
import '../core/discovery/discovery_engine.dart';
import '../core/transfer/transfer_manager.dart';

final transferServiceProvider = Provider<TransferService>((ref) {
  final svc = TransferService();
  // Fire-and-forget init
  // ignore: discarded_futures
  svc.manager.initialize();
  ref.onDispose(() {
    // ignore: discarded_futures
    svc.manager.dispose();
  });
  return svc;
});

final discoveredDevicesProvider = StreamProvider<List<PeerDevice>>((ref) {
  final svc = ref.watch(transferServiceProvider);
  return (svc.manager.discovery).devices;
});

final transferProgressProvider = StreamProvider<TransferProgress>((ref) {
  final svc = ref.watch(transferServiceProvider);
  return svc.manager.progress;
});
