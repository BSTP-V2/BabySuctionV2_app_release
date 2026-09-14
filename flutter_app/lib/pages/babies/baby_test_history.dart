import 'package:bstp_v2/pages/babies/comparision_test_history.dart';
import 'package:bstp_v2/pages/babies/setup_test.dart';
import 'package:bstp_v2/pages/babies/specific_test_history.dart';
import 'package:bstp_v2/services/database_handler.dart';
import 'package:bstp_v2/services/suction_test_handler.dart';
import 'package:bstp_v2/services/ui_helper.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BabyTestHistoryPage extends StatefulWidget {
  final Map<String, dynamic> baby;
  const BabyTestHistoryPage({super.key, required this.baby});

  @override
  State<BabyTestHistoryPage> createState() => _BabyTestHistoryPageState();
} //class: BabyTestHistoryPage

class _BabyTestHistoryPageState extends State<BabyTestHistoryPage> {
  List<Map<String, dynamic>> allDataOfTest = [];
  bool sortByDate = true;
  bool sortDateByDESC = true;
  bool sortByValue = false;
  bool sortByQuantity = false;
  List<int> selectedHistoryIds = [];
  final Map<int, ExpansibleController> _listTileController = {};

  @override
  void initState() {
    super.initState();
    handleFetchTestHistory();
  } //initState

  void handleFetchTestHistory() async {
    try {
      final List<Map<String, dynamic>> getData = await DatabaseHelper.fetchTestsHistoryByBabyId(id: widget.baby['id']);

      for (var data in getData) {
        _listTileController[data['history_id']] = ExpansibleController();
      }

      setState(() {
        allDataOfTest = getData;

        sortHistoryByMeasureAt();
      });
    } catch (e) {
      if (mounted) UIHelper.popUpErrorMessage(context, e);
    }
  } //function: Handle get test history process.

  void sortHistoryByMeasureAt() {
    List<Map<String, dynamic>> tempList = List.from(allDataOfTest);

    if (sortDateByDESC == false) {
      tempList.sort((a, b) {
        DateTime timeA = DateTime.parse(a['measure_at']);
        DateTime timeB = DateTime.parse(b['measure_at']);

        return timeA.compareTo(timeB);
      });
    } else {
      tempList.sort((a, b) {
        DateTime timeA = DateTime.parse(a['measure_at']);
        DateTime timeB = DateTime.parse(b['measure_at']);

        return timeB.compareTo(timeA);
      });
    } //process: Check sortByDateCurrentToOldState condition.

    allDataOfTest = tempList;
  } //function: Sort testHistory from Date time.

  void sortHistoryByAvgValue() {
    List<Map<String, dynamic>> tempList = List.from(allDataOfTest);

    tempList.sort((a, b) => (b['avg_value'] as double).compareTo(a['avg_value'] as double));
    allDataOfTest = tempList;
  } //funciton: Sort testHistoryList from avg value high to low.

  void sortHistoryBySuctionCount() {
    List<Map<String, dynamic>> tempList = List.from(allDataOfTest);

    tempList.sort((a, b) => (b['suction_count'] as int).compareTo(a['suction_count'] as int));
    allDataOfTest = tempList;
  } //funciton: Sort testHistoryList from suction count high to low.

