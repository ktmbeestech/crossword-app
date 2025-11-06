import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';

class DeviceInfoService {
  Future<String?> getDeviceMacAddress() async {
    try {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        return '${androidInfo.model}_${androidInfo.id}';
      } else if (Platform.isIOS) {
        final IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        return '${iosInfo.utsname.machine}_${iosInfo.identifierForVendor}';
      }
    } catch (e) {
      return null;
    }
    return null;
  }
}

final DeviceInfoService deviceInfoService = DeviceInfoService();
