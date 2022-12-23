import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:path/path.dart' as Path;
import 'package:royal_marble/account_settings/helpers.dart';
import 'package:royal_marble/account_settings/helpers_list.dart';
import 'package:royal_marble/location/google_map_navigation.dart';
import 'package:royal_marble/location/http_navigation.dart';
import 'package:royal_marble/models/user_model.dart';
import 'package:royal_marble/services/database.dart';
import 'package:royal_marble/shared/constants.dart';
import 'package:royal_marble/shared/loading.dart';
import 'package:royal_marble/shared/snack_bar.dart';
import '../shared/country_picker.dart';

class UserDetails extends StatefulWidget {
  const UserDetails(
      {Key key, this.currentUser, this.myAccount, this.selectedUser})
      : super(key: key);
  final UserData currentUser;
  final UserData selectedUser;
  final bool myAccount;

  @override
  State<UserDetails> createState() => _UserDetailsState();
}

class _UserDetailsState extends State<UserDetails> {
  Size _size;
  DatabaseService db = DatabaseService();
  final _snackBarWidget = SnackBarWidget();
  final _formKey = GlobalKey<FormState>();
  HttpNavigation _httpNavigation = HttpNavigation();
  UserData newUserData = UserData();
  Map<String, dynamic> _myLocation = {};
  String selectedRoles;
  XFile pickedImage;
  File pickImageFile;
  final ImagePicker _picker = ImagePicker();
  bool _imageRequested = false;
  ImageSource _imageSource;
  List<dynamic> currentRoles = [
    'Mason',
    'Supervisor',
    'Site Engineer',
    'Sales',
    'Admin'
  ];
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _snackBarWidget.context = context;

    if (widget.currentUser != null && widget.selectedUser == null) {
      newUserData.firstName = widget.currentUser.firstName;
      newUserData.lastName = widget.currentUser.lastName;
      newUserData.phoneNumber = widget.currentUser.phoneNumber;
      newUserData.company = widget.currentUser.company;
      newUserData.nationality = widget.currentUser.nationality;
      newUserData.homeAddress = widget.currentUser.homeAddress;
      newUserData.imageUrl = widget.currentUser.imageUrl;
      if (newUserData.homeAddress != null) {
        _myLocation = newUserData.homeAddress;
      }
    }

