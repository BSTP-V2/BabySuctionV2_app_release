//=============================================================
//    ฟังก์ชันสำหรับที่จำเกี่ยวกับการทดสอบ
//=============================================================

import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SuctionTestHandler {
  static String currentUnit = "";

  static List<List<double>> decodeGraphJsonToListDouble({required String graphAsJson}) {
    List<dynamic> graphInListDynamic = jsonDecode(graphAsJson);

    return graphInListDynamic.map((innerList) {
      return (innerList as List<dynamic>).map((value) {
        // ใช้ .toDouble() เพื่อป้องกันกรณี JSON เก็บเป็น int (เช่น 10 แทนที่จะเป็น 10.0)
        return (value as num).toDouble();
      }).toList();
    }).toList();
  } //Decode json format of graph to List<List<double>>.

  static double doubleAsFixed(double num, {required int fixed}) {
    return double.parse(num.toStringAsFixed(fixed));
  } //Make double to as .

  static String handleDisplayDateTime(String dateTimeIsoFormat, {String format = 'dd/MM/yyyy - HH:mm'}) {
    if (dateTimeIsoFormat.isEmpty) return '';

    DateTime dateTime = DateTime.parse(dateTimeIsoFormat);

    return DateFormat(format).format(dateTime);
  } //handleDisplayDateTime

  static List<List<double>> graphConvertToCurrentUnit(List<List<double>> graphData) {
    List<List<double>> graphOnCurrentUnit = graphData
        .map<List<double>>((data) => [data[0], SuctionTestHandler.convertHPaToCurrentUnit(data[1])])
        .toList();
    return graphOnCurrentUnit;
  } //funciton: Just convert graph to current unit that user selected.

  static List<FlSpot> graphConvertListDoubleToFLSpot(List<List<double>> graphOnCurrentUnit) {
    List<FlSpot> graphTypeFlSpot = graphOnCurrentUnit.map((data) {
      return FlSpot((data[0] as num).toDouble(), (data[1] as num).toDouble());
    }).toList(); // data[0] คือแกน X, data[1] คือแกน Y
    return graphTypeFlSpot;
  } //function: Will convert graph type List<List<double>> to List<FlSpot>.

  static Color getColorOfValue(double value) {
    if (value >= 75) {
      return Colors.blue.shade600;
    } else if (value >= 70) {
      return Colors.green;
    } else if (value >= 40) {
      return Colors.orange;
    } else if (value >= 15) {
      return Colors.red;
    } else {
      return Colors.blueGrey.shade600;
    } //ifelse
  } //function : Get color of value.

  static double convertHPaToCurrentUnit(double hPa) {
    double convertedValue;
    if (currentUnit == "mmHg") {
      convertedValue = hPa * 0.750062;
    } else if (currentUnit == "kPa") {
      convertedValue = hPa / 10.0;
    } else if (currentUnit == 'N/m^2') {
      convertedValue = hPa * 100.0;
    } else {
      convertedValue = 0.0;
    } //Check unit condition .
    return doubleAsFixed(convertedValue, fixed: 2);
  } //function: Auto convert to current unit.
} //class
