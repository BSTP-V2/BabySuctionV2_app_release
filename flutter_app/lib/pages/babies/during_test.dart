import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:bstp_v2/pages/babies/baby_test_history.dart';
import 'package:bstp_v2/pages/babies/sumary_test.dart';
import 'package:bstp_v2/services/suction_test_handler.dart';
import 'package:flutter/material.dart';
import 'package:bstp_v2/services/ui_helper.dart';
import 'package:bstp_v2/services/ble_handler.dart';
import 'package:circular_countdown_timer/circular_countdown_timer.dart';

class DuringTestPage extends StatefulWidget {
  final Map<String, dynamic> baby;
  final int setMinute;
  final int setSecond;

  const DuringTestPage({super.key, required this.baby, required this.setMinute, required this.setSecond});

  @override
  State<DuringTestPage> createState() => _DuringTestPageState();
}

class _DuringTestPageState extends State<DuringTestPage> {
  static final Color _panelBackground = Colors.blueGrey.shade50;
  final CountDownController _timerController = CountDownController();
  bool _duringTest = false;
  StreamSubscription? _receiveSensorValueListener;
  final Stopwatch _testStopwatch = Stopwatch();

  double currentValue = 0;
  bool isSuctioning = false;
  List<double> lastCycleValues = [];
  List<double> allAvgValuesEachCycle = [];

  Map<String, dynamic> dataOfTest = {
    'baby_id': null, 'measure_at': "", 'max_value': 0.0, 'avg_value': 0.0,
    'min_value': 0.0, 'suction_count': 0, 'test_duration': "", 'graph': <List<double>>[],
  };

  @override
  void initState() {
    super.initState();
    UIHelper.unAllowDirectPushToBabiesListPage = true;
    BleHandler.isConnected.addListener(handleDeviceDisconnected);
    handleStartTest();
    dataOfTest['baby_id'] = widget.baby['id'];
  }

  @override
  void dispose() {
    if (_duringTest) handleClearOnFinish();
    super.dispose();
  }

  void handleStartTest() async {
    try {
      await BleHandler.deviceServiceChar['sensor_value']!.setNotifyValue(true);
      if (mounted) {
        UIHelper.showTextDialogInSpecificTime(context, onTimeOut: () {
          handleStartStopWatchOfTest();
          handleOnReceiveValue();
          setState(() => _timerController.start());
          _duringTest = true;
          dataOfTest['measure_at'] = DateTime.now().toIso8601String();
        }, msg: "เริ่มการทดสอบ", timeOutSeconds: 1);
      }
    } catch (e) {
      if (mounted) { Navigator.pop(context); UIHelper.popUpErrorMessage(context, e); }
    }
  }

  void handleStartStopWatchOfTest() { _testStopwatch.reset(); _testStopwatch.start(); }

  Future<void> handleClearOnFinish() async {
    try { await BleHandler.deviceServiceChar['test_state']!.write([0x00], withoutResponse: false); } catch (e) {}
    BleHandler.isConnected.removeListener(handleDeviceDisconnected);
    await BleHandler.deviceServiceChar['sensor_value']?.setNotifyValue(false);
    _receiveSensorValueListener?.cancel();
  }

  void handleDeviceDisconnected() {
    if (!BleHandler.isConnected.value) { Navigator.pop(context); UIHelper.unAllowDirectPushToBabiesListPage = false; }
  }

  void handleOnReceiveValue() {
    final char = BleHandler.deviceServiceChar['sensor_value'];
    if (char != null) {
      _receiveSensorValueListener = char.onValueReceived.listen((value) {
        if (value.isNotEmpty) {
          try {
            String decodedString = utf8.decode(value, allowMalformed: true).trim();
            double getPressure = double.tryParse(decodedString) ?? 0.0;

            if (mounted) {
              setState(() => currentValue = getPressure);
              (dataOfTest['graph'] as List).add([_testStopwatch.elapsedMilliseconds / 1000, getPressure]);
              handleSuctionCycle(getPressure);
            }
          } catch (e) { debugPrint("Error receiving: $e"); }
        }
      });
    }
  }

  void handleSuctionCycle(final double getPressure) {
    if (getPressure <= -22.0 && !isSuctioning) { 
      isSuctioning = true; 
      dataOfTest['suction_count']++; 
    } else if (getPressure > -10.0 && isSuctioning) {
      isSuctioning = false;
      if (lastCycleValues.isNotEmpty) {
        // ใช้ min(lastCycleValues) เพื่อหาค่าที่ติดลบมากที่สุดในรอบนั้น
        double peakOfLastCycle = lastCycleValues.reduce(min);
        findMinMaxValue(peakOfLastCycle);
        allAvgValuesEachCycle.add(findAverage(lastCycleValues));
        lastCycleValues.clear();
      }
    }
    if (isSuctioning) lastCycleValues.add(getPressure);
  }

 
  void findMinMaxValue(double peakOfCurrentCycle) {
  
    if (dataOfTest['min_value'] == 0 || peakOfCurrentCycle < dataOfTest['min_value']) {
      dataOfTest['min_value'] = peakOfCurrentCycle;
    }
    
    if (dataOfTest['max_value'] == 0 || peakOfCurrentCycle > dataOfTest['max_value']) {
      dataOfTest['max_value'] = peakOfCurrentCycle; 
    }
  }

