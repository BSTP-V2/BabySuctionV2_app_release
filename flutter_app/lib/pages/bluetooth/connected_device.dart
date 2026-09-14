//=============================================================
//    หน้า - จับคู่กับอุปกรณ์แล้ว, แสดงรายละเอียดของอุปกรณ์ที่จับคู่
//=============================================================

import 'dart:async';
import 'dart:convert';
import 'package:bstp_v2/pages/bluetooth/finding_devices.dart';
import 'package:bstp_v2/services/ble_handler.dart';
import 'package:flutter/material.dart';
import 'package:bstp_v2/services/ui_helper.dart'; //ของ Flutter
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class MatchedDevicePage extends StatefulWidget {
  final BluetoothDevice device;
  const MatchedDevicePage({super.key, required this.device});

  @override
  State<MatchedDevicePage> createState() => _MatchedDevicePageState();
}

class _MatchedDevicePageState extends State<MatchedDevicePage> {
  int deviceBattery = -1;
  
  StreamSubscription? _disconnectSubscription;

  // Service and characteristic UUIDs for testing with V2 firmware. (V1 use FF10, FF11, FF13, FF14)
  static const String suctionServiceUuid = "FF10";
  static const String sensorUuid = "FF11";
  static const String timerUuid = "FF13";
  static const String batteryUuid = "FF14";


  


  StreamSubscription? _receiveBatteryStateListener;

  @override
  void initState() {
    super.initState();
    BleHandler.isConnected.value = true;
    handleDisconnected();
    handleDiscoverServices();
  } //initState

  @override
  void dispose() {
    _disconnectSubscription!.cancel();
    super.dispose();
  } //dispose






// batt show
  void handleReceiveBatteryState() async {
 
  final char = BleHandler.deviceServiceChar['battery_state'];

  if (char == null) {
    debugPrint("Error: battery_state ยังเป็น null อยู่");
    return;
  }

 
  try {
    await char.setNotifyValue(true);
    debugPrint("สั่ง Notify ไปที่ FF14 สำเร็จ");
  } catch (e) {
    debugPrint("สั่ง Notify FF14 ไม่ผ่าน: $e");
  }


  _receiveBatteryStateListener = char.onValueReceived.listen((value) {
    if (value.isNotEmpty && mounted) {
    
      String decodedString = utf8.decode(value, allowMalformed: true).trim();
      
     
      int battery = int.tryParse(decodedString) ?? value[0]; 


      // เอาไว้ดูดีบัค
      debugPrint("ได้รับข้อมูล: $decodedString | แปลงเป็นละ int: $battery");

      if (battery >= 0 && battery <= 100) {
        setState(() {
          deviceBattery = battery;
        });
      }
    }
  });
}

  // void handleReceiveBatteryState() async {
  //   await BleHandler.deviceServiceChar['battery_state']!.setNotifyValue(true);

  //   _receiveBatteryStateListener = BleHandler.deviceServiceChar['battery_state']!.onValueReceived.listen((value) {
  //     if (value.isNotEmpty) {
  //       final RegExp regExp = RegExp(r'\d+');
  //       final String valuDecodeString = utf8.decode(value);

  //       String valueOnlyString = regExp.stringMatch(valuDecodeString) ?? "";
  //       final int getBatteryState = int.tryParse(valueOnlyString) ?? 0;

  //       setState(() => deviceBattery = getBatteryState);
  //     }
  //   });
  // } //function: Receive battery state.

  
  
  

  void handleDiscoverServices() async {
  List<BluetoothService> services = await widget.device.discoverServices();
  
  for (var service in services) {
    String sUuid = service.uuid.toString().toUpperCase();
    
    if (sUuid.contains(suctionServiceUuid.toUpperCase())) {
      for (var characteristic in service.characteristics) {
        String uuid = characteristic.uuid.toString().toUpperCase();

        if (uuid.contains(sensorUuid.toUpperCase())) {
          BleHandler.deviceServiceChar['sensor_value'] = characteristic;
     
        } else if (uuid.contains(timerUuid.toUpperCase())) {
          BleHandler.deviceServiceChar['test_state'] = characteristic;
        } else if (uuid.contains(batteryUuid.toUpperCase())) {
          BleHandler.deviceServiceChar['battery_state'] = characteristic;
         
          handleReceiveBatteryState(); 
        }
      }
    }
  }
}
  

  
  // void handleDiscoverServices() async {
  //   List<BluetoothService> services = await widget.device.discoverServices();
  //   BluetoothService suctionService = services.firstWhere(
  //     (service) => service.uuid.toString().toUpperCase().contains(suctionServiceUuid),
  //   ); //FF10 is folder service that actually use in V1.

