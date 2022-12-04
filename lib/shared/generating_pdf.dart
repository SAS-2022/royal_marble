import 'dart:math';
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
        yAxis: pw.FixedAxis.fromStrings(
          [
            '100',
            '200',
            '300',
            '400',
            '500',
          ],
          marginStart: 30,
          marginEnd: 30,
          ticks: true,
        ),
        xAxis: pw.FixedAxis.fromStrings(
          [
            'Yasser',
            'Ali',
            'Samir',
          ],
          marginStart: 30,
          marginEnd: 30,
          ticks: true,
        )),
    datasets: [],
  );

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
      ]);
    },
  ));

  return document.save();
}