  ButtonStyle customAppBarSortButtonStyle({
    bool selected = false,
    double width = 0.2,
    double height = 0.02,
    double lowerLimitWidth = 90,
    double upperLimitWidth = 300,
  }) {
    return TextButton.styleFrom(
      fixedSize: Size(
        UIHelper.screenWidth(context, width, lowerLimit: lowerLimitWidth, upperLimit: upperLimitWidth),
        UIHelper.screenHeight(context, height),
      ),
      side: BorderSide(color: Colors.white, width: 2),
      backgroundColor: selected ? UIHelper.appThemeForeground : UIHelper.appThemeBackground,
      foregroundColor: selected ? UIHelper.appThemeBackground : UIHelper.appThemeForeground,
      textStyle: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: UIHelper.screenWidth(context, 0.03, lowerLimit: 10, upperLimit: 18),
      ),
      iconAlignment: IconAlignment.end,
      iconSize: 16,
    );
  } //sortButtonStyle

  Widget appBarSortButtonPanel() {
    double paddingLeftRight = UIHelper.screenWidth(context, 0.02, lowerLimit: 0, upperLimit: 100);

    return Padding(
      padding: EdgeInsets.only(left: paddingLeftRight, right: paddingLeftRight),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          TextButton.icon(
            onPressed: () => setState(() {
              if (sortByDate && sortDateByDESC) {
                sortDateByDESC = false;
              } else if (sortByDate && !sortDateByDESC) {
                sortDateByDESC = true;
              }
              sortByDate = true;
              sortByValue = false;
              sortByQuantity = false;
              sortHistoryByMeasureAt();
            }),
            style: customAppBarSortButtonStyle(selected: sortByDate, width: 0.2, upperLimitWidth: 400),
            icon: Icon(
              !sortByDate
                  ? Icons.unfold_more
                  : sortDateByDESC
                  ? Icons.arrow_downward
                  : Icons.arrow_upward,
            ),
            label: Text("ล่าสุด"),
          ),
          TextButton(
            onPressed: () {
              if (!sortByValue) {
                setState(() {
                  sortByDate = false;
                  sortByValue = true;
                  sortByQuantity = false;
                  sortHistoryByAvgValue();
                });
              } //Check sortByValueState condition.
            },
            style: customAppBarSortButtonStyle(selected: sortByValue, width: 0.34, upperLimitWidth: 500),
            child: Text("แรงดูดเฉลี่ยสูงสุด"),
          ),
          TextButton(
            onPressed: () {
              if (!sortByQuantity) {
                setState(() {
                  sortByDate = false;
                  sortByValue = false;
                  sortByQuantity = true;
                  sortHistoryBySuctionCount();
                });
              } //Check sortByQuantityState condition.
            },
            style: customAppBarSortButtonStyle(selected: sortByQuantity, width: 0.34, upperLimitWidth: 500),
            child: Text("จำนวนการดูดสูงสุด"),
          ),
        ],
      ),
    );
  } //appBarSortButton

  Widget appBarListTitle() {
    Color listTitleColor = const Color(0xFF2E2E2E);
    double fontSize = UIHelper.screenWidth(context, 0.030, lowerLimit: 0, upperLimit: 22);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          // top: BorderSide(color: Colors.black),
          bottom: BorderSide(color: Colors.black),
        ),
      ),
      child: Padding(
        padding: const EdgeInsetsGeometry.fromLTRB(0, 4, 0, 4),
        child: Row(
          children: [
            Expanded(
              child: Center(
                child: UIHelper.textBold("ลำดับ", fontColor: listTitleColor, fontSize: fontSize),
              ),
            ),
            Expanded(
              child: Center(
                child: Column(
                  children: [
                    UIHelper.textBold("เวลา", fontColor: listTitleColor, fontSize: fontSize),
                    UIHelper.textBold("วัน/เดือน/ปี", fontColor: listTitleColor, fontSize: fontSize),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  Center(
                    child: UIHelper.textBold("แรงดูดเฉลี่ย", fontColor: listTitleColor, fontSize: fontSize),
                  ),
                  Center(
                    child: UIHelper.textBold("จำนวนครั้ง", fontColor: listTitleColor, fontSize: fontSize),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: UIHelper.textBold("ระยะเวลา", fontColor: listTitleColor, fontSize: fontSize),
              ),
            ),
          ],
        ),
      ),
    );
  } //appBarListHeader

  List<Widget> appBarActions() {
    double setIconSize = UIHelper.screenWidth(context, 0.084, lowerLimit: 24, upperLimit: 50);
    int selectionCount = selectedHistoryIds.length;
    bool canCompareTheTest = (selectionCount > 1 && selectionCount <= 5);

    return [
      // Icon เปรียบเทียบการวัด
      Row(
        children: [
          Visibility(
            visible: selectionCount > 1,
            child: UIHelper.textBold(
              "( $selectionCount )",
              fontColor: selectionCount > 5 ? Colors.red.shade600 : UIHelper.appThemeForeground,
            ),
          ),
          IconButton(
            tooltip: "เปรียบเทียบกราฟจากรายการที่เลือกไว้",
            icon: Icon(Icons.area_chart),
            onPressed: () {
              if (canCompareTheTest) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ComparisionChartPage(historyIds: selectedHistoryIds, baby: widget.baby),
                  ),
                );
              }
            },
            iconSize: setIconSize,
            color: canCompareTheTest
                ? UIHelper.appThemeForeground
                : Color.lerp(UIHelper.appThemeForeground, Colors.black, 0.2),
          ),
        ],
      ),
      SizedBox(width: UIHelper.screenWidth(context, 0.012, lowerLimit: 4, upperLimit: 30)),
      //Icon เพิ่มการทดสอบ
      Padding(
        padding: const EdgeInsets.only(right: 20),
        child: IconButton(
          tooltip: "ไปที่หน้าเพิ่มการทดสอบ",
          icon: Icon(Icons.add_chart),
          iconSize: setIconSize,
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => TestDurationConfigPage(baby: widget.baby)),
          ),
        ),
      ),
    ];
  } //appBarActionsIcon

  void deleteTestHistoryDialog(Map<String, dynamic> dataOfTest) {
    String measureAt = SuctionTestHandler.handleDisplayDateTime(dataOfTest['measure_at']);
    double max = SuctionTestHandler.convertHPaToCurrentUnit(dataOfTest['max_value']);
    double min = SuctionTestHandler.convertHPaToCurrentUnit(dataOfTest['min_value']);
    double avg = SuctionTestHandler.convertHPaToCurrentUnit(dataOfTest['avg_value']);
    String unit = SuctionTestHandler.currentUnit;
    Color contentColor = Colors.grey.shade700;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: UIHelper.textBold("ประวัติการวัด"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            UIHelper.textBold(measureAt),
            SizedBox(height: 10),
            Text("แรงดูดสูงสุด: $max $unit", style: TextStyle(color: contentColor)),
            Text("แรงดูดต่ำสุด: $min $unit", style: TextStyle(color: contentColor)),
            Text("แรงดูดเฉลี่ย: $avg $unit", style: TextStyle(color: contentColor)),
            Text("จำนวนการดูด: ${dataOfTest['suction_count']} ครั้ง", style: TextStyle(color: contentColor)),
            Text("ระยะเวลา: ${dataOfTest['test_duration']} นาที", style: TextStyle(color: contentColor)),
          ],
        ),
        actions: [
          Divider(),
          ListTile(
            iconColor: Colors.red,
            leading: Icon(Icons.delete),
            title: UIHelper.textBold("ลบประวัติการวัด", textAlign: TextAlign.center, fontColor: Colors.red),
            onTap: () => UIHelper.twoStepConfirmActionDialog(
              context,
              "ยืนยันลบประวัติการวัด?",
              onConfirm: () async {
                try {
                  await DatabaseHelper.deleteTestHistory(dataOfTest['history_id']);
                  handleFetchTestHistory();

                  if (!context.mounted) return;
                  Navigator.of(context, rootNavigator: true).pop();
                  UIHelper.justAlert(context, "ลบประวัติการวัดสำเร็จ");
                } catch (e) {
                  if (context.mounted) {
                    return UIHelper.popUpErrorMessage(context, e);
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  } //deleteTestHistoryDialog

  Widget testHistoryListTileUXUI() {
    double fontSize = UIHelper.screenWidth(context, 0.030, lowerLimit: 0, upperLimit: 22);
    double moreInfoBtnWidth = UIHelper.screenWidth(context, 0.4);
    double moreInfoBtnHeight = UIHelper.screenHeight(context, 0.04, lowerLimit: 0, upperLimit: 20);
    double paddingLR = UIHelper.screenWidth(context, 0.1);
    double paddingTB = UIHelper.screenHeight(context, 0.008);
    String unit = SuctionTestHandler.currentUnit;

    return ListView.builder(
      itemCount: allDataOfTest.length,
      itemBuilder: (context, index) {
        final Map<String, dynamic> dataOfTest = allDataOfTest[index];
        final DateTime measureAtDateTime = DateTime.parse(dataOfTest['measure_at']);
        final String measureAtDate = DateFormat('dd/MM/yyyy').format(measureAtDateTime);
        final String measureAtTime = DateFormat('HH:mm').format(measureAtDateTime);

        double maxOnCurrentUnit = SuctionTestHandler.convertHPaToCurrentUnit(dataOfTest['max_value']);
        double avgOnCurrentUnit = SuctionTestHandler.convertHPaToCurrentUnit(dataOfTest['avg_value']);
        double minOnCurrentUnit = SuctionTestHandler.convertHPaToCurrentUnit(dataOfTest['min_value']);

        return GestureDetector(
          onLongPress: () => deleteTestHistoryDialog(dataOfTest),
          child: Container(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(width: 1, color: Colors.grey.shade300)),
            ),
            child: ExpansionTile(
              controller: _listTileController[dataOfTest['history_id']],
              tilePadding: EdgeInsets.only(left: 0, right: 0),
              onExpansionChanged: (value) {
                if (value) {
                  setState(() => selectedHistoryIds.add(dataOfTest['history_id']));
                } else {
                  setState(() => selectedHistoryIds.remove(dataOfTest['history_id']));
                } //Add or remove id from compare selection.
              },
              showTrailingIcon: false,
              title: Row(
                children: [
                  Expanded(
                    child: Center(
                      child: Text((index + 1).toString(), style: TextStyle(fontSize: fontSize)),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Column(
                        children: [
                          Text(measureAtTime, style: TextStyle(fontSize: fontSize)),
                          Text(measureAtDate, style: TextStyle(fontSize: fontSize)),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Column(
                        children: [
                          Text("$avgOnCurrentUnit $unit", style: TextStyle(fontSize: fontSize)),
                          Text("${dataOfTest['suction_count'].toString()} ครั้ง", style: TextStyle(fontSize: fontSize)),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        "${dataOfTest['test_duration'].toString()} นาที",
                        style: TextStyle(fontSize: fontSize),
                      ),
                    ),
                  ),
                ],
              ),

              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(paddingLR, paddingTB, paddingLR, paddingTB),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      UIHelper.textBold("📊 รายละเอียดเพิ่มเติม", fontSize: fontSize),
                      SizedBox(height: 8),
                      Text("• แรงดูดสูงสุด : $maxOnCurrentUnit $unit", style: TextStyle(fontSize: fontSize)),
                      Text("• แรงดูดต่ำสุด : $minOnCurrentUnit $unit", style: TextStyle(fontSize: fontSize)),
                      Divider(),
                      Center(
                        child: UIHelper.actionButton(
                          "เรียกดูรายงานกราฟ",
                          () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    SpecificTestHistory(historyId: dataOfTest['history_id'], baby: widget.baby),
                              ),
                            );

                            setState(() {});
                          },
                          iconSize: UIHelper.screenWidth(context, 0.04, lowerLimit: 0, upperLimit: 26),
                          setIcon: Icons.show_chart,
                          fontSize: fontSize,
                          width: moreInfoBtnWidth,
                          height: moreInfoBtnHeight,
                          textColor: UIHelper.appThemeForeground,
                          buttonColor: UIHelper.appThemeBackground,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  } //function: Return test history list tile.

  PreferredSizeWidget pageAppBar() {
    return AppBar(
      toolbarHeight: UIHelper.screenHeight(context, 0.1, lowerLimit: 60, upperLimit: 100),
      leading: selectedHistoryIds.isEmpty
          ? null
          : IconButton(
              onPressed: () {
                for (int id in selectedHistoryIds.toList()) {
                  _listTileController[id]!.collapse();
                }
                selectedHistoryIds.clear();
              },
              icon: Icon(Icons.clear),
              color: UIHelper.appThemeForeground,
            ),
      title: Row(
        children: [Icon(Icons.account_circle_outlined), UIHelper.textBold(" : ${widget.baby['hn']}", fontSize: 20)],
      ),
      backgroundColor: UIHelper.appThemeBackground,
      foregroundColor: UIHelper.appThemeForeground,
      actions: appBarActions(),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Column(children: [appBarSortButtonPanel(), SizedBox(height: 10), appBarListTitle()]),
      ),
    );
  } //PreferredSizeWidget: pageAppBar

  Widget pageBody() {
    return allDataOfTest.isEmpty
        ? Center(child: UIHelper.messageOnCenterDisplay(context, "ยังไม่มีประวัติการวัด"))
        : testHistoryListTileUXUI();
  } //Widget: pageBody

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: pageAppBar(), body: pageBody());
  } //WidgetL build
} //class _BabyTestHistoryPageState
