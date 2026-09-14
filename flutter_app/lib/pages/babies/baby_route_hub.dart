import 'package:bstp_v2/pages/babies/babies_list.dart';
import 'package:bstp_v2/pages/babies/baby_test_history.dart';
import 'package:bstp_v2/pages/babies/setup_test.dart';
import 'package:bstp_v2/services/ui_helper.dart';
import 'package:flutter/material.dart';

class BabyRouteHubPage extends StatelessWidget {
  final Map<String, dynamic> baby;

  const BabyRouteHubPage({super.key, required this.baby});

  PreferredSizeWidget pageAppBar() {
    return UIHelper.minimalAppBar(" : ${baby['hn']}", titleIcon: Icons.account_circle_outlined);
  } //pageAppBar

  Widget pageBody(BuildContext context) {
    double buttonWidth = UIHelper.screenWidth(context, 0.7, lowerLimit: 0, upperLimit: 600);
    double buttonHeight = UIHelper.screenHeight(context, 0.086, lowerLimit: 0, upperLimit: 130);
    double columnGap = UIHelper.screenHeight(context, 0.048);
    double buttonTitleSize = UIHelper.screenWidth(context, 0.050, lowerLimit: 0, upperLimit: 38);
    double buttonIconSize = UIHelper.screenWidth(context, 0.08, lowerLimit: 0, upperLimit: 48);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          UIHelper.actionButton(
            "ทดสอบวัดแรงดูด",
            () => Navigator.push(context, MaterialPageRoute(builder: (context) => TestDurationConfigPage(baby: baby))),
            buttonColor: Colors.green,
            setIcon: Icons.bar_chart_rounded,
            iconSize: buttonIconSize,
            fontSize: buttonTitleSize,
            width: buttonWidth,
            height: buttonHeight,
            shadowOn: true,
          ),
          SizedBox(height: columnGap),
          UIHelper.actionButton(
            "ประวัติการวัดแรงดูด",
            () => Navigator.push(context, MaterialPageRoute(builder: (context) => BabyTestHistoryPage(baby: baby))),
            buttonColor: Colors.blue,
            setIcon: Icons.pie_chart_rounded,
            iconSize: buttonIconSize,
            fontSize: buttonTitleSize,
            width: buttonWidth,
            height: buttonHeight,
            shadowOn: true,
          ),
          SizedBox(height: columnGap),
          UIHelper.actionButton(
            "ย้อนกลับ",
            () => Navigator.canPop(context)
                ? Navigator.pop(context)
                : Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => BabiesListPage())),
            buttonColor: Colors.grey.shade800,
            iconSize: 0,
            fontSize: buttonTitleSize,
            width: buttonWidth,
            height: buttonHeight,
            shadowOn: true,
          ),
        ],
      ),
    );
  } //pageBody

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: pageAppBar(), body: pageBody(context));
  }
} //class:
