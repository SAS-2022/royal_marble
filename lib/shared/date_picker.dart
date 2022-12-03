import 'package:flutter/material.dart';
import 'package:royal_marble/reports/report_details.dart';
import 'package:royal_marble/sales_pipeline/visits/visit_grid.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import '../models/user_model.dart';

class DatePicker extends StatefulWidget {
  const DatePicker(
      {Key key,
      this.selectedUser,
      this.bulkUsers,
      this.reportType,
      this.reportSection,
      this.currentUser})
      : super(key: key);
  final UserData currentUser;
  final UserData selectedUser;
  final List<UserData> bulkUsers;
  final String reportType;
  final String reportSection;

  @override
  State<DatePicker> createState() => _DatePickerState();
}

class _DatePickerState extends State<DatePicker> {
  DateTime startDate;
  DateTime endDate;
  Size _size;

  @override
  Widget build(BuildContext context) {
    _size = MediaQuery.of(context).size;
    return SizedBox(
      height: _size.height / 2,
      width: _size.width - 10,
      child: Center(
          child: SfDateRangePicker(
        showActionButtons: true,
        onSubmit: ((p0) {
          switch (widget.reportType) {
            case 'pipeline':
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => VisitsGrid(
                            currentUser: widget.currentUser,
                            selectedUser: widget.selectedUser,
                            fromDate: startDate,
                            toDate: endDate,
                          )));
              break;
            case 'timesheet':
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => ReportDetails(
                            bulkUsers: widget.bulkUsers,
                            currentUser: widget.currentUser,
                            reportType: widget.reportType,
                            fromDate: startDate,
                            toDate: endDate,
                            reportSection: widget.reportSection,
                          )));
              break;
          }
        }),
        onCancel: () => Navigator.pop(context),
        onSelectionChanged: _onSelectionChanged,
        selectionMode: DateRangePickerSelectionMode.range,
        initialSelectedRange: PickerDateRange(
            DateTime.now().subtract(const Duration(days: 2)),
            DateTime.now().add(const Duration(days: 2))),
      )),
    );
  }

  void _onSelectionChanged(DateRangePickerSelectionChangedArgs args) {
    if (mounted) {
      setState(() {
        if (args.value is PickerDateRange) {
          startDate = args.value.startDate;
          endDate = args.value.endDate ?? args.value.startDate;
        }
      });
    }
  }
}
