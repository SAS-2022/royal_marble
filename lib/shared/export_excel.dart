import 'package:flutter/material.dart';
import 'package:royal_marble/models/user_model.dart';
import 'package:royal_marble/services/database.dart';
import 'package:royal_marble/shared/save_launch_file.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' hide Column;

class CreateExcelFile extends StatefulWidget {
  const CreateExcelFile(
      {Key key,
      this.generatedDate,
      this.reportSection,
      this.selectedUsers,
      this.mappedData})
      : super(key: key);
  final List<dynamic> generatedDate;
  final Map<dynamic, dynamic> mappedData;
  final String reportSection;
  final List<UserData> selectedUsers;

  @override
  State<CreateExcelFile> createState() => _CreateExcelFileState();
}

class _CreateExcelFileState extends State<CreateExcelFile> {
  Size _size;
  List<UserData> allUsers = [];
  DatabaseService db = DatabaseService();
  @override
  Widget build(BuildContext context) {
    _size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Excel File'),
        backgroundColor: const Color.fromARGB(255, 54, 214, 75),
      ),
      body: _buildExcelFileBody(),
    );
  }

  @override
  void initState() {
    super.initState();
    //get all users depending on the report section
    _getAllUsers();
  }

  void _getAllUsers() async {
    if (widget.reportSection != null) {
      //get users depending on the section
      allUsers = await db.getUsersPerRole(userRole: widget.reportSection);
    }
  }

  Widget _buildExcelFileBody() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SizedBox(
          height: _size.height - 200,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              SizedBox(
                width: _size.width - 20,
                height: 50,
                child: ElevatedButton(
                  style: ButtonStyle(
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                    ),
                    backgroundColor: MaterialStateProperty.resolveWith<Color>(
                      (Set<MaterialState> states) {
                        if (states.contains(MaterialState.pressed)) {
                          return const Color.fromARGB(255, 103, 48, 11);
                        }
                        return const Color.fromARGB(255, 13, 74, 21);
                      },
                    ),
                  ),
                  onPressed: generateExcel,
                  child: const Text('Generate Excel'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> generateExcel() async {
    var startingDate;
    //create workbook
    final Workbook workbook = Workbook();
    //accessing the workbook with the index
    final Worksheet sheet = workbook.worksheets[0];
    sheet.showGridlines = true;
    //enable sheet calculations
    sheet.enableSheetCalculations();
    var totalHours;
    var totalMin;

    //add sheet title
    sheet.getRangeByIndex(1, 1).setText('Employees Timetable');

    //add title for excel sheet first
    sheet.getRangeByIndex(3, 1).columnWidth = 20;
    sheet.getRangeByIndex(3, 1).setText('Employee Name');
    sheet.getRangeByIndex(3, 2).columnWidth = 30;
    sheet.getRangeByIndex(3, 2).setText('Arrived At');
    sheet.getRangeByIndex(3, 3).columnWidth = 30;
    sheet.getRangeByIndex(3, 3).setText('Left At');
    sheet.getRangeByIndex(3, 4).columnWidth = 10;
    sheet.getRangeByIndex(3, 4).setText('Project');
    sheet.getRangeByIndex(3, 5).columnWidth = 10;
    sheet.getRangeByIndex(3, 5).setText('Total Hours');
    sheet.getRangeByIndex(3, 6).columnWidth = 10;
    sheet.getRangeByIndex(3, 6).setText('Work Type');
    sheet.getRangeByIndex(3, 7).columnWidth = 10;
    sheet.getRangeByIndex(3, 7).setText('Meters');

    final Range range1 = sheet.getRangeByName('A1: G1');
    final Range range2 = sheet.getRangeByName('A3: G3');
    range1.cellStyle.fontSize = 20;
    range1.cellStyle.bold = true;
    range1.cellStyle.hAlign = HAlignType.left;

    range2.cellStyle.fontSize = 14;
    range2.cellStyle.bold = true;
    if (widget.generatedDate[0]['arrivedAt'] != null) {
      startingDate = DateTime.parse(widget.generatedDate[0]['arrivedAt'])
          .toString()
          .split(' ')[0];
    }

    //loop over generated list in order to add the data
    for (var i = 0; i < widget.generatedDate.length; i++) {
      //calculate total hours and minutes
      totalHours = 0;
      totalMin = 0;
      var arrived = widget.generatedDate[i]['arrivedAt'] != null
          ? DateTime.parse(widget.generatedDate[i]['arrivedAt'])
          : null;

      var left = widget.generatedDate[i]['leftAt'] != null
          ? DateTime.parse(widget.generatedDate[i]['leftAt'])
          : null;
      if (left != null && arrived != null) {
        var diff = left.difference(arrived);
        totalHours = diff.inHours;
        totalMin = diff.inMinutes % 60;
      }

      sheet.getRangeByIndex(i + 4, 1).setText(
          '${widget.generatedDate[i]['firstName']} ${widget.generatedDate[i]['lastName']}');

      sheet
          .getRangeByIndex(i + 4, 2)
          .setText('${widget.generatedDate[i]['arrivedAt']}');

      sheet
          .getRangeByIndex(i + 4, 3)
          .setText('${widget.generatedDate[i]['leftAt']}');
      sheet
          .getRangeByIndex(i + 4, 4)
          .setText('${widget.generatedDate[i]['projectName']}');
      sheet.getRangeByIndex(i + 4, 5).setText('$totalHours:$totalMin');
      sheet
          .getRangeByIndex(i + 4, 6)
          .setText('${widget.generatedDate[i]['workType']}');
      sheet
          .getRangeByIndex(i + 4, 7)
          .setText('${widget.generatedDate[i]['squareMeters']}');
      if (arrived != null) {
        if (startingDate != arrived.toString().split(' ')[0]) {
          i++;
          sheet.getRangeByIndex(i + 4, 1).setText('Date: $startingDate');
          startingDate = arrived.toString().split(' ')[0];
        }
      }
    }
    print('the map: ${widget.mappedData.length}');
    widget.mappedData.forEach((key, value) {
      print('the key: $key');
      print('the value: $value');
    });
    //Save the file
    final List<int> bytes = workbook.saveAsStream();
    //dispose workbook

    workbook.dispose();

    //save and launch file
    await saveAndLaunchFile(bytes, 'Timesheet.xlsx');
  }
}
