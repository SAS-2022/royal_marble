import 'dart:io';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:royal_marble/services/checkin_service.dart';
import 'package:royal_marble/widgets/checkin_card.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:royal_marble/models/business_model.dart';
import 'package:royal_marble/shared/constants.dart';
import 'package:royal_marble/shared/loading.dart';
import '../location/google_map_navigation.dart';
import '../location/http_navigation.dart';
import '../models/user_model.dart';
import '../services/database.dart';
import '../shared/snack_bar.dart';

class MockupForm extends StatefulWidget {
  const MockupForm(
      {Key? key,
      this.selectedMockUp,
      this.allWorkers,
      this.projectLocation,
      this.assignCirule,
      this.currentUser,
      this.isNewMockup})
      : super(key: key);
  final UserData? currentUser;
  final MockupData? selectedMockUp;
  final Map<String, dynamic>? projectLocation;
  final bool? isNewMockup;
  final List<UserData>? allWorkers;
  final Function? assignCirule;

  @override
  State<MockupForm> createState() => _MockupFormState();
}

class _MockupFormState extends State<MockupForm> {
  bool _editContent = false;
  Size? _size;
  final _formKey = GlobalKey<FormState>();
  Map<String, dynamic> _myLocation = {};
  MockupData newMockup = MockupData();
  final db = DatabaseService();
  final _snackBarWidget = SnackBarWidget();
  UserData? selectedUser;
  List<UserData> addedUsers = [];
  List<UserData> removedUsers = [];
  Future? _checkAssignedWorkers;
  List<UserData> workerOnThisProject = [];
  List<double> availableRadius = [100, 200, 400, 600, 1000];
  double? radius;
  HttpNavigation _httpNavigation = HttpNavigation();
  Future? userStatus;
  bool _isLoading = false;
  PhoneNumber phoneNumber = PhoneNumber(isoCode: 'AE');
  TextEditingController _phoneController = TextEditingController();
  Color? _statusColor;

