import 'package:bstp_v2/services/database_handler.dart';
import 'package:bstp_v2/services/suction_test_handler.dart';
import 'package:bstp_v2/services/ui_helper.dart';
import 'package:flutter/material.dart';

class SpecificTestHistory extends StatefulWidget {
  final int historyId;
  final Map<String, dynamic> baby;

  const SpecificTestHistory({super.key, required this.historyId, required this.baby});

  @override
  State<SpecificTestHistory> createState() => _SpecificTestHistoryState();
}

class _SpecificTestHistoryState extends State<SpecificTestHistory> {
  Map<String, dynamic> dataOfTest = {};

  @override
  void initState() {
    super.initState();
    fetchDataOfTest();
  } //initState

  void fetchDataOfTest() async {
    try {
      final List<Map<String, dynamic>> getData = await DatabaseHelper.fetchTestsHistoryByHistoryId(
        historyIds: [widget.historyId],
      );

      setState(() {
        getData[0].forEach((key, value) {
          if (key != 'graph') {
            dataOfTest[key] = value;
          } else {
            List<List<double>> usableGraph = SuctionTestHandler.decodeGraphJsonToListDouble(graphAsJson: value);
            dataOfTest[key] = usableGraph;
          }
        });
      });
    } catch (e) {
      if (mounted) UIHelper.popUpErrorMessage(context, e);
    }
  } //functino: fetch graph data.

  PreferredSizeWidget pageAppBar() {
    return UIHelper.minimalAppBar(
      " : ${widget.baby['hn']}",
      titleIcon: Icons.account_circle_outlined,
      action: UIHelper.measureUnitOptionButton(context, () => setState(() {}), askForConfirm: true),
    );
  } //function: Return appbar of page.

  Widget pageBody() {
    if (dataOfTest.isEmpty) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator(color: UIHelper.appThemeBackground)),
      );
    } else {
      double columnGap = UIHelper.screenHeight(context, 0.020);
      String measureAtDateTime = SuctionTestHandler.handleDisplayDateTime(dataOfTest['measure_at'] ?? "");

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
              UIHelper.tableOfTestHistory(context, dataOfTest: dataOfTest),
              SizedBox(height: columnGap),
              UIHelper.lineChartGenerate(context, allGraphData: [dataOfTest['graph']]),
              SizedBox(height: columnGap),
              UIHelper.actionButton(
                "ย้อนกลับ",
                () => Navigator.pop(context),
                fontSize: UIHelper.screenWidth(context, 0.04, lowerLimit: 0, upperLimit: 40),
                width: UIHelper.screenWidth(context, 0.4, lowerLimit: 0, upperLimit: 400),
                height: UIHelper.screenHeight(context, 0.06, lowerLimit: 0, upperLimit: 90),
                borderRadius: UIHelper.screenWidth(context, 0.04, lowerLimit: 0, upperLimit: 22),
              ),
            ],
          ),
        ),
      );
    }
  } //function: Return body of page.

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: pageAppBar(), body: pageBody());
  } //build state
} //class:
