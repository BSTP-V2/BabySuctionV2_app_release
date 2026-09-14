//=============================================================
//    ฟังก์ชันสำหรับจัดการระบบ Bluetooth, ขอสิทธ์การเข้าถึง ใช้ในหน้า BleScanDevices
//=============================================================

import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter/foundation.dart';

class BleHandler {
  static ValueNotifier<bool> isConnected = ValueNotifier<bool>(false);
  static Map<String, BluetoothCharacteristic?> deviceServiceChar = {
    "sensor_value": null,
    "test_state": null,
    "battery_state": null,
  }; //Service Characteristic

  static Future<bool> reqPermissionForBLE() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
      Permission.bluetooth,
    ].request();

    if (statuses[Permission.bluetoothScan]!.isGranted && statuses[Permission.bluetoothConnect]!.isGranted) {
      return true;
    } else {
      return false;
    }
  } //requestBluetoothPermission
} //class: BleHandler
