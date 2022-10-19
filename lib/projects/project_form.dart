import 'dart:io';

import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:royal_marble/models/business_model.dart';
import 'package:royal_marble/shared/constants.dart';
import 'package:royal_marble/shared/loading.dart';

import '../location/google_map_navigation.dart';
import '../services/database.dart';
import '../shared/snack_bar.dart';

class ProjectForm extends StatefulWidget {
  const ProjectForm({Key key, this.selectedProject, this.isNewProject})
      : super(key: key);
  final ProjectData selectedProject;
  final bool isNewProject;

  @override
  State<ProjectForm> createState() => _ProjectFormState();
}

class _ProjectFormState extends State<ProjectForm> {
  bool _editContent = false;
  Size _size;
  final _formKey = GlobalKey<FormState>();
  Map<String, dynamic> _myLocation = {};
  ProjectData newProject = ProjectData();
  final db = DatabaseService();
  final _snackBarWidget = SnackBarWidget();

  @override
  void initState() {
    super.initState();
    _snackBarWidget.context = context;
  }

  @override
  Widget build(BuildContext context) {
    _size = MediaQuery.of(context).size;
    print(
        'the project name: ${widget.selectedProject.uid} - ${widget.selectedProject.projectName}');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Form'),
        backgroundColor: const Color.fromARGB(255, 191, 180, 66),
        actions: [
          TextButton(
              onPressed: () {
                setState(() {
                  _editContent = !_editContent;
                });
              },
              child: const Text(
                'Edit',
                style: buttonStyle,
              ))
        ],
      ),
      body: !widget.isNewProject ? _buildProjectBody() : _buildNewProjectForm(),
    );
  }

  //will allow to build a current project
  Widget _buildProjectBody() {
    return widget.selectedProject.uid != null
        ? Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 35),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const Text(
                      'The following form will allow you to view or update the current project, all required field should be filled before you can proceed',
                      style: textStyle6,
                    ),
                    const SizedBox(
                      height: 15,
                    ),
                    _editContent
                        ? TextFormField(
                            autofocus: false,
                            initialValue: widget.selectedProject.projectName,
                            style: textStyle5,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration(
                              filled: true,
                              label: const Text('Project Name'),
                              hintText: 'Ex: Villa Mr. X',
                              fillColor: Colors.grey[100],
                              enabledBorder: const OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(15.0)),
                                  borderSide: BorderSide(color: Colors.grey)),
                              focusedBorder: const OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(15.0)),
                                  borderSide: BorderSide(color: Colors.green)),
                            ),
                            validator: (val) => val.isEmpty
                                ? 'Project name cannot be empty'
                                : null,
                            onChanged: (val) {
                              setState(() {
                                newProject.projectName = val.trim();
                              });
                            },
                          )
                        : Row(children: [
                            const Expanded(
                              flex: 1,
                              child: Text(
                                'Project Name',
                                style: textStyle5,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                widget.selectedProject.projectName,
                                style: textStyle3,
                              ),
                            )
                          ]),
                    const SizedBox(
                      height: 15,
                    ),
                    _editContent
                        ? TextFormField(
                            autofocus: false,
                            initialValue:
                                widget.selectedProject.contactorCompany,
                            style: textStyle5,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration(
                              filled: true,
                              label: const Text('Contractor'),
                              hintText: 'Ex: Horizon Contracting Co.',
                              fillColor: Colors.grey[100],
                              enabledBorder: const OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(15.0)),
                                  borderSide: BorderSide(color: Colors.grey)),
                              focusedBorder: const OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(15.0)),
                                  borderSide: BorderSide(color: Colors.green)),
                            ),
                            validator: (val) => val.isEmpty
                                ? 'Contractor section cannot be empty'
                                : null,
                            onChanged: (val) {
                              setState(() {
                                newProject.contactorCompany = val.trim();
                              });
                            },
                          )
                        : Row(children: [
                            const Expanded(
                              flex: 1,
                              child: Text(
                                'Contractor',
                                style: textStyle5,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                widget.selectedProject.contactorCompany,
                                style: textStyle3,
                              ),
                            )
                          ]),

                    const SizedBox(
                      height: 15,
                    ),
                    _editContent
                        ? TextFormField(
                            autofocus: false,
                            initialValue: widget.selectedProject.contactPerson,
                            style: textStyle5,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration(
                              filled: true,
                              label: const Text('Contact Person'),
                              hintText: 'Ex: John Martin',
                              fillColor: Colors.grey[100],
                              enabledBorder: const OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(15.0)),
                                  borderSide: BorderSide(color: Colors.grey)),
                              focusedBorder: const OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(15.0)),
                                  borderSide: BorderSide(color: Colors.green)),
                            ),
                            validator: (val) => val.isEmpty
                                ? 'Contact person cannot be empty'
                                : null,
                            onChanged: (val) {
                              setState(() {
                                newProject.contactPerson = val.trim();
                              });
                            },
                          )
                        : Row(children: [
                            const Expanded(
                              flex: 1,
                              child: Text(
                                'Contact Name',
                                style: textStyle5,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                widget.selectedProject.contactPerson,
                                style: textStyle3,
                              ),
                            )
                          ]),
                    const SizedBox(
                      height: 15,
                    ),
                    _editContent
                        ? TextFormField(
                            autofocus: false,
                            initialValue: widget.selectedProject.phoneNumber,
                            style: textStyle5,
                            keyboardType: TextInputType.number,
                            inputFormatters: <TextInputFormatter>[
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: InputDecoration(
                              filled: true,
                              label: const Text('Contact Phone'),
                              hintText: 'Ex: 05 123 12345',
                              fillColor: Colors.grey[100],
                              enabledBorder: const OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(15.0)),
                                  borderSide: BorderSide(color: Colors.grey)),
                              focusedBorder: const OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(15.0)),
                                  borderSide: BorderSide(color: Colors.green)),
                            ),
                            validator: (val) {
                              Pattern pattern = r'^(?:[05]8)?[0-9]{10}$';
                              var regexp = RegExp(pattern.toString());
                              if (val.isEmpty) {
                                return 'Phone cannot be empty';
                              }
                              if (!regexp.hasMatch(val)) {
                                return 'Phone number does not match a UAE number';
                              } else {
                                return null;
                              }
                            },
                            onChanged: (val) {
                              setState(() {
                                newProject.phoneNumber = val.trim();
                              });
                            },
                          )
                        : Row(children: [
                            const Expanded(
                              flex: 1,
                              child: Text(
                                'Phone Number',
                                style: textStyle5,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                widget.selectedProject.phoneNumber,
                                style: textStyle3,
                              ),
                            )
                          ]),
                    const SizedBox(
                      height: 15,
                    ),
                    _editContent
                        ? TextFormField(
                            autofocus: false,
                            initialValue: widget.selectedProject.emailAddress,
                            style: textStyle5,
                            decoration: InputDecoration(
                              filled: true,
                              label: const Text('Email Address'),
                              hintText: 'example@email.com',
                              fillColor: Colors.grey[100],
                              enabledBorder: const OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(15.0)),
                                  borderSide: BorderSide(color: Colors.grey)),
                              focusedBorder: const OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(15.0)),
                                  borderSide: BorderSide(color: Colors.green)),
                            ),
                            validator: (val) {
                              if (val.isEmpty) {
                                return 'Email Address cannot be empty';
                              }
                              if (!EmailValidator.validate(val)) {
                                return 'This is not a valid email address';
                              } else {
                                return null;
                              }
                            },
                            onChanged: (val) {
                              setState(() {
                                newProject.emailAddress = val.trim();
                              });
                            },
                          )
                        : Row(children: [
                            const Expanded(
                              flex: 1,
                              child: Text(
                                'Project Email',
                                style: textStyle5,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                widget.selectedProject.emailAddress,
                                style: textStyle3,
                              ),
                            )
                          ]),
                    const SizedBox(
                      height: 15,
                    ),
                    _editContent
                        ? GestureDetector(
                            onTap: () async {
                              if (Platform.isIOS) {
                              } else {
                                await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => GoogleMapNavigation(
                                              getLocation: selecteMapLocation,
                                            )));
                              }
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                  border: Border.all(),
                                  borderRadius: BorderRadius.circular(15)),
                              height: 50,
                              child: Center(
                                child: Text(
                                  _myLocation.isNotEmpty
                                      ? 'Change Address'
                                      : 'Add Address',
                                  style: textStyle5,
                                ),
                              ),
                            ),
                          )
                        : Row(children: [
                            const Expanded(
                              flex: 1,
                              child: Text(
                                'Location',
                                style: textStyle5,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                _myLocation['addressName'].toString(),
                                style: textStyle3,
                              ),
                            )
                          ]),
                    const SizedBox(
                      height: 15,
                    ),

                    //Submit button will allow you add the entered data into the database
                    _editContent
                        ? Center(
                            child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    primary:
                                        const Color.fromARGB(255, 191, 180, 66),
                                    fixedSize: Size(_size.width / 2, 45),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(25))),
                                onPressed: () async {
                                  if (_formKey.currentState.validate()) {
                                    var result = await db.addNewProject(
                                        project: newProject);
                                    if (result == 'Completed') {
                                      Navigator.pop(context);
                                    } else {
                                      _snackBarWidget.content =
                                          'failed to update account, please contact developer';
                                      _snackBarWidget.showSnack();
                                    }
                                  }
                                },
                                child: const Text(
                                  'Submit',
                                  style: textStyle2,
                                )),
                          )
                        : const SizedBox.shrink(),
                  ],
                ),
              ),
            ),
          )
        : const Center(
            child: Loading(),
          );
  }

  //will allow building a new project form
  Widget _buildNewProjectForm() {
    return Container();
  }

  Future selecteMapLocation(
      {String locationName, LatLng locationAddress}) async {
    if (locationAddress != null && locationName != null) {
      _myLocation = {
        'addressName': locationName,
        'Lat': locationAddress.latitude,
        'Lng': locationAddress.longitude,
      };
      newProject.projectAddress = _myLocation;

      setState(() {});
    }
  }
}
