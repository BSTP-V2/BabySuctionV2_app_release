# Baby Suction Tracker Prototype Version2

ระบบวัดและประเมินแรงดูดทารกแรกเกิดแบบเรียลไทม์ผ่านการเชื่อมต่อไร้สาย (Flutter + ESP32)

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)
![BLE](https://img.shields.io/badge/ESP32-%23E7352C.svg?style=for-the-badge&logo=espressif&logoColor=white)
![SQLite](https://img.shields.io/badge/sqlite-%2307405e.svg?style=for-the-badge&logo=sqlite&logoColor=white)
![BLE](https://img.shields.io/badge/BLE-%230082FC.svg?style=for-the-badge&logo=bluetooth&logoColor=white)

### Project Structure of Application

    application/
    ├── 📁 android/                                 # การตั้งค่าสำหรับระบบปฏิบัติการ Android
    │   ├── app/
    │   │   ├── build.gradle.kts
    │   │   └── src/
    │   │       ├── debug/
    │   │       ├── main/
    │   │       │   ├── AndroidManifest.xml
    │   │       │   ├── java/ ... /GeneratedPluginRegistrant.java
    │   │       │   ├── kotlin/ ... /MainActivity.kt
    │   │       │   └── res/                        # ไอคอน, สไตล์, และรูปหน้า Launch
    │   │       └── profile/
    │   ├── build.gradle.kts
    │   ├── gradle/
    │   ├── gradle.properties
    │   └── settings.gradle.kts
    │
    ├── 📁 ios/                                     # การตั้งค่าสำหรับระบบปฏิบัติการ iOS
    │   ├── Flutter/
    │   └── Runner/
    │       ├── AppDelegate.swift
    │       ├── Assets.xcassets/                    # AppIcon & LaunchImage
    │       ├── Base.lproj/                         # Main & LaunchScreen Storyboards
    │       ├── Info.plist
    │       └── Runner.xcodeproj / Runner.xcworkspace
    │
    ├── 📁 lib/                                     # 💡 Source Code หลักของแอปพลิเคชัน
    │   ├── main.dart                               # จุดเริ่มต้นทำงานหลักของโปรแกรม (Entry point)
    │   ├── 📁 pages/                               # ส่วนแสดงผลหน้าจอ (Screens / Pages)
    │   │   ├── 📁 babies/                          # หน้าเกี่ยวกับเด็กและการทดสอบ
    │   │   │   ├── babies_list.dart
    │   │   │   ├── baby_route_hub.dart
    │   │   │   ├── baby_test_history.dart
    │   │   │   ├── comparision_test_history.dart
    │   │   │   ├── during_test.dart
    │   │   │   ├── setup_test.dart
    │   │   │   ├── specific_test_history.dart
    │   │   │   └── sumary_test.dart
    │   │   └── 📁 bluetooth/                       # หน้าการเชื่อมต่ออุปกรณ์ Bluetooth
    │   │       ├── connected_device.dart
    │   │       └── finding_devices.dart
    │   └── 📁 services/                            # ส่วนประมวลผล Logic & Data Handlers
    │       ├── babies_list_dialog_handler.dart     # ส่วนจัดการ Dialog ของหน้ารายการทารก
    │       ├── ble_handler.dart                    # จัดการ Bluetooth Low Energy
    │       ├── database_handler.dart               # จัดการฐานข้อมูล (Local DB)
    │       ├── suction_test_handler.dart
    │       └── ui_helper.dart
    │
    ├── 📁 assets/                                  # ไฟล์ Static Resource ของแอป
    │   ├── images/
    │   │   └── git-teamwork-tip.png
    │   └── translations/                           # ไฟล์แปลภาษา (Localization)
    │       ├── en.json
    │       └── th.json
    │
    ├── 📁 images/                                  # โลโก้โปรเจกต์/แบรนดิ้ง
    │   ├── bstp2_app_logo.png
    │   └── BSTP_V2.png
    │
    ├── 📁 web/                                     # การตั้งค่ารองรับ Web Platform
    ├── 📁 linux/                                   # การตั้งค่ารองรับ Linux Platform
    ├── 📁 macos/                                   # การตั้งค่ารองรับ macOS Platform
    ├── 📁 windows/                                 # การตั้งค่ารองรับ Windows Platform
    ├── 📁 test/                                    # Unit / Widget Testing
    │   └── widget_test.dart
    │
    ├── 📄 analysis_options.yaml                    # กฎการตรวจ Linting Rules ของ Dart
    ├── 📄 devtools_options.yaml                    # การตั้งค่า Flutter DevTools
    ├── 📄 pubspec.yaml                             # ไฟล์กำหนด Dependencies & Asset config
    ├── 📄 pubspec.lock                             # ไฟล์ล็อกเวอร์ชันของ Packages
    └── 📄 README.md                                # เอกสารอธิบายโปรเจกต์