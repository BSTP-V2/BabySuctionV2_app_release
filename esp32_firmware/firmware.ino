
#include <BLEDevice.h>
#include <BLEUtils.h>
#include <BLEServer.h>
#include <BLE2902.h>
#include <Wire.h>


#define INA226_ADDR 0x44
#define MPRLS_ADDR  0x18
#define SERVICE_UUID "FF10"
#define SENSOR_UUID  "FF11"
#define BATTERY_UUID "FF14"
#define TIMER_UUID   "FF13"

const float MPRLS_MIN_RAW = 1677722.0;
const float MPRLS_MAX_RAW = 15099494.0;
const float MPRLS_MIN_PSI = 0.0;
const float MPRLS_MAX_PSI = 25.0;
const float PSI_TO_MMHG   = 51.7149;
const float BAT_MIN_V     = 3.2;
const float BAT_MAX_V     = 4.2;


const int ledPin = 7;


BLECharacteristic *pCharacteristicSensor;
BLECharacteristic *pCharacteristicBattery;
BLECharacteristic *pCharacteristicTimer;
BLEServer *pServer = NULL;

bool deviceConnected = false;
bool is_running      = false;

float baseline_hPa      = 0;
float pressureBuffer[5] = {0, 0, 0, 0, 0};
int bufferIndex         = 0;

unsigned long lastSensorTime  = 0;
unsigned long lastBatteryTime = 0;


float readMPRLS_Pressure();
void startSystem();
void stopSystem();




float readSensorAverage(int samples) {
  float sum = 0;
  for (int i = 0; i < samples; i++) {
    sum += readMPRLS_Pressure();
    delay(20); 
  }
  return sum / samples;
}

float readMPRLS_Pressure() {
  Wire.beginTransmission(MPRLS_ADDR);
  Wire.write(0xAA); Wire.write(0x00); Wire.write(0x00);
  Wire.endTransmission();
  delay(10);
  Wire.requestFrom((uint8_t)MPRLS_ADDR, (uint8_t)4);
  if (Wire.available() == 4) {
    Wire.read();
    uint32_t raw = (uint32_t)Wire.read() << 16 | (uint32_t)Wire.read() << 8 | Wire.read();
    float psi = (raw - MPRLS_MIN_RAW) * (MPRLS_MAX_PSI - MPRLS_MIN_PSI) / (MPRLS_MAX_RAW - MPRLS_MIN_RAW);
    return psi * PSI_TO_MMHG;
  }
  return 0.0;
}

float readINA226_Voltage() {
  Wire.beginTransmission(INA226_ADDR);
  Wire.write(0x02);
  Wire.endTransmission(false);
  Wire.requestFrom((uint8_t)INA226_ADDR, (uint8_t)2);
  if (Wire.available() == 2) {
    uint16_t raw = (Wire.read() << 8) | Wire.read();
    return raw * 0.00125;
  }
  return 3.7;
}

int getBatteryPercent(float voltage) {
  return constrain((int)((voltage - BAT_MIN_V) / (BAT_MAX_V - BAT_MIN_V) * 100), 0, 100);
}


void startSystem() {
  is_running = true;
  float initialPressure = readMPRLS_Pressure();
  for (int i = 0; i < 5; i++) pressureBuffer[i] = initialPressure;
  bufferIndex = 0;
  Serial.println("System: START");
}

void stopSystem() {
  is_running = false;
  Serial.println("System: STOP");
}

float getFilteredPressure() {
  pressureBuffer[bufferIndex] = readMPRLS_Pressure();
  bufferIndex = (bufferIndex + 1) % 5;
  
  float sum = 0;
  for (float val : pressureBuffer) sum += val;
  return (sum / 5.0) - baseline_hPa;
}





class TimerCallbacks : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic *pCharacteristic) {
    if (pCharacteristic->getValue()[0] == 0x01) startSystem();
    else if (pCharacteristic->getValue()[0] == 0x30) stopSystem();
  }
};

class MyServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer* pServer)    { deviceConnected = true; }
  void onDisconnect(BLEServer* pServer) { deviceConnected = false; stopSystem(); BLEDevice::startAdvertising(); }
};

// --- Main ---
void setup() {
  Serial.begin(115200);
  Wire.begin(8, 9);
 
  pinMode(ledPin, OUTPUT);
  digitalWrite(ledPin, HIGH);
  
  baseline_hPa = readSensorAverage(20); 

  BLEDevice::init("ฺฺBSTP_V2");
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());

  BLEService *pService = pServer->createService(SERVICE_UUID);
  pCharacteristicSensor  = pService->createCharacteristic(SENSOR_UUID, BLECharacteristic::PROPERTY_NOTIFY);
  pCharacteristicBattery = pService->createCharacteristic(BATTERY_UUID, BLECharacteristic::PROPERTY_NOTIFY);
  pCharacteristicTimer   = pService->createCharacteristic(TIMER_UUID, BLECharacteristic::PROPERTY_WRITE);
  
  pCharacteristicTimer->setCallbacks(new TimerCallbacks());
  pCharacteristicSensor->addDescriptor(new BLE2902());
  pCharacteristicBattery->addDescriptor(new BLE2902());

  pService->start();
  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->start();
}

void loop() {
  unsigned long currentMillis = millis();

 
  if (deviceConnected && (currentMillis - lastBatteryTime >= 5000)) {
    lastBatteryTime = currentMillis;
    pCharacteristicBattery->setValue(String(getBatteryPercent(readINA226_Voltage())).c_str());
    pCharacteristicBattery->notify();
  }

  if (deviceConnected && is_running && (currentMillis - lastSensorTime >= 500)) {
    lastSensorTime = currentMillis;
    pCharacteristicSensor->setValue(String(getFilteredPressure(), 1).c_str());
    pCharacteristicSensor->notify();
  }
}