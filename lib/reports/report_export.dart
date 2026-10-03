import 'dart:typed_data';

import 'package:flutter/material.dart' show DateTimeRange;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xls;

import 'report_data.dart';

final _day = DateFormat('EEE d MMM yyyy');
final _time = DateFormat('HH:mm');
String _t(DateTime? d) => d == null ? '' : _time.format(d);
String _range(DateTimeRange r) =>
    '${DateFormat('d MMM yyyy').format(r.start)} – ${DateFormat('d MMM yyyy').format(r.end)}';

const _gold = PdfColor.fromInt(0xFFC2A64A);
const _charcoal = PdfColor.fromInt(0xFF23221C);
const _line = PdfColor.fromInt(0xFFE6E1D3);

/// Why a row needs a second look, in English like the rest of the export.
String _note(AttendanceRow r) => [
      if (r.autoReason == 'left_site') 'Auto check-out: left the site',
      if (r.autoReason == 'end_of_day') 'Auto check-out: end of day',
      if (r.corrected) 'Edited by admin',
      if (r.away.inMinutes > 0) 'Away ${formatDuration(r.away)}',
    ].join('; ');

/// Attendance report as a PDF: summary per person, then each day's entries.
Future<Uint8List> attendancePdf({
  required String title,
  required DateTimeRange range,
  required List<AttendanceRow> rows,
}) async {
  final doc = pw.Document(title: title, author: 'Royal Marble');
  final people = totalsByPerson(rows);
  final byDay = <DateTime, List<AttendanceRow>>{};
  for (final r in rows) {
    byDay.putIfAbsent(r.day, () => []).add(r);
  }

  pw.Widget table(List<String> headers, List<List<String>> data) =>
      pw.TableHelper.fromTextArray(
        headers: headers,
        data: data,
        border: const pw.TableBorder(
            horizontalInside: pw.BorderSide(color: _line, width: 0.5)),
        headerStyle: pw.TextStyle(
            color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9),
        headerDecoration: const pw.BoxDecoration(color: _charcoal),
        cellStyle: const pw.TextStyle(fontSize: 9),
        cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      );

  doc.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4.landscape,
    margin: const pw.EdgeInsets.all(28),
    header: (ctx) => pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 8),
      margin: const pw.EdgeInsets.only(bottom: 12),
      decoration: const pw.BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide(color: _gold, width: 2))),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('ROYAL MARBLE · $title',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
          pw.Text(_range(range), style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
    ),
    footer: (ctx) => pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
    ),
    build: (ctx) => [
      pw.Text('Summary',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
      pw.SizedBox(height: 6),
      table(
        ['Name', 'Days', 'Hours', 'Area (m²)', 'Missing check-outs'],
        [
          for (final p in people)
            [
              p.name,
              '${p.days}',
              formatDuration(p.worked),
              p.squareMeters == 0 ? '' : p.squareMeters.toStringAsFixed(1),
              p.missingCheckOuts == 0 ? '' : '${p.missingCheckOuts}',
            ]
        ],
      ),
      if (totalsBySite(rows).length > 1) ...[
        pw.SizedBox(height: 16),
        pw.Text('Hours by site',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
        pw.SizedBox(height: 6),
        table(
          ['Site', 'People', 'Days', 'Hours', 'Area (m²)'],
          [
            for (final t in totalsBySite(rows))
              [
                t.name,
                '${t.people}',
                '${t.days}',
                formatDuration(t.worked),
                t.squareMeters == 0 ? '' : t.squareMeters.toStringAsFixed(1),
              ]
          ],
        ),
      ],
      for (final e in byDay.entries) ...[
        pw.SizedBox(height: 16),
        pw.Text(_day.format(e.key),
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
        pw.SizedBox(height: 4),
        table(
          ['Name', 'Site', 'In', 'Out', 'Hours', 'Work', 'Area (m²)', 'Note'],
          [
            for (final r in e.value)
              [
                r.name,
                r.project,
                _t(r.arrived),
                r.stillOnSite ? 'on site' : _t(r.left),
                r.worked == null ? '' : formatDuration(r.worked!),
                r.workType ?? '',
                r.squareMeters?.toStringAsFixed(1) ?? '',
                _note(r),
              ]
          ],
        ),
      ],
    ],
  ));
  return doc.save();
}

