import 'dart:io';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:royal_marble/models/business_model.dart';
import 'package:royal_marble/projects/work_completed.dart';
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
import 'package:sentry/sentry.dart';

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
  bool _isLoading = false;
  bool _checkInOutLoading = false;
  PhoneNumber phoneNumber = PhoneNumber(isoCode: 'AE');
  TextEditingController _phoneController = TextEditingController();
  Color _statusColor;

  @override
  void initState() {
    super.initState();

    _snackBarWidget.context = context;
    if (!widget.isNewProject) {
      newProject = widget.selectedProject;

      phoneNumber = PhoneNumber(
        phoneNumber: widget.selectedProject.phoneNumber.phoneNumber,
        isoCode: widget.selectedProject.phoneNumber.isoCode,
        dialCode: widget.selectedProject.phoneNumber.dialCode,
      );

      _checkAssignedWorkers = checkProjectWorkers();
    } else {
      newProject.projectStatus = 'potential';
      selectMapLocation(
          locationAddress: LatLng(
              widget.projectLocation['Lat'], widget.projectLocation['Lng']),
          locationName: widget.projectLocation['addressName']
              .toString()
              .characters
              .take(120)
              .toString());
    }

    if (newProject.projectStatus != null) {
      switch (newProject.projectStatus) {
        case 'active':
          _statusColor = const Color.fromARGB(255, 148, 218, 83);
          break;
        case 'potential':
          _statusColor = const Color.fromARGB(255, 214, 163, 238);
          break;
        case 'closed':
          _statusColor = const Color.fromARGB(255, 243, 98, 49);
          break;
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
    _phoneController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text('Project Form'),
            //Project status
            Padding(
              padding: const EdgeInsets.only(left: 15),
              child: Container(
                padding: const EdgeInsets.all(4),
                width: _size.width / 3.5,
                decoration: BoxDecoration(
                  color: _statusColor,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Text(
                  newProject.projectStatus.toUpperCase(),
                  style: textStyle12,
                  textAlign: TextAlign.center,
                ),
              ),
            )
          ],
        ),
        backgroundColor: const Color.fromARGB(255, 191, 180, 66),
        actions: [
          !widget.isNewProject
              ? widget.currentUser.roles.contains('isAdmin')
                  ? TextButton(
                      style: TextButton.styleFrom(
                          backgroundColor: !_editContent
                              ? const Color.fromARGB(255, 191, 180, 66)
                              : Colors.grey[500]),
                      onPressed: () {
                        setState(() {
                          _editContent = !_editContent;
                        });
                      },
                      child: Text(
                        'Edit',
                        style: !_editContent ? textStyle2 : textStyle4,
                      ))
                  : const SizedBox.shrink()
              : const SizedBox.shrink()
        ],
      ),
      body: _isLoading
          ? const Center(child: Loading())
          : !widget.isNewProject
              ? _buildProjectBody()
              : _buildNewProjectForm(),
    );
  }

  Future<List<UserData>> checkProjectWorkers() async {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (widget.allWorkers != null && widget.allWorkers.isNotEmpty) {
        for (var worker in widget.allWorkers) {
          if (worker.assignedProject != null &&
              worker.assignedProject.runtimeType == List) {
            for (var project in worker.assignedProject) {
              if (project['id'] == widget.selectedProject.uid) {
                workerOnThisProject.add(worker);
              }
            }
          }

          if (worker.assignedProject != null &&
              worker.assignedProject.runtimeType != List) {
            if (worker.assignedProject['id'] == widget.selectedProject.uid) {
              workerOnThisProject.add(worker);
            }
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
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
                    //Project contact person
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
                        ? InternationalPhoneNumberInput(
                            onInputChanged: (PhoneNumber number) {
                              print(
                                  '${number.phoneNumber} - ${number.isoCode}');
                            },
                            onInputValidated: (bool value) {
                              print(value);
                            },
                            selectorConfig: const SelectorConfig(
                              selectorType: PhoneInputSelectorType.BOTTOM_SHEET,
                            ),
                            ignoreBlank: false,
                            autoValidateMode: AutovalidateMode.disabled,
                            selectorTextStyle:
                                const TextStyle(color: Colors.black),
                            initialValue: phoneNumber,
                            textFieldController: _phoneController,
                            formatInput: false,
                            keyboardType: const TextInputType.numberWithOptions(
                                signed: true, decimal: true),
                            inputBorder: const OutlineInputBorder(),
                            onSaved: (PhoneNumber number) {
                              newProject.phoneNumber = number;
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
                                phoneNumber != null
                                    ? phoneNumber.phoneNumber
                                    : '',
                                style: textStyle3,
                              ),
                            )
                          ]),
                    const SizedBox(
                      height: 15,
                    ),
                    //Project email address
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
                    //Project location
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
                                //will start google navigation for the current project location
                                _httpNavigation.context = context;
                                _httpNavigation.lat = widget
                                    .selectedProject.projectAddress['Lat'];
                                _httpNavigation.lng = widget
                                    .selectedProject.projectAddress['Lng'];
                                _httpNavigation.startNaviagtionGoogleMap();
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
                                  if (snapshot.data['data']
                                          [widget.currentUser.uid] !=
                                      null) {
                                    _isAtSite = snapshot.data['data']
                                        [widget.currentUser.uid]['isOnSite'];
                                  }
                                }
                              }

                              return Stack(
                                children: [
                                  Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: SizedBox(
                                        height: _size.width / 2,
                                        width: _size.width / 2,
                                        child: Container(
                                          decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.3),
                                                  spreadRadius: 6,
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 3),
                                                )
                                              ]),
                                          child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                  elevation: 3,
                                                  backgroundColor: !_isAtSite
                                                      ? Colors.green[400]
                                                      : Colors.red[600],
                                                  shape: const CircleBorder()),
                                              onPressed: !_checkInOutLoading
                                                  ? () async {
                                                      setState(() {
                                                        _checkInOutLoading =
                                                            true;
                                                      });
                                                      await checkInOut(
                                                          snapshot);
                                                      setState(() {
                                                        _checkInOutLoading =
                                                            false;
                                                      });
                                                      Navigator.pop(context);
                                                    }
                                                  : null,
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
                                      ),
                                    ),
                                  ),
                                  _checkInOutLoading
                                      ? Center(
                                          child: SizedBox(
                                              height: _size.width / 2,
                                              width: _size.width / 2,
                                              child: const Loading()),
                                        )
                                      : const SizedBox.shrink()
                                ],
                              );
                            })
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
                                          if (selectedUser.assignedProject !=
                                                  null &&
                                              selectedUser
                                                  .assignedProject.isNotEmpty &&
                                              !selectedUser.roles
                                                  .contains('isSupervisor')) {
                                            showDialog(
                                                context: context,
                                                builder: (_) => AlertDialog(
                                                      backgroundColor:
                                                          Colors.red[100],
                                                      shape:
                                                          RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          35)),
                                                      title: const Text(
                                                        'Warning',
                                                        textAlign:
                                                            TextAlign.center,
                                                      ),
                                                      content: Text(
                                                        '${selectedUser.firstName} ${selectedUser.lastName} is already assigned to project ${selectedUser.assignedProject['name']}.\nPlease remove the user from the first project before adding to a new one?',
                                                        textAlign:
                                                            TextAlign.center,
                                                      ),
                                                      actions: [
                                                        Center(
                                                          child: TextButton(
                                                              onPressed: () {
                                                                Navigator.pop(
                                                                    context);
                                                              },
                                                              child: const Text(
                                                                'Ok',
                                                                style:
                                                                    textStyle3,
                                                              )),
                                                        ),
                                                      ],
                                                    ));
                                          } else {
                                            if (!addedUsers.contains(val)) {
                                              addedUsers.add(val);
                                            }
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

                    widget.currentUser.roles.contains('isAdmin')
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
                                  setState(() {
                                    _isLoading = true;
                                  });
                                  if (_editContent) {
                                    if (_formKey.currentState.validate()) {
                                      _formKey.currentState.save();
                                      var result = await db.updateProjectData(
                                        project: newProject,
                                      );
                                      Navigator.pop(context);
                                    } else {
                                      setState(() {
                                        _isLoading = false;
                                      });
                                      _snackBarWidget.content =
                                          'Please validate your entries';
                                      _snackBarWidget.showSnack();
                                    }
                                  } else {
                                    if (addedUsers.isNotEmpty) {
                                      List<String> userIds = [];
                                      for (var element in addedUsers) {
                                        userIds.add(element.uid);
                                      }

                                      var result =
                                          await db.updateProjectWithWorkers(
                                              project: widget.selectedProject,
                                              selectedUserIds: userIds,
                                              addedUsers: addedUsers,
                                              removedUsers: removedUsers);

                                      if (result == 'Completed') {
                                        Navigator.pop(context);
                                      } else {
                                        _snackBarWidget.content =
                                            'failed to update account, please contact developer';
                                        _snackBarWidget.showSnack();
                                      }
                                    } else {
                                      if (_formKey.currentState.validate()) {
                                        var result = await db.updateProjectData(
                                            project: newProject);

                                        if (result == 'Completed') {
                                          Navigator.pop(context);
                                        } else {
                                          _snackBarWidget.content =
                                              'failed to update account, please contact developer';
                                          _snackBarWidget.showSnack();
                                          setState(() {
                                            _isLoading = false;
                                          });
                                        }
                                      }
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
              InternationalPhoneNumberInput(
                onInputChanged: (PhoneNumber number) {
                  print('${number.phoneNumber} - ${number.isoCode}');
                },
                onInputValidated: (bool value) {
                  print(value);
                },
                selectorConfig: const SelectorConfig(
                  selectorType: PhoneInputSelectorType.BOTTOM_SHEET,
                ),
                ignoreBlank: false,
                autoValidateMode: AutovalidateMode.disabled,
                selectorTextStyle: const TextStyle(color: Colors.black),
                initialValue: phoneNumber,
                textFieldController: _phoneController,
                formatInput: false,
                keyboardType: const TextInputType.numberWithOptions(
                    signed: true, decimal: true),
                inputBorder: const OutlineInputBorder(),
                onSaved: (PhoneNumber number) {
                  newProject.phoneNumber = number;
                },
              ),
              // TextFormField(
              //   autofocus: false,
              //   initialValue: '',
              //   style: textStyle5,
              //   keyboardType: TextInputType.number,
              //   inputFormatters: <TextInputFormatter>[
              //     FilteringTextInputFormatter.digitsOnly,
              //   ],
              //   decoration: InputDecoration(
              //     filled: true,
              //     label: const Text('Contact Phone'),
              //     hintText: 'Ex: 05 123 12345',
              //     fillColor: Colors.grey[100],
              //     enabledBorder: const OutlineInputBorder(
              //         borderRadius: BorderRadius.all(Radius.circular(15.0)),
              //         borderSide: BorderSide(color: Colors.grey)),
              //     focusedBorder: const OutlineInputBorder(
              //         borderRadius: BorderRadius.all(Radius.circular(15.0)),
              //         borderSide: BorderSide(color: Colors.green)),
              //   ),
              //   validator: (val) {
              //     Pattern pattern = r'^(?:[05]8)?[0-9]{10}$';
              //     var regexp = RegExp(pattern.toString());
              //     if (val.isEmpty) {
              //       return 'Phone cannot be empty';
              //     }
              //     if (!regexp.hasMatch(val)) {
              //       return 'Phone number does not match a UAE number';
              //     } else {
              //       return null;
              //     }
              //   },
              //   onChanged: (val) {
              //     setState(() {
              //       newProject.phoneNumber = val.trim();
              //     });
              //   },
              // ),
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
                        _formKey.currentState.save();
                        setState(() {
                          _isLoading = true;
                        });
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
    try {
      CalculateDistance _calculate = CalculateDistance();
      var dt = DateTime.now();
      String dateFormat = DateFormat('hh:mm a').format(dt);
      var result = _calculate.distanceBetweenTwoPoints(
          myLocation.latitude,
          myLocation.longitude,
          widget.selectedProject.projectAddress['Lat'],
          widget.selectedProject.projectAddress['Lng']);
      //will check if the worker has arrived to the site
      if (result != null && result * 1000 <= widget.selectedProject.radius) {
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
            'You have ${((result * 1000) - widget.selectedProject.radius).round()} meters to arrive to your destination.';
        _snackBarWidget.showSnack();
      }

      return dt;
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
      return e;
    }
  }

  //will allow the working to checkin or checkout
  Future<void> checkInOut(var data) async {
    Map<String, dynamic> completedWork = {};
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
        //Code will execute for isNormalUser only when trying to check out
        if (!_isAtSite && widget.currentUser.roles.contains('isNormalUser')) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => WorkCompleted(
                  isAtSite: _isAtSite,
                  currentUser: widget.currentUser,
                  timeSheetId: '${result.day}-${result.month}-${result.year}',
                  selectedProject: widget.selectedProject,
                  checkIn: todayTimeSheet['data'][widget.currentUser.uid]
                      ['arriving_at'],
                  checkOut: result.toString()),
            ),
          );
        } else {
          //code will execute for all user including isNormalUser to check it, and for all users excluding isNormalUser to checkout
          if (todayTimeSheet['data'] != null) {
            if (todayTimeSheet['data'][widget.currentUser.uid] != null) {
              if (_isAtSite) {
                timeSheetUpdated = await db.updateWorkerTimeSheet(
                    isAtSite: _isAtSite,
                    currentUser: widget.currentUser,
                    userRole: widget.currentUser.roles.first,
                    selectedProject: widget.selectedProject,
                    today: '${result.day}-${result.month}-${result.year}',
                    checkOut: todayTimeSheet['data'][widget.currentUser.uid]
                        ['leaving_at'],
                    checkIn: result.toString());
              } else {
                timeSheetUpdated = await db.updateWorkerTimeSheet(
                    isAtSite: _isAtSite,
                    currentUser: widget.currentUser,
                    selectedProject: widget.selectedProject,
                    userRole: widget.currentUser.roles.first,
                    today: '${result.day}-${result.month}-${result.year}',
                    checkIn: todayTimeSheet['data'][widget.currentUser.uid]
                        ['arriving_at'],
                    checkOut: result.toString());
              }
            } else {
              //set the data base with the required information
              timeSheetUpdated = await db.updateWorkerTimeSheet(
                isAtSite: _isAtSite,
                currentUser: widget.currentUser,
                selectedProject: widget.selectedProject,
                userRole: widget.currentUser.roles.first,
                today: '${result.day}-${result.month}-${result.year}',
                checkIn: result.toString(),
              );
            }
          } else {
            //set the data base with the required information
            if (_isAtSite) {
              timeSheetUpdated = await db.setWorkerTimeSheet(
                  userRole: widget.currentUser.roles.first,
                  isAtSite: _isAtSite,
                  currentUser: widget.currentUser,
                  selectedProject: widget.selectedProject,
                  today: '${result.day}-${result.month}-${result.year}',
                  checkIn: result.toString());
            } else {
              timeSheetUpdated = await db.setWorkerTimeSheet(
                  userRole: widget.currentUser.roles.first,
                  isAtSite: _isAtSite,
                  currentUser: widget.currentUser,
                  selectedProject: widget.selectedProject,
                  today: '${result.day}-${result.month}-${result.year}',
                  checkOut: result.toString());
            }
          }
        }
      }
    }
  }

  Future<Map<String, dynamic>> _completedWork() async {}

  Future checkCurrentUserStatus() async {
    String currentDate =
        '${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}';

    var result = await db.getCurrentTimeSheet(today: currentDate);
    return result;
  }
}
