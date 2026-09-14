//=============================================================
//    ฟังก์ชันสำหรับจัดการบานข้อมูลของแอพ ( Database )
//=============================================================

import 'dart:convert';
import 'package:path/path.dart'; // จาก pub.get: ใช้อะไรสักอย่างเกี่ยวกับ
import 'package:sqflite/sqflite.dart'; // จาก pub.get: ของ Database Sqflite

class DatabaseHelper {
  const DatabaseHelper();

  static const String dbName = "baby_suction.db";
  static const int _version = 1;

  static const int fixedHNDigits = 7;

  static Future<Database> _connectDatabase() async {
    String createBabyTableSQL =
        '''
    CREATE TABLE babies (
      id INTEGER PRIMARY KEY, 
      hn TEXT UNIQUE CHECK (length(hn) == $fixedHNDigits ), 
      parent_fname TEXT NOT NULL,
      parent_lname TEXT NOT NULL
    )
    ''';

    String createTestHistoryTableSQL = '''
    CREATE TABLE test_history (
      history_id INTEGER PRIMARY KEY AUTOINCREMENT,
      baby_id INTEGER NOT NULL,
      measure_at TEXT NOT NULL,
      max_value REAL NOT NULL,
      avg_value REAL NOT NULL,
      min_value REAL NOT NULL,
      suction_count INTEGER NOT NULL,
      test_duration TEXT NOT NULL,
      graph TEXT NOT NULL,
      FOREIGN KEY (baby_id) REFERENCES babies (id) ON DELETE RESTRICT
    )
    ''';

    try {
      return await openDatabase(
        join(await getDatabasesPath(), dbName),
        onConfigure: (db) async => await db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, version) async {
          await db.execute(createBabyTableSQL);
          await db.execute(createTestHistoryTableSQL);
        },
        version: _version,
      );
    } catch (error /*, stackTrack*/) {
      // print("Database Connection Error: $error");
      // print("StackTrack : $stackTrack");
      rethrow;
    }
  } //Future: _connectDatabase

  static Future<int> addBaby({
    required String newHN,
    required String newParentFName,
    required String newParentLName,
  }) async {
    try {
      final db = await _connectDatabase();

      return await db.insert("babies", {
        "hn": newHN,
        "parent_fname": newParentFName,
        "parent_lname": newParentLName,
      }); //คืนค่าเป็น Row ID ที่ถูกดำเนินการ
    } catch (error /*, stackTrack*/) {
      // print("Create Baby Error : $error");
      // print("StackTrack : $stackTrack");
      rethrow;
    }
  } //Future: addBabyInfo

  static Future<int> deleteBabyId(int id) async {
    try {
      final db = await _connectDatabase();

      return await db.delete("babies", where: 'id = ?', whereArgs: [id]);
    } catch (error /*, stackTrack*/) {
      // print("Delete Baby ID Error : $error");
      // print("StackTrack : $stackTrack");
      rethrow;
    }
  } //Future: addBabyInfo

  static Future<int> editBabyInfo({
    required int id,
    required String newHN,
    required String newParentFName,
    required String newParentLName,
  }) async {
    print(id);
    print(newHN);
    print(newParentFName);
    print(newParentLName);

    try {
      final db = await _connectDatabase();

      return await db.update(
        "babies",
        {"hn": newHN, "parent_fname": newParentFName, "parent_lname": newParentLName},
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (error /*, stackTrack*/) {
      // print("Delete Baby ID Error : $error");
      // print("StackTrack : $stackTrack");
      rethrow;
    }
  } //Future: editBabyInfo

  static Future<List<Map<String, dynamic>>> fetchBabiesData() async {
    try {
      final db = await _connectDatabase();

      return await db.query("babies");
    } catch (error /*, stackTrack*/) {
      // print("Fetch Babies Data Error : $error");
      // print("StackTrack : $stackTrack");
      rethrow;
    }
  } //function: Get all babies data.

  static Future<List<Map<String, dynamic>>> fetchTestsHistoryByHistoryId({required List<int> historyIds}) async {
    String placeholders = List.filled(historyIds.length, '?').join(', ');

    try {
      final db = await _connectDatabase();

      return await db.query("test_history", where: 'history_id IN ($placeholders)', whereArgs: historyIds);
    } catch (error /*, stackTrack*/) {
      // print("Fetch Babies Data Error : $error");
      // print("StackTrack : $stackTrack");
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> fetchTestsHistoryByBabyId({required int id}) async {
    try {
      const List<String> allColumnExceptGraphSQL = [
        'history_id',
        'baby_id',
        'measure_at',
        'max_value',
        'avg_value',
        'min_value',
        'suction_count',
        'test_duration',
      ];
      final db = await _connectDatabase();

      return await db.query("test_history", where: 'baby_id = ?', whereArgs: [id], columns: allColumnExceptGraphSQL);
    } catch (error /*, stackTrack*/) {
      // print("Fetch Babies Data Error : $error");
      // print("StackTrack : $stackTrack");
      rethrow;
    }
  } //function: Get all test history of baby.

  static Future<int> saveTestHistoryOfBaby(Map<String, dynamic> dataOfTest) async {
    try {
      final db = await _connectDatabase();

      return await db.insert("test_history", {
        "baby_id": dataOfTest["baby_id"],
        "measure_at": dataOfTest["measure_at"],
        "max_value": dataOfTest["max_value"],
        "avg_value": dataOfTest["avg_value"],
        "min_value": dataOfTest["min_value"],
        "suction_count": dataOfTest["suction_count"],
        "test_duration": dataOfTest["test_duration"],
        "graph": jsonEncode(dataOfTest["graph"]),
      });
    } catch (error /*, stackTrack*/) {
      // print("Create History Error : $error");
      // print("StackTrack : $stackTrack");
      rethrow;
    }
  } //function: Save test history to baby.

  static Future<int> deleteTestHistory(int historyId) async {
    try {
      final db = await _connectDatabase();

      return await db.delete("test_history", where: 'history_id = ?', whereArgs: [historyId]);
    } catch (error /*, stackTrack*/) {
      // print("Create History Error : $error");
      // print("StackTrack : $stackTrack");
      rethrow;
    }
  }
} //class: BabiesDatabase
