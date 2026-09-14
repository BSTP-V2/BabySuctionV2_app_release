//=============================================================
//    หน้า - เริ่มต้นแอพ, Bottom Navigation Bar หลัก
//=============================================================

import 'package:bstp_v2/services/suction_test_handler.dart';
import 'package:bstp_v2/services/ui_helper.dart';
import 'package:flutter/material.dart'; //ของ Flutter
import 'package:bstp_v2/pages/babies/babies_list.dart'; // class จากไฟล์หน้า Babies
import 'package:bstp_v2/pages/bluetooth/finding_devices.dart'; // class จากไฟล์หน้า ค้นหาอุปกรณ์
import 'package:device_preview/device_preview.dart'; // DevicePreview เอาไว้ทำ Responsive
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  //==========================ใช้งานปกติไม่ทำ Responsive ==========================
  runApp(const MyApp());
  //==========================ใช้งานปกติไม่ทำ Responsive ==========================

  //==========================เปิดใช้งาน DevicePreview ทำ Responsive==========================
  // runApp(
  //   DevicePreview(
  //     enabled: true,
  //     builder: (context) => MyApp(), // Wrap app
  //   ),
  // );
  //==========================เปิดใช้งาน DevicePreview ทำ Responsive==========================
} //void: main

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
} //class: MyApp

class _MyAppState extends State<MyApp> {
  int pageStackIndex = 1; // Index เลือก Stack ของหน้าแอพ
  final GlobalKey<NavigatorState> babiesNavigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    initAppFetchUnit();
  } //initState

  void initAppFetchUnit() async {
    final prefs = await SharedPreferences.getInstance();
    // ถ้ายังไม่เคยบันทึก ให้ใช้ 'mmHg' เป็นค่าเริ่มต้น (Default)
    SuctionTestHandler.currentUnit = prefs.getString('current_unit') ?? 'mmHg';
  } //function: Fetch last current that set in app.

  Widget pageAppBarAndBody() {
    return IndexedStack(
      //AppBar และ Main Body ของแอพ
      index: pageStackIndex,
      children: [
        Navigator(
          // Stack[0]: เมนู "เชื่อมต่ออุปกรณ์"
          onGenerateRoute: (settings) => MaterialPageRoute(builder: (context) => BleScanDevicesPage()),
        ),
        Navigator(
          // Stack[1]: เมนู "การบันทึกทั้งหมด"
          key: babiesNavigatorKey,
          onGenerateRoute: (settings) => MaterialPageRoute(builder: (context) => BabiesListPage()),
        ),
      ], // children
    );
  } //Widget: appBar

  Widget mainBottomNavBar() {
    return Container(
      // เมนู Bar
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: UIHelper.appThemeBackground.withAlpha(100), width: 2.4)),
      ),
      child: BottomNavigationBar(
        backgroundColor: UIHelper.appThemeBackground,
        selectedItemColor: UIHelper.appThemeForeground,
        unselectedItemColor: Color(0x99FFFFFF),
        currentIndex: pageStackIndex,
        onTap: (tapIndex) {
          if (tapIndex == 1 && pageStackIndex == 1 && !UIHelper.unAllowDirectPushToBabiesListPage) {
            babiesNavigatorKey.currentState?.popUntil((route) => route.isFirst);
          }
          setState(() => pageStackIndex = tapIndex);
        },
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.bluetooth, size: 55), label: "เชื่อมต่ออุปกรณ์"),
          BottomNavigationBarItem(icon: Icon(Icons.save_outlined, size: 55), label: "การบันทึกทั้งหมด"),
        ],
      ),
    );
  } //Widget: mainBottomNavBar

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Baby Suction 2",
      home: PopScope(
        canPop: false,
        child: Scaffold(body: pageAppBarAndBody(), bottomNavigationBar: mainBottomNavBar()),
      ),
      debugShowCheckedModeBanner: false,
    );
  } //build
}//class _MyAppState