  //   for (var characteristic in suctionService.characteristics) {
  //     String uuid = characteristic.uuid.toString().toUpperCase();

  //     if (uuid.contains(sensorUuid)) {
  //       BleHandler.deviceServiceChar['sensor_value'] = characteristic;
  //     } else if (uuid.contains(timerUuid)) {
  //       BleHandler.deviceServiceChar['test_state'] = characteristic;
  //     } else if (uuid.contains(batteryUuid)) {
  //       BleHandler.deviceServiceChar['battery_state'] = characteristic;
  //       handleReceiveBatteryState();
  //     }
  //   } //process: Loop collect services found.
  // } //handleDiscoverServices




  void handleDisconnected() {
    _disconnectSubscription = widget.device.connectionState.listen((BluetoothConnectionState state) async {
      if (state == BluetoothConnectionState.disconnected) {
        if (mounted) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => BleScanDevicesPage()));
          UIHelper.justAlert(context, "ตัดการเชื่อมต่ออุปกรณ์แล้ว");
        } //if: Alert and route to default page

        await BleHandler.deviceServiceChar['battery_state']?.setNotifyValue(false);
        _receiveBatteryStateListener?.cancel();

        BleHandler.deviceServiceChar['sensor_value'] = null;
        BleHandler.deviceServiceChar['timer_state'] = null;
        BleHandler.deviceServiceChar['battery_state'] = null;
        BleHandler.isConnected.value = false;
      } //condition: mounted or not.
    }); //Handle disconnected event.

    // Automatic cleanup of the listener on any disconnection (including failed attempts)
    widget.device.cancelWhenDisconnected(_disconnectSubscription!, delayed: true);
  } //handleDisconnected

  PreferredSizeWidget pageAppBar() {
    return AppBar(
      backgroundColor: UIHelper.appThemeBackground,
      foregroundColor: UIHelper.appThemeForeground,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          UIHelper.textBold(
            widget.device.advName,
            fontSize: UIHelper.screenWidth(context, 0.05, lowerLimit: 0, upperLimit: 20),
          ),
          Text(
            "แบตเตอรี่: $deviceBattery%",
            style: TextStyle(fontSize: UIHelper.screenWidth(context, 0.040, lowerLimit: 0, upperLimit: 16)),
          ),
        ],
      ),
    );
  } //pageAppBar

  Widget pageBody() {
    double gap = UIHelper.screenHeight(context, 0.022);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          UIHelper.textBold(
            "เชื่อมต่ออุปกรณ์แล้ว",
            fontSize: UIHelper.screenWidth(context, 0.054, lowerLimit: 0, upperLimit: 44),
            fontColor: Colors.grey.shade800,
          ),
          SizedBox(height: gap),
          Text(
            widget.device.remoteId.str,
            style: TextStyle(
              fontSize: UIHelper.screenWidth(context, 0.038, lowerLimit: 0, upperLimit: 30),
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: gap),
          UIHelper.actionButton(
            "ตัดการเชื่อมต่อ",
            setIcon: Icons.bluetooth_disabled,
            fontSize: UIHelper.screenWidth(context, 0.044, lowerLimit: 0, upperLimit: 34),
            iconSize: UIHelper.screenWidth(context, 0.066, lowerLimit: 0, upperLimit: 38),
            textColor: UIHelper.appThemeForeground,
            buttonColor: UIHelper.appThemeBackground,
            height: UIHelper.screenHeight(context, 0.072, lowerLimit: 0, upperLimit: 90),
            width: UIHelper.screenWidth(context, 0.54, lowerLimit: 0, upperLimit: 420),
            borderRadius: 16,
            () async {
              if (mounted) {
                UIHelper.twoStepConfirmActionDialog(
                  context,
                  "ยืนยันตัดการเชื่อมต่อ?",
                  onConfirm: () async => await widget.device.disconnect(),
                  confirmBtnColor: Colors.blue.shade600,
                );
              } //if: Context still here.
            },
          ),
        ],
      ),
    );
  } //pageBody

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) await widget.device.disconnect();
      },
      child: Scaffold(appBar: pageAppBar(), body: pageBody()),
    );
  }
}//class: MatchBlePage