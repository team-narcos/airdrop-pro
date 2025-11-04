import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/app_database.dart';

class TrustedDevice {
  final String deviceId;
  final String name;
  final DateTime addedAt;

  const TrustedDevice({
    required this.deviceId,
    required this.name,
    required this.addedAt,
  });
}

class TrustedDevicesNotifier extends AsyncNotifier<List<TrustedDevice>> {
  @override
  Future<List<TrustedDevice>> build() async {
    // Load from database
    final db = ref.watch(appDatabaseProvider);
    final List<TrustedDeviceRecord> records = await db.getAllTrustedDevices();
    return records.map((r) => TrustedDevice(
      deviceId: r.deviceId,
      name: r.name,
      addedAt: r.addedAt,
    )).toList();
  }

  Future<void> addDevice({required String deviceId, required String name}) async {
    final db = ref.read(appDatabaseProvider);
    await db.addTrustedDevice(deviceId: deviceId, name: name);
    ref.invalidateSelf();
  }

  Future<void> removeDevice(String deviceId) async {
    final db = ref.read(appDatabaseProvider);
    await db.removeTrustedDevice(deviceId);
    ref.invalidateSelf();
  }

  bool isTrusted(String deviceId) {
    return state.value?.any((d) => d.deviceId == deviceId) ?? false;
  }
}

final trustedDevicesProvider = AsyncNotifierProvider<TrustedDevicesNotifier, List<TrustedDevice>>(() {
  return TrustedDevicesNotifier();
});
