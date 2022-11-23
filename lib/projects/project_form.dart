import 'dart:io';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:royal_marble/models/business_model.dart';
import 'package:royal_marble/shared/calculate_distance.dart';
import 'package:royal_marble/shared/constants.dart';
import 'package:royal_marble/shared/loading.dart';
import 'package:geolocator/geolocator.dart' as geo;
import '../location/google_map_navigation.dart';
import '../location/http_navigation.dart';
import '../models/user_model.dart';
import '../services/database.dart';
import '../shared/snack_bar.dart';
import 'package:intl/intl.dart';

class ProjectForm extends StatefulWidget {
  const ProjectForm(
      {Key key,
      this.selectedProject,
      this.isNewProject,
      this.allWorkers,
      this.projectLocation,
      this.assignCirule,
      this.currentUser})
      : super(key: key);
  final UserData currentUser;
  final ProjectData selectedProject;
  final Map<String, dynamic> projectLocation;
  final bool isNewProject;
  final List<UserData> allWorkers;
  final Function assignCirule;

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
  UserData selectedUser;
  List<UserData> addedUsers = [];
  List<UserData> removedUsers = [];
  Future _checkAssignedWorkers;
  List<UserData> workerOnThisProject = [];
  List<double> availableRadius = [100, 200, 400, 600, 1000];
  double radius;
  HttpNavigation _httpNavigation = HttpNavigation();
  bool _isAtSite = false;
  Future userStatus;

  @override
  void initState() {
    super.initState();
    _snackBarWidget.context = context;
    if (!widget.isNewProject) {
      newProject = widget.selectedProject;
      _checkAssignedWorkers = checkProjectWorkers();
    } else {
      selectMapLocation(
          locationAddress: LatLng(
              widget.projectLocation['Lat'], widget.projectLocation['Lng']),
          locationName: widget.projectLocation['addressName']
              .toString()
              .characters
              .take(120)
              .toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    _size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Form'),
        backgroundColor: const Color.fromARGB(255, 191, 180, 66),
        actions: [
          !widget.isNewProject
              ? widget.currentUser.roles.contains('isAdmin')
                  ? TextButton(
                      onPressed: () {
                        setState(() {
                          _editContent = !_editContent;
                        });
                      },
                      child: const Text(
                        'Edit',
                        style: buttonStyle,
                      ))
                  : const SizedBox.shrink()
              : const SizedBox.shrink()
        ],
      ),
      body: !widget.isNewProject ? _buildProjectBody() : _buildNewProjectForm(),
    );
  }

