# 🧮 System Algorithms & Pseudo Code

เอกสารนี้อธิบายตรรกะการทำงานหลัก (Core Logic) ของโปรเจกต์ **BSTP V2 (Infant Suction Measurement System)** ทั้งในส่วนของ **Mobile Application (Flutter)** และ **Hardware Control (ESP32 Firmware)**

---

## 📱 1. Mobile Application Logic (Flutter)

### 1.1 State & Navigation Flow
สถาปัตยกรรมระดับบนสุดในการจัดการ Navigation และ State หลักของแอปพลิเคชัน

```pseudocode
GLOBAL dateTimeSortDirection = "ASC"   // สลับทิศทางการเรียงตามวันที่
GLOBAL currentUnit = "mmHg"            // หน่วยการแสดงผลปัจจุบัน (mmHg, kPa, N/m2)

FUNCTION MainProcess()
    IF press_baby_list_tab THEN
        CALL DisplayBabyList()
    ELSE IF press_bluetooth_tab THEN
        CALL ScanBluetoothScreen()
    ENDIF
END FUNCTION

FUNCTION DisplayBabyList()
    babyList = CALL SelectAllBabies()

    IF babyList IS EMPTY THEN
        CALL ShowTextOnDisplay("ยังไม่มีรายชื่อในฐานข้อมูล")
    ELSE
        FOR EACH baby IN babyList
            CALL CreateDataTile(baby)
        ENDFOR
    ENDIF

    IF press_add_baby_button THEN
        CALL ShowAddBabyDialog()
    ENDIF

    IF long_press_on_baby(babyId) THEN
        CALL ShowEditOrDeleteDialog(babyId)
    ENDIF

    IF press_on_baby(babyId) THEN
        babyData = CALL SelectBabyById(babyId)
        CALL NavigateToOptionMenu(babyData)
    ENDIF
END FUNCTION
```

---

### 1.2 Real-time Suction Peak & Cycle Detection Algorithm
ตรรกะการจับรอบการดูดของทารก (Suction Cycle) จาก Stream ข้อมูล BLE โดยนับรอบเมื่อแรงดูด $\ge 22\text{ mmHg}$

> **Note:** ระบบจะจัดเก็บข้อมูลกราฟดิบและค่าสถิติในฐานข้อมูลด้วยหน่วย `mmHg` เสมอ และจะแปลงหน่วยเป็น `kPa` หรือ `N/m^2` เฉพาะตอนแสดงผลบน UI เท่านั้น

```pseudocode
FUNCTION NavigateToTestScreen(babyData, testDuration)
    startTime = CALL GetCurrentTime()
    CALL SendBluetoothCommand("START")
    
    suctionCount = 0
    peakOfEveryCycle = []    // เก็บค่าสูงสุดของแต่ละรอบการดูด
    graphData = []           // เก็บ [elapsedTime, rawValue] ทุกค่า
    currentCycle = []        // เก็บค่าที่ >= 22 mmHg ในรอบปัจจุบัน
    inCycle = FALSE
    elapsedTime = 0
    earlyStop = FALSE

    WHILE elapsedTime < testDuration AND earlyStop == FALSE
        rawValue = CALL ListenBluetoothValue()
        elapsedTime = CALL GetElapsedTime(startTime)
        
        IF rawValue IS NOT NULL THEN
            graphData.append([elapsedTime, rawValue])
            
            // ตรวจจับรอบการดูด (เกณฑ์การเริ่มรอบเมื่อค่า >= 22 mmHg)
            IF rawValue >= 22 THEN
                IF inCycle == FALSE THEN
                    inCycle = TRUE
                ENDIF
                currentCycle.append(rawValue)
            ELSE
                IF inCycle == TRUE THEN
                    // สิ้นสุดรอบการดูด -> คำนวณหาจุด Peak ของรอบนั้น
                    suctionCount = suctionCount + 1
                    peak = CALL FindMaximum(currentCycle)
                    peakOfEveryCycle.append(peak)
                    currentCycle = []
                    inCycle = FALSE
                ENDIF
            ENDIF
        ENDIF

        IF press_early_stop_button THEN
            earlyStop = TRUE
        ENDIF
    ENDWHILE

    CALL SendBluetoothCommand("STOP")

    IF suctionCount == 0 THEN
        CALL DisplayHistoryScreen(babyData.id)
        RETURN
    ENDIF

    summary = CALL CalculateSummary(peakOfEveryCycle, suctionCount)
    testData = CALL CreateTestData(startTime, elapsedTime, graphData)
    record = CALL MERGE(testData, summary)

    CALL NavigateToResultsScreen(babyData, record)
END FUNCTION
```

