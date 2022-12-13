import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:royal_marble/shared/constants.dart';

import '../models/user_model.dart';
import '../shared/date_picker.dart';

class ReportTypeList extends StatefulWidget {
  const ReportTypeList({Key key, this.reportType, this.currentUser})
      : super(key: key);
  final String reportType;
  final UserData currentUser;

  @override
  State<ReportTypeList> createState() => _ReportTypeListState();
}

class _ReportTypeListState extends State<ReportTypeList> {
  var userProvider;
  Size _size;
  @override
  Widget build(BuildContext context) {
    _size = MediaQuery.of(context).size;
    userProvider = Provider.of<List<UserData>>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Report Type - ${widget.reportType.toUpperCase()}'),
        backgroundColor: const Color.fromARGB(255, 191, 180, 66),
      ),
      body: _buildListOfReportTypes(),
    );
  }

  Widget _buildListOfReportTypes() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 25),
        child: widget.reportType == 'site'
            ? Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                    //Identify page
                    const Text(
                      'The following document will allow you to view the current time sheets and progress of your workers!',
                      style: textStyle6,
                    ),
                    const SizedBox(
                      height: 25,
                    ),
                    //Site Workers Reports
                    GestureDetector(
                      onTap: () {
                        showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                                  content: DatePicker(
                                    reportType: 'timesheet',
                                    bulkUsers: userProvider,
                                    currentUser: widget.currentUser,
                                    reportSection: 'isNormalUser',
                                  ),
                                ));
                      },
                      child: Container(
                        decoration: BoxDecoration(
                            boxShadow: const [
                              BoxShadow(
                                  color: Colors.black,
                                  offset: Offset(-2, 2),
                                  spreadRadius: 1)
                            ],
                            color: const Color.fromARGB(255, 181, 160, 130),
                            border: Border.all(),
                            borderRadius: BorderRadius.circular(15)),
                        width: _size.width - 10,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 15, vertical: 10),
                          child: Text(
                            'Site Workers',
                            style: textStyle3,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 25,
                    ),
                    //Site Engineers Report
                    GestureDetector(
                      onTap: () {
                        showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                                  content: DatePicker(
                                    reportType: 'timesheet',
                                    bulkUsers: userProvider,
                                    currentUser: widget.currentUser,
                                    reportSection: 'isSiteEngineer',
                                  ),
                                ));
                      },
                      child: Container(
                        decoration: BoxDecoration(
                            boxShadow: const [
                              BoxShadow(
                                  color: Colors.black,
                                  offset: Offset(-2, 2),
                                  spreadRadius: 1)
                            ],
                            color: const Color.fromARGB(255, 181, 160, 130),
                            border: Border.all(),
                            borderRadius: BorderRadius.circular(15)),
                        width: _size.width - 10,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 15, vertical: 10),
                          child: Text(
                            'Site Engineer',
                            style: textStyle3,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 25,
                    ),
                    //Site Supervisors Reports
                    GestureDetector(
                      onTap: () {
                        showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                                  content: DatePicker(
                                    reportType: 'timesheet',
                                    bulkUsers: userProvider,
                                    currentUser: widget.currentUser,
                                    reportSection: 'isSupervisor',
                                  ),
                                ));
                      },
                      child: Container(
                        decoration: BoxDecoration(
                            boxShadow: const [
                              BoxShadow(
                                  color: Colors.black,
                                  offset: Offset(-2, 2),
                                  spreadRadius: 1)
                            ],
                            color: const Color.fromARGB(255, 181, 160, 130),
                            border: Border.all(),
                            borderRadius: BorderRadius.circular(15)),
                        width: _size.width - 10,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 15, vertical: 10),
                          child: Text(
                            'Supervisor',
                            style: textStyle3,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 25,
                    ),
                    // //All Together
                    // GestureDetector(
                    //   child: Container(
                    //     decoration: BoxDecoration(
                    //         boxShadow: const [
                    //           BoxShadow(
                    //               color: Colors.black,
                    //               offset: Offset(-2, 2),
                    //               spreadRadius: 1)
                    //         ],
                    //         color: const Color.fromARGB(255, 181, 160, 130),
                    //         border: Border.all(),
                    //         borderRadius: BorderRadius.circular(15)),
                    //     width: _size.width - 10,
                    //     child: const Padding(
                    //       padding: EdgeInsets.symmetric(
                    //           horizontal: 15, vertical: 10),
                    //       child: Text(
                    //         'All Together',
                    //         style: textStyle3,
                    //       ),
                    //     ),
                    //   ),
                    // ),
                  ])
            : Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                    //Identify page
                    const Text(
                      'The following document will allow you to view the progress of your current sales team',
                      style: textStyle6,
                    ),
                    const SizedBox(
                      height: 25,
                    ),
                    //Sales Team
                    GestureDetector(
                      onTap: () {
                        showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                                  content: DatePicker(
                                    reportType: 'salesReport',
                                    bulkUsers: userProvider,
                                    currentUser: widget.currentUser,
                                    reportSection: 'isSales',
                                  ),
                                ));
                      },
                      child: Container(
                        decoration: BoxDecoration(
                            boxShadow: const [
                              BoxShadow(
                                  color: Colors.black,
                                  offset: Offset(-2, 2),
                                  spreadRadius: 1)
                            ],
                            color: const Color.fromARGB(255, 181, 160, 130),
                            border: Border.all(),
                            borderRadius: BorderRadius.circular(15)),
                        width: _size.width - 10,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 15, vertical: 10),
                          child: Text(
                            'Sales Team',
                            style: textStyle3,
                          ),
                        ),
                      ),
                    ),
                  ]),
      ),
    );
  }
}