  double findAverage(List<double> valueList) => valueList.isEmpty ? 0.0 : valueList.reduce((a, b) => a + b) / valueList.length;

  void handleTestComplete() async {
    await handleClearOnFinish();
    _duringTest = false;
    int timeSec = (_testStopwatch.elapsedMilliseconds / 1000).toInt();
    dataOfTest['test_duration'] = "${(timeSec ~/ 60).toString().padLeft(2, '0')}:${(timeSec % 60).toString().padLeft(2, '0')}";
    dataOfTest['avg_value'] = findAverage(allAvgValuesEachCycle);

    if (mounted) {
      if (dataOfTest['suction_count'] != 0) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => SumaryOfTestPage(baby: widget.baby, dataOfTest: dataOfTest)));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => BabyTestHistoryPage(baby: widget.baby)));
        UIHelper.justAlert(context, "ไม่มีการดูดเกิดขึ้น");
      }
    }
  }

  Widget currentValuePanelUXUI(double titleFontSize, double subtitleFontSize, double panelWidth) {
    Color valColor = SuctionTestHandler.getColorOfValue(currentValue);
    double val = SuctionTestHandler.doubleAsFixed(SuctionTestHandler.convertHPaToCurrentUnit(currentValue), fixed: 1);
    return Container(
      decoration: BoxDecoration(color: _panelBackground, borderRadius: BorderRadius.circular(20)), width: panelWidth,
      child: Padding(padding: EdgeInsets.symmetric(vertical: UIHelper.screenHeight(context, 0.032)),
        child: Column(children: [
          UIHelper.textBold("สถานะแรงดูด", fontSize: subtitleFontSize), SizedBox(height: UIHelper.screenHeight(context, 0.012)),
          UIHelper.textBold("$val ${SuctionTestHandler.currentUnit}", fontSize: titleFontSize, fontColor: valColor),
        ]),
      ),
    );
  }

  Widget timerPanelUXUI(double titleFontSize, double subtitleFontSize, double panelWidth) {
    return Container(
      decoration: BoxDecoration(color: _panelBackground, borderRadius: BorderRadius.circular(20)), width: panelWidth,
      child: Padding(padding: EdgeInsets.symmetric(vertical: UIHelper.screenHeight(context, 0.032)),
        child: Column(children: [
          UIHelper.textBold("เวลาที่เหลือ", fontSize: UIHelper.screenWidth(context, 0.054)),
          SizedBox(height: UIHelper.screenHeight(context, 0.04)),
          CircularCountDownTimer(controller: _timerController, autoStart: false,
            width: UIHelper.screenWidth(context, 0.4), height: UIHelper.screenWidth(context, 0.4),
            duration: (widget.setMinute * 60) + widget.setSecond,
            fillColor: Colors.blueGrey.shade100, ringColor: UIHelper.appThemeBackground,
            isReverse: true, textFormat: CountdownTextFormat.MM_SS,
            strokeWidth: UIHelper.screenWidth(context, 0.052),
            textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: titleFontSize), onComplete: () => handleTestComplete(),
          ),
        ]),
      ),
    );
  }

  Widget sumaryTestNowButton(double panelWidth) {
    return UIHelper.actionButton("สรุปผลทันที",
      () => UIHelper.twoStepConfirmActionDialog(context, "ยืนยันเพื่อสรุปผลทันที", onConfirm: () => handleTestComplete()),
      borderRadius: 100, buttonColor: Colors.red.shade700, height: UIHelper.screenHeight(context, 0.07), width: UIHelper.screenWidth(context, 0.46),
    );
  }

  @override
  Widget build(BuildContext context) {
    double panelWidth = UIHelper.screenWidth(context, 0.74);
    return PopScope(canPop: false, onPopInvokedWithResult: (didPop, _) {
      if (didPop) return;
      UIHelper.twoStepConfirmActionDialog(context, "ยืนยันออกจากการทดสอบ?", onConfirm: () async {
        Navigator.pop(context); await handleClearOnFinish(); UIHelper.unAllowDirectPushToBabiesListPage = false;
      });
    }, child: Scaffold(appBar: UIHelper.minimalAppBar(" : ${widget.baby['hn']}", titleIcon: Icons.account_circle_outlined),
      body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        currentValuePanelUXUI(UIHelper.screenWidth(context, 0.07), UIHelper.screenWidth(context, 0.04), panelWidth),
        SizedBox(height: UIHelper.screenHeight(context, 0.032)),
        timerPanelUXUI(UIHelper.screenWidth(context, 0.07), UIHelper.screenWidth(context, 0.04), panelWidth),
        SizedBox(height: UIHelper.screenHeight(context, 0.032)),
        sumaryTestNowButton(panelWidth),
      ])),
    ));
  }
}