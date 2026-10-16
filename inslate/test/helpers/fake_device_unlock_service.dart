import 'dart:async';
import 'package:inslate/services/device_unlock_service.dart';

class FakeDeviceUnlockService extends DeviceUnlockService {
  bool available = true, verified = true, failAuth = false;
  bool? failProtection;
  int authenticationCalls = 0;
  Completer<bool>? pendingAuthentication;
  final protection = <bool>[];
  @override
  Future<bool> isAvailable() async => available;
  @override
  Future<bool> authenticate() async {
    authenticationCalls++;
    if (failAuth) throw StateError('private platform details');
    return pendingAuthentication?.future ?? verified;
  }

  @override
  Future<void> protectScreen(bool enabled) async {
    protection.add(enabled);
    if (failProtection == enabled) throw StateError('private platform details');
  }
}