/// Attendance as an Excel workbook: a "Daily" sheet and a "Summary" sheet.
List<int> attendanceXlsx({
  required DateTimeRange range,
  required List<AttendanceRow> rows,
}) {
  final book = xls.Workbook();
  final header = book.styles.add('header')
    ..bold = true
    ..fontColor = '#FFFFFF'
    ..backColor = '#23221C';

  void headers(xls.Worksheet s, List<String> names) {
    for (var c = 0; c < names.length; c++) {
      s.getRangeByIndex(1, c + 1)
        ..setText(names[c])
        ..cellStyle = header;
    }
  }

  final daily = book.worksheets[0]..name = 'Daily';
  headers(daily, [
    'Date', 'Name', 'Site', 'In', 'Out', 'Hours', 'Work', 'Area (m²)', 'Note'
  ]);
  for (var i = 0; i < rows.length; i++) {
    final r = rows[i];
    final row = i + 2;
    daily.getRangeByIndex(row, 1).setText(DateFormat('yyyy-MM-dd').format(r.day));
    daily.getRangeByIndex(row, 2).setText(r.name);
    daily.getRangeByIndex(row, 3).setText(r.project);
    daily.getRangeByIndex(row, 4).setText(_t(r.arrived));
    daily.getRangeByIndex(row, 5).setText(r.stillOnSite ? 'on site' : _t(r.left));
    if (r.worked != null) {
      daily.getRangeByIndex(row, 6).setNumber(
          double.parse((r.worked!.inMinutes / 60).toStringAsFixed(2)));
    }
    daily.getRangeByIndex(row, 7).setText(r.workType ?? '');
    if (r.squareMeters != null) {
      daily.getRangeByIndex(row, 8).setNumber(r.squareMeters!);
    }
    daily.getRangeByIndex(row, 9).setText(_note(r));
  }
  daily.getRangeByIndex(1, 1, rows.length + 1, 9).autoFitColumns();

  final summary = book.worksheets.addWithName('Summary');
  headers(summary, ['Name', 'Days', 'Hours', 'Area (m²)', 'Missing check-outs']);
  final people = totalsByPerson(rows);
  for (var i = 0; i < people.length; i++) {
    final p = people[i];
    final row = i + 2;
    summary.getRangeByIndex(row, 1).setText(p.name);
    summary.getRangeByIndex(row, 2).setNumber(p.days.toDouble());
    summary.getRangeByIndex(row, 3).setNumber(
        double.parse((p.worked.inMinutes / 60).toStringAsFixed(2)));
    summary.getRangeByIndex(row, 4).setNumber(p.squareMeters);
    summary.getRangeByIndex(row, 5).setNumber(p.missingCheckOuts.toDouble());
  }
  summary.getRangeByIndex(1, 1, people.length + 1, 5).autoFitColumns();

  final bySite = book.worksheets.addWithName('By site');
  headers(bySite, ['Site', 'People', 'Days', 'Hours', 'Area (m²)']);
  final sites = totalsBySite(rows);
  for (var i = 0; i < sites.length; i++) {
    final t = sites[i];
    final row = i + 2;
    bySite.getRangeByIndex(row, 1).setText(t.name);
    bySite.getRangeByIndex(row, 2).setNumber(t.people.toDouble());
    bySite.getRangeByIndex(row, 3).setNumber(t.days.toDouble());
    bySite.getRangeByIndex(row, 4).setNumber(
        double.parse((t.worked.inMinutes / 60).toStringAsFixed(2)));
    bySite.getRangeByIndex(row, 5).setNumber(t.squareMeters);
  }
  bySite.getRangeByIndex(1, 1, sites.length + 1, 5).autoFitColumns();

  final bytes = book.saveAsStream();
  book.dispose();
  return bytes;
}

/// Sales activity as a PDF: one row per salesperson plus their visits.
Future<Uint8List> salesPdf({
  required DateTimeRange range,
  required List<SalesSummary> sales,
}) async {
  final doc = pw.Document(title: 'Sales report', author: 'Royal Marble');
  doc.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.all(28),
    header: (ctx) => pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 8),
      margin: const pw.EdgeInsets.only(bottom: 12),
      decoration: const pw.BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide(color: _gold, width: 2))),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('ROYAL MARBLE · Sales report',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
          pw.Text(_range(range), style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
    ),
    build: (ctx) => [
      pw.TableHelper.fromTextArray(
        headers: ['Salesperson', 'Working days', 'Client visits', 'Project visits'],
        data: [
          for (final s in sales)
            [
              '${s.user.firstName ?? ''} ${s.user.lastName ?? ''}',
              '${s.workingDays}',
              '${s.clientVisits.length}',
              '${s.projectVisits.length}',
            ]
        ],
        headerDecoration: const pw.BoxDecoration(color: _charcoal),
        headerStyle: pw.TextStyle(
            color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10),
        cellStyle: const pw.TextStyle(fontSize: 10),
      ),
      for (final s in sales)
        if (s.totalVisits > 0) ...[
          pw.SizedBox(height: 14),
          pw.Text('${s.user.firstName ?? ''} ${s.user.lastName ?? ''}',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.TableHelper.fromTextArray(
            headers: ['Date', 'Type', 'Name', 'Purpose'],
            data: [
              for (final v in s.clientVisits)
                ['${v.visitTime}', 'Client', v.clientName ?? '', v.visitPurpose ?? ''],
              for (final v in s.projectVisits)
                ['${v.visitTime}', 'Project', v.projectName ?? '', v.visitPurpose ?? ''],
            ]..sort((a, b) => a[0].compareTo(b[0])),
            headerDecoration: const pw.BoxDecoration(color: _line),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
            cellStyle: const pw.TextStyle(fontSize: 9),
          ),
        ],
    ],
  ));
  return doc.save();
}
