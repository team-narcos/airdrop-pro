import '../models/peer_device.dart';
import '../transfer/transfer_job.dart';
import 'transport.dart';

class ProtocolSelector {
  const ProtocolSelector();

  Transport choose(List<Transport> transports, PeerDevice peer, TransferJob job) {
    // Filter supported and reachable transports first (callers should have probed).
    final candidates = transports.where((t) => t.isSupported).toList()
      ..sort((a, b) => b.priority.compareTo(a.priority));

    // TODO: add better heuristics using peer.meta, RSSI, network type, file size.
    if (candidates.isEmpty) {
      // Fallback to first (will throw when used if unsupported)
      return transports.first;
    }
    return candidates.first;
  }
}
