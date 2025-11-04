import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class WebRTCTransferService {
  RTCPeerConnection? _peerConnection;
  RTCDataChannel? _dataChannel;
  
  final _progressController = StreamController<TransferProgress>.broadcast();
  Stream<TransferProgress> get progressStream => _progressController.stream;
  
  final _connectionController = StreamController<ConnectionState>.broadcast();
  Stream<ConnectionState> get connectionStream => _connectionController.stream;
  
  bool _isConnected = false;
  
  Future<void> initialize() async {
    final configuration = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
        {'urls': 'stun:stun1.l.google.com:19302'},
      ]
    };
    
    _peerConnection = await createPeerConnection(configuration);
    
    _peerConnection!.onIceCandidate = (candidate) {
      // In production, send this to peer via signaling server
      _handleIceCandidate(candidate);
    };
    
    _peerConnection!.onIceConnectionState = (state) {
      _connectionController.add(_mapIceState(state));
    };
  }
  
  Future<String> createOffer() async {
    // Create data channel
    _dataChannel = await _peerConnection!.createDataChannel(
      'fileTransfer',
      RTCDataChannelInit()..maxRetransmits = 30,
    );
    
    _setupDataChannel();
    
    // Create offer
    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);
    
    return offer.sdp!;
  }
  
  Future<String> createAnswer(String offerSdp) async {
    await _peerConnection!.setRemoteDescription(
      RTCSessionDescription(offerSdp, 'offer'),
    );
    
    _peerConnection!.onDataChannel = (channel) {
      _dataChannel = channel;
      _setupDataChannel();
    };
    
    final answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);
    
    return answer.sdp!;
  }
  
  Future<void> setRemoteAnswer(String answerSdp) async {
    await _peerConnection!.setRemoteDescription(
      RTCSessionDescription(answerSdp, 'answer'),
    );
  }
  
  void _setupDataChannel() {
    _dataChannel!.onMessage = (message) {
      _handleReceivedData(message.binary);
    };
    
    _dataChannel!.onDataChannelState = (state) {
      if (state == RTCDataChannelState.RTCDataChannelOpen) {
        _isConnected = true;
        _connectionController.add(ConnectionState.connected);
      }
    };
  }
  
  Future<void> sendFile(String fileName, Uint8List fileData) async {
    if (!_isConnected || _dataChannel == null) {
      throw Exception('Not connected');
    }
    
    final totalSize = fileData.length;
    const chunkSize = 16384; // 16KB chunks
    int sentBytes = 0;
    
    // Send file metadata
    final metadata = {
      'type': 'metadata',
      'name': fileName,
      'size': totalSize,
    };
    _dataChannel!.send(RTCDataChannelMessage(metadata.toString()));
    
    // Send file in chunks
    while (sentBytes < totalSize) {
      final end = (sentBytes + chunkSize > totalSize) 
          ? totalSize 
          : sentBytes + chunkSize;
      
      final chunk = fileData.sublist(sentBytes, end);
      _dataChannel!.send(RTCDataChannelMessage.fromBinary(chunk));
      
      sentBytes = end;
      
      // Emit progress
      _progressController.add(TransferProgress(
        fileName: fileName,
        totalBytes: totalSize,
        sentBytes: sentBytes,
        progress: sentBytes / totalSize,
      ));
      
      // Small delay to prevent overwhelming
      await Future.delayed(const Duration(microseconds: 100));
    }
    
    _progressController.add(TransferProgress(
      fileName: fileName,
      totalBytes: totalSize,
      sentBytes: totalSize,
      progress: 1.0,
      isComplete: true,
    ));
  }
  
  void _handleReceivedData(Uint8List data) {
    // Handle received file chunks
    // In production, accumulate chunks and save file
  }
  
  void _handleIceCandidate(RTCIceCandidate candidate) {
    // In production, send to signaling server
  }
  
  ConnectionState _mapIceState(RTCIceConnectionState state) {
    switch (state) {
      case RTCIceConnectionState.RTCIceConnectionStateConnected:
        return ConnectionState.connected;
      case RTCIceConnectionState.RTCIceConnectionStateDisconnected:
        return ConnectionState.disconnected;
      case RTCIceConnectionState.RTCIceConnectionStateFailed:
        return ConnectionState.failed;
      default:
        return ConnectionState.connecting;
    }
  }
  
  Future<void> dispose() async {
    await _dataChannel?.close();
    await _peerConnection?.close();
    await _progressController.close();
    await _connectionController.close();
  }
}

class TransferProgress {
  final String fileName;
  final int totalBytes;
  final int sentBytes;
  final double progress;
  final bool isComplete;
  
  TransferProgress({
    required this.fileName,
    required this.totalBytes,
    required this.sentBytes,
    required this.progress,
    this.isComplete = false,
  });
}

enum ConnectionState {
  connecting,
  connected,
  disconnected,
  failed,
}
