import 'dart:io';
import 'package:flutter/services.dart';

/// Uses Android's existing device credentials; InSlate never receives the PIN.
class DeviceUnlockService {
  static const _channel = MethodChannel('inslate/device_unlock');
  const DeviceUnlockService();

  Future<bool> isAvailable() async {
    if (!Platform.isAndroid) return false;
    try {
      return await _channel.invokeMethod<bool>('isAvailable') ?? false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<bool> authenticate() async {
    if (!Platform.isAndroid) {
      throw UnsupportedError('Device unlock requires Android.');
    }
    return await _channel.invokeMethod<bool>('authenticate') ?? false;
  }

  Future<void> protectScreen(bool enabled) async {
    if (!Platform.isAndroid) {
      if (enabled) throw UnsupportedError('Device unlock requires Android.');
      return;
    }
    try {
      await _channel.invokeMethod<void>('protectScreen', {'enabled': enabled});
    } on MissingPluginException {
      // Other platforms have no device-unlock implementation or enable switch.
      if (enabled) rethrow;
    }
  }
}
