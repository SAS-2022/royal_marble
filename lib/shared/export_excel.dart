import 'dart:io';
import 'package:path/path.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';

class ExportExcel {
  List<dynamic> timeTable = [];
  File excelFile;
  var excel = Excel.createExcel();

  //Declaring a cell style
  CellStyle cellStyle = CellStyle(
      bold: true,
      italic: false,
      textWrapping: TextWrapping.WrapText,
      fontFamily: getFontFamily(FontFamily.Comic_Sans_MS),
      rotation: 0);

  Future<File> createExcelTables() async {
    var sheet = excel['timeSheet'];

    var cell = sheet.cell(CellIndex.indexByString('A1'));
    cell.value =
        'The Following table shows the attandance of the selected workers';
    cell.cellStyle = cellStyle;

    for (int index = 0; index < timeTable.length; index++) {
      var _colIndex = 2;

      for (var val in timeTable[index].values) {
        var cell1 = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: _colIndex, rowIndex: index),
        );
        cell1.value = val;

        _colIndex++;
      }
    }

    //get the local path
    final directory = await getApplicationDocumentsDirectory()
        .catchError((err) => print('Error getting directory: $err'));
    final path = directory.path;

    String outputFile = '$path/timesheet.xlsx';
    excelFile = File(outputFile);
    List<int> fileBytes = excel.save();

    if (fileBytes != null) {
      excelFile
        ..createSync(recursive: true)
        ..writeAsBytes(fileBytes)
            .catchError((err) => print('Error writing excel file: $err'));
    }

    return excelFile;
  }
}
