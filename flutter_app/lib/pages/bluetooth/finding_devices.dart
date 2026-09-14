//=============================================================
//    หน้า - ค้นหาอุปกรณ์, แสดงลิสต์อุปกรณ์, เชื่อมต่ออุปกรณ์
//=============================================================

import 'package:bstp_v2/services/ble_handler.dart';
import 'package:flutter/material.dart'; //ของ Flutter
import 'package:bstp_v2/services/ui_helper.dart';
import 'package:bstp_v2/pages/bluetooth/connected_device.dart'; // class จากไฟล์หน้าเชื่อมต่ออุปกรณ์แล้ว
import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart'; // package ของ bluetooth

class BleScanDevicesPage extends StatefulWidget {
  const BleScanDevicesPage({super.key});

  @override
  State<BleScanDevicesPage> createState() => _BleScanDevicesPageState();
} //class: FindBlePage

class _BleScanDevicesPageState extends State<BleScanDevicesPage> {
  static const String _deviceTargetName = 'BabySuctionV2';
  // static const String _deviceTargetName = 'ESP32 FSR Server';

  static const int _connectionTimedOut = 10;
  static const int _scanDuration = 10;
  bool isBluetoothSupported = false; //เช็คว่าอุปกรณ์รองรับบลูทธหรือไม่
  bool bluetoothPermissionGranted = false; //เช็คว่าผู้ใช้อนุญาติให้เข้าถึงสิทธ์การใช้งานหรือไม่
  bool isBluetoothTurnOn = false; //เช็คว่าผู้ใช้เปิดบลูทธยัง
  StreamSubscription<BluetoothAdapterState>? _deviceSubscription; //ติดตามสถานะเปิด-ปิด บลูทธ
  List<ScanResult> _devicesList = []; //อุปกรณ์ที่สแกนเจอ
  StreamSubscription<bool>? _scanStateSubscription; //ติดตามสถานะสแกนบลูทธ
  bool duringScan = false; //ใช้โชว์ "Scaning..."

  @override
  void initState() {
    super.initState();
    initBluetooth();
    _scanStateSubscription = FlutterBluePlus.isScanning.listen((isScanning) {
      if (isScanning) {
        setState(() => duringScan = true);
      } else {
        setState(() => duringScan = false);
      } //process: React on scanning.
    }); //process: Listen on scanner.
  } //initState

  Future<void> initBluetooth() async {
    isBluetoothSupported = await FlutterBluePlus.isSupported;
    bluetoothPermissionGranted = await BleHandler.reqPermissionForBLE(); //custom helper
    BluetoothAdapterState initialState = await FlutterBluePlus.adapterState.first;

    setState(() {
      isBluetoothTurnOn = (initialState == BluetoothAdapterState.on);
    });

    if (!isBluetoothSupported || !bluetoothPermissionGranted) return;

    _deviceSubscription?.cancel();

    _deviceSubscription = FlutterBluePlus.adapterState.listen((state) {
      setState(() {
        isBluetoothTurnOn = (state == BluetoothAdapterState.on);
        if (isBluetoothTurnOn == true) handleScanDevices();
      });
    });
  } //initBluetooth

  @override
  void dispose() {
    _deviceSubscription?.cancel();
    _scanStateSubscription?.cancel();
    super.dispose();
  } //function: Clear memory.

