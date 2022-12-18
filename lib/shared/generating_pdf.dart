import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:typed_data';

import 'package:printing/printing.dart';

Future<Uint8List> generateReport(
  PdfPageFormat pdfPageFormat,
  List<dynamic> data,
) async {
  const tableHead = [
    'Name',
    'Arrived',
    'Left',
    'Project',
    'Total Hours',
    'Work Type',
    'Meters'
  ];
  Map<String, List<Map>> days = {};
  Map<String, List<Map<dynamic, dynamic>>> userTimeTable = {};
  int pageRowNumber = 0;

  final document = pw.Document();
  final theme = pw.ThemeData.withFont(
    base: await PdfGoogleFonts.openSansRegular(),
    bold: await PdfGoogleFonts.openSansBold(),
  );
  const baseColor = PdfColors.amber;
  List<pw.Widget> pageWidgets = [];

  Future<Map<String, List<Map>>> generateTableDate() async {
    var totalHours;
    var totalMin;
    for (var index = 0; index < data.length; index++) {
      var arrived = data[index]['arrivedAt'] != null
          ? DateTime.parse(data[index]['arrivedAt'])
          : null;
      var left = data[index]['leftAt'] != null
          ? DateTime.parse(data[index]['leftAt'])
          : null;
      if (left != null && arrived != null) {
        var diff = left.difference(arrived);
        totalHours = diff.inHours;
        totalMin = diff.inMinutes % 60;
      }

      var thisDate = '${arrived.day}-${arrived.month}-${arrived.year}';
      //will update the list if the day is alreayd added

      if (days[thisDate] != null) {
        days[thisDate].add({
          'name': '${data[index]['firstName']} ${data[index]['lastName']}',
          'arrived':
              arrived != null ? DateFormat('hh:mm a').format(arrived) : '',
          'left': left != null ? DateFormat('hh:mm a').format(left) : '',
          'project': data[index]['projectName'],
          'totalHours': '$totalHours:$totalMin',
          'workType': '${data[index]['workType']}',
          'meters': '${data[index]['squareMeters']}',
        });
      }

      //will add a day if it doesn't exist in the map
      days.putIfAbsent(
          thisDate,
          () => [
                {
                  'name':
                      '${data[index]['firstName']} ${data[index]['lastName']}',
                  'arrived': arrived != null
                      ? DateFormat('hh:mm a').format(arrived)
                      : '',
                  'left':
                      left != null ? DateFormat('hh:mm a').format(left) : '',
                  'project': data[index]['projectName'],
                  'totalHours': '$totalHours:$totalMin',
                  'workType': '${data[index]['workType']}',
                  'meters': '${data[index]['squareMeters']}',
                }
              ]);
    }
    return days;
  }

  userTimeTable = await generateTableDate();
  Map<int, pw.TableColumnWidth> widths = {};

  widths = {
    0: const pw.FractionColumnWidth(0.5),
    1: const pw.FractionColumnWidth(0.1),
    2: const pw.FractionColumnWidth(0.1),
    3: const pw.FractionColumnWidth(0.15),
    4: const pw.FractionColumnWidth(0.1),
    5: const pw.FractionColumnWidth(0.15),
    6: const pw.FractionColumnWidth(0.1),
  };

  List<pw.Table> table = [];
  List.generate(userTimeTable.length, (index) {
    String key = userTimeTable.keys.elementAt(index);

    table.add(
      pw.Table.fromTextArray(
        border: null,
        data: [
          [key]
        ],
        columnWidths: widths,
        headerStyle: pw.TextStyle(
            color: PdfColors.white, fontWeight: pw.FontWeight.bold),
        headerDecoration: const pw.BoxDecoration(color: PdfColors.amber700),
        rowDecoration: const pw.BoxDecoration(
          border: pw.Border(
            bottom: pw.BorderSide(color: PdfColors.amber700, width: 0.5),
          ),
        ),
        cellAlignment: pw.Alignment.center,
        cellAlignments: {0: pw.Alignment.center},
      ),
    );

    table.add(
      pw.Table.fromTextArray(
        border: null,
        headers: tableHead,
        data: List<List<dynamic>>.generate(
          userTimeTable[key].length,
          (i) {
            List<String> list = [
              userTimeTable[key][i]['name'],
              userTimeTable[key][i]['arrived'] ?? '',
              userTimeTable[key][i]['left'] ?? '',
              userTimeTable[key][i]['project'],
              userTimeTable[key][i]['totalHours'],
              userTimeTable[key][i]['workType'],
              userTimeTable[key][i]['meters']
            ];
            pageRowNumber = list.length + userTimeTable.length;

            return list;
          },
        ),
        headerStyle: pw.TextStyle(
            color: PdfColors.white, fontWeight: pw.FontWeight.bold),
        headerDecoration: const pw.BoxDecoration(color: PdfColors.amber400),
        rowDecoration: const pw.BoxDecoration(
          border: pw.Border(
            bottom: pw.BorderSide(color: PdfColors.amber400, width: 0.5),
          ),
        ),
        cellAlignment: pw.Alignment.center,
        cellAlignments: {0: pw.Alignment.centerLeft},
      ),
    );
  });
  pageWidgets.add(
    pw.Text(
      'Attendance Report',
      style: const pw.TextStyle(color: baseColor, fontSize: 36),
    ),
  );
  pageWidgets.add(pw.Divider(thickness: 4));
  pageWidgets.add(pw.ListView(children: table));

  document.addPage(pw.MultiPage(
    pageFormat: pdfPageFormat,
    theme: theme,
    build: (context) {
      return pageWidgets;
    },
  ));

  return document.save();
}
