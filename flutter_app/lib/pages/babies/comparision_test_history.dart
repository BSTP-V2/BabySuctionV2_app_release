import 'package:bstp_v2/services/database_handler.dart';
import 'package:bstp_v2/services/suction_test_handler.dart';
import 'package:bstp_v2/services/ui_helper.dart';
import 'package:flutter/material.dart';

class ComparisionChartPage extends StatefulWidget {
  final List<int> historyIds;
  final Map<String, dynamic> baby;

  const ComparisionChartPage({super.key, required this.historyIds, required this.baby});

  @override
  State<ComparisionChartPage> createState() => _ComparisionChartPageState();
}

class _ComparisionChartPageState extends State<ComparisionChartPage> {
  List<Map<String, dynamic>> allDataOfTest = [];
  late double columnGap;

  @override
  void initState() {
    super.initState();
    fetchTestsAndKeepAsUsable();
  } //initState

  void fetchTestsAndKeepAsUsable() async {
    try {
      List<Map<String, dynamic>> rawAllDataOfTest = await DatabaseHelper.fetchTestsHistoryByHistoryId(
        historyIds: widget.historyIds,
      ); //Getting raw data of test.

      for (Map<String, dynamic> rawDataOfTest in rawAllDataOfTest) {
        Map<String, dynamic> usableDataOfTest = {};

        rawDataOfTest.forEach((key, value) {
          if (key != 'graph') {
            usableDataOfTest[key] = value;
          } else {
            List<List<double>> usableGraph = SuctionTestHandler.decodeGraphJsonToListDouble(graphAsJson: value);
            usableDataOfTest[key] = usableGraph;
          }
        });
        setState(() => allDataOfTest.add(usableDataOfTest));
      } //forIn
    } catch (error) {
      if (mounted) UIHelper.popUpErrorMessage(context, error);
    } //try-catch
  } //function: Fetch tests data by history id and save to variable correctly.

  Widget pageTitleTextUXUI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: columnGap),
        UIHelper.textBold(
          "เปรียบเทียบกราฟ",
          fontSize: UIHelper.screenWidth(context, 0.064, lowerLimit: 0, upperLimit: 56),
        ),
        Text(
          "ทั้งหมด ${widget.historyIds.length} รายการ",
          style: TextStyle(fontSize: UIHelper.screenWidth(context, 0.038, lowerLimit: 0, upperLimit: 34)),
        ),
      ],
    );
  }

  Widget popPageButtonUXUI() {
    return UIHelper.actionButton(
      "ย้อนกลับ",
      () => Navigator.pop(context),
      fontSize: UIHelper.screenWidth(context, 0.04, lowerLimit: 0, upperLimit: 40),
      width: UIHelper.screenWidth(context, 0.4, lowerLimit: 0, upperLimit: 400),
      height: UIHelper.screenHeight(context, 0.06, lowerLimit: 0, upperLimit: 90),
      borderRadius: UIHelper.screenWidth(context, 0.04, lowerLimit: 0, upperLimit: 22),
    );
  } //function: Return pop page button.

  PreferredSizeWidget pageAppBarUXUI() {
    return UIHelper.minimalAppBar(
      " : ${widget.baby['hn']}",
      titleIcon: Icons.account_circle_outlined,
      action: UIHelper.measureUnitOptionButton(context, () => setState(() {}), askForConfirm: true),
    );
  } //function: Return page app bar.

  Widget pageBodyUXUI() {
    if (allDataOfTest.isEmpty) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator(color: UIHelper.appThemeBackground)),
      );
    } else {
      columnGap = UIHelper.screenHeight(context, 0.020);

      List<List<List<double>>> containAllGraph = List.generate(
        allDataOfTest.length,
        (index) => allDataOfTest[index]['graph'],
      );

      List<Widget> containAllTable = List.generate(
        allDataOfTest.length,
        (index) => Column(
          children: [
            UIHelper.tableOfTestHistory(
              context,
              dataOfTest: allDataOfTest[index],
              headingRowColor: UIHelper.colorsByIndex[index],
              showMeasureAtCell: true,
            ),
            SizedBox(height: columnGap),
          ],
        ),
      );

      return SingleChildScrollView(
        child: Center(
          child: IntrinsicWidth(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                pageTitleTextUXUI(),
                SizedBox(height: columnGap),
                UIHelper.lineChartGenerate(context, allGraphData: containAllGraph),
                SizedBox(height: columnGap),
                ...containAllTable,
                popPageButtonUXUI(),
                SizedBox(height: columnGap),
              ],
            ),
          ),
        ),
      );
    }
  } //function: Return page body.

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: pageAppBarUXUI(), body: pageBodyUXUI());
  } //build
} //class
