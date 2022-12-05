import 'dart:math';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:typed_data';

import 'package:printing/printing.dart';

Future<Uint8List> generateReport(
  PdfPageFormat pdfPageFormat,
  List<dynamic> data,
) async {
  const tableHead = ['Name', 'Arrived', 'Left', 'Project', 'Total Hours'];

  final document = pw.Document();
  final theme = pw.ThemeData.withFont(
    base: await PdfGoogleFonts.openSansRegular(),
    bold: await PdfGoogleFonts.openSansBold(),
  );
  const baseColor = PdfColors.amber;

  final chart1 = pw.Chart(
    left: pw.Container(
      alignment: pw.Alignment.topCenter,
      margin: const pw.EdgeInsets.all(10),
      child: pw.Transform.rotateBox(
        angle: pi / 2,
        child: pw.Text('Hours'),
      ),
    ),
    overlay: pw.ChartLegend(
      position: const pw.Alignment(-7, 1),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(
          color: PdfColors.black,
          width: 1,
        ),
      ),
    ),
    grid: pw.CartesianGrid(
        yAxis: pw.FixedAxis(
          [
            1,
            5,
            10,
            20,
            25,
          ],
          marginStart: 30,
          marginEnd: 30,
          ticks: true,
        ),
        xAxis: pw.FixedAxis.fromStrings(
          List.generate(data.length, (index) {
            return '${data[index]['firstName']} ${data[index]['lastName']}';
          }),
          marginStart: 50,
          marginEnd: 50,
          ticks: true,
        )),
    datasets: [
      pw.BarDataSet(
        color: PdfColors.blue100,
        legend: tableHead[0],
        width: 15,
        offset: -10,
        borderColor: baseColor,
        data: List<pw.PointChartValue>.generate(
          data.length,
          (index) {
            var arrived = data[index]['arrivedAt'] != null
                ? DateTime.parse(data[index]['arrivedAt'])
                : null;
            var left = data[index]['leftAt'] != null
                ? DateTime.parse(data[index]['leftAt'])
                : null;
            var diff = left.difference(arrived);
            var totalHours = diff.inHours;
            print('the total Hours: $totalHours');
            return pw.PointChartValue(index.toDouble(), totalHours.toDouble());
          },
        ),
      ),
    ],
  );

  final table = pw.Table.fromTextArray(
      border: null,
      headers: tableHead,
      data: List<List<String>>.generate(
        data.length,
        (index) {
          var arrived = data[index]['arrivedAt'] != null
              ? DateTime.parse(data[index]['arrivedAt'])
              : null;
          var left = data[index]['leftAt'] != null
              ? DateTime.parse(data[index]['leftAt'])
              : null;
          var diff = left.difference(arrived);
          var totalHours = diff.inHours;
          var totalMin = diff.inMinutes % 60;

          return <String>[
            '${data[index]['firstName']} ${data[index]['lastName']}',
            DateFormat('hh:mm a').format(arrived),
            DateFormat('hh:mm a').format(left),
            data[index]['projectName'],
            '$totalHours:$totalMin'
          ];
        },
      ),
      headerStyle:
          pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold),
      headerDecoration: const pw.BoxDecoration(color: baseColor),
      rowDecoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: baseColor, width: 0.5),
        ),
      ),
      cellAlignment: pw.Alignment.center,
      cellAlignments: {0: pw.Alignment.centerLeft});

  document.addPage(pw.Page(
    pageFormat: pdfPageFormat,
    theme: theme,
    build: (context) {
      return pw.Column(children: [
        pw.Text(
          'Attendance Report',
          style: const pw.TextStyle(color: baseColor, fontSize: 36),
        ),
        pw.Divider(thickness: 4),
        pw.Container(height: pdfPageFormat.height / 2, child: chart1),
        pw.Divider(thickness: 2),
        pw.Container(height: pdfPageFormat.height / 2 - 10, child: table),
      ]);
    },
  ));

  return document.save();
}
