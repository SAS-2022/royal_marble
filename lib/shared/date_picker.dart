import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:royal_marble/sales_pipeline/visits/visit_grid.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

import '../models/user_model.dart';

class DatePicker extends StatefulWidget {
  const DatePicker({Key key, this.selectedUser}) : super(key: key);
  final UserData selectedUser;

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
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => VisitsGrid(
                        selectedUser: widget.selectedUser,
                        fromDate: startDate,
                        toDate: endDate,
                      )));
        }),
        onCancel: () => Navigator.pop(context),
        onSelectionChanged: _onSelectionChanged,
        selectionMode: DateRangePickerSelectionMode.range,
        initialSelectedRange: PickerDateRange(
            DateTime.now().subtract(const Duration(days: 4)),
            DateTime.now().add(const Duration(days: 3))),
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
      print('the start: $startDate, the end: $endDate');
    }
  }
}
