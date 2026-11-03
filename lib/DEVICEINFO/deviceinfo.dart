import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

class DeviceInfoService {
  static Future<Map<String, dynamic>> getDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;

      return {
        'deviceType': 'Android',
        'deviceModel': androidInfo.model,
        'manufacturer': androidInfo.manufacturer,
        'osVersion': androidInfo.version.release,
        'sdkVersion': androidInfo.version.sdkInt,
      };
    }

    if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;

      return {
        'deviceType': 'iOS',
        'deviceModel': iosInfo.model,
        'manufacturer': 'Apple',
        'osVersion': iosInfo.systemVersion,
      };
    }

    return {};
  }
}


// final deviceData = await DeviceInfoService.getDeviceInfo();
  //print(deviceData);


// final body = {
//   'phone': phone,
//   'password': password,

    // New device data
      //  'cDeviceModel': deviceData['deviceModel'],
      //  'cManufacturer': deviceData['manufacturer'],
      //  'cOSVersion': deviceData['osVersion'],
      //  'nSDKVersion': deviceData['sdkVersion'],
// };

// Device Type: Android
// Device Model: 23076PC4BI
// Manufacturer: Xiaomi
// OS Version: 15
// SDK Version: 35