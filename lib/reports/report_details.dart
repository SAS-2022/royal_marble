import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:royal_marble/models/business_model.dart';
import 'package:royal_marble/models/user_model.dart';
import 'package:royal_marble/services/database.dart';
import 'package:royal_marble/shared/constants.dart';
import 'package:royal_marble/shared/export_excel.dart';
import 'package:royal_marble/shared/loading.dart';
import 'package:royal_marble/shared/pdf_builder.dart';

class ReportDetails extends StatefulWidget {
  const ReportDetails(
      {Key? key,
      this.reportType,
      this.bulkUsers,
      this.currentUser,
      this.reportSection,
      this.fromDate,
      this.toDate})
      : super(key: key);
  final String? reportType;
  final List<UserData>? bulkUsers;
  final UserData? currentUser;
  final DateTime? fromDate;
  final DateTime? toDate;
  final String? reportSection;
  @override
  State<ReportDetails> createState() => _ReportDetailsState();
}

class _ReportDetailsState extends State<ReportDetails> {
  Size? _size;
  DatabaseService db = DatabaseService();
  PdfPageFormat? pdfFormat;
  var days;
  List<DateTime> dateRange = [];
  var singleUserMap = [];
  var generateddata = [];
  List<UserData> requiredUsers = [];
  var mapAllData = {};
  @override
  Widget build(BuildContext context) {
    _size = MediaQuery.of(context).size;
    pdfFormat = PdfPageFormat(_size!.width, _size!.height);
    return Scaffold(
      appBar: AppBar(
        title: Text('Report Details - ${widget.reportType}'),
        backgroundColor: const Color.fromARGB(255, 191, 180, 66),
        actions: [
          //Generate document pdf
          TextButton(
              onPressed: () async {
                //show dialog that will allow you to chose between excel and pdf
                showDialog(
                    context: context,
                    builder: (_) {
                      return AlertDialog(
                        content: SizedBox(
                          height: _size!.height / 5,
                          child: Padding(
                            padding: const EdgeInsets.all(15.0),
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  //Pdf Generator
                                  Expanded(
                                    child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color.fromARGB(
                                                    255, 232, 8, 8),
                                            fixedSize:
                                                Size(_size!.width / 2, 30),
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(25))),
                                        onPressed: () async {
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => PdfPreview(
                                                maxPageWidth: _size!.width - 10,
                                                build: (format) => fileTypes[0]
                                                    .builder(pdfFormat!,
                                                        generateddata),
                                              ),
                                            ),
                                          );
                                        },
                                        child: const Text('PDF Generator')),
                                  ),
                                  const SizedBox(
                                    height: 10,
                                  ),

                                  //Excel Generator
                                  Expanded(
                                    child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color.fromARGB(
                                                    255, 54, 214, 75),
                                            fixedSize:
                                                Size(_size!.width / 2, 30),
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(25))),
                                        onPressed: () async {
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => CreateExcelFile(
                                                generatedDate: generateddata,
                                                mappedData: mapAllData,
                                                reportSection:
                                                    widget.reportSection!,
                                                selectedUsers: requiredUsers,
                                              ),
                                            ),
                                          );
                                        },
                                        child: const Text('Excel Generator')),
                                  )
                                ]),
                          ),
                        ),
                      );
                    });
              },
              child: const Text(
                'Export',
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
      days = widget.toDate!.difference(widget.fromDate!).inDays;
      dateRange = List.generate(
          days,
          (i) => DateTime(widget.fromDate!.year, widget.fromDate!.month,
              widget.fromDate!.day + (i)));
    }

    //select the users depending on the role required
    _selectRequiredUsers();
  }

  void _selectRequiredUsers() {
    for (var user in widget.bulkUsers!) {
      if (user.roles!.contains(widget.reportSection)) {
        requiredUsers.add(user);
      }
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
          height: _size!.height - 10,
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
                                    'workType': value['workCompleted'] != null
                                        ? value['workCompleted']['workType']
                                        : '',
                                    'squareMeters': value['workCompleted'] !=
                                            null
                                        ? value['workCompleted']['sqaureMeters']
                                        : ''
                                  });
                                });

                                generateddata.addAll(singleUserMap);
                                generateddata.sort(
                                  (v1, v2) => v1['arrivedAt'].compareTo(
                                    v2['arrivedAt'],
                                  ),
                                );

                                //after sorting arrange data with dates as the main key
                                _organizeDataWithDates();

                                return Container(
                                  width: _size!.width,
                                  color: Colors.grey[300],
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
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10),
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
                                            dataRowMaxHeight: 20.0,
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
                                                width: _size!.width / 8,
                                                child: const Text(
                                                  'Name',
                                                ),
                                              )),
                                              DataColumn(
                                                  label: SizedBox(
                                                width: _size!.width / 8,
                                                child: const Text(
                                                  'Arrived At',
                                                ),
                                              )),
                                              DataColumn(
                                                  label: SizedBox(
                                                width: _size!.width / 8,
                                                child: const Text(
                                                  'Left At',
                                                ),
                                              )),
                                              DataColumn(
                                                  label: SizedBox(
                                                width: _size!.width / 8,
                                                child: const Text(
                                                  'Project Name',
                                                ),
                                              )),
                                              DataColumn(
                                                  label: SizedBox(
                                                width: _size!.width / 8,
                                                child: const Text(
                                                  'Work',
                                                ),
                                              )),
                                              DataColumn(
                                                  label: SizedBox(
                                                width: _size!.width / 8,
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
                                                    arrived != null
                                                        ? DataCell(Text(
                                                            DateFormat(
                                                                    'hh:mm a')
                                                                .format(
                                                                    arrived)))
                                                        : const DataCell(
                                                            Text('')),
                                                    left != null
                                                        ? DataCell(Text(
                                                            DateFormat(
                                                                    'hh:mm a')
                                                                .format(left)))
                                                        : const DataCell(
                                                            Text('')),
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

  void _organizeDataWithDates() {
    var currentDate;
    var dateBasedData = [];
    mapAllData.clear();
    for (var data in generateddata) {
      currentDate ??= data['arrivedAt'].toString().split(' ')[0];

      if (data['arrivedAt'].toString().split(' ')[0] != currentDate) {
        currentDate = data['arrivedAt'].toString().split(' ')[0];
        dateBasedData.clear();
      }
      dateBasedData.add(data);
      mapAllData.addAll({currentDate: dateBasedData});
    }
    debugPrint('All Data: $mapAllData');
  }

  //build sales report details
  Widget _buildSalesReportDetails() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
      child: SingleChildScrollView(
        child: SizedBox(
          height: _size!.height,
          child: ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.bulkUsers!.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.all(15),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        boxShadow: const [
                          BoxShadow(
                              color: Colors.black87,
                              offset: Offset(-2, 4),
                              spreadRadius: 2,
                              blurStyle: BlurStyle.normal)
                        ],
                        color: const Color.fromARGB(255, 196, 196, 196),
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(10)),
                    height: _size!.height / 2,
                    child: FutureBuilder(
                      future: _getSalesVisits(
                          userId: widget.bulkUsers![index].uid!),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
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
                                      '${widget.bulkUsers![index].firstName} ${widget.bulkUsers![index].lastName}',
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
                                      'Working Days',
                                      style: textStyle3,
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      '${snapshot.data['workingDays'].length}',
                                      style: textStyle12,
                                    ),
                                  )
                                ],
                              ),
                              SizedBox(
                                height: _size!.height / 5,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Row(
                                        children: [
                                          const Expanded(
                                            flex: 2,
                                            child: Text(
                                              'Projects Visited: ',
                                              style: textStyle3,
                                            ),
                                          ),
                                          Expanded(
                                            flex: 3,
                                            child: Text(
                                                '${snapshot.data['projectVisits'].length}'),
                                          )
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: SizedBox(
                                        width: _size!.width - 20,
                                        child: ListView.builder(
                                            scrollDirection: Axis.horizontal,
                                            itemCount: snapshot
                                                .data['projectVisits'].length,
                                            itemBuilder: (context, index) {
                                              return Padding(
                                                padding:
                                                    const EdgeInsets.all(5.0),
                                                child: Card(
                                                  elevation: 3,
                                                  shadowColor: Colors.grey,
                                                  color: const Color.fromARGB(
                                                      255, 131, 197, 194),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            25),
                                                  ),
                                                  child: Container(
                                                    padding: const EdgeInsets
                                                            .symmetric(
                                                        horizontal: 10),
                                                    width: _size!.width / 3,
                                                    child: Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Text(
                                                          '${snapshot.data['projectVisits'][index] != null ? snapshot.data['projectVisits'][index].projectName : ''}',
                                                          style: textStyle12,
                                                        ),
                                                        Text(
                                                          '${snapshot.data['projectVisits'][index] != null ? snapshot.data['projectVisits'][index].visitPurpose : ''}',
                                                          style: textStyle12,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                              SizedBox(
                                height: _size!.height / 5,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Row(
                                        children: [
                                          const Expanded(
                                            flex: 2,
                                            child: Text(
                                              'Clients Visited: ',
                                              style: textStyle3,
                                            ),
                                          ),
                                          Expanded(
                                            flex: 3,
                                            child: Text(
                                                '${snapshot.data['clientVisits'].length}'),
                                          )
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: SizedBox(
                                        width: _size!.width - 20,
                                        child: ListView.builder(
                                            scrollDirection: Axis.horizontal,
                                            itemCount: snapshot
                                                .data['clientVisits'].length,
                                            itemBuilder: (context, index) {
                                              return Padding(
                                                padding:
                                                    const EdgeInsets.all(5.0),
                                                child: Card(
                                                  elevation: 3,
                                                  shadowColor: Colors.grey,
                                                  color: const Color.fromARGB(
                                                      255, 204, 202, 243),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            25),
                                                  ),
                                                  child: Container(
                                                    padding: const EdgeInsets
                                                            .symmetric(
                                                        horizontal: 10),
                                                    width: _size!.width / 3,
                                                    child: Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Text(
                                                          '${snapshot.data['clientVisits'][index].clientName}',
                                                          style: textStyle12,
                                                        ),
                                                        Text(
                                                          '${snapshot.data['clientVisits'][index].visitPurpose}',
                                                          style: textStyle12,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ],
                          );
                        } else {
                          return const Center(
                            child: Text(
                              'No Visits were found!',
                              style: textStyle2,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                );
              }),
        ),
      ),
    );
  }

  Future _getDatesTimeSheet({String? uid}) async {
    var result = await db.getRangeTimeSheets(
        uid: uid!, reportSection: widget.reportSection!);

    return result;
  }

  //Get the sales client and project visits
  Future _getSalesVisits({String? userId}) async {
    List<ClientVisitDetails> clientVisits = [];
    List<ProjectVisitDetails> projectVisits = [];
    List<dynamic> workingDays = [];
    //get clients visits
    clientVisits = await db.getTimeRangedClientVisitsFuture(
        userId: userId!, fromDate: widget.fromDate!, toDate: widget.toDate!);

    //get project visits
    projectVisits = await db.getTimeRangedProjectVisitsFuture(
        userId: userId, fromDate: widget.fromDate!, toDate: widget.toDate!);

    for (var clients in clientVisits) {
      if (!workingDays.contains(clients.visitTime)) {
        workingDays.add(clients.visitTime);
      }
    }

    for (var projects in projectVisits) {
      if (!workingDays.contains(projects.visitTime)) {
        workingDays.add(projects.visitTime);
      }
    }

    Map<String, List<dynamic>> visits = {
      'clientVisits': clientVisits,
      'projectVisits': projectVisits,
      'workingDays': workingDays
    };
    return visits;
  }
}
