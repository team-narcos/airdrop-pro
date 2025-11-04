import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class SettingsService {
  static const String _keyDeviceName = 'device_name';
  static const String _keyDiscoverable = 'is_discoverable';
  static const String _keyAirdropEnabled = 'airdrop_enabled';
  static const String _keyAllowEveryone = 'allow_everyone';
  static const String _keyAutoAcceptContacts = 'auto_accept_contacts';
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyAccentColor = 'accent_color';
  static const String _keyFontScale = 'font_scale';
  static const String _keyPort = 'port_number';
  static const String _keyBandwidthLimit = 'bandwidth_limit';
  static const String _keyEnableCompression = 'enable_compression';
  static const String _keyRequireBiometric = 'require_biometric';
  static const String _keyHistoryRetention = 'history_retention_days';
  static const String _keyNotificationsEnabled = 'notifications_enabled';
  static const String _keyAutoSaveLocation = 'auto_save_location';
  static const String _keyTransferTimeout = 'transfer_timeout_seconds';
  static const String _keyMaxFileSize = 'max_file_size_mb';
  static const String _keyAutoCleanup = 'auto_cleanup_enabled';
  static const String _keyNotificationSound = 'notification_sound_enabled';
  static const String _keyNotificationVibrate = 'notification_vibrate_enabled';
  static const String _keyShowTransferSpeed = 'show_transfer_speed';
  static const String _keyKeepScreenOn = 'keep_screen_on_transfer';
  
  SharedPreferences? _prefs;
  final _settingsController = StreamController<AppSettings>.broadcast();
  
  Stream<AppSettings> get settingsStream => _settingsController.stream;
  
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadSettings();
  }
  
  Future<AppSettings> _loadSettings() async {
    final settings = AppSettings(
      deviceName: _prefs!.getString(_keyDeviceName) ?? 'My Device',
      isDiscoverable: _prefs!.getBool(_keyDiscoverable) ?? true,
      airdropEnabled: _prefs!.getBool(_keyAirdropEnabled) ?? true,
      allowEveryone: _prefs!.getBool(_keyAllowEveryone) ?? false,
      autoAcceptFromContacts: _prefs!.getBool(_keyAutoAcceptContacts) ?? true,
      themeMode: _getThemeMode(_prefs!.getString(_keyThemeMode)),
      accentColor: Color(_prefs!.getInt(_keyAccentColor) ?? 0xFF007AFF),
      fontScale: _prefs!.getDouble(_keyFontScale) ?? 1.0,
      portNumber: _prefs!.getInt(_keyPort) ?? 8080,
      bandwidthLimit: _prefs!.getInt(_keyBandwidthLimit) ?? 0, // 0 = unlimited
      enableCompression: _prefs!.getBool(_keyEnableCompression) ?? true,
      requireBiometric: _prefs!.getBool(_keyRequireBiometric) ?? false,
      historyRetentionDays: _prefs!.getInt(_keyHistoryRetention) ?? 30,
      notificationsEnabled: _prefs!.getBool(_keyNotificationsEnabled) ?? true,
      autoSaveLocation: _prefs!.getString(_keyAutoSaveLocation) ?? 'Downloads',
      transferTimeout: _prefs!.getInt(_keyTransferTimeout) ?? 300, // 5 minutes
      maxFileSize: _prefs!.getInt(_keyMaxFileSize) ?? 2048, // 2GB
      autoCleanup: _prefs!.getBool(_keyAutoCleanup) ?? false,
      notificationSound: _prefs!.getBool(_keyNotificationSound) ?? true,
      notificationVibrate: _prefs!.getBool(_keyNotificationVibrate) ?? true,
      showTransferSpeed: _prefs!.getBool(_keyShowTransferSpeed) ?? true,
      keepScreenOn: _prefs!.getBool(_keyKeepScreenOn) ?? false,
    );
    
    _settingsController.add(settings);
    return settings;
  }
  
  ThemeMode _getThemeMode(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
  
  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      default:
        return 'system';
    }
  }
  
  Future<void> setDeviceName(String name) async {
    await _prefs!.setString(_keyDeviceName, name);
    await _loadSettings();
  }
  
  Future<void> setDiscoverable(bool value) async {
    await _prefs!.setBool(_keyDiscoverable, value);
    await _loadSettings();
  }
  
  Future<void> setAirdropEnabled(bool value) async {
    await _prefs!.setBool(_keyAirdropEnabled, value);
    await _loadSettings();
  }
  
  Future<void> setAllowEveryone(bool value) async {
    await _prefs!.setBool(_keyAllowEveryone, value);
    await _loadSettings();
  }
  
  Future<void> setAutoAcceptFromContacts(bool value) async {
    await _prefs!.setBool(_keyAutoAcceptContacts, value);
    await _loadSettings();
  }
  
  Future<void> setThemeMode(ThemeMode mode) async {
    await _prefs!.setString(_keyThemeMode, _themeModeToString(mode));
    await _loadSettings();
  }
  
  Future<void> setAccentColor(Color color) async {
    await _prefs!.setInt(_keyAccentColor, color.value);
    await _loadSettings();
  }
  
  Future<void> setFontScale(double scale) async {
    await _prefs!.setDouble(_keyFontScale, scale);
    await _loadSettings();
  }
  
  Future<void> setPortNumber(int port) async {
    await _prefs!.setInt(_keyPort, port);
    await _loadSettings();
  }
  
  Future<void> setBandwidthLimit(int limit) async {
    await _prefs!.setInt(_keyBandwidthLimit, limit);
    await _loadSettings();
  }
  
  Future<void> setEnableCompression(bool value) async {
    await _prefs!.setBool(_keyEnableCompression, value);
    await _loadSettings();
  }
  
  Future<void> setCompressionEnabled(bool value) async {
    await setEnableCompression(value);
  }
  
  Future<void> setRequireBiometric(bool value) async {
    await _prefs!.setBool(_keyRequireBiometric, value);
    await _loadSettings();
  }
  
  Future<void> setBiometricEnabled(bool value) async {
    await setRequireBiometric(value);
  }
  
  Future<void> setHistoryRetentionDays(int days) async {
    await _prefs!.setInt(_keyHistoryRetention, days);
    await _loadSettings();
  }
  
  Future<void> setNotificationsEnabled(bool value) async {
    await _prefs!.setBool(_keyNotificationsEnabled, value);
    await _loadSettings();
  }
  
  Future<void> setAutoSaveLocation(String location) async {
    await _prefs!.setString(_keyAutoSaveLocation, location);
    await _loadSettings();
  }
  
  Future<void> setTransferTimeout(int seconds) async {
    await _prefs!.setInt(_keyTransferTimeout, seconds);
    await _loadSettings();
  }
  
  Future<void> setMaxFileSize(int sizeMB) async {
    await _prefs!.setInt(_keyMaxFileSize, sizeMB);
    await _loadSettings();
  }
  
  Future<void> setAutoCleanup(bool value) async {
    await _prefs!.setBool(_keyAutoCleanup, value);
    await _loadSettings();
  }
  
  Future<void> setNotificationSound(bool value) async {
    await _prefs!.setBool(_keyNotificationSound, value);
    await _loadSettings();
  }
  
  Future<void> setNotificationVibrate(bool value) async {
    await _prefs!.setBool(_keyNotificationVibrate, value);
    await _loadSettings();
  }
  
  Future<void> setShowTransferSpeed(bool value) async {
    await _prefs!.setBool(_keyShowTransferSpeed, value);
    await _loadSettings();
  }
  
  Future<void> setKeepScreenOn(bool value) async {
    await _prefs!.setBool(_keyKeepScreenOn, value);
    await _loadSettings();
  }
  
  Future<AppSettings> getCurrentSettings() async {
    return await _loadSettings();
  }
  
  void dispose() {
    _settingsController.close();
  }
}

