import 'package:flutter/material.dart';
import 'package:royal_marble/models/business_model.dart';
import 'package:royal_marble/services/database.dart';
import 'package:royal_marble/shared/snack_bar.dart';
import '../shared/constants.dart';
import '../shared/loading.dart';

class MockupStatus extends StatefulWidget {
  const MockupStatus({Key key, this.selectedMockup}) : super(key: key);
  final MockupData selectedMockup;

  @override
  State<MockupStatus> createState() => _MockupStatusState();
}

class _MockupStatusState extends State<MockupStatus> {
  Size _size;
  bool _loading = false;
  MockupData editedProject;
  DatabaseService db = DatabaseService();
  SnackBarWidget _snackBarWidget = SnackBarWidget();

  @override
  void initState() {
    super.initState();
    _snackBarWidget.context = context;
    if (widget.selectedMockup != null) {
      editedProject = widget.selectedMockup;
    }
  }

  @override
  Widget build(BuildContext context) {
    _size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Status'),
        backgroundColor: const Color.fromARGB(255, 191, 180, 66),
      ),
      body: Stack(
        children: [
          _buildProjectState(),
          _loading
              ? const Center(
                  child: Loading(),
                )
              : const SizedBox.shrink()
        ],
      ),
    );
  }

  Widget _buildProjectState() {
    //Will show the current status of the project and the ability to update it
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const Text(
                'You can change the project status through this section'),
            const SizedBox(
              height: 25,
            ),
            Row(children: [
              const Expanded(
                flex: 1,
                child: Text(
                  'Project Name',
                  style: textStyle3,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  widget.selectedMockup.mockupName,
                  style: textStyle4,
                ),
              )
            ]),
            const SizedBox(
              height: 15,
            ),
            Row(children: [
              const Expanded(
                flex: 1,
                child: Text(
                  'Project Details',
                  style: textStyle3,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  widget.selectedMockup.mockupDetails,
                  style: textStyle4,
                ),
              )
            ]),
            const SizedBox(
              height: 15,
            ),
            Row(children: [
              const Expanded(
                flex: 1,
                child: Text(
                  'Contractor',
                  style: textStyle3,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  widget.selectedMockup.contactorCompany,
                  style: textStyle4,
                ),
              )
            ]),
            const SizedBox(
              height: 15,
            ),
            Row(children: [
              const Expanded(
                flex: 1,
                child: Text(
                  'Contact Name',
                  style: textStyle3,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  widget.selectedMockup.contactPerson,
                  style: textStyle4,
                ),
              )
            ]),
            const SizedBox(
              height: 15,
            ),
            Row(children: [
              const Expanded(
                flex: 1,
                child: Text(
                  'Phone Number',
                  style: textStyle3,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  widget.selectedMockup.phoneNumber.phoneNumber,
                  style: textStyle4,
                ),
              )
            ]),
            const SizedBox(
              height: 15,
            ),
            //Will set three button to switch the project status
            SizedBox(
              height: 100,
              width: _size.width - 10,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  //for active projects
                  Expanded(
                    flex: 1,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color.fromARGB(255, 148, 218, 83),
                        disabledBackgroundColor: Colors.grey,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(25),
                              bottomLeft: Radius.circular(25)),
                        ),
                      ),
                      onPressed: widget.selectedMockup.mockupStatus != 'active'
                          ? () async {
                              setState(() {
                                _loading = true;
                              });
                              editedProject.mockupStatus = 'active';
                              //will change project status
                              await db.updateMockupStatus(
                                  mockup: editedProject);

                              Navigator.pop(context);
                            }
                          : null,
                      child: const Text('Activate'),
                    ),
                  ),
                  // //for potential projects
                  // Expanded(
                  //   flex: 1,
                  //   child: ElevatedButton(
                  //     style: ElevatedButton.styleFrom(
                  //       shape: RoundedRectangleBorder(
                  //           borderRadius: BorderRadius.circular(0)),
                  //       backgroundColor:
                  //           const Color.fromARGB(255, 214, 163, 238),
                  //       disabledBackgroundColor: Colors.grey,
                  //     ),
                  //     onPressed:
                  //         widget.selectedMockup.mockupStatus != 'potential'
                  //             ? () async {
                  //                 //Cannot put project on hold if workers are still assigned to it
                  //                 if (widget.selectedMockup.assignedWorkers !=
                  //                         null &&
                  //                     widget.selectedMockup.assignedWorkers
                  //                         .isNotEmpty) {
                  //                   _snackBarWidget.content =
                  //                       'You have workers assigned to this projects, remove them before holding it';
                  //                   _snackBarWidget.showSnack();
                  //                   return;
                  //                 }
                  //                 setState(() {
                  //                   _loading = true;
                  //                 });
                  //                 editedProject.mockupStatus = 'potential';
                  //                 //will change project status
                  //                 //will change project status
                  //             await db.updateMockupStatus(
                  //                 mockup: editedProject);

                  //                 Navigator.pop(context);
                  //               }
                  //             : null,
                  //     child: const Text('Hold'),
                  //   ),
                  // ),
                  //for closed projects
                  Expanded(
                    flex: 1,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 243, 98, 49),
                        disabledBackgroundColor: Colors.grey,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                              topRight: Radius.circular(25),
                              bottomRight: Radius.circular(25)),
                        ),
                      ),
                      onPressed: widget.selectedMockup.mockupStatus != 'closed'
                          ? () async {
                              //Cannot close project if workers are still assigned to it
                              if (widget.selectedMockup.assignedWorkers !=
                                      null &&
                                  widget.selectedMockup.assignedWorkers
                                      .isNotEmpty) {
                                _snackBarWidget.content =
                                    'You have workers assigned to this projects, remove them before closing it';
                                _snackBarWidget.showSnack();
                                return;
                              }

                              setState(() {
                                _loading = true;
                              });

                              editedProject.mockupStatus = 'closed';

                              //will change project status
                              //will change project status
                              await db.updateMockupStatus(
                                  mockup: editedProject);

                              //should remove any workers currently on the project

                              Navigator.pop(context);
                            }
                          : null,
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
