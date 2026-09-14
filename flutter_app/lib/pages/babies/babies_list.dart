import 'package:bstp_v2/pages/babies/baby_route_hub.dart';
import 'package:flutter/material.dart'; //ของ Flutter
import 'package:bstp_v2/services/ui_helper.dart';
import 'package:bstp_v2/services/database_handler.dart'; // class จากไฟล์ Database
import 'package:bstp_v2/services/babies_list_dialog_handler.dart';

class BabiesListPage extends StatefulWidget {
  const BabiesListPage({super.key});
  @override
  State<BabiesListPage> createState() => _BabiesPageState();
} //class BabiesListPage

class _BabiesPageState extends State<BabiesListPage> {
  List<Map<String, dynamic>> containBabies = [];
  List<Map<String, dynamic>> displayBabies = [];
  TextEditingController searchController = TextEditingController();
  bool searchBarInUse = false;
  final FocusNode focusNodeSearchBar = FocusNode();

  @override
  void initState() {
    super.initState();
    handleFetchBabiesList();
  } //void: initState - เริ่มต้นหน้าแอพ ทำคำสั่งนี้ครั้งแรกครั้งเดียว

  @override
  void dispose() {
    focusNodeSearchBar.dispose();
    super.dispose();
  } //void: dispose -  คืนหน่วยความจำเมื่อเลิกใช้งาน Search Bar

  Future handleFetchBabiesList() async {
    List<Map<String, dynamic>> getBabiesList = await DatabaseHelper.fetchBabiesData();

    setState(() {
      containBabies = getBabiesList;
      displayBabies = containBabies;
    });
  } // Future: handleFetchBabiesList - ดึงข้อมูลจากดาต้าเบตมาใส่ตัวแปร displayBabiesList

  Widget searchBarUXUI() {
    return Center(
      child: SizedBox(
        height: UIHelper.screenWidth(context, 0.11, lowerLimit: 0, upperLimit: 40),
        width: UIHelper.screenWidth(context, 0.84),
        child: TextField(
          controller: searchController,
          onChanged: onSearchFilter,
          focusNode: focusNodeSearchBar,
          decoration: InputDecoration(
            contentPadding: EdgeInsets.zero,
            labelText: "ค้นหา...",
            hintText: "ค้นหา...",
            filled: true,
            fillColor: Colors.white,
            floatingLabelBehavior: FloatingLabelBehavior.never,
            floatingLabelStyle: TextStyle(color: Colors.white),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(32)),
              borderSide: BorderSide(color: Colors.white),
            ),

            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(32)),
              borderSide: BorderSide(color: const Color(0xFFB7B7B7)),
            ),

            prefixIcon: Icon(Icons.search, color: Colors.grey.shade700),
            suffixIcon: IconButton(
              icon: Icon(Icons.cancel_rounded, color: Colors.grey.shade700, size: 26),
              onPressed: () => resetSearchBar(),
            ),
          ),
        ),
      ),
    );
  } //Widget: searchBarUXUI

  void onSearchFilter(String query) {
    setState(() {
      if (query.isEmpty) {
        displayBabies = containBabies; // ถ้าช่องค้นหา = "ว่าง" ให้โชว์ทุกรายการ
      } else {
        displayBabies = containBabies.where((baby) {
          final name = baby['parent_name'].toLowerCase();
          final hn = baby['hn'].toLowerCase();
          final searchLower = query.toLowerCase();

          // ค้นหาได้ทั้งชื่อ และ HN
          return name.contains(searchLower) || hn.contains(searchLower);
        }).toList();
      }
    });
  } //void: searchFilter

  List<Widget>? appbarActionsPanel() {
    return [
      //ปุ่มไอคอนค้นหา
      IconButton(
        icon: Icon(Icons.search),
        iconSize: 30,
        onPressed: () {
          setState(() {
            searchBarInUse = true;
            focusNodeSearchBar.requestFocus();
          });
        },
      ),
      //ปุ่มไอคอนบวก( เพิ่มรายชื่อ )
      Padding(
        padding: EdgeInsets.only(right: 20),
        child: IconButton(
          iconSize: 30,
          icon: Icon(Icons.person_add),
          onPressed: () async {
            final bool? addNewBaby = await BabiesDialog.addBabyDialog(context);
            if (addNewBaby == true) {
              await handleFetchBabiesList();
            }
          },
        ),
      ),
    ];
  } //appBarActionsButton

  Widget babiesListTileUXUI() {
    return RefreshIndicator(
      onRefresh: () => handleFetchBabiesList(),
      backgroundColor: UIHelper.appThemeBackground,
      color: UIHelper.appThemeForeground,
      child: ListView.builder(
        itemCount: displayBabies.length,
        //เนื้อหา
        itemBuilder: (context, index) {
          final baby = displayBabies[index];

          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade300, width: 1)),
            ),
            child: ListTile(
              title: Text("HN: ${baby['hn']}"),
              subtitle: Text("ชื่อมารดา: ${baby['parent_fname']} ${baby['parent_lname']}"),
              trailing: Icon(
                // Icons.keyboard_double_arrow_right_rounded,
                Icons.keyboard_double_arrow_right_rounded,
                size: 22,
              ),
              onTap: () =>
                  Navigator.push(context, MaterialPageRoute(builder: (context) => BabyRouteHubPage(baby: baby))),
              onLongPress: () async {
                final bool? deleteOrChangeBabyInfo = await BabiesDialog.babyOptionsDialog(context, baby);
                if (deleteOrChangeBabyInfo == true) {
                  await handleFetchBabiesList();
                } //if( มีการเปลี่ยนแปลงข้อมูลในระบบ )
              },
            ),
          );
        },
      ),
    );
  } //Widget: showBabiesList

  void resetSearchBar() {
    setState(() {
      setState(() {
        searchBarInUse = false;
        searchController.clear();
        onSearchFilter("");
      });
    });
  } //void: resetSearchBar

  PreferredSizeWidget pageAppBar() {
    return AppBar(
      backgroundColor: UIHelper.appThemeBackground,
      foregroundColor: UIHelper.appThemeForeground,
      title: (searchBarInUse == true) ? searchBarUXUI() : UIHelper.textBold("รายการทั้งหมด", fontSize: 20),
      actions: (searchBarInUse == true) ? null : appbarActionsPanel(),
    );
  } //Widget: pageAppBar

  Widget pageBody() {
    return displayBabies.isEmpty
        ? Center(child: UIHelper.messageOnCenterDisplay(context, "ไม่พบรายชื่อในระบบ"))
        : babiesListTileUXUI();
  } //Widget: pageBody - เนื้อหา body

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: pageAppBar(), body: pageBody());
  } //Widget: build - จัดการ Scaffold
}//class: BabiesListPage