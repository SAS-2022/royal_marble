import 'dart:async';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:royal_marble/shared/generating_pdf.dart';

const fileTypes = [
  PdfBuilder('generating_pdf.dart', generateReport),
];

typedef LayoutCallbackWithData = Future<Uint8List> Function(
    PdfPageFormat pageFormat, List<dynamic> data);

class PdfBuilder {
  const PdfBuilder(this.file, this.builder);
  final String file;
  final LayoutCallbackWithData builder;
}
