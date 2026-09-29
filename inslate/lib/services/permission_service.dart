import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  Future<bool> requestSmsPermission() async {
    final status = await Permission.sms.request();

    return status.isGranted;
  }

  Future<bool> isGranted() async {
    return Permission.sms.isGranted;
  }
}
