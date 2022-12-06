import 'package:flutter/material.dart';
import 'package:royal_marble/models/business_model.dart';
import 'package:royal_marble/models/user_model.dart';
import 'package:royal_marble/services/database.dart';
import 'package:royal_marble/shared/constants.dart';
import 'package:royal_marble/shared/snack_bar.dart';

class VisitDetailsClass extends StatefulWidget {
  const VisitDetailsClass(
      {Key key,
      this.currentUser,
      this.currentVisit,
      this.selectedUser,
      this.projectVisit,
      this.visitType})
      : super(key: key);
  final UserData currentUser;
  final UserData selectedUser;
  final ClientVisitDetails currentVisit;
  final ProjectVisitDetails projectVisit;
  final String visitType;

  @override
  State<VisitDetailsClass> createState() => _VisitDetailsClassState();
}

class _VisitDetailsClassState extends State<VisitDetailsClass> {
  Size _size;
  bool _edit = false;

  String visitDetails;
  String managerComments;
  DatabaseService db = DatabaseService();
  SnackBarWidget _snackBarWidget = SnackBarWidget();
  String visitUser;
  @override
  void initState() {
    super.initState();
    if (widget.currentVisit == null) {
      visitDetails = widget.projectVisit.visitDetails;
      managerComments = widget.projectVisit.managerComments ?? '';
      visitUser = widget.projectVisit.userId;
      print('visit details: ${widget.projectVisit} ');
    } else {
      visitDetails = widget.currentVisit.visitDetails;
      managerComments = widget.currentVisit.managerComments ?? '';
      visitUser = widget.currentVisit.userId;
      print('visit details: ${widget.currentVisit} ');
    }
  }

  @override
  Widget build(BuildContext context) {
    _size = MediaQuery.of(context).size;
    return Scaffold(
        appBar: AppBar(
          title: const Text('Daily Visits Details'),
          backgroundColor: const Color.fromARGB(255, 191, 180, 66),
          actions: [
            //create an edit button to edit content
            TextButton(
                onPressed: () {
                  setState(() {
                    _edit = !_edit;
                  });
                },
                child: const Text(
                  'Edit',
                  style: buttonStyle,
                ))
          ],
        ),
        body: widget.currentVisit != null || widget.projectVisit != null
            ? _buildVisitDetails()
            : _buildNullVisit());
  }

  Widget _buildNullVisit() {
    return const Center(
      child: Text('Error selecting visit, please contact admin!'),
    );
  }

  Widget _buildVisitDetails() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //build the details of the visit
            //Client name
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const Expanded(
                  flex: 1,
                  child: Text(
                    'Client Name: ',
                    style: textStyle3,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    widget.currentVisit != null
                        ? widget.currentVisit.clientName.toUpperCase()
                        : widget.projectVisit.projectName.toUpperCase(),
                    style: textStyle5,
                  ),
                )
              ],
            ),
            const SizedBox(
              height: 15,
            ),
            //contact name
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const Expanded(
                  flex: 1,
                  child: Text(
                    'Contact Name: ',
                    style: textStyle3,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    widget.currentVisit != null
                        ? widget.currentVisit.contactPerson.toUpperCase()
                        : widget.projectVisit.contactPerson.toUpperCase(),
                    style: textStyle5,
                  ),
                )
              ],
            ),
            const SizedBox(
              height: 15,
            ),
            //visit purpose
            SizedBox(
              height: 60,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const Expanded(
                        flex: 1,
                        child: Text(
                          'Visit Purpose: ',
                          style: textStyle3,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          widget.currentVisit != null
                              ? widget.currentVisit.visitPurpose.toUpperCase()
                              : widget.projectVisit.visitPurpose.toUpperCase(),
                          style: textStyle5,
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),

            //visit details

            const SizedBox(
              height: 15,
            ),
            //visit purpose
            SizedBox(
              height: _size.height / 4,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.only(top: 10, left: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const Expanded(
                        flex: 1,
                        child: Text(
                          'Visit Details: ',
                          style: textStyle3,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: !_edit
                            ? Text(
                                visitDetails,
                                style: textStyle5,
                              )
                            : widget.selectedUser.uid == visitUser
                                ? TextFormField(
                                    initialValue: visitDetails,
                                    maxLines: 7,
                                    style: textStyle5,
                                    decoration: const InputDecoration(
                                      filled: true,
                                      hintText: 'Visit Details',
                                      border: InputBorder.none,
                                    ),
                                    validator: (val) {
                                      if (val.isEmpty) {
                                        return 'Details cannot be left empty';
                                      }
                                      return null;
                                    },
                                    onChanged: (val) {
                                      if (val != null) {
                                        visitDetails = val.trim();
                                      }
                                    },
                                  )
                                : Text(
                                    visitDetails,
                                    style: textStyle5,
                                  ),
                      )
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(
              height: 15,
            ),
            //manager comments for manager purpose only
            SizedBox(
              height: _size.height / 4,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.only(top: 10, left: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const Expanded(
                        flex: 1,
                        child: Text(
                          'Manager Comments: ',
                          style: textStyle3,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: !_edit
                            ? Text(
                                managerComments,
                                style: textStyle5,
                              )
                            : widget.currentUser.roles.contains('isAdmin')
                                ? TextFormField(
                                    initialValue: managerComments,
                                    maxLines: 7,
                                    style: textStyle5,
                                    decoration: const InputDecoration(
                                      filled: true,
                                      hintText: 'Manager Comments',
                                      border: InputBorder.none,
                                    ),
                                    validator: (val) {
                                      if (val.isEmpty) {
                                        return 'Details cannot be left empty';
                                      }
                                      return null;
                                    },
                                    onChanged: (val) {
                                      if (val != null) {
                                        managerComments = val.trim();
                                      }
                                    },
                                  )
                                : Text(
                                    managerComments,
                                    style: textStyle5,
                                  ),
                      )
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(
              height: 15,
            ),
            //Save in case we are editing
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[400],
                        fixedSize: Size(_size.width / 2, 45),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25))),
                    onPressed: () async {
                      var result;
                      _snackBarWidget.context = context;
                      var managerCommentsOld;
                      var visitDetailsOld;

                      if (widget.currentVisit != null) {
                        managerCommentsOld =
                            widget.currentVisit.managerComments ?? '';
                        visitDetailsOld = widget.currentVisit.visitDetails;
                      } else {
                        managerCommentsOld =
                            widget.projectVisit.managerComments ?? '';
                        visitDetailsOld = widget.projectVisit.visitDetails;
                      }
                      //will update the manager comment or edit the content of the visit details
                      if (managerComments != managerCommentsOld ||
                          visitDetails != visitDetailsOld) {
                        //will shall save changes
                        result = await db.updateCurrentSalesVisit(
                            visitId: widget.currentVisit != null
                                ? widget.currentVisit.uid
                                : widget.projectVisit.uid,
                            userId: widget.currentVisit != null
                                ? widget.currentVisit.userId
                                : widget.projectVisit.userId,
                            managerComments: managerComments,
                            visitDetails: visitDetails,
                            visitType: widget.visitType);
                      }
                      Navigator.pop(context);
                      _snackBarWidget.content = result;
                      _snackBarWidget.showSnack();
                    },
                    child: const Text(
                      'Save',
                      style: textStyle2,
                    )),
              ],
            )
          ],
        ),
      ),
    );
  }
}
