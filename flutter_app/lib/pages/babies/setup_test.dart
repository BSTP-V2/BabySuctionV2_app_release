import 'package:bstp_v2/pages/babies/during_test.dart';
import 'package:bstp_v2/services/ble_handler.dart';
import 'package:bstp_v2/services/ui_helper.dart';
import 'package:flutter/material.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:bstp_v2/pages/babies/baby_route_hub.dart';

class TestDurationConfigPage extends StatefulWidget {
  final Map<String, dynamic> baby;

  const TestDurationConfigPage({super.key, required this.baby});

  @override
  State<TestDurationConfigPage> createState() => _TestDurationConfigPageState();
} //class: TestDurationConfigPage

class _TestDurationConfigPageState extends State<TestDurationConfigPage> {
  int setMinute = 0;
  int setSecond = 30;
  bool minuteIs15 = false;

  Widget customEachNumberPicker(
    int setValue,
    String title,
    int limitValue,
    Function(int) newOnChange, {
    required int step,
  }) {
    Color borderColor = Colors.grey.shade400;

    return Column(
      children: [
        UIHelper.textBold(
          title,
          fontSize: UIHelper.screenWidth(context, 0.044, lowerLimit: 0, upperLimit: 46),
          fontColor: Colors.grey.shade800,
        ),
        SizedBox(height: UIHelper.screenHeight(context, 0.01)),
        NumberPicker(
          step: step,
          minValue: 0,
          maxValue: limitValue,
          value: setValue,
          itemHeight: UIHelper.screenHeight(context, 0.068, lowerLimit: 0, upperLimit: 140),
          itemWidth: UIHelper.screenWidth(context, 0.36, lowerLimit: 0, upperLimit: 360),
          infiniteLoop: true,
          zeroPad: true,
          textStyle: TextStyle(fontSize: UIHelper.screenWidth(context, 0.036), color: Colors.grey.shade700),
          selectedTextStyle: TextStyle(
            color: Colors.grey.shade800,
            fontWeight: FontWeight.bold,
            fontSize: UIHelper.screenWidth(context, 0.064, lowerLimit: 0, upperLimit: 70),
          ),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: borderColor),
              bottom: BorderSide(color: borderColor),
            ),
          ),
          onChanged: (value) => setState(() => newOnChange(value)),
        ),
      ],
    );
  } //Widget: customNumberPicker

  Widget customEachSetTimeButton(String theTime) {
    double btnWidthHeight = UIHelper.screenWidth(context, 0.22, lowerLimit: 0, upperLimit: 200);

    List<String> parts = theTime.split(":");

    int minInt = int.parse(parts[0]);
    int secInt = int.parse(parts[1]);

    return UIHelper.actionButton(
      theTime,
      () => setState(() {
        setMinute = minInt;
        setSecond = secInt;
      }),
      buttonColor: UIHelper.appThemeBackground,
      width: btnWidthHeight,
      height: btnWidthHeight,
      fontSize: UIHelper.screenWidth(context, 0.04, lowerLimit: 0, upperLimit: 40),
      shadowOn: true,
      borderRadius: btnWidthHeight,
    );
  } //function: Return Time Button.

  Widget numberPickerPanelUXUI() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        customEachNumberPicker(setMinute, "นาที", 15, (value) {
          setMinute = value;
          if (setMinute == 15) {
            setState(() {
              minuteIs15 = true;
            });
          } else {
            setState(() => minuteIs15 = false);
          }
        }, step: 1),
        customEachNumberPicker(minuteIs15 ? 0 : setSecond, "วินาที", 50, (value) => setSecond = value, step: 10),
      ],
    );
  } //functino: Return Number Picker Panel.

  Widget includeTimeButtonUXUI() {
    double rowGap = UIHelper.screenWidth(context, 0.068, lowerLimit: 0, upperLimit: 68);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        customEachSetTimeButton("00:30"),
        SizedBox(width: rowGap),
        customEachSetTimeButton("01:00"),
        SizedBox(width: rowGap),
        customEachSetTimeButton("05:00"),
      ],
    );
  } //function: Return Time Button Panel.

  Widget includeActionButtonPanelUXUI() {
    double btnWidth = UIHelper.screenWidth(context, 0.36, lowerLimit: 0, upperLimit: 326);
    double btnHeight = UIHelper.screenHeight(context, 0.072, lowerLimit: 0, upperLimit: 120);
    double btnFontSize = UIHelper.screenWidth(context, 0.04, lowerLimit: 0, upperLimit: 40);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        UIHelper.actionButton(
          "ย้อนกลับ",
          () => Navigator.canPop(context)
              ? Navigator.pop(context)
              : Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => BabyRouteHubPage(baby: widget.baby)),
                ),
          buttonColor: Colors.grey.shade800,
          width: btnWidth,
          height: btnHeight,
          shadowOn: true,
          fontSize: btnFontSize,
        ), //Go back button
        SizedBox(width: UIHelper.screenWidth(context, 0.06)),
        UIHelper.actionButton(
          "เริ่มทดสอบ",
          () {
            bool sensorValidation =
                (BleHandler.deviceServiceChar['sensor_value'] != null);


                // (BleHandler.deviceServiceChar['sensor_value'] != null &&
                // BleHandler.deviceServiceChar['test_state'] != null);




            if (BleHandler.isConnected.value == false && sensorValidation == false) {
              UIHelper.popUpErrorMessage(context, "ยังไม่ได้เชื่อมต่ออุปกรณ์");
            } else if ((setMinute == 0) && (setSecond == 0)) {
              UIHelper.popUpErrorMessage(context, "โปรดเลือกเวลาทดสอบให้เหมาะสม");
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      DuringTestPage(baby: widget.baby, setMinute: setMinute, setSecond: minuteIs15 ? 0 : setSecond),
                ),
              );
            }
          },
          buttonColor: Colors.green,
          width: btnWidth,
          height: btnHeight,
          shadowOn: true,
          fontSize: btnFontSize,
          setIcon: Icons.timer_sharp,
          iconSize: UIHelper.screenWidth(context, 0.06, lowerLimit: 0, upperLimit: 50),
        ), //Start test button.
      ],
    );
  } //function: routeButtonPanel

  Widget pageBody() {
    double columnGap = UIHelper.screenHeight(context, 0.036);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          UIHelper.textBold(
            "จับเวลาทดสอบ",
            fontSize: UIHelper.screenWidth(context, 0.072, lowerLimit: 0, upperLimit: 70),
            fontColor: UIHelper.appThemeBackground,
          ),
          SizedBox(height: columnGap),
          numberPickerPanelUXUI(),
          SizedBox(height: columnGap),
          includeTimeButtonUXUI(),
          SizedBox(height: columnGap),
          includeActionButtonPanelUXUI(),
        ],
      ),
    );
  } //function: Return Body.

  PreferredSizeWidget pageAppBar() {
    return UIHelper.minimalAppBar(
      " : ${widget.baby['hn']}",
      titleIcon: Icons.account_circle_outlined,
      action: UIHelper.measureUnitOptionButton(context, askForConfirm: false, () => setState(() {})),
    );
  } //function: Return AppBar.

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: pageAppBar(), body: pageBody());
  }
}//class: ConfigSuctionTimePage