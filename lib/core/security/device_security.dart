import 'package:flutter/foundation.dart';
import 'package:safe_device/safe_device.dart';

class DeviceSecurityReport {
  const DeviceSecurityReport({required this.rooted, required this.emulator});

  final bool rooted;
  final bool emulator;

  bool get isSafe => !rooted && !emulator;

  static const unknown = DeviceSecurityReport(rooted: false, emulator: false);
}

class DeviceSecurity {
  /// Root / emulator detection. Failures are treated as "unknown, not unsafe"
  /// so a plugin error never blocks a legitimate user.
  static Future<DeviceSecurityReport> check() async {
    try {
      final rooted = await SafeDevice.isJailBroken;
      final real = await SafeDevice.isRealDevice;
      return DeviceSecurityReport(rooted: rooted, emulator: !real);
    } catch (e) {
      debugPrint('Device security check failed: $e');
      return DeviceSecurityReport.unknown;
    }
  }
}
