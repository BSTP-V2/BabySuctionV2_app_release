//=============================================================
//    ฟังก์ชันสำหรับจัดการระบบ Show dialog ใช้ในหน้า BabiesListPage
//=============================================================

import 'package:flutter/material.dart';
import 'package:bstp_v2/services/ui_helper.dart';
import 'package:bstp_v2/services/database_handler.dart';

class BabiesDialog {
  static const int fixedHNDigits = 7;

  static Future<bool?> babyInputInfoDialog(
    BuildContext context, {
    required String title,
    required TextEditingController hnController,
    required TextEditingController parentFNameController,
    required TextEditingController parentLNameController,
    required Future<void> Function() onConfirm,
    IconData confirmBtnIcon = Icons.save,
  }) async {
    return showDialog(
      context: context,
      builder: (context) => Center(
        child: AlertDialog(
          title: UIHelper.textBold("เพิ่มรายชื่อ"),
          //เนื้อหา
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                UIHelper.readyMadeTextField(
                  controller: hnController,
                  labelText: "HN: Hospital Number",
                  hintText: "ระบุเป็นตัวเลข",
                  keyboardType: TextInputType.number,
                  maxLength: fixedHNDigits,
                ),
                UIHelper.readyMadeTextField(
                  controller: parentFNameController,
                  labelText: "ชื่อ - มารดา",
                  hintText: "ระบุเป็นตัวอักษร",
                  keyboardType: TextInputType.text,
                ),
                UIHelper.readyMadeTextField(
                  controller: parentLNameController,
                  labelText: "นามสกุล - มารดา",
                  hintText: "ระบุเป็นตัวอักษร",
                  keyboardType: TextInputType.text,
                ),
              ],
            ),
          ),
          actions: [
            Row(
              children: [
                //ปุ่มยกเลิก
                Expanded(
                  child: UIHelper.cancelButton(
                    context,
                    fontSize: 20,
                    width: double.infinity,
                    height: 50,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 10),
                //ปุ่มบันทึกการแก้ไขข้อมูลทารก
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(confirmBtnIcon),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      minimumSize: Size(0, 50),
                      textStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    label: Text("บันทึก"),
                    onPressed: () async {
                      final String newHN = hnController.text.trim();
                      final String newParentFName = parentFNameController.text.trim();
                      final String newParentLName = parentLNameController.text.trim();

                      try {
                        if (newHN.isEmpty || newParentFName.isEmpty || newParentLName.isEmpty) {
                          throw "กรุณากรอกข้อมูลให้ครบถ้วน";
                        } else {
                          await onConfirm();

                          if (!context.mounted) return;
                          Navigator.pop(context, true);
                        }
                      } catch (error) {
                        if (!context.mounted) return;
                        handleProcessError(context, error);
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Future<bool?> babyOptionsDialog(BuildContext context, Map<String, dynamic> baby) async {
    double fontSize = UIHelper.screenWidth(context, 0.04, lowerLimit: 0, upperLimit: 20);

    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: UIHelper.textBold("จัดการข้อมูลรายชื่อ"),
        //เนื้อหา
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            UIHelper.textBold(
              "HN: ${baby['hn']}\nชื่อมารดา: ${baby['parent_fname']} ${baby['parent_lname']}",
              fontSize: 16,
              fontColor: Colors.grey.shade700,
            ),
            SizedBox(height: 12),
            Divider(),
          ],
        ),
        actions: [
          Center(
            child: Row(
              children: [
                //ปุ่มลบรายชื่อ
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.delete),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.red.shade800,
                      foregroundColor: Colors.white,
                      minimumSize: Size(0, 50),
                      iconSize: fontSize + 10,
                      textStyle: TextStyle(fontSize: fontSize),
                    ),
                    label: UIHelper.textBold("ลบ"),
                    onPressed: () async {
                      try {
                        final bool? isBabyDeleted = await UIHelper.twoStepConfirmActionDialog(
                          context,
                          "ลบรายชื่อนี้?",
                          onConfirm: () async {
                            await DatabaseHelper.deleteBabyId(baby['id']);
                            if (!context.mounted) return;
                            UIHelper.justAlert(context, "ลบรายชื่อสำเร็จ");
                          },
                        );
                        if (!context.mounted) return;
                        if (isBabyDeleted == true) Navigator.pop(context, true);
                      } catch (error) {
                        if (!context.mounted) return;
                        UIHelper.popUpErrorMessage(context, "ไม่สามารถลบข้อมูลได้ โปรดตรวจสอบแล้วลองอีกครั้ง");
                      }
                    },
                  ),
                ),
                SizedBox(width: 10),
                //ปุ่มแก้ไขรายชื่อ
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.edit),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                      minimumSize: Size(0, 50),
                      iconSize: fontSize + 10,
                      textStyle: TextStyle(fontSize: fontSize),
                    ),
                    label: UIHelper.textBold("แก้ไข"),
                    onPressed: () async {
                      final bool? babyInfoHasChange = await editBabyInfoDialog(context, baby);
                      if (!context.mounted) return;
                      if (babyInfoHasChange == true) Navigator.pop(context, true);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  } //Future: popUpBabyOptions - dialog ลบ, แก้ไขรายชื่อทารก

  static Future<bool?> addBabyDialog(BuildContext context) async {
    TextEditingController hnController = TextEditingController();
    TextEditingController parentFNameController = TextEditingController();
    TextEditingController parentLNameController = TextEditingController();

    return await babyInputInfoDialog(
      context,
      title: "เพิ่มรายชื่อ",
      hnController: hnController,
      parentFNameController: parentFNameController,
      parentLNameController: parentLNameController,
      onConfirm: () async {
        String newHN = hnController.text.trim();
        String newParentFName = parentFNameController.text.trim();
        String newParentLName = parentLNameController.text.trim();
        await DatabaseHelper.addBaby(newHN: newHN, newParentFName: newParentFName, newParentLName: newParentLName);
      },
    );
  } //Future: popUpAddingBaby - dialog เพิ่มทารกใหม่เข้าระบบ

  static Future<dynamic> editBabyInfoDialog(BuildContext context, Map<String, dynamic> baby) async {
    TextEditingController hnController = TextEditingController(text: baby['hn']);
    TextEditingController parentFNameController = TextEditingController(text: baby['parent_fname']);
    TextEditingController parentLNameController = TextEditingController(text: baby['parent_lname']);

    String originHN = baby['hn'];
    String originParentFName = baby['parent_fname'];
    String originParentLName = baby['parent_lname'];

    return await babyInputInfoDialog(
      context,
      title: "แก้ไขข้อมูลรายชื่อ",
      hnController: hnController,
      parentFNameController: parentFNameController,
      parentLNameController: parentLNameController,
      confirmBtnIcon: Icons.save_as,
      onConfirm: () async {
        String newHN = hnController.text.trim();
        String newParentFName = parentFNameController.text.trim();
        String newParentLName = parentLNameController.text.trim();

        if (newHN == originHN && newParentFName == originParentFName && newParentLName == originParentLName) return;

        await DatabaseHelper.editBabyInfo(
          id: baby['id'],
          newHN: newHN,
          newParentFName: newParentFName,
          newParentLName: newParentLName,
        );
      },
    );
  } //Future: popUpEditingBabyInfo - dialog แก้ไขรายชื่อทารก

  static void handleProcessError(BuildContext context, error) {
    if (!context.mounted) return;
    if (error is String) {
      UIHelper.popUpErrorMessage(context, error);
    } else if (error.toString().contains('CHECK constraint failed')) {
      UIHelper.popUpErrorMessage(context, "กรุณากรอก HN ให้ครบ 6 หลัก");
    } else {
      UIHelper.popUpErrorMessage(context, "HN ซ้ำหรืออื่นๆ โปรดตรวจสอบแล้วลองอีกครั้ง");
    } //if( error เป็น String คือ เป็นข้อความที่มาจาก throw "" ; ) & else( error จะเป็น Object คือ มาจากระบบเอง )
  } //void: handleBabyUpdateError - dialog โชว์ error ของ dialog addingBaby กับ editBabyInfo
}//class: BabiesDialog