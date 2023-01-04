import 'dart:io';
import 'package:path/path.dart';
import 'package:excel/excel.dart';

class ExportExcel {
  var excel = Excel.createExcel();

  void createExcelTables() {
    for (var table in excel.tables.keys) {
      print('1 - $table');
      print('2 - ${excel.tables[table].maxCols}');
      print('3 - ${excel.tables[table].maxRows}');

      for (var row in excel.tables[table].rows) {
        print('Row: ${row.map((e) => e.value)}');
      }
    }

    //Declaring a cell style
    CellStyle cellStyle = CellStyle(
        bold: true,
        italic: false,
        textWrapping: TextWrapping.WrapText,
        fontFamily: getFontFamily(FontFamily.Comic_Sans_MS),
        rotation: 0);

    var sheet = excel['mySheet'];

    var cell = sheet.cell(CellIndex.indexByString('A1'));
    cell.value = 'Hey, this is just a test';
    cell.cellStyle = cellStyle;

    String outputFile = Directory.current.path + '/r.xlsx';

    List<int> fileBytes = excel.save();
    if (fileBytes != null) {
      File(join(outputFile))
        ..createSync(recursive: true)
        ..writeAsBytes(fileBytes);
    }
  }
}