---

### 1.3 Unit Conversion Utilities
ฟังก์ชันสำหรับการแปลงหน่วยความดันในชั้นแสดงผล (Display Layer)

```pseudocode
FUNCTION ConvertUnit(valueInMmHg, targetUnit)
    IF targetUnit == "mmHg" THEN
        RETURN valueInMmHg
    ELSE IF targetUnit == "kPa" THEN
        RETURN valueInMmHg * 0.133322
    ELSE IF targetUnit == "N/m2" THEN
        RETURN valueInMmHg * 133.322
    ENDIF
END FUNCTION

FUNCTION ConvertGraphData(graphDataArray, targetUnit)
    convertedArray = []
    FOR EACH point IN graphDataArray
        timestamp = point[0]
        rawValue = point[1]
        convertedValue = CALL ConvertUnit(rawValue, targetUnit)
        convertedArray.append([timestamp, convertedValue])
    ENDFOR
    RETURN convertedArray
END FUNCTION
```

---

## 📟 2. ESP32 Firmware Logic (Microcontroller)

### 2.1 Deep Sleep & Wakeup Intent Verification
การจัดการพลังงานและการป้องกันอุบัติเหตุจากการกดเปิดเครื่องโดยไม่ตั้งใจ (Accidental Wakeup)

```pseudocode
FUNCTION MainProcess()
    CALL CheckWakeupIntent()
    
    // คาลิเบรตจุดศูนย์ (Zero Point Calibration) ก่อนเริ่มทำงาน
    zeroPressure = CALL CalibrateZeroPoint()

    CALL EnableBluetoothAdvertising()

    // รอการเชื่อมต่อจากแอปพลิเคชันภายใน 20 วินาที
    connected = CALL WaitForConnection(timeoutSeconds = 20)
    
    IF connected == FALSE THEN
        CALL GoToSleep()
        RETURN
    ENDIF

    CALL SetLedSolid()
    CALL ConnectedLoop()
END FUNCTION

FUNCTION CheckWakeupIntent()
    wakeupReason = READ_HARDWARE_WAKEUP_CAUSE()
    pinState = READ_PIN(WAKE_PIN)

    // หากไม่ได้ปลุกจากขาภายนอก หรือขานั้นอยู่ในสถานะ LOW ให้กลับไปหลับทันที
    IF wakeupReason ≠ EXTERNAL_PIN_WAKEUP AND pinState == LOW THEN
        CALL GoToSleep()
    ENDIF
END FUNCTION
```

---

### 2.2 Moving Average Pressure Smoothing
การกรองสัญญาณรบกวน (Noise Filtering) ด้วยวิธี Moving Average 5 จุด ล่าสุด ก่อนส่งค่าผ่าน BLE

```pseudocode
GLOBAL zeroPressure = 0
GLOBAL pressureBuffer[5] = {0, 0, 0, 0, 0}
GLOBAL bufferIndex = 0

FUNCTION StreamSmoothedPressure()
    newReading = READ_PRESSURE_SENSOR()
    pressureBuffer[bufferIndex] = newReading
    bufferIndex = (bufferIndex + 1) MOD 5

    total = 0
    FOR EACH value IN pressureBuffer
        total = total + value
    ENDFOR
    average = total / 5

    // คำนวณหาค่าแรงดูดที่ต่างจากจุด Zero
    IF average >= zeroPressure THEN
        suctionValue = 0
    ELSE
        suctionValue = zeroPressure - average
    ENDIF

    CALL BLE_SendPressure(suctionValue)
END FUNCTION
```

---

### 2.3 Battery Level & Protection Logic
การคำนวณเปอร์เซ็นต์แบตเตอรี่ Li-Po (3.2V - 4.2V) พร้อมระบบป้องกันค่าความผิดพลาด

```pseudocode
FUNCTION ReportBatteryLevel()
    voltage = READ_BATTERY_VOLTAGE()
    maxVoltage = 4.2
    minVoltage = 3.2
    errorThreshold = 4.35   // เกณฑ์ตรวจจับค่าผิดปกติฮาร์ดแวร์

    IF voltage > errorThreshold THEN
        batteryPercent = 0
    ELSE
        batteryPercent = ((voltage - minVoltage) / (maxVoltage - minVoltage)) * 100
        IF batteryPercent < 0 THEN batteryPercent = 0
        IF batteryPercent > 100 THEN batteryPercent = 100
    ENDIF
    
    CALL BLE_SendBatteryLevel(batteryPercent)
END FUNCTION
```