  @override
  void initState() {
    super.initState();
    _snackBarWidget.context = context;
    if (!widget.isNewMockup!) {
      newMockup = widget.selectedMockUp!;

      phoneNumber = PhoneNumber(
        phoneNumber: widget.selectedMockUp!.phoneNumber!.phoneNumber,
        isoCode: widget.selectedMockUp!.phoneNumber!.isoCode,
        dialCode: widget.selectedMockUp!.phoneNumber!.dialCode,
      );

      _checkAssignedWorkers = checkProjectWorkers();
    } else {
      newMockup.mockupStatus = 'active';
      selectMapLocation(
          locationAddress: LatLng(
              widget.projectLocation!['Lat'], widget.projectLocation!['Lng']),
          locationName: widget.projectLocation!['addressName']
              .toString()
              .characters
              .take(120)
              .toString());
    }

    if (newMockup.mockupStatus != null) {
      switch (newMockup.mockupStatus) {
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

  //keep time sheet data even when offline

  @override
  Widget build(BuildContext context) {
    _size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text('Mock-Up Form'),
            //Project status
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Container(
                padding: const EdgeInsets.all(4),
                width: _size!.width / 3.6,
                decoration: BoxDecoration(
                  color: _statusColor,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Text(
                  newMockup.mockupStatus!.toUpperCase(),
                  style: textStyle12,
                  textAlign: TextAlign.center,
                ),
              ),
            )
          ],
        ),
        backgroundColor: const Color.fromARGB(255, 191, 180, 66),
        actions: [
          !widget.isNewMockup!
              ? widget.currentUser!.roles!.contains('isAdmin')
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
          : !widget.isNewMockup!
              ? _buildMockupBody()
              : _buildNewMockupForm(),
    );
  }

  Future<List<UserData>> checkProjectWorkers() async {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (widget.allWorkers != null && widget.allWorkers!.isNotEmpty) {
        for (var worker in widget.allWorkers!) {
          if (worker.assignedMockups != null &&
              worker.assignedMockups.runtimeType == List) {
            for (var project in worker.assignedMockups) {
              if (project['id'] == widget.selectedMockUp!.uid) {
                workerOnThisProject.add(worker);
              }
            }
          }

          if (worker.assignedMockups != null &&
              worker.assignedMockups.runtimeType != List) {
            if (worker.assignedMockups['id'] == widget.selectedMockUp!.uid) {
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
  Widget _buildMockupBody() {
    if (widget.allWorkers!.isNotEmpty) {
      selectedUser = widget.allWorkers![0];
    }
    return widget.selectedMockUp!.uid != null
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
                            initialValue: widget.selectedMockUp!.mockupName,
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
                            validator: (val) {
                              if (val != null || val!.isEmpty) {
                                return 'Project name cannot be empty';
                              }
                              return null;
                            },
                            onChanged: (val) {
                              setState(() {
                                newMockup.mockupName = val.trim();
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
                                widget.selectedMockUp!.mockupName!,
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
                            initialValue: widget.selectedMockUp!.mockupDetails,
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
                            validator: (val) => val!.isEmpty
                                ? 'Project details cannot be empty'
                                : null,
                            onChanged: (val) {
                              setState(() {
                                newMockup.mockupDetails = val.trim();
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
                                widget.selectedMockUp!.mockupDetails!,
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
                                widget.selectedMockUp!.contactorCompany,
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
                            validator: (val) => val!.isEmpty
                                ? 'Contractor section cannot be empty'
                                : null,
                            onChanged: (val) {
                              setState(() {
                                newMockup.contactorCompany = val.trim();
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
                                widget.selectedMockUp!.contactorCompany!,
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
                            initialValue: widget.selectedMockUp!.contactPerson,
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
                            validator: (val) => val!.isEmpty
                                ? 'Contact person cannot be empty'
                                : null,
                            onChanged: (val) {
                              setState(() {
                                newMockup.contactPerson = val.trim();
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
                                widget.selectedMockUp!.contactPerson!,
                                style: textStyle3,
                              ),
                            )
                          ]),
                    const SizedBox(
                      height: 15,
                    ),
                    _editContent
                        ? InternationalPhoneNumberInput(
                            onInputChanged: (PhoneNumber number) {},
                            onInputValidated: (bool value) {},
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
                              newMockup.phoneNumber = number;
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
                                phoneNumber.phoneNumber ?? '',
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
                            initialValue: widget.selectedMockUp!.emailAddress,
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
                              if (val!.isEmpty) {
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
                                newMockup.emailAddress = val.trim();
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
                                widget.selectedMockUp!.emailAddress!,
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
                                    .selectedMockUp!.mockupAddress!['Lat'];
                                _httpNavigation.lng = widget
                                    .selectedMockUp!.mockupAddress!['Lng'];
                                _httpNavigation.startNaviagtionGoogleMap();
                              } else {
                                await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => GoogleMapNavigation(
                                              lat: widget.selectedMockUp!
                                                  .mockupAddress!['Lat'],
                                              lng: widget.selectedMockUp!
                                                  .mockupAddress!['Lng'],
                                              navigate: true,
                                            )));
                              }
                            },
                            child: Text(
                              widget
                                  .selectedMockUp!.mockupAddress!['addressName']
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
                    //User check in and Check out
                    //check in / check out
                    if (!widget.currentUser!.roles!.contains('isAdmin') &&
                        !widget.currentUser!.roles!.contains('isSales'))
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: CheckInCard(
                          user: widget.currentUser!,
                          kind: SiteKind.mockup,
                          siteId: widget.selectedMockUp!.uid!,
                          siteName: widget.selectedMockUp!.mockupName ?? '',
                          lat: (widget.selectedMockUp!.mockupAddress?['Lat'] as num?)
                              ?.toDouble(),
                          lng: (widget.selectedMockUp!.mockupAddress?['Lng'] as num?)
                              ?.toDouble(),
                          radius: widget.selectedMockUp!.radius,
                        ),
                      ),
                    //Assigning users to mockup
                    //this feature is only available for admin users
                    widget.currentUser!.roles!.contains('isAdmin')
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
                                    onChanged: (UserData? val) {
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
                                      return widget.allWorkers!
                                          .map<Widget>(
                                            (item) => Center(
                                              child: Text(
                                                '${item.firstName} ${item.lastName} - ${item.roles!.first}',
                                                style: textStyle5,
                                              ),
                                            ),
                                          )
                                          .toList();
                                    },
                                    validator: (val) => val == null
                                        ? 'Please select User'
                                        : null,
                                    items: widget.allWorkers!
                                        .map((item) =>
                                            DropdownMenuItem<UserData>(
                                              value: item,
                                              child: Center(
                                                  child: Text(
                                                '${item.firstName} ${item.lastName}- ${item.roles!.first}',
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
                    widget.currentUser!.roles!.contains('isAdmin')
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
                                        height: _size!.height / 4.5,
                                        width: _size!.width - 80,
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
                                                      '${addedUsers[index].firstName} ${addedUsers[index].lastName} - ${addedUsers[index].roles!.first}',
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
                                      height: _size!.height / 4.5,
                                      width: _size!.width - 60,
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
                    //Submit button to update changes or to update workers on mockup
                    widget.currentUser!.roles!.contains('isAdmin')
                        ? Center(
                            child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        const Color.fromARGB(255, 191, 180, 66),
                                    fixedSize: Size(_size!.width / 2, 45),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(25))),
                                onPressed: () async {
                                  setState(() {
                                    _isLoading = true;
                                  });
                                  if (_editContent) {
                                    if (_formKey.currentState!.validate()) {
                                      _formKey.currentState!.save();
                                      var result = await db.updateMockupData(
                                        mockup: newMockup,
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
                                        userIds.add(element.uid!);
                                      }
                                      var result =
                                          await db.updateMockupWithWorkers(
                                              mockup: widget.selectedMockUp!,
                                              selectedUserIds: userIds,
                                              addedUsers: addedUsers,
                                              removedUsers: removedUsers);
                                      Navigator.pop(context);
                                    } else {
                                      if (_formKey.currentState!.validate()) {
                                        var result = await db.updateMockupData(
                                            mockup: newMockup);

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
  Widget _buildNewMockupForm() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 35),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const Text(
                'The following form will allow you to add a new mock-up, all required field should be filled before you can proceed',
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
                  label: const Text('Mockup Name'),
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
                    val!.isEmpty ? 'Mockup name cannot be empty' : null,
                onChanged: (val) {
                  setState(() {
                    newMockup.mockupName = val.trim();
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
                  label: const Text('Mockup Details'),
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
                    val!.isEmpty ? 'Mock-up details cannot be empty' : null,
                onChanged: (val) {
                  setState(() {
                    newMockup.mockupDetails = val.trim();
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
                    val!.isEmpty ? 'Contractor section cannot be empty' : null,
                onChanged: (val) {
                  setState(() {
                    newMockup.contactorCompany = val.trim();
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
                    val!.isEmpty ? 'Contact person cannot be empty' : null,
                onChanged: (val) {
                  setState(() {
                    newMockup.contactPerson = val.trim();
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
                  newMockup.phoneNumber = number;
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
                  if (val!.isEmpty) {
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
                    newMockup.emailAddress = val.trim();
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
                        newMockup.radius = radius!;
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
                          widget.projectLocation!['addressName']
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
                        fixedSize: Size(_size!.width / 2, 45),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25))),
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();
                        setState(() {
                          _isLoading = true;
                        });
                        var result = await db.addNewMockup(mockup: newMockup);
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
      {String? locationName, LatLng? locationAddress}) async {
    if (locationAddress != null && locationName != null) {
      _myLocation = {
        'addressName': locationName,
        'Lat': locationAddress.latitude,
        'Lng': locationAddress.longitude,
      };
      newMockup.mockupAddress = _myLocation;
      setState(() {});
    }
  }
}