    //show the current user role
    if (widget.selectedUser != null &&
        widget.selectedUser.roles != null &&
        widget.selectedUser.roles.isNotEmpty) {
      switch (widget.selectedUser.roles.first.toString()) {
        case 'isNormalUser':
          selectedRoles = 'Mason';
          break;
        case 'isSupervisor':
          selectedRoles = 'Supervisor';
          break;
        case 'isSiteEngineer':
          selectedRoles = 'Site Engineer';
          break;
        case 'isAdmin':
          selectedRoles = 'Admin';
          break;
        case 'isSales':
          selectedRoles = 'Sales';
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Page'),
        backgroundColor: const Color.fromARGB(255, 191, 180, 66),
        actions: [
          //Button to add helpers
          widget.selectedUser != null &&
                  widget.selectedUser.roles.contains('isNormalUser')
              ? Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: TextButton(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => HelperProvider(
                              currentUser: widget.currentUser,
                              selectedUser: widget.selectedUser,
                            ),
                          ),
                        );
                      },
                      child: const Text(
                        'Helpers',
                        style: textStyle2,
                      )),
                )
              : const SizedBox.shrink(),
          //in case the current user is a mson in order to view his helpers
          widget.myAccount && widget.currentUser.roles.contains('isNormalUser')
              ? Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: TextButton(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => HelpersList(
                              currentUser: widget.currentUser,
                            ),
                          ),
                        );
                      },
                      child: const Text(
                        'Helpers',
                        style: textStyle2,
                      )),
                )
              : const SizedBox.shrink(),
        ],
      ),
      body: Stack(children: [
        SingleChildScrollView(
            child:
                widget.myAccount ? _buildMyUserDetails() : _buildUserDetails()),
        _isUpdating
            ? const Center(
                child: Loading(),
              )
            : const SizedBox.shrink(),
      ]),
      bottomNavigationBar: _imageRequested
          ? BottomAppBar(
              clipBehavior: Clip.hardEdge,
              elevation: 2,
              child: Container(
                decoration: BoxDecoration(
                    color: Colors.grey[600],
                    border: Border.all(color: Colors.grey[800]),
                    borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(25),
                        topRight: Radius.circular(25))),
                height: _size.height / 10,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                            onPressed: () async {
                              _imageSource = ImageSource.gallery;
                              await _openImagePicker();
                            },
                            icon: const Icon(
                              Icons.photo_album,
                              size: 50,
                              color: Color.fromARGB(255, 191, 180, 66),
                            )),
                        IconButton(
                            onPressed: () async {
                              _imageSource = ImageSource.camera;
                              await _openImagePicker();
                            },
                            icon: const Icon(
                              Icons.camera,
                              size: 50,
                              color: Color.fromARGB(255, 191, 180, 66),
                            ))
                      ]),
                ),
              ))
          : null,
    );
  }

  Widget _buildUserDetails() {
    return Padding(
      padding: const EdgeInsets.only(top: 5, left: 15, right: 15),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Container(
                height: _size.height / 5,
                width: _size.width / 2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(),
                ),
                child: widget.selectedUser.imageUrl == null
                    ? const Center(
                        child: Text(
                          'No Photo',
                          style: textStyle3,
                        ),
                      )
                    : CircleAvatar(
                        backgroundImage: NetworkImage(
                        widget.selectedUser.imageUrl,
                        scale: 2,
                      )),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(15)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      flex: 2,
                      child: Text(
                        'First Name: ',
                        style: textStyle5,
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        widget.selectedUser.firstName,
                        style: textStyle12,
                      ),
                    )
                  ],
                ),
                const SizedBox(
                  height: 15,
                ),
                Row(
                  children: [
                    const Expanded(
                      flex: 2,
                      child: Text(
                        'Last Name: ',
                        style: textStyle5,
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        widget.selectedUser.lastName,
                        style: textStyle12,
                      ),
                    )
                  ],
                ),
                const SizedBox(
                  height: 15,
                ),
                Row(
                  children: [
                    const Expanded(
                      flex: 2,
                      child: Text(
                        'Phone Number: ',
                        style: textStyle5,
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        widget.selectedUser.phoneNumber,
                        style: textStyle12,
                      ),
                    )
                  ],
                ),
                const SizedBox(
                  height: 15,
                ),
                Row(
                  children: [
                    const Expanded(
                      flex: 2,
                      child: Text(
                        'Email Address: ',
                        style: textStyle5,
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        widget.selectedUser.emailAddress,
                        style: textStyle12,
                      ),
                    )
                  ],
                ),
                const SizedBox(
                  height: 15,
                ),
                Row(
                  children: [
                    const Expanded(
                      flex: 2,
                      child: Text(
                        'Nationality: ',
                        style: textStyle5,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        widget.selectedUser.nationality['countryName'],
                        style: textStyle12,
                      ),
                    )
                  ],
                ),
                const SizedBox(
                  height: 15,
                ),
                Row(
                  children: [
                    const Expanded(
                      flex: 2,
                      child: Text(
                        'Company: ',
                        style: textStyle5,
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        widget.selectedUser.company,
                        style: textStyle12,
                      ),
                    )
                  ],
                ),
                const SizedBox(
                  height: 15,
                ),
                Row(
                  children: [
                    const Expanded(
                      flex: 2,
                      child: Text(
                        'Home Address: ',
                        style: textStyle5,
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: GestureDetector(
                        onTap: () async {
                          if (widget.selectedUser.homeAddress != null) {
                            if (Platform.isIOS) {
                              _httpNavigation.context = context;
                              _httpNavigation.lat = _myLocation['Lat'];
                              _httpNavigation.lng = _myLocation['Lng'];
                              await _httpNavigation.startNaviagtionGoogleMap();
                            } else {
                              await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => GoogleMapNavigation(
                                            getLocation: selecteMapLocation,
                                            lat: _myLocation['Lat'],
                                            lng: _myLocation['Lng'],
                                            navigate: true,
                                          )));
                            }
                          }
                        },
                        child: Text(
                          widget.selectedUser.homeAddress != null
                              ? widget.selectedUser.homeAddress['addressName']
                              : 'Address not found',
                          style: textStyle12,
                        ),
                      ),
                    )
                  ],
                ),
                const SizedBox(
                  height: 15,
                ),
                Row(
                  children: [
                    const Expanded(
                      flex: 2,
                      child: Text(
                        'Active User: ',
                        style: textStyle5,
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        widget.selectedUser.isActive.toString(),
                        style: textStyle12,
                      ),
                    )
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 15,
          ),
          // const Divider(height: 30, thickness: 3),
          //the below code will be functions for the admin to do
          //Assign user's role
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'The following option will allow you to assign a certain role for this user',
                style: textStyle6,
              ),
              const SizedBox(
                height: 10,
              ),
              //drop down list showing current roles available
              Container(
                alignment: AlignmentDirectional.centerStart,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(
                    Radius.circular(15.0),
                  ),
                  border: Border.all(width: 1.0, color: Colors.grey),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration.collapsed(hintText: ''),
                    isExpanded: true,
                    value: selectedRoles,
                    hint: const Center(
                      child: Text(
                        'Select User',
                      ),
                    ),
                    onChanged: (String val) {
                      if (val != null) {
                        setState(() {
                          selectedRoles = val;
                        });
                      }
                    },
                    selectedItemBuilder: (BuildContext context) {
                      return currentRoles
                          .map<Widget>(
                            (item) => Center(
                              child: Text(
                                item,
                                style: textStyle5,
                              ),
                            ),
                          )
                          .toList();
                    },
                    validator: (val) =>
                        val == null ? 'Please select User Role' : null,
                    items: currentRoles
                        .map((item) => DropdownMenuItem<String>(
                              value: item,
                              child: Center(
                                  child: Text(
                                item,
                                style: textStyle5,
                              )),
                            ))
                        .toList(),
                  ),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[400],
                      fixedSize: Size(_size.width / 2, 45),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25))),
                  onPressed: () async {
                    var result;
                    if (selectedRoles != null) {
                      result = await db.assignUserRole(
                          selectedRole: selectedRoles,
                          uid: widget.currentUser.uid);
                    }
                    if (result == 'Completed') {
                      Navigator.pop(context);
                    } else {
                      _snackBarWidget.content =
                          'failed to deactivate account, please contact developer';
                      _snackBarWidget.showSnack();
                    }
                  },
                  child: const Text(
                    'Assign',
                    style: textStyle2,
                  ))
            ],
          ),
          const SizedBox(
            height: 20,
          ),

          //Activate or deactivate an account
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'The following button will allow you to grant access and remove it from a selected user',
                style: textStyle6,
              ),
              const SizedBox(
                height: 10,
              ),
              ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: widget.selectedUser.isActive
                          ? Colors.red[400]
                          : Colors.green[400],
                      fixedSize: Size(_size.width / 2, 45),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25))),
                  onPressed: () async {
                    var result = await db.activateDeactivateUser(
                        uid: widget.selectedUser.uid,
                        active: !widget.selectedUser.isActive);
                    if (result == 'Completed') {
                      Navigator.pop(context);
                    } else {
                      _snackBarWidget.content =
                          'failed to deactivate account, please contact developer';
                      _snackBarWidget.showSnack();
                    }
                  },
                  child: widget.selectedUser.isActive
                      ? const Text(
                          'Deactivate',
                          style: textStyle2,
                        )
                      : const Text(
                          'Activate',
                          style: textStyle2,
                        ))
            ],
          ),
          const SizedBox(
            height: 20,
          ),
          //Delete an account
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'The following button will allow you to delete a current user (A user has to be deactivated before they can be deleted)',
                style: textStyle6,
              ),
              const SizedBox(
                height: 10,
              ),
              ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: widget.selectedUser.isActive
                          ? Colors.grey[300]
                          : Colors.red[400],
                      fixedSize: Size(_size.width / 2, 45),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25))),
                  onPressed: widget.selectedUser.isActive
                      ? null
                      : () async {
                          //will delete the selected user
                          var result =
                              await db.deleteUser(uid: widget.selectedUser.uid);

                          _snackBarWidget.content = result;
                          _snackBarWidget.showSnack();
                          Navigator.pop(context);
                        },
                  child: const Text(
                    'Delete',
                    style: textStyle2,
                  ))
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMyUserDetails() {
    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.only(top: 5, left: 25, right: 10),
        child: SizedBox(
          width: _size.width - 10,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: GestureDetector(
                    onTap: () async => _selectImageSource(),
                    child: Container(
                      height: _size.height / 5,
                      width: _size.width / 2,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(),
                      ),
                      child:
                          pickImageFile == null && newUserData.imageUrl == null
                              ? const Center(
                                  child: Text(
                                    'Add Photo',
                                    style: textStyle3,
                                  ),
                                )
                              : pickImageFile != null
                                  ? CircleAvatar(
                                      backgroundImage: FileImage(
                                      File(pickImageFile.path),
                                      scale: 2,
                                    ))
                                  : CircleAvatar(
                                      backgroundImage: NetworkImage(
                                      newUserData.imageUrl,
                                      scale: 2,
                                    )),
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  const Expanded(
                    flex: 1,
                    child: Text(
                      'First Name: ',
                      style: textStyle5,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      initialValue: newUserData.firstName,
                      style: textStyle3,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey[100],
                        enabledBorder: const OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(15.0)),
                            borderSide: BorderSide(color: Colors.grey)),
                        focusedBorder: const OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(15.0)),
                            borderSide: BorderSide(color: Colors.blue)),
                      ),
                      validator: (val) {
                        return val.isEmpty ? 'Last Name cannot be empty' : null;
                      },
                      onChanged: (val) {
                        if (val.isNotEmpty) {
                          newUserData.firstName = val.trim();
                        }
                      },
                    ),
                  )
                ],
              ),
              const SizedBox(
                height: 15,
              ),
              Row(
                children: [
                  const Expanded(
                    flex: 1,
                    child: Text(
                      'Last Name: ',
                      style: textStyle5,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      initialValue: newUserData.lastName,
                      style: textStyle3,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey[100],
                        enabledBorder: const OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(15.0)),
                            borderSide: BorderSide(color: Colors.grey)),
                        focusedBorder: const OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(15.0)),
                            borderSide: BorderSide(color: Colors.blue)),
                      ),
                      validator: (val) {
                        return val.isEmpty ? 'Last Name cannot be empty' : null;
                      },
                      onChanged: (val) {
                        if (val.isNotEmpty) {
                          newUserData.lastName = val.trim();
                        }
                      },
                    ),
                  )
                ],
              ),
              const SizedBox(
                height: 15,
              ),
              Row(
                children: [
                  const Expanded(
                    flex: 1,
                    child: Text(
                      'Phone Number: ',
                      style: textStyle5,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      initialValue: newUserData.phoneNumber,
                      style: textStyle3,
                      keyboardType: TextInputType.number,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey[100],
                        enabledBorder: const OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(15.0)),
                            borderSide: BorderSide(color: Colors.grey)),
                        focusedBorder: const OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(15.0)),
                            borderSide: BorderSide(color: Colors.blue)),
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
                        if (val.isNotEmpty) {
                          newUserData.phoneNumber = val.trim();
                        }
                      },
                    ),
                  )
                ],
              ),
              const SizedBox(
                height: 15,
              ),
              Row(
                children: [
                  const Expanded(
                    flex: 1,
                    child: Text(
                      'Email Address: ',
                      style: textStyle5,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      widget.currentUser.emailAddress,
                      style: textStyle3,
                    ),
                  )
                ],
              ),
              const SizedBox(
                height: 15,
              ),
              Row(
                children: [
                  const Expanded(
                    flex: 1,
                    child: Text(
                      'Nationality: ',
                      style: textStyle5,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.grey,
                          ),
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                        child: CountryDropDownPicker(
                          selectCountry: selectCountry,
                          countryOfResidence: newUserData.nationality,
                        )),
                  )
                ],
              ),
              const SizedBox(
                height: 15,
              ),
              Row(
                children: [
                  const Expanded(
                    flex: 1,
                    child: Text(
                      'Company: ',
                      style: textStyle5,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      initialValue: newUserData.company,
                      style: textStyle3,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey[100],
                        enabledBorder: const OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(15.0)),
                            borderSide: BorderSide(color: Colors.grey)),
                        focusedBorder: const OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(15.0)),
                            borderSide: BorderSide(color: Colors.blue)),
                      ),
                      validator: (val) =>
                          val.isEmpty ? 'Company cannot be empty' : null,
                      onChanged: (val) {
                        if (val.isNotEmpty) {
                          setState(() {
                            newUserData.company = val.trim();
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 15,
              ),
              Row(
                children: [
                  const Expanded(
                    flex: 1,
                    child: Text(
                      'Home Address: ',
                      style: textStyle5,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: () async {
                        await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => GoogleMapNavigation(
                                      getLocation: selecteMapLocation,
                                      navigate: false,
                                    )));
                      },
                      child: Container(
                        decoration: BoxDecoration(
                            border: Border.all(),
                            borderRadius: BorderRadius.circular(15)),
                        height: 60,
                        child: Center(
                          child: _myLocation.isEmpty
                              ? const Text(
                                  'Add Address',
                                  style: textStyle5,
                                )
                              : Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 5),
                                  child: Text(
                                    _myLocation['addressName'],
                                    style: textStyle9,
                                    softWrap: true,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  )
                ],
              ),
              const SizedBox(
                height: 25,
              ),
              //Add and update button in order to monitor update
              Center(
                child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: widget.currentUser.isActive
                            ? Colors.red[400]
                            : Colors.green[400],
                        fixedSize: Size(_size.width / 2, 45),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25))),
                    onPressed: _isUpdating
                        ? null
                        : () async {
                            if (_formKey.currentState.validate() &&
                                _myLocation.isNotEmpty) {
                              setState(() {
                                _isUpdating = true;
                              });
                              if (pickedImage != null) {
                                String imageUrl =
                                    await _uploadImage(file: pickedImage);
                                newUserData.imageUrl = imageUrl;
                              }

                              var result = await db.updateCurrentUser(
                                  uid: widget.currentUser.uid,
                                  newUsers: newUserData);
                              if (result == 'Completed') {
                                if (mounted) {
                                  setState(() {
                                    _isUpdating = false;
                                  });
                                }
                                Navigator.pop(context);
                              } else {
                                if (mounted) {
                                  setState(() {
                                    _isUpdating = false;
                                  });
                                }
                                _snackBarWidget.content =
                                    'failed to update account, please contact developer';
                                _snackBarWidget.showSnack();
                              }
                            }
                          },
                    child: const Text(
                      'Update',
                      style: textStyle2,
                    )),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _selectImageSource() {
    setState(() {
      _imageRequested = !_imageRequested;
    });
  }

  Future<String> _uploadImage({XFile file}) async {
    FirebaseStorage storageReference;
    String folderName = 'profile_images';

    try {
      storageReference = FirebaseStorage.instance;
      var ref = storageReference
          .ref()
          .child('$folderName/${Path.basename(file.path)}');
      var uploadTask = ref.putFile(File(file.path));
      var downloadUrl = await (await uploadTask).ref.getDownloadURL();
      return downloadUrl;
    } catch (e, stackTrace) {
      _snackBarWidget.content = 'Image Error: $e';
      _snackBarWidget.showSnack();
      return e;
    }
  }

  Future _openImagePicker() async {
    try {
      if (_imageRequested) {
        pickedImage = await _picker.pickImage(
            preferredCameraDevice: CameraDevice.front,
            source: _imageSource,
            maxHeight: _size.height - 10,
            maxWidth: _size.width - 10,
            imageQuality: 100);
      }
      _imageRequested = false;
      setState(() {});
      pickImageFile = File(pickedImage.path);
      return pickedImage;
    } catch (e) {
      print('the error: $e');
      _snackBarWidget.content = 'Image could not be picked: $e';
      _snackBarWidget.showSnack();
    }
  }

  Future selecteMapLocation(
      {String locationName, LatLng locationAddress}) async {
    if (locationAddress != null && locationName != null) {
      _myLocation = {
        'addressName': locationName,
        'Lat': locationAddress.latitude,
        'Lng': locationAddress.longitude,
      };
      newUserData.homeAddress = _myLocation;
      setState(() {});
    } else {
      _myLocation = {'Lat': '', 'Lng': ''};
    }
  }

  selectCountry(Map<String, dynamic> country) {
    newUserData.nationality = country;
  }
}
