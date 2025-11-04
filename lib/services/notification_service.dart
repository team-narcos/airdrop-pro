import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Simple notification service using Flutter's own notification system
/// For production, you would use flutter_local_notifications package
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final _notificationController = StreamController<AppNotification>.broadcast();
  Stream<AppNotification> get notificationStream => _notificationController.stream;
  
  BuildContext? _context;
  
  void initialize(BuildContext context) {
    _context = context;
  }

  /// Show notification for file received
  void showFileReceived(String fileName, String filePath) {
    final notification = AppNotification(
      title: 'File Received',
      body: fileName,
      type: NotificationType.fileReceived,
      timestamp: DateTime.now(),
      data: {'fileName': fileName, 'filePath': filePath},
    );
    
    _notificationController.add(notification);
    _showInAppNotification(notification);
  }

  /// Show notification for transfer progress
  void showTransferProgress(String fileName, int progress) {
    final notification = AppNotification(
      title: 'Transferring',
      body: '$fileName - $progress%',
      type: NotificationType.transferProgress,
      timestamp: DateTime.now(),
      data: {'fileName': fileName, 'progress': progress},
    );
    
    _notificationController.add(notification);
  }

  /// Show notification for transfer complete
  void showTransferComplete(String fileName) {
    final notification = AppNotification(
      title: 'Transfer Complete',
      body: fileName,
      type: NotificationType.transferComplete,
      timestamp: DateTime.now(),
      data: {'fileName': fileName},
    );
    
    _notificationController.add(notification);
    _showInAppNotification(notification);
  }

  /// Show notification for transfer failed
  void showTransferFailed(String fileName, String error) {
    final notification = AppNotification(
      title: 'Transfer Failed',
      body: '$fileName - $error',
      type: NotificationType.transferFailed,
      timestamp: DateTime.now(),
      data: {'fileName': fileName, 'error': error},
    );
    
    _notificationController.add(notification);
    _showInAppNotification(notification);
  }

  /// Show notification for device connected
  void showDeviceConnected(String deviceName) {
    final notification = AppNotification(
      title: 'Device Connected',
      body: deviceName,
      type: NotificationType.deviceConnected,
      timestamp: DateTime.now(),
      data: {'deviceName': deviceName},
    );
    
    _notificationController.add(notification);
    _showInAppNotification(notification);
  }

  /// Show notification for device disconnected
  void showDeviceDisconnected(String deviceName) {
    final notification = AppNotification(
      title: 'Device Disconnected',
      body: deviceName,
      type: NotificationType.deviceDisconnected,
      timestamp: DateTime.now(),
      data: {'deviceName': deviceName},
    );
    
    _notificationController.add(notification);
  }

  /// Show in-app banner notification using SnackBar
  void _showInAppNotification(AppNotification notification) {
    if (_context == null || !(_context as Element).mounted) return;

    final scaffoldMessenger = ScaffoldMessenger.maybeOf(_context!);
    if (scaffoldMessenger == null) return;

    final icon = _getNotificationIcon(notification.type);
    final color = _getNotificationColor(notification.type);

    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    notification.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    notification.body,
                    style: const TextStyle(color: Colors.white70),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.fileReceived:
        return CupertinoIcons.arrow_down_doc;
      case NotificationType.transferProgress:
        return CupertinoIcons.arrow_2_circlepath;
      case NotificationType.transferComplete:
        return CupertinoIcons.checkmark_circle;
      case NotificationType.transferFailed:
        return CupertinoIcons.xmark_circle;
      case NotificationType.deviceConnected:
        return CupertinoIcons.device_phone_portrait;
      case NotificationType.deviceDisconnected:
        return CupertinoIcons.xmark;
    }
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.fileReceived:
        return const Color(0xFF007AFF); // Blue
      case NotificationType.transferProgress:
        return const Color(0xFF5856D6); // Purple
      case NotificationType.transferComplete:
        return const Color(0xFF34C759); // Green
      case NotificationType.transferFailed:
        return const Color(0xFFFF3B30); // Red
      case NotificationType.deviceConnected:
        return const Color(0xFF30D158); // Green
      case NotificationType.deviceDisconnected:
        return const Color(0xFFFF9500); // Orange
    }
  }

  void dispose() {
    _notificationController.close();
  }
}

class AppNotification {
  final String title;
  final String body;
  final NotificationType type;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  AppNotification({
    required this.title,
    required this.body,
    required this.type,
    required this.timestamp,
    this.data = const {},
  });
}

enum NotificationType {
  fileReceived,
  transferProgress,
  transferComplete,
  transferFailed,
  deviceConnected,
  deviceDisconnected,
}
