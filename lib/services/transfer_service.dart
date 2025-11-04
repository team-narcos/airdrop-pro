import 'dart:async';
import 'package:flutter/foundation.dart' show visibleForTesting;
import '../core/discovery/discovery_engine.dart';
import '../core/discovery/mdns_discovery.dart';
import '../core/discovery/ble_discovery.dart';
import '../core/discovery/qr_pairing_discovery.dart';
import '../core/security/crypto_service.dart';
import '../core/transfer/transfer_manager.dart';
import '../core/transport/webrtc_transport.dart';
import '../core/transport/wifi_direct_transport.dart';
import '../core/transport/ble_transport.dart';

class TransferService {
  late final TransferManager manager;
  late final CompositeDiscoveryEngine discovery;
  late final QrPairingDiscovery qr;

  TransferService() {
    qr = QrPairingDiscovery();
    discovery = CompositeDiscoveryEngine([
      MdnsDiscovery(),
      BleDiscovery(),
      qr,
    ]);

    manager = TransferManager(
      discovery: discovery,
      primaryTransport: WebRtcTransport(),
      fallbacks: [WifiDirectTransport(), BleTransport()],
      crypto: CryptoService(),
    );
  }

  void addManualPeer(PeerDevice device) => qr.addPeer(device);
}