class AppSettings {
  final String deviceName;
  final bool isDiscoverable;
  final bool airdropEnabled;
  final bool allowEveryone;
  final bool autoAcceptFromContacts;
  final ThemeMode themeMode;
  final Color accentColor;
  final double fontScale;
  final int portNumber;
  final int bandwidthLimit;
  final bool enableCompression;
  final bool requireBiometric;
  final int historyRetentionDays;
  final bool notificationsEnabled;
  final String autoSaveLocation;
  final int transferTimeout;
  final int maxFileSize;
  final bool autoCleanup;
  final bool notificationSound;
  final bool notificationVibrate;
  final bool showTransferSpeed;
  final bool keepScreenOn;
  
  // Convenience getters
  bool get compressionEnabled => enableCompression;
  bool get biometricEnabled => requireBiometric;
  
  AppSettings({
    required this.deviceName,
    required this.isDiscoverable,
    required this.airdropEnabled,
    required this.allowEveryone,
    required this.autoAcceptFromContacts,
    required this.themeMode,
    required this.accentColor,
    required this.fontScale,
    required this.portNumber,
    required this.bandwidthLimit,
    required this.enableCompression,
    required this.requireBiometric,
    required this.historyRetentionDays,
    required this.notificationsEnabled,
    required this.autoSaveLocation,
    required this.transferTimeout,
    required this.maxFileSize,
    required this.autoCleanup,
    required this.notificationSound,
    required this.notificationVibrate,
    required this.showTransferSpeed,
    required this.keepScreenOn,
  });
}
