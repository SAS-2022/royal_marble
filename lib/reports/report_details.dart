import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:royal_marble/models/user_model.dart';
import 'package:royal_marble/services/database.dart';
import 'package:royal_marble/shared/constants.dart';
import 'package:royal_marble/shared/loading.dart';

class ReportDetails extends StatefulWidget {
  const ReportDetails(
      {Key key,
      this.reportType,
      this.bulkUsers,
      this.currentUser,
      this.reportSection,
      this.fromDate,
      this.toDate})
      : super(key: key);
  final String reportType;
  final List<UserData> bulkUsers;
  final UserData currentUser;
  final DateTime fromDate;
  final DateTime toDate;
  final String reportSection;
  @override
  State<ReportDetails> createState() => _ReportDetailsState();
}

class _ReportDetailsState extends State<ReportDetails> {
  Size _size;
  DatabaseService db = DatabaseService();
  var days;
  List<DateTime> dateRange = [];
  var singleUserMap = [];
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
    if (widget.fromDate != null && widget.toDate != null) {
      days = widget.toDate.difference(widget.fromDate).inDays;
      dateRange = List.generate(
          days,
          (i) => DateTime(widget.fromDate.year, widget.fromDate.month,
              widget.fromDate.day + (i)));
    }
  }

  Widget _buildReportDetails() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SizedBox(
          height: _size.height - 10,
          child: widget.fromDate != null && widget.toDate != null
              ? ListView.builder(
                  itemCount: dateRange.length,
                  itemBuilder: ((context, index) {
                    String dateName =
                        DateFormat('EEEE').format(dateRange[index]);
                    String uid =
                        '${dateRange[index].day}-${dateRange[index].month}-${dateRange[index].year}';

                    return FutureBuilder(
                        future: _getDatesTimeSheet(uid: uid),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: Loading(),
                              );
                            } else {
                              if (snapshot.data['data'] != null) {
                                snapshot.data['data'].forEach((key, value) {
                                  singleUserMap.add({
                                    'uid': key,
                                    'firstName': value['firstName'],
                                    'lastName': value['lastName'],
                                    'arrivedAt': value['arriving_at'],
                                    'leftAt': value['leaving_at'],
                                    'projectName': value['projectName'],
                                  });
                                });

                                return Container(
                                  width: _size.width,
                                  padding: const EdgeInsets.all(5),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      //set the date for the current transaction
                                      Padding(
                                        padding: const EdgeInsets.all(5.0),
                                        child: Text(
                                          '$dateName: $uid',
                                          style: textStyle8,
                                        ),
                                      ),
                                      //Display the list of employees that were on site
                                      DataTable(
                                        dividerThickness: 1,
                                        columnSpacing: 6,
                                        horizontalMargin: 5,
                                        headingTextStyle: textStyle9,
                                        dataTextStyle: textStyle11,
                                        headingRowColor:
                                            MaterialStateProperty.resolveWith(
                                                (states) =>
                                                    const Color.fromARGB(
                                                        255, 216, 133, 33)),
                                        headingRowHeight: 28.0,
                                        dataRowHeight: 20.0,
                                        dataRowColor:
                                            MaterialStateProperty.resolveWith(
                                                (states) =>
                                                    const Color.fromARGB(
                                                        255, 223, 207, 186)),
                                        border: const TableBorder(
                                            left: BorderSide(width: 2),
                                            right: BorderSide(width: 2),
                                            bottom: BorderSide(width: 2),
                                            top: BorderSide(width: 2),
                                            verticalInside:
                                                BorderSide(width: 1)),
                                        columns: [
                                          DataColumn(
                                              label: SizedBox(
                                            width: _size.width / 6,
                                            child: const Text(
                                              'First Name',
                                            ),
                                          )),
                                          DataColumn(
                                              label: SizedBox(
                                            width: _size.width / 6,
                                            child: const Text(
                                              'Last Name',
                                            ),
                                          )),
                                          DataColumn(
                                              label: SizedBox(
                                            width: _size.width / 7,
                                            child: const Text(
                                              'Arrived At',
                                            ),
                                          )),
                                          DataColumn(
                                              label: SizedBox(
                                            width: _size.width / 7,
                                            child: const Text(
                                              'Left At',
                                            ),
                                          )),
                                          DataColumn(
                                              label: SizedBox(
                                            width: _size.width / 6,
                                            child: const Text(
                                              'Project Name',
                                            ),
                                          )),
                                        ],
                                        rows: singleUserMap.map(
                                          (e) {
                                            return DataRow(
                                              cells: [
                                                DataCell(
                                                    Text('${e['firstName']}')),
                                                DataCell(
                                                    Text('${e['lastName']}')),
                                                DataCell(
                                                    Text('${e['arrivedAt']}')),
                                                DataCell(
                                                    Text('${e['leftAt']}')),
                                                DataCell(Text(
                                                    '${e['projectName']}')),
                                              ],
                                            );
                                          },
                                        ).toList(),
                                      ),
                                    ],
                                  ),
                                );
                              } else {
                                return const SizedBox.shrink();
                              }
                            }
                          } else if (snapshot.hasError) {
                            return Center(
                              child: Text('Error occured: ${snapshot.error}'),
                            );
                          } else {
                            return const Center(
                              child: Loading(),
                            );
                          }
                        });
                  }))
              : const Center(
                  child: Text(
                    'Please select a date range!',
                    style: textStyle3,
                  ),
                ),
        ),
      ),
    );
  }

  Future _getDatesTimeSheet({String uid}) async {
    var result = await db.getRangeTimeSheets(
        uid: uid, reportSection: widget.reportSection);

    return result;
  }
}
