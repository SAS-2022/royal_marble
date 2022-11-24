import 'package:flutter/material.dart';
import 'package:royal_marble/models/user_model.dart';

class ReportDetails extends StatefulWidget {
  const ReportDetails(
      {Key key,
      this.reportType,
      this.bulkUsers,
      this.currentUser,
      this.fromDate,
      this.toDate})
      : super(key: key);
  final String reportType;
  final List<UserData> bulkUsers;
  final UserData currentUser;
  final DateTime fromDate;
  final DateTime toDate;
  @override
  State<ReportDetails> createState() => _ReportDetailsState();
}

class _ReportDetailsState extends State<ReportDetails> {
  Size _size;
  var days;
  List<DateTime> dateRange = [];
  @override
  Widget build(BuildContext context) {
    _size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: Text('Report Details - ${widget.reportType}'),
        backgroundColor: const Color.fromARGB(255, 191, 180, 66),
      ),
      body: _buildReportDetails(),
    );
  }

  @override
  void initState() {
    super.initState();
    days = widget.toDate.difference(widget.fromDate).inDays;
    dateRange = List.generate(
        days,
        (i) => DateTime(widget.fromDate.year, widget.fromDate.month,
            widget.fromDate.day + (i)));
  }

  Widget _buildReportDetails() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SizedBox(
          height: _size.height - 10,
          child: ListView.builder(
              itemCount: dateRange.length,
              itemBuilder: ((context, index) {
                return Container(
                  padding: const EdgeInsets.all(5),
                  child: Text('The Date: ${dateRange[index]}'),
                );
              })),
        ),
      ),
    );
  }
}
