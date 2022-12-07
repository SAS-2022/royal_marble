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
  Map<String, List<Map>> days = {};

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
          marginStart: 20,
          marginEnd: 20,
          ticks: true,
        )),
    datasets: [
      pw.BarDataSet(
        color: PdfColors.blue200,
        legend: tableHead[0],
        width: 15,
        offset: 0,
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
          var thisDate = '${arrived.day}-${arrived.month}-${arrived.year}';
          //will add a day if it doesn't exist in the map
          days.putIfAbsent(
              thisDate,
              () => [
                    {
                      'name':
                          '${data[index]['firstName']} ${data[index]['lastName']}',
                      'arrived': DateFormat('hh:mm a').format(arrived),
                      'left': DateFormat('hh:mm a').format(left),
                      'project': data[index]['projectName'],
                      'totalHours': '$totalHours:$totalMin'
                    }
                  ]);
          //will update the list if the day is alreayd added

          if (days[thisDate] != null) {
            days[thisDate].add({
              'name': '${data[index]['firstName']} ${data[index]['lastName']}',
              'arrived': DateFormat('hh:mm a').format(arrived),
              'left': DateFormat('hh:mm a').format(left),
              'project': data[index]['projectName'],
              'totalHours': '$totalHours:$totalMin'
            });
          }

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
        pw.Container(height: pdfPageFormat.height / 4, child: chart1),
        pw.Divider(thickness: 2),
        pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(),
            ),
            height: pdfPageFormat.height,
            child: table),
      ]);
    },
  ));

  return document.save();
}
