import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:royal_marble/models/business_model.dart';
import 'package:royal_marble/models/user_model.dart';
import 'package:royal_marble/services/database.dart';
import 'package:royal_marble/shared/constants.dart';
import 'package:royal_marble/shared/generating_pdf.dart';
import 'package:royal_marble/shared/loading.dart';
import 'package:royal_marble/shared/pdf_builder.dart';

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
  PdfPageFormat pdfFormat;
  var days;
  List<DateTime> dateRange = [];
  var singleUserMap = [];
  var generateddata = [];
  @override
  Widget build(BuildContext context) {
    _size = MediaQuery.of(context).size;
    pdfFormat = PdfPageFormat(_size.width, _size.height);
    return Scaffold(
      appBar: AppBar(
        title: Text('Report Details - ${widget.reportType}'),
        backgroundColor: const Color.fromARGB(255, 191, 180, 66),
        actions: [
          //Generate document pdf
          TextButton(
              onPressed: () async {
                var pageFormat = PdfPageFormat(_size.width, _size.height);
                if (generateddata != null && generateddata.isNotEmpty) {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PdfPreview(
                        maxPageWidth: _size.width - 10,
                        build: (format) =>
                            fileTypes[0].builder(pdfFormat, generateddata),
                      ),
                    ),
                  );
                }
              },
              child: const Text(
                'PDF',
                style: buttonStyle,
              ))
        ],
      ),
      body: widget.reportType == 'salesReport'
          ? _buildSalesReportDetails()
          : _buildWorkerReportDetails(),
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

  //build worker report details
  Widget _buildWorkerReportDetails() {
    if (generateddata.isNotEmpty) {
      generateddata = [];
    }
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
                          singleUserMap = [];

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
                                    'workType': value['workCompleted']
                                        ['workType'],
                                    'squareMeters': value['workCompleted']
                                        ['sqaureMeters']
                                  });
                                });

                                generateddata.addAll(singleUserMap);

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
                                      SingleChildScrollView(
                                        scrollDirection: Axis.vertical,
                                        child: SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: DataTable(
                                            dividerThickness: 1,
                                            columnSpacing: 6,
                                            horizontalMargin: 5,
                                            headingTextStyle: textStyle9,
                                            dataTextStyle: textStyle11,
                                            headingRowColor:
                                                MaterialStateProperty
                                                    .resolveWith((states) =>
                                                        const Color.fromARGB(
                                                            255, 216, 133, 33)),
                                            headingRowHeight: 28.0,
                                            dataRowHeight: 20.0,
                                            dataRowColor: MaterialStateProperty
                                                .resolveWith((states) =>
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
                                                width: _size.width / 8,
                                                child: const Text(
                                                  'Name',
                                                ),
                                              )),
                                              DataColumn(
                                                  label: SizedBox(
                                                width: _size.width / 8,
                                                child: const Text(
                                                  'Arrived At',
                                                ),
                                              )),
                                              DataColumn(
                                                  label: SizedBox(
                                                width: _size.width / 8,
                                                child: const Text(
                                                  'Left At',
                                                ),
                                              )),
                                              DataColumn(
                                                  label: SizedBox(
                                                width: _size.width / 8,
                                                child: const Text(
                                                  'Project Name',
                                                ),
                                              )),
                                              DataColumn(
                                                  label: SizedBox(
                                                width: _size.width / 8,
                                                child: const Text(
                                                  'Work',
                                                ),
                                              )),
                                              DataColumn(
                                                  label: SizedBox(
                                                width: _size.width / 8,
                                                child: const Text(
                                                  'Meters',
                                                ),
                                              )),
                                            ],
                                            rows: singleUserMap.map(
                                              (e) {
                                                var arrived =
                                                    e['arrivedAt'] != null
                                                        ? DateTime.parse(
                                                            e['arrivedAt'])
                                                        : null;

                                                var left = e['leftAt'] != null
                                                    ? DateTime.parse(
                                                        e['leftAt'])
                                                    : null;
                                                return DataRow(
                                                  cells: [
                                                    DataCell(Text(
                                                        '${e['firstName']} ${e['lastName']}')),
                                                    DataCell(Text(
                                                        DateFormat('hh:mm a')
                                                            .format(arrived))),
                                                    DataCell(Text(
                                                        DateFormat('hh:mm a')
                                                            .format(left))),
                                                    DataCell(Text(
                                                        '${e['projectName']}')),
                                                    DataCell(Text(
                                                        '${e['workType']}')),
                                                    DataCell(Text(
                                                        '${e['squareMeters']}')),
                                                  ],
                                                );
                                              },
                                            ).toList(),
                                          ),
                                        ),
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
                  }),
                )
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

  //build sales report details
  Widget _buildSalesReportDetails() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 25),
      child: SingleChildScrollView(
        child: SizedBox(
          height: _size.height,
          child: ListView.builder(
              itemCount: widget.bulkUsers.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]),
                          borderRadius: BorderRadius.circular(10)),
                      height: _size.height / 2,
                      child: FutureBuilder(
                          future: _getSalesVisits(
                              userId: widget.bulkUsers[index].uid),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              print('the snapshot: ${snapshot.data}');
                            }
                            return Column(
                              children: [
                                //Name
                                Row(
                                  children: [
                                    const Expanded(
                                      flex: 2,
                                      child: Text(
                                        'Name',
                                        style: textStyle3,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        '${widget.bulkUsers[index].firstName} ${widget.bulkUsers[index].lastName}',
                                        style: textStyle12,
                                      ),
                                    )
                                  ],
                                ),
                                //Days worked
                                Row(
                                  children: [
                                    const Expanded(
                                      flex: 2,
                                      child: Text(
                                        'Working Day',
                                        style: textStyle3,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        '',
                                        style: textStyle12,
                                      ),
                                    )
                                  ],
                                ),
                                SizedBox(
                                  height: _size.height / 5,
                                  child: Row(
                                    children: [
                                      const Expanded(
                                        flex: 2,
                                        child: Text(
                                          'Projects Visited',
                                          style: textStyle3,
                                        ),
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          '',
                                          style: textStyle12,
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  height: _size.height / 5,
                                  child: Row(
                                    children: [
                                      const Expanded(
                                        flex: 2,
                                        child: Text(
                                          'Clients Visited',
                                          style: textStyle3,
                                        ),
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          '',
                                          style: textStyle12,
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ],
                            );
                          })),
                );
              }),
        ),
      ),
    );
  }

  Future _getDatesTimeSheet({String uid}) async {
    var result = await db.getRangeTimeSheets(
        uid: uid, reportSection: widget.reportSection);

    return result;
  }

  //Get the sales client and project visits
  Future _getSalesVisits({String userId}) async {
    List<ClientVisitDetails> clientVisits = [];
    List<ProjectVisitDetails> projectVisits = [];
    //get clients visits
    clientVisits = await db.getTimeRangedClientVisitsFuture(
        userId: userId, fromDate: widget.fromDate, toDate: widget.toDate);

    //get project visits
    projectVisits = await db.getTimeRangedProjectVisitsFuture(
        userId: userId, fromDate: widget.fromDate, toDate: widget.toDate);

    Map<String, List<dynamic>> visits = {};
  }
}
