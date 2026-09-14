//=============================================================
//    ฟังก์ชันสำหรับ UX/UI ที่ใช้งานบ่อย ( ทำให้เขียนโค้ดสั้นลงในแต่ละหน้า )
//=============================================================

import 'package:shared_preferences/shared_preferences.dart';
import 'package:bstp_v2/services/suction_test_handler.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class UIHelper {
  const UIHelper();

  static const Color appThemeBackground = Color(0xFF00A8EA);
  static const Color appThemeForeground = Color(0xFFFFFFFF);
  static bool unAllowDirectPushToBabiesListPage = false;

  static List<Color> colorsByIndex = [
    UIHelper.appThemeBackground,
    Colors.red,
    Colors.green,
    Colors.yellow.shade700,
    Colors.purple.shade400,
  ];

  static double screenWidth(BuildContext context, double width, {double? lowerLimit, double? upperLimit}) {
    double screenWidth = MediaQuery.of(context).size.width * width;
    if (lowerLimit != null && upperLimit != null) {
      return screenWidth.clamp(lowerLimit, upperLimit);
    }
    return screenWidth;
  } //double: screenWidth

  static double screenHeight(BuildContext context, double height, {double? lowerLimit, double? upperLimit}) {
    double screenHeight = MediaQuery.of(context).size.height * height;
    if (lowerLimit != null && upperLimit != null) {
      return screenHeight.clamp(lowerLimit, upperLimit);
    }
    return screenHeight;
  } //double: screenHeight

  static Widget textBold(String text, {double? fontSize, Color? fontColor, TextAlign? textAlign}) {
    return Text(
      text,
      style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: fontColor),
      textAlign: textAlign,
    );
  } //Widget: textAndBold

  static void showTextDialogInSpecificTime(
    BuildContext context, {
    required VoidCallback onTimeOut,
    required String msg,
    required int timeOutSeconds,
    fontSizePercent = 0.08,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        Future.delayed(Duration(seconds: timeOutSeconds), () {
          if (context.mounted) {
            if (Navigator.canPop(context)) {
              Navigator.of(context, rootNavigator: true).pop();

              onTimeOut();
            }
          } //process: After 1s will start test.
        });

        return Center(
          child: UIHelper.textBold(
            msg,
            textAlign: TextAlign.center,
            fontSize: UIHelper.screenWidth(context, fontSizePercent),
            fontColor: UIHelper.appThemeForeground,
          ),
        );
      },
    );
  } //functino: Show text dialog in specific time period.

  static Widget actionButton(
    String text,
    VoidCallback onPressed, {
    Color buttonColor = const Color(0xFF5C5C5C),
    Color textColor = UIHelper.appThemeForeground,
    IconData? setIcon,
    double iconSize = 0,
    double width = 220,
    double height = 64,
    double fontSize = 18,
    bool shadowOn = false,
    bool iconAtEnd = false,
    double borderRadius = 100,
  }) {
    return TextButton.icon(
      iconAlignment: iconAtEnd ? IconAlignment.end : IconAlignment.start,
      icon: Icon(setIcon, size: iconSize),
      onPressed: onPressed,
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius)),
        backgroundColor: buttonColor,
        foregroundColor: textColor,
        shadowColor: shadowOn ? Colors.black : null,
        elevation: 4,
        minimumSize: Size(width, height),
        textStyle: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
      ),
      label: UIHelper.textBold(text),
    );
  } //Widget: actionButton

  static Widget cancelButton(
    BuildContext context, {
    FontWeight? fontWeight,
    double fontSize = 20,
    double? width,
    double? height,
    String title2StepConfirm = "ยืนยันยกเลิก?",
    bool enable2StepConfirm = false,
  }) {
    return TextButton(
      //enable2StepConfirm = true จะขึ้นถามให้กดยืนยันการทำรายการ ยังใช้งานกับ textField ไม่ได้เพราะไม่รู้จะส่ง true false มาแบบง่ายๆยังไง
      onPressed: () async {
        if (enable2StepConfirm == true) {
          final bool? action = await twoStepConfirmActionDialog(context, title2StepConfirm, onConfirm: () {});
          if (!context.mounted) return;
          if (action == true) Navigator.pop(context);
        } else {
          if (!context.mounted) return;
          Navigator.of(context).pop();
        }
      },
      style: TextButton.styleFrom(
        backgroundColor: Colors.grey.shade800,
        foregroundColor: Colors.white,
        minimumSize: Size(width ?? 0, height ?? 0),
        textStyle: TextStyle(fontSize: fontSize, fontWeight: fontWeight),
      ),
      child: const Text("ยกเลิก"),
    );
  } //Widget: cancelButton

  static Widget messageOnCenterDisplay(BuildContext context, String msg) {
    return Center(
      child: UIHelper.textBold(
        msg,
        fontColor: Colors.grey.shade700,
        fontSize: UIHelper.screenWidth(context, 0.042, lowerLimit: 0, upperLimit: 40),
      ),
    );
  } //messageOnCenterDisplay

  static void justAlert(BuildContext context, String alertMsg) {
    if (!context.mounted) return;
    double fontSize = UIHelper.screenWidth(context, 0.05, lowerLimit: 0, upperLimit: 36);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          alertMsg,
          style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
        ),
        actions: [
          Center(
            child: TextButton(
              style: TextButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
                foregroundColor: Colors.white,
                backgroundColor: Colors.grey[800],
                shape: RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(14)),
              ),
              child: Text(
                "ตกลง",
                style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  } //justAlert

  static void popUpErrorMessage(BuildContext context, Object error) {
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("ไม่สามารถทำรายการได้", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        content: Text("เกิดข้อผิดพลาด: $error"),
        actions: [
          Center(
            child: TextButton(
              style: TextButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
                foregroundColor: Colors.white,
                backgroundColor: Colors.grey[800],
                shape: RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(14)),
              ),
              child: const Text("ตกลง", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  } //: errorAlert

  static Future<bool?> twoStepConfirmActionDialog(
    BuildContext context,
    String title, {
    Color confirmBtnColor = const Color(0xFFC91B1B),
    double fontSize = 20,
    double? btnGap,
    FontWeight? btnFontWeight,
    double? btnWidth,
    double? btnHeight,
    Widget? content,
    required VoidCallback onConfirm,
    bool autoScale = true,
  }) async {
    if (!context.mounted) return null;
    fontSize = autoScale ? UIHelper.screenWidth(context, 0.034, lowerLimit: 18, upperLimit: double.infinity) : fontSize;
    btnWidth = autoScale ? UIHelper.screenWidth(context, 0.18, lowerLimit: 106, upperLimit: double.infinity) : btnWidth;
    btnGap = autoScale ? UIHelper.screenWidth(context, 0.02) : btnGap;

    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Center(
          child: Text(
            title,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize),
          ),
        ),
        content: content,
        actions: [
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                cancelButton(
                  context,
                  fontWeight: btnFontWeight,
                  fontSize: fontSize,
                  width: btnWidth,
                  height: btnHeight,
                ),
                SizedBox(width: btnGap),
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: confirmBtnColor,
                    foregroundColor: Colors.white,
                    minimumSize: Size(btnWidth ?? 0, btnHeight ?? 0),
                    textStyle: TextStyle(fontSize: fontSize, fontWeight: btnFontWeight),
                  ),
                  child: const Text("ยืนยัน"),
                  onPressed: () async {
                    onConfirm();
                    if (context.mounted) Navigator.pop(context, true);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  } //: popUpAskToAction

  static PreferredSizeWidget minimalAppBar(
    String title, {
    IconData? titleIcon,
    bool autoCreatePopButton = true,
    Widget? action,
  }) {
    return AppBar(
      title: Row(children: [Icon(titleIcon), textBold(title, fontSize: 20)]),
      backgroundColor: UIHelper.appThemeBackground,
      foregroundColor: UIHelper.appThemeForeground,
      automaticallyImplyLeading: autoCreatePopButton,
      actions: (action != null) ? [action] : null,
    );
  } //PreferredSizeWidget

  //TextField สำเร็จรูป
  static Widget readyMadeTextField({
    String? labelText,
    String? hintText,
    TextInputType? keyboardType,
    required TextEditingController? controller,
    Color floatingLabelColor = const Color(0xFF424242),
    double borderRadius = 15,
    Color unfocusBorderColor = const Color(0xFFBDBDBD),
    Color focusBorderColor = const Color(0xFF424242),
    double marginBottom = 10,
    int? maxLength,
  }) {
    return Column(
      children: [
        SizedBox(
          width: 270,
          child: TextField(
            maxLength: maxLength,
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              labelText: labelText,
              hintText: hintText,

              floatingLabelStyle: TextStyle(color: floatingLabelColor, fontWeight: FontWeight.bold),

              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
                borderSide: BorderSide(color: unfocusBorderColor, width: 1.5),
              ),

              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
                borderSide: BorderSide(color: focusBorderColor, width: 2.0),
              ),

              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
                borderSide: BorderSide(color: unfocusBorderColor, width: 1.5),
              ),

              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
                borderSide: BorderSide(color: focusBorderColor, width: 2.0),
              ),
            ),
          ),
        ),
        SizedBox(height: marginBottom),
      ],
    );
  } //Widget: customTextField

  static Widget tableOfTestHistory(
    BuildContext context, {
    required Map<String, dynamic> dataOfTest,
    Color headingRowColor = appThemeBackground,
    bool showMeasureAtCell = false,
  }) {
    double fontSize = UIHelper.screenWidth(context, 0.040, lowerLimit: 0, upperLimit: 26);
    double tableRowHeight = UIHelper.screenHeight(context, 0.04, lowerLimit: 0, upperLimit: 50);
    double columnWidth = UIHelper.screenWidth(context, 0.30);
    Color borderSideColor = Colors.grey;
    double maxOnCurrntUnit = SuctionTestHandler.convertHPaToCurrentUnit(dataOfTest['max_value']);
    double minOnCurrntUnit = SuctionTestHandler.convertHPaToCurrentUnit(dataOfTest['min_value']);
    double avgOnCurrntUnit = SuctionTestHandler.convertHPaToCurrentUnit(dataOfTest['avg_value']);
    // Color maxColor = SuctionTestHandler.getColorOfValue(dataOfTest['max_value']);
    // Color minColor = SuctionTestHandler.getColorOfValue(dataOfTest['min_value']);
    // Color avgColor = SuctionTestHandler.getColorOfValue(dataOfTest['avg_value']);
    String unit = SuctionTestHandler.currentUnit;
    String measureAtDate = SuctionTestHandler.handleDisplayDateTime(dataOfTest['measure_at'], format: 'dd/MM/yyyy');
    String measureAtTime = SuctionTestHandler.handleDisplayDateTime(dataOfTest['measure_at'], format: 'HH:mm');

    return DataTable(
      border: TableBorder(
        top: BorderSide(color: borderSideColor),
        left: BorderSide(color: borderSideColor),
        right: BorderSide(color: borderSideColor),
        bottom: BorderSide(color: borderSideColor),
      ),
      showBottomBorder: true,
      headingRowColor: WidgetStatePropertyAll(headingRowColor),
      headingRowHeight: tableRowHeight,
      dataRowMaxHeight: tableRowHeight,
      dataRowMinHeight: 0,

      columns: [
        DataColumn(
          label: SizedBox(
            width: columnWidth,
            child: UIHelper.textBold("ข้อมูล", fontSize: fontSize, fontColor: UIHelper.appThemeForeground),
          ),
        ),
        DataColumn(
          label: SizedBox(
            width: columnWidth,
            child: UIHelper.textBold("ค่า", fontSize: fontSize, fontColor: UIHelper.appThemeForeground),
          ),
        ),
      ],
      rows: [
        if (showMeasureAtCell)
          DataRow(
            cells: [
              DataCell(Text("วันที่", style: TextStyle(fontSize: fontSize))),
              DataCell(Text(measureAtDate, style: TextStyle(fontSize: fontSize /*color: maxColor*/))),
            ],
          ),
        if (showMeasureAtCell)
          DataRow(
            cells: [
              DataCell(Text("เวลา", style: TextStyle(fontSize: fontSize))),
              DataCell(Text(measureAtTime, style: TextStyle(fontSize: fontSize /*color: maxColor*/))),
            ],
          ),
        DataRow(
          cells: [
            DataCell(
              Text(
                "แรงดูดสูงสุด",
                style: TextStyle(fontSize: fontSize, color: Colors.blue.shade600),
              ),
            ),
            DataCell(Text("$maxOnCurrntUnit $unit", style: TextStyle(fontSize: fontSize /*color: maxColor*/))),
          ],
        ),
        DataRow(
          cells: [
            DataCell(
              Text(
                "แรงดูดต่ำสุด",
                style: TextStyle(fontSize: fontSize, color: Colors.orangeAccent),
              ),
            ),
            DataCell(Text("$minOnCurrntUnit $unit", style: TextStyle(fontSize: fontSize /*color: minColor*/))),
          ],
        ),
        DataRow(
          cells: [
            DataCell(
              Text(
                "แรงดูดเฉลี่ย",
                style: TextStyle(fontSize: fontSize, color: Colors.blueGrey),
              ),
            ),
            DataCell(Text("$avgOnCurrntUnit $unit", style: TextStyle(fontSize: fontSize /*color: avgColor*/))),
          ],
        ),
        DataRow(
          cells: [
            DataCell(Text("จำนวนการดูด", style: TextStyle(fontSize: fontSize))),
            DataCell(Text("${dataOfTest['suction_count']} ครั้ง", style: TextStyle(fontSize: fontSize))),
          ],
        ),
        DataRow(
          cells: [
            DataCell(Text("ระยะเวลาวัด", style: TextStyle(fontSize: fontSize))),
            DataCell(Text("${dataOfTest['test_duration']} นาที", style: TextStyle(fontSize: fontSize))),
          ],
        ),
      ],
    );
  } //function: Return data table.

  static Widget lineChartGenerate(BuildContext context, {required List<List<List<double>>> allGraphData}) {
    double fontSize = 10;
    List<LineChartBarData> allFLSpotGraph = [];

    for (var i = 0; i < allGraphData.length; i++) {
      List<List<double>> graphOnCurrentUnit = SuctionTestHandler.graphConvertToCurrentUnit(allGraphData[i]);
      List<FlSpot> graphFLSpot = SuctionTestHandler.graphConvertListDoubleToFLSpot(graphOnCurrentUnit);

      allFLSpotGraph.add(
        LineChartBarData(
          spots: graphFLSpot,
          dotData: FlDotData(show: false),
          color: colorsByIndex[i],
          belowBarData: BarAreaData(show: true, color: colorsByIndex[i].withAlpha(20)),
        ),
      );
    }

    return SizedBox(
      height: UIHelper.screenHeight(context, 0.224),
      width: UIHelper.screenWidth(context, 0.8, lowerLimit: 0, upperLimit: 800),
      child: LineChart(
        LineChartData(
          lineBarsData: allFLSpotGraph,
          titlesData: FlTitlesData(
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                maxIncluded: false,
                reservedSize: 34,
                getTitlesWidget: (value, meta) => Text("$value", style: TextStyle(fontSize: fontSize)),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                maxIncluded: false,
                getTitlesWidget: (value, meta) => Text("${value.toInt()}s", style: TextStyle(fontSize: fontSize)),
              ),
            ),
          ),
        ),
      ),
    );
  } //function: Return line chart of data.

  static Widget measureUnitOptionButton(BuildContext context, VoidCallback onSelected, {required bool askForConfirm}) {
    Color borderColor = Colors.grey.shade400;
    double fontSize = screenWidth(context, 0.06, lowerLimit: 0, upperLimit: 32);
    Color mmHgColor = Colors.red;
    Color kPaColor = Colors.blue;
    Color nm2Color = Colors.green;
    String unit = SuctionTestHandler.currentUnit;

    void action(String selectUnit) async {
      SuctionTestHandler.currentUnit = selectUnit;
      Navigator.of(context, rootNavigator: true).pop();
      onSelected();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_unit', selectUnit);
    } //function: action without ask anything.

    void actionWithCondition(String selectUnit) {
      if (selectUnit == SuctionTestHandler.currentUnit) {
        Navigator.of(context, rootNavigator: true).pop();
      } else {
        if (askForConfirm) {
          twoStepConfirmActionDialog(
            context,
            "เปลี่ยนหน่วยวัดเป็น $selectUnit",
            onConfirm: () => action(selectUnit),
            confirmBtnColor: Colors.orange,
          );
        } else {
          action(selectUnit);
        }
      }
    } //function: action with ask for confirm.

    return Padding(
      padding: EdgeInsets.only(right: screenWidth(context, 0.04)),
      child: actionButton(
        "หน่วย: ${SuctionTestHandler.currentUnit}",
        () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              contentPadding: EdgeInsets.all(0),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(width: 1, color: borderColor)),
                    ),
                    child: ListTile(
                      title: textBold("mmHg", fontSize: fontSize, fontColor: mmHgColor, textAlign: TextAlign.center),
                      onTap: () => actionWithCondition("mmHg"),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(width: 1, color: borderColor)),
                    ),
                    child: ListTile(
                      title: textBold("kPa", fontSize: fontSize, fontColor: kPaColor, textAlign: TextAlign.center),
                      onTap: () => actionWithCondition("kPa"),
                    ),
                  ),
                  ListTile(
                    title: textBold("N/m^2", fontSize: fontSize, fontColor: nm2Color, textAlign: TextAlign.center),
                    onTap: () => actionWithCondition("N/m^2"),
                  ),
                ],
              ),
            ),
          );
        },
        fontSize: 14,
        textColor: unit == "mmHg"
            ? mmHgColor
            : unit == "kPa"
            ? kPaColor
            : nm2Color,
        buttonColor: appThemeForeground,
        shadowOn: true,
        width: screenWidth(context, 0.32, lowerLimit: 0, upperLimit: 300),
        height: screenHeight(context, 0.02),
      ),
    );
  } //functino: Return button that can select measure unit.
}//class: UIHelper