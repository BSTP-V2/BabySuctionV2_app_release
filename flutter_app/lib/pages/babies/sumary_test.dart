import 'package:bstp_v2/pages/babies/baby_test_history.dart';
import 'package:bstp_v2/services/database_handler.dart';
import 'package:bstp_v2/services/suction_test_handler.dart';
import 'package:bstp_v2/services/ui_helper.dart';
import 'package:flutter/material.dart';

class SumaryOfTestPage extends StatefulWidget {
  final Map<String, dynamic> baby;
  final Map<String, dynamic> dataOfTest;

  const SumaryOfTestPage({super.key, required this.baby, required this.dataOfTest});

  @override
  State<SumaryOfTestPage> createState() => _SumaryOfTestPageState();
}

class _SumaryOfTestPageState extends State<SumaryOfTestPage> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        UIHelper.showTextDialogInSpecificTime(context, onTimeOut: () {}, msg: "การทดสอบเสร็จสิ้น", timeOutSeconds: 1);
      } //process: If mounted show text dialog in specified time period
    });
  } //initState

  @override
  void dispose() {
    UIHelper.unAllowDirectPushToBabiesListPage = false;
    super.dispose();
  } //dispose

  void handlePopPage() {
    UIHelper.twoStepConfirmActionDialog(
      context,
      "ละทิ้งผลทดสอบ?",
      onConfirm: () {
        Navigator.pop(context);
        UIHelper.unAllowDirectPushToBabiesListPage = false;
      },
    );
  } //function

  Widget actionButtonsPanel() {
    double btnWidth = UIHelper.screenWidth(context, 0.36, lowerLimit: 0, upperLimit: 260);
    double btnHeight = UIHelper.screenHeight(context, 0.052);
    double fontSize = UIHelper.screenWidth(context, 0.038, lowerLimit: 0, upperLimit: 28);
    double rowGap = UIHelper.screenWidth(context, 0.06);
    double iconSize = UIHelper.screenWidth(context, 0.054, lowerLimit: 0, upperLimit: 42);
    double borderRadius = UIHelper.screenWidth(context, 0.034, lowerLimit: 0, upperLimit: 22);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        UIHelper.actionButton(
          "ย้อนกลับ",
          setIcon: Icons.delete_forever,
          fontSize: fontSize,
          width: btnWidth,
          height: btnHeight,
          buttonColor: Colors.grey.shade800,
          borderRadius: borderRadius,
          () => handlePopPage(),
        ),
        SizedBox(width: rowGap),
        UIHelper.actionButton(
          "บันทึกผล",
          () async {
            try {
              await DatabaseHelper.saveTestHistoryOfBaby(widget.dataOfTest);

              if (mounted) {
                Navigator.of(context).removeRouteBelow(ModalRoute.of(context)!);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => BabyTestHistoryPage(baby: widget.baby)),
                );
              }
            } catch (e) {
              if (mounted) UIHelper.popUpErrorMessage(context, e);
            } //process:try-catch
          },
          iconSize: iconSize,
          setIcon: Icons.save,
          fontSize: fontSize,
          width: btnWidth,
          height: btnHeight,
          buttonColor: Colors.green,
          borderRadius: borderRadius,
        ),
      ],
    );
  } //function: Return buttons panel.

  PreferredSizeWidget pageAppBar() {
    return UIHelper.minimalAppBar(
      " : ${widget.baby['hn']}",
      titleIcon: Icons.account_circle_outlined,
      action: UIHelper.measureUnitOptionButton(context, () => setState(() {}), askForConfirm: true),
    );
  } //function: Return AppBar.

  Widget pageBody() {
    double columnGap = UIHelper.screenHeight(context, 0.022);
    String measureAtDateTime = SuctionTestHandler.handleDisplayDateTime(widget.dataOfTest['measure_at']);

    return Center(
      child: IntrinsicWidth(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: columnGap),
                UIHelper.textBold(
                  "ผลการทดสอบ",
                  fontSize: UIHelper.screenWidth(context, 0.064, lowerLimit: 0, upperLimit: 56),
                ),
                Text(
                  measureAtDateTime,
                  style: TextStyle(fontSize: UIHelper.screenWidth(context, 0.038, lowerLimit: 0, upperLimit: 34)),
                ),
              ],
            ),
            SizedBox(height: columnGap),
            UIHelper.tableOfTestHistory(context, dataOfTest: widget.dataOfTest),
            SizedBox(height: columnGap),
            UIHelper.lineChartGenerate(context, allGraphData: [widget.dataOfTest['graph']]),
            SizedBox(height: columnGap),
            actionButtonsPanel(),
          ],
        ),
      ),
    );
  } //function: Return Body of page.

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        handlePopPage();
      },
      child: Scaffold(appBar: pageAppBar(), body: pageBody()),
    );
  } //build
} //class