  Future<List<UserData>> checkProjectWorkers() async {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (widget.allWorkers != null && widget.allWorkers.isNotEmpty) {
        for (var worker in widget.allWorkers) {
          if (worker.assignedProject != null &&
              worker.assignedProject['id'] == widget.selectedProject.uid) {
            workerOnThisProject.add(worker);
          }

          setState(() {});
        }

        return workerOnThisProject;
      }
    });

    return workerOnThisProject;
  }

  //will allow to build a current project
  Widget _buildProjectBody() {
    if (widget.allWorkers.isNotEmpty) {
      selectedUser = widget.allWorkers[0];
    }
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
                    //project details
                    _editContent
                        ? TextFormField(
                            autofocus: false,
                            initialValue: widget.selectedProject.projectDetails,
                            style: textStyle5,
                            textCapitalization: TextCapitalization.sentences,
                            maxLines: 3,
                            decoration: InputDecoration(
                              filled: true,
                              label: const Text('Project Details'),
                              hintText: 'Ex: The project is about',
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
                                ? 'Project details cannot be empty'
                                : null,
                            onChanged: (val) {
                              setState(() {
                                newProject.projectDetails = val.trim();
                              });
                            },
                          )
                        : Row(children: [
                            const Expanded(
                              flex: 1,
                              child: Text(
                                'Project Details',
                                style: textStyle5,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                widget.selectedProject.projectDetails,
                                style: textStyle3,
                              ),
                            )
                          ]),
                    const SizedBox(
                      height: 15,
                    ),

                    //project contractor
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

                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all()),
                      child: Row(children: [
                        const Expanded(
                          flex: 1,
                          child: Text(
                            'Location',
                            style: textStyle5,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: GestureDetector(
                            onTap: () async {
                              if (Platform.isIOS) {
                                _httpNavigation.context = context;
                                _httpNavigation.lat = widget
                                    .selectedProject.projectAddress['Lat'];
                                _httpNavigation.lng = widget
                                    .selectedProject.projectAddress['Lng'];
                              } else {
                                await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => GoogleMapNavigation(
                                              lat: widget.selectedProject
                                                  .projectAddress['Lat'],
                                              lng: widget.selectedProject
                                                  .projectAddress['Lng'],
                                              navigate: true,
                                            )));
                              }
                            },
                            child: Text(
                              widget
                                  .selectedProject.projectAddress['addressName']
                                  .toString(),
                              style: textStyle3,
                            ),
                          ),
                        )
                      ]),
                    ),
                    const SizedBox(
                      height: 15,
                    ),
                    //will allow the worker to check in the project they just arrived to
                    widget.currentUser.roles.contains('isNormalUser') ||
                            widget.currentUser.roles
                                .contains('isSiteEngineer') ||
                            widget.currentUser.roles.contains('isSupervisor')
                        ? FutureBuilder(
                            future: checkCurrentUserStatus(),
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                if (snapshot.data['data'] != null) {
                                  _isAtSite = snapshot.data['data']
                                      [widget.currentUser.uid]['isOnSite'];
                                }
                              }

                              return Padding(
                                padding: const EdgeInsets.all(12),
                                child: SizedBox(
                                  height: _size.width / 2,
                                  width: _size.width / 2,
                                  child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: !_isAtSite
                                              ? Colors.green[400]
                                              : Colors.red[600],
                                          shape: const CircleBorder()),
                                      onPressed: () async {
                                        await checkInOut(snapshot);
                                      },
                                      child: !_isAtSite
                                          ? const Text(
                                              'Check In',
                                              style: textStyle2,
                                            )
                                          : const Text(
                                              'Check Out',
                                              style: textStyle2,
                                            )),
                                ),
                              );
                            })
                        : const SizedBox.shrink(),

                    //Submit button will allow you add the entered data into the database
                    _editContent
                        ? Center(
                            child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor:
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
                    //this feature is only available for admin users
                    widget.currentUser.roles.contains('isAdmin')
                        ? !_editContent
                            ? Container(
                                alignment: AlignmentDirectional.centerStart,
                                height: 50,
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.all(
                                    Radius.circular(15.0),
                                  ),
                                  border: Border.all(
                                      width: 1.0, color: Colors.grey),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButtonFormField<UserData>(
                                    decoration: const InputDecoration.collapsed(
                                        hintText: ''),
                                    isExpanded: true,
                                    value: selectedUser,
                                    hint: const Center(
                                      child: Text(
                                        'Select User',
                                      ),
                                    ),
                                    onChanged: (UserData val) {
                                      if (val != null) {
                                        setState(() {
                                          selectedUser = val;
                                          if (!addedUsers.contains(val)) {
                                            addedUsers.add(val);
                                          }
                                        });
                                      }
                                    },
                                    selectedItemBuilder:
                                        (BuildContext context) {
                                      return widget.allWorkers
                                          .map<Widget>(
                                            (item) => Center(
                                              child: Text(
                                                '${item.firstName} ${item.lastName} - ${item.roles.first}',
                                                style: textStyle5,
                                              ),
                                            ),
                                          )
                                          .toList();
                                    },
                                    validator: (val) => val == null
                                        ? 'Please select User'
                                        : null,
                                    items: widget.allWorkers
                                        .map((item) =>
                                            DropdownMenuItem<UserData>(
                                              value: item,
                                              child: Center(
                                                  child: Text(
                                                '${item.firstName} ${item.lastName}- ${item.roles.first}',
                                                style: textStyle5,
                                              )),
                                            ))
                                        .toList(),
                                  ),
                                ),
                              )
                            : const SizedBox.shrink()
                        : const SizedBox.shrink(),
                    //Feature only available for admin user
                    widget.currentUser.roles.contains('isAdmin')
                        ? !_editContent
                            ? FutureBuilder(
                                future: _checkAssignedWorkers,
                                builder: (context, snapshot) {
                                  if (snapshot.hasData) {
                                    addedUsers = snapshot.data;
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 10),
                                      child: Container(
                                        decoration: const BoxDecoration(
                                            border: Border.symmetric(
                                                horizontal: BorderSide(
                                                  width: 2,
                                                ),
                                                vertical: BorderSide.none)),
                                        height: _size.height / 4.5,
                                        width: _size.width - 80,
                                        child: ListView.builder(
                                          itemCount: addedUsers.length,
                                          itemBuilder: ((context, index) =>
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 10,
                                                        horizontal: 20),
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                      color: Colors.grey[200],
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20)),
                                                  padding:
                                                      const EdgeInsets.all(12),
                                                  child: GestureDetector(
                                                    onTap: () {
                                                      //check the removed users
                                                      if (!removedUsers
                                                          .contains(addedUsers[
                                                              index])) {
                                                        removedUsers.add(
                                                            addedUsers[index]);
                                                      }
                                                      addedUsers
                                                          .removeAt(index);
                                                      setState(() {});
                                                    },
                                                    child: Text(
                                                      '${addedUsers[index].firstName} ${addedUsers[index].lastName} - ${addedUsers[index].roles.first}',
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                  ),
                                                ),
                                              )),
                                        ),
                                      ),
                                    );
                                  } else {
                                    return Container(
                                      decoration: const BoxDecoration(
                                          border: Border.symmetric(
                                              horizontal: BorderSide(
                                                width: 2,
                                              ),
                                              vertical: BorderSide.none)),
                                      height: _size.height / 4.5,
                                      width: _size.width - 60,
                                      child: ListView.builder(
                                        itemCount: addedUsers.length,
                                        itemBuilder: ((context, index) =>
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 10,
                                                      horizontal: 20),
                                              child: Container(
                                                decoration: BoxDecoration(
                                                    border: Border.all(),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20)),
                                                padding:
                                                    const EdgeInsets.all(12),
                                                child: GestureDetector(
                                                  onTap: () {
                                                    //check the removed users
                                                    if (!removedUsers.contains(
                                                        addedUsers[index])) {
                                                      removedUsers.add(
                                                          addedUsers[index]);
                                                    }
                                                    addedUsers.removeAt(index);
                                                    setState(() {});
                                                  },
                                                  child: Text(
                                                      '${addedUsers[index].firstName} ${addedUsers[index].lastName}'),
                                                ),
                                              ),
                                            )),
                                      ),
                                    );
                                  }
                                })
                            : const SizedBox.shrink()
                        : const SizedBox.shrink(),
                    !_editContent
                        ? Center(
                            child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        const Color.fromARGB(255, 191, 180, 66),
                                    fixedSize: Size(_size.width / 2, 45),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(25))),
                                onPressed: () async {
                                  if (addedUsers.isNotEmpty) {
                                    List<String> userIds = [];
                                    for (var element in addedUsers) {
                                      userIds.add(element.uid);
                                    }

                                    var result =
                                        await db.updateProjectWithWorkers(
                                            project: widget.selectedProject,
                                            selectedUserIds: userIds,
                                            removedUsers: removedUsers);
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 35),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const Text(
                'The following form will allow you to add a new project, all required field should be filled before you can proceed',
                style: textStyle6,
              ),
              const SizedBox(
                height: 15,
              ),
              TextFormField(
                autofocus: false,
                initialValue: '',
                style: textStyle5,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  filled: true,
                  label: const Text('Project Name'),
                  hintText: 'Ex: Villa Mr. X',
                  fillColor: Colors.grey[100],
                  enabledBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(15.0)),
                      borderSide: BorderSide(color: Colors.grey)),
                  focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(15.0)),
                      borderSide: BorderSide(color: Colors.green)),
                ),
                validator: (val) =>
                    val.isEmpty ? 'Project name cannot be empty' : null,
                onChanged: (val) {
                  setState(() {
                    newProject.projectName = val.trim();
                  });
                },
              ),
              const SizedBox(
                height: 15,
              ),
              //project details
              TextFormField(
                autofocus: false,
                initialValue: '',
                style: textStyle5,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 3,
                decoration: InputDecoration(
                  filled: true,
                  label: const Text('Project Details'),
                  hintText: 'Ex: The project is about',
                  fillColor: Colors.grey[100],
                  enabledBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(15.0)),
                      borderSide: BorderSide(color: Colors.grey)),
                  focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(15.0)),
                      borderSide: BorderSide(color: Colors.green)),
                ),
                validator: (val) =>
                    val.isEmpty ? 'Project details cannot be empty' : null,
                onChanged: (val) {
                  setState(() {
                    newProject.projectDetails = val.trim();
                  });
                },
              ),
              const SizedBox(
                height: 15,
              ),

              //project contractor
              TextFormField(
                autofocus: false,
                initialValue: '',
                style: textStyle5,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  filled: true,
                  label: const Text('Contractor'),
                  hintText: 'Ex: Horizon Contracting Co.',
                  fillColor: Colors.grey[100],
                  enabledBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(15.0)),
                      borderSide: BorderSide(color: Colors.grey)),
                  focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(15.0)),
                      borderSide: BorderSide(color: Colors.green)),
                ),
                validator: (val) =>
                    val.isEmpty ? 'Contractor section cannot be empty' : null,
                onChanged: (val) {
                  setState(() {
                    newProject.contactorCompany = val.trim();
                  });
                },
              ),

              const SizedBox(
                height: 15,
              ),
              TextFormField(
                autofocus: false,
                initialValue: '',
                style: textStyle5,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  filled: true,
                  label: const Text('Contact Person'),
                  hintText: 'Ex: John Martin',
                  fillColor: Colors.grey[100],
                  enabledBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(15.0)),
                      borderSide: BorderSide(color: Colors.grey)),
                  focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(15.0)),
                      borderSide: BorderSide(color: Colors.green)),
                ),
                validator: (val) =>
                    val.isEmpty ? 'Contact person cannot be empty' : null,
                onChanged: (val) {
                  setState(() {
                    newProject.contactPerson = val.trim();
                  });
                },
              ),
              const SizedBox(
                height: 15,
              ),
              TextFormField(
                autofocus: false,
                initialValue: '',
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
                      borderRadius: BorderRadius.all(Radius.circular(15.0)),
                      borderSide: BorderSide(color: Colors.grey)),
                  focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(15.0)),
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
              ),
              const SizedBox(
                height: 15,
              ),
              TextFormField(
                autofocus: false,
                initialValue: '',
                style: textStyle5,
                decoration: InputDecoration(
                  filled: true,
                  label: const Text('Email Address'),
                  hintText: 'example@email.com',
                  fillColor: Colors.grey[100],
                  enabledBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(15.0)),
                      borderSide: BorderSide(color: Colors.grey)),
                  focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(15.0)),
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
              ),
              const SizedBox(
                height: 15,
              ),
              Container(
                alignment: Alignment.center,
                height: 50.0,
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey,
                  ),
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(15.0),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButtonFormField<double>(
                    decoration: const InputDecoration.collapsed(hintText: ''),
                    isExpanded: true,
                    value: radius,
                    hint: const Center(child: Text('Project Radius')),
                    onChanged: (val) {
                      setState(() {
                        FocusScope.of(context).requestFocus(FocusNode());
                        radius = val;
                        newProject.radius = radius;
                      });
                    },
                    validator: (val) =>
                        val == null ? 'Please select a radius' : null,
                    selectedItemBuilder: (BuildContext context) {
                      return availableRadius.map<Widget>((double rad) {
                        return Center(
                          child: Text(
                            rad.toString(),
                            style: textStyle4,
                          ),
                        );
                      }).toList();
                    },
                    items: availableRadius.map((double item) {
                      return DropdownMenuItem<double>(
                        value: item,
                        child: Text(item.toString()),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(
                height: 15,
              ),
              Row(children: [
                const Expanded(
                  flex: 1,
                  child: Text(
                    'Location',
                    style: textStyle5,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: widget.projectLocation != null
                      ? Text(
                          widget.projectLocation['addressName']
                              .toString()
                              .characters
                              .take(120)
                              .toString(),
                          style: textStyle3,
                        )
                      : const Text(
                          'Address not found',
                          style: textStyle3,
                        ),
                )
              ]),
              const SizedBox(
                height: 15,
              ),

              //Submit button will allow you add the entered data into the database
              Center(
                child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color.fromARGB(255, 191, 180, 66),
                        fixedSize: Size(_size.width / 2, 45),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25))),
                    onPressed: () async {
                      if (_formKey.currentState.validate()) {
                        var result =
                            await db.addNewProject(project: newProject);
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
            ],
          ),
        ),
      ),
    );
  }

  Future selectMapLocation(
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

  //calculates the distance between two points
  Future<DateTime> _calculateDistance(LatLng myLocation) async {
    CalculateDistance _calculate = CalculateDistance();
    var dt = DateTime.now();
    String dateFormat = DateFormat('hh:mm a').format(dt);
    var result = _calculate.distanceBetweenTwoPoints(
        myLocation.latitude,
        myLocation.longitude,
        widget.selectedProject.projectAddress['Lat'],
        widget.selectedProject.projectAddress['Lng']);

    //will check if the worker has arrived to the site
    if (result != null && result <= widget.selectedProject.radius) {
      if (_isAtSite) {
        _snackBarWidget.content =
            'Have a great day, you have checked out.\nTime: $dateFormat\n';
        _snackBarWidget.showSnack();
      } else {
        _snackBarWidget.content =
            'Wonderful, you have arrived to your assigned location.\nTime: $dateFormat\n';
        _snackBarWidget.showSnack();
      }

      if (mounted) {
        setState(() {
          _isAtSite = !_isAtSite;
        });
      }
    } else {
      dt = null;
      _snackBarWidget.content =
          'You have ${(result - widget.selectedProject.radius).round()} meters to arrive to your destination.';
      _snackBarWidget.showSnack();
    }
    return dt;
  }

  //will allow the working to checkin or checkout
  Future<void> checkInOut(var data) async {
    geo.Position userLocation = await geo.Geolocator.getCurrentPosition(
        desiredAccuracy: geo.LocationAccuracy.high);

    if (userLocation != null) {
      var result = await _calculateDistance(
          LatLng(userLocation.latitude, userLocation.longitude));

      //we will check if user in at site and record it in the report collection
      if (result != null && data.hasData) {
        var timeSheetUpdated;
        //check if field is available
        var todayTimeSheet = data.data;

        if (todayTimeSheet['data'] != null) {
          if (todayTimeSheet['data'] != null) {
            if (todayTimeSheet['data'][widget.currentUser.uid] != null) {
              if (_isAtSite) {
                timeSheetUpdated = await db.updateWorkerTimeSheet(
                    isAtSite: _isAtSite,
                    currentUser: widget.currentUser,
                    selectedProject: widget.selectedProject,
                    today: '${result.day}-${result.month}-${result.year}',
                    checkOut: todayTimeSheet['data'][widget.currentUser.uid]
                        ['leaving_at'],
                    checkIn: DateFormat('hh:mm a').format(result));
              } else {
                timeSheetUpdated = await db.updateWorkerTimeSheet(
                    isAtSite: _isAtSite,
                    currentUser: widget.currentUser,
                    selectedProject: widget.selectedProject,
                    today: '${result.day}-${result.month}-${result.year}',
                    checkIn: todayTimeSheet['data'][widget.currentUser.uid]
                        ['arriving_at'],
                    checkOut: DateFormat('hh:mm a').format(result));
              }
            }
          }
        } else {
          //set the data base with the required information
          if (_isAtSite) {
            timeSheetUpdated = await db.setWorkerTimeSheet(
                isAtSite: _isAtSite,
                currentUser: widget.currentUser,
                selectedProject: widget.selectedProject,
                today: '${result.day}-${result.month}-${result.year}',
                checkIn: DateFormat('hh:mm a').format(result));
          } else {
            timeSheetUpdated = await db.setWorkerTimeSheet(
                isAtSite: _isAtSite,
                currentUser: widget.currentUser,
                selectedProject: widget.selectedProject,
                today: '${result.day}-${result.month}-${result.year}',
                checkOut: DateFormat('hh:mm a').format(result));
          }
        }
      }
    }
  }

  Future checkCurrentUserStatus() async {
    String currentDate =
        '${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}';

    var result = await db.getCurrentTimeSheet(today: currentDate);
    return result;
  }
}