  Widget handlePermissionDeniedUXUI() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        UIHelper.messageOnCenterDisplay(context, "ไม่มีสิทธิ์การเข้าถึงบลูทูธ"),
        SizedBox(height: UIHelper.screenHeight(context, 0.02)),
        UIHelper.actionButton(
          "ไปที่การตั้งค่า",
          () => openAppSettings(),
          fontSize: UIHelper.screenWidth(context, 0.042, lowerLimit: 0, upperLimit: 40),
          buttonColor: UIHelper.appThemeBackground,
          height: UIHelper.screenHeight(context, 0.06),
          width: UIHelper.screenWidth(context, 0.5),
        ),
      ],
    );
  } //permissionDeniedUI

  Widget handleTurnOnBluetoothButton() {
    return UIHelper.actionButton(
      "เปิดใช้งานบลูทูธ",
      () async => await FlutterBluePlus.turnOn(),
      buttonColor: UIHelper.appThemeForeground,
      textColor: UIHelper.appThemeBackground,
      fontSize: UIHelper.screenWidth(context, 0.032, lowerLimit: 0, upperLimit: 20),
      height: UIHelper.screenHeight(context, 0.044, lowerLimit: 0, upperLimit: 24),
      width: UIHelper.screenWidth(context, 0.4, lowerLimit: 0, upperLimit: 300),
      setIcon: Icons.power_settings_new_rounded,
      iconSize: UIHelper.screenWidth(context, 0.046, lowerLimit: 0, upperLimit: 28),
    );
  } //handleBluetoothDisabledUXUI

  void handleScanDevices() async {
    await FlutterBluePlus.stopScan();

    StreamSubscription<List<ScanResult>> subscription = FlutterBluePlus.onScanResults.listen((results) {
      setState(() => _devicesList = results);
    }, onError: (e) => mounted ? UIHelper.popUpErrorMessage(context, e) : {});

    FlutterBluePlus.cancelWhenScanComplete(subscription);

    await FlutterBluePlus.startScan(
      timeout: Duration(seconds: _scanDuration),
      // withNames: [_deviceTargetName],
    );
  } //handleScanDevices

  List<Widget> pageAppBarActionsIconsUXUI() {
    return [
      Padding(
        padding: EdgeInsets.only(right: UIHelper.screenWidth(context, 0.032)),
        child: !isBluetoothTurnOn
            ? handleTurnOnBluetoothButton()
            : duringScan
            ? Padding(
                padding: const EdgeInsets.only(right: 12),
                child: CircularProgressIndicator(
                  color: UIHelper.appThemeForeground,
                  strokeWidth: 3.2,
                  constraints: BoxConstraints(maxHeight: 100, minHeight: 20, maxWidth: 100, minWidth: 20),
                ),
              )
            : IconButton(
                icon: Icon(Icons.refresh_sharp),
                iconSize: UIHelper.screenWidth(context, 0.08, lowerLimit: 0, upperLimit: 38),
                onPressed: () => handleScanDevices(), // onPress
              ),
      ),
    ];
  } //handleRefreshScanIcon

  Widget handleShowListOfFoundedDevicesUXUI() {
    return _devicesList.isEmpty
        ? UIHelper.messageOnCenterDisplay(context, "ไม่พบอุปกรณ์")
        : ListView.builder(
            itemCount: _devicesList.length,
            itemBuilder: (context, index) {
              final deviceAdvName = _devicesList[index].device.advName;
              final deviceRemoteId = _devicesList[index].device.remoteId.str;
              BluetoothDevice device = BluetoothDevice.fromId(deviceRemoteId);
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: Colors.grey.shade300, width: 1)),
                ),
                child: ListTile(
                  title: Text(deviceAdvName),
                  subtitle: Text(deviceRemoteId),
                  onTap: () => handleConnectDevice(device),
                  trailing: Icon(Icons.bluetooth),
                ),
              );
            },
          );
  } //handleScanForDevice

  Future<void> disconnectAllOldDevices() async {
    // 1. Get the list of every device currently connected to your app
    List<BluetoothDevice> connected = FlutterBluePlus.connectedDevices;

    // 2. Loop through and kill every connection
    for (BluetoothDevice device in connected) {
      try {
        await device.disconnect();
      } catch (e) {
        return;
      } //try-catch
    } //forloop
  } //function: disconnectAllOldDevices - safety

  void handleConnectDevice(BluetoothDevice device) async {
    await FlutterBluePlus.stopScan();
    await disconnectAllOldDevices();

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: UIHelper.textBold(
          "กำลังเชื่อมต่อ...",
          fontSize: UIHelper.screenWidth(context, 0.08),
          fontColor: UIHelper.appThemeForeground,
        ),
      ),
    );

    try {
      await device.connect(
        license: License.free,
        timeout: Duration(seconds: _connectionTimedOut),
        autoConnect: false, //False for dynamic to use.
      ); //process: connecting device.

      if (!mounted) return;

      Navigator.of(context, rootNavigator: true).pop();
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MatchedDevicePage(device: device)));
    } catch (error) {
      String errorMsg;

      if (!mounted) return;

      Navigator.of(context, rootNavigator: true).pop();

      if (error.toString().contains("Timed out")) {
        errorMsg = "หมดเวลาการเชื่อมต่อ โปรดเช็คว่าอุปกรณ์อยู่ในระยะการเชื่อมต่อและเปิดใช้งาน";
      } else {
        errorMsg = error.toString();
      } //process: Handle connect error.

      UIHelper.popUpErrorMessage(context, errorMsg);
    } //try-catch: catches timeouts or Bluetooth being turned off on the phone
  } //handleConnectDevice

  PreferredSizeWidget pageAppBar() {
    return AppBar(
      backgroundColor: UIHelper.appThemeBackground,
      foregroundColor: UIHelper.appThemeForeground,
      title: UIHelper.textBold(
        "ค้นหาอุปกรณ์",
        fontSize: UIHelper.screenWidth(context, 0.052, lowerLimit: 0, upperLimit: 28),
      ),
      actions: pageAppBarActionsIconsUXUI(),
    );
  } //PreferredSizeWidget: pageAppBar

  Widget pageBody() {
    if (isBluetoothSupported) {
      if (bluetoothPermissionGranted) {
        if (isBluetoothTurnOn) {
          return handleShowListOfFoundedDevicesUXUI();
        } else {
          return UIHelper.messageOnCenterDisplay(context, "บลูทูธไม่ได้เปิดใช้งาน");
        }
      } else {
        return handlePermissionDeniedUXUI();
      }
    } else {
      return UIHelper.messageOnCenterDisplay(context, "บลูทูธไม่รองรับบนอุปกรณ์นี้");
    }
  } //Widget: pageBody

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: pageAppBar(), body: pageBody());
  } //Widget: build
}//class: FindBlePageState