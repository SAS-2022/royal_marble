import 'dart:io';

import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:royal_marble/location/google_map_navigation.dart';
import 'package:royal_marble/models/user_model.dart';
import 'package:royal_marble/services/database.dart';
import 'package:royal_marble/shared/constants.dart';
import 'package:royal_marble/shared/snack_bar.dart';

import '../shared/country_picker.dart';

class UserDetails extends StatefulWidget {
  const UserDetails({Key key, this.currentUser, this.myAccount})
      : super(key: key);
  final UserData currentUser;
  final bool myAccount;

  @override
  State<UserDetails> createState() => _UserDetailsState();
}

class _UserDetailsState extends State<UserDetails> {
  Size _size;
  DatabaseService db = DatabaseService();
  SnackBarWidget _snackBarWidget = SnackBarWidget();
  final _formKey = GlobalKey<FormState>();
  UserData newUserData = UserData();

  @override
  void initState() {
    super.initState();
    _snackBarWidget.context = context;
    if (widget.currentUser != null) {
      newUserData.firstName = widget.currentUser.firstName;
      newUserData.lastName = widget.currentUser.lastName;
      newUserData.phoneNumber = widget.currentUser.phoneNumber;
      newUserData.company = widget.currentUser.company;
      newUserData.nationality = widget.currentUser.nationality;
      newUserData.homeAddress = widget.currentUser.homeAddress;
    }
  }

  @override
  Widget build(BuildContext context) {
    _size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Main Page'),
        backgroundColor: const Color.fromARGB(255, 191, 180, 66),
      ),
      body: SingleChildScrollView(
          child:
              widget.myAccount ? _buildMyUserDetails() : _buildUserDetails()),
    );
  }

  Widget _buildUserDetails() {
    return Padding(
      padding: const EdgeInsets.only(top: 35, left: 25, right: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'First Name: ',
                style: textStyle5,
              ),
              Text(
                widget.currentUser.firstName,
                style: textStyle3,
              )
            ],
          ),
          const SizedBox(
            height: 15,
          ),
          Row(
            children: [
              const Text(
                'Last Name: ',
                style: textStyle5,
              ),
              Text(
                widget.currentUser.lastName,
                style: textStyle3,
              )
            ],
          ),
          const SizedBox(
            height: 15,
          ),
          Row(
            children: [
              const Text(
                'Phone Number: ',
                style: textStyle5,
              ),
              Text(
                widget.currentUser.phoneNumber,
                style: textStyle3,
              )
            ],
          ),
          const SizedBox(
            height: 15,
          ),
          Row(
            children: [
              const Text(
                'Email Address: ',
                style: textStyle5,
              ),
              Text(
                widget.currentUser.emailAddress,
                style: textStyle3,
              )
            ],
          ),
          const SizedBox(
            height: 15,
          ),
          Row(
            children: [
              const Text(
                'Nationality: ',
                style: textStyle5,
              ),
              Text(
                widget.currentUser.nationality['countryName'],
                style: textStyle3,
              )
            ],
          ),
          const SizedBox(
            height: 15,
          ),
          Row(
            children: [
              const Text(
                'Company: ',
                style: textStyle5,
              ),
              Text(
                widget.currentUser.company,
                style: textStyle3,
              )
            ],
          ),
          const SizedBox(
            height: 15,
          ),
          Row(
            children: [
              const Text(
                'Home Address: ',
                style: textStyle5,
              ),
              widget.currentUser.homeAddress != null &&
                      widget.currentUser.homeAddress.isNotEmpty
                  ? Text(
                      widget.currentUser.homeAddress != null
                          ? widget.currentUser.homeAddress['name']
                          : 'address not assigned',
                      style: textStyle3,
                    )
                  : GestureDetector(
                      onTap: () async {},
                      child: const Text('Add Address', style: textStyle3),
                    )
            ],
          ),
          const SizedBox(
            height: 15,
          ),
          Row(
            children: [
              const Text(
                'Active User: ',
                style: textStyle5,
              ),
              Text(
                widget.currentUser.isActive.toString(),
                style: textStyle3,
              )
            ],
          ),
          const Divider(height: 30, thickness: 3),
          //the below code will be functions for the admin to do
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
                      primary: widget.currentUser.isActive
                          ? Colors.red[400]
                          : Colors.green[400],
                      fixedSize: Size(_size.width / 2, 45),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25))),
                  onPressed: () async {
                    var result = await db.activateDeactivateUser(
                        uid: widget.currentUser.uid,
                        active: !widget.currentUser.isActive);
                    if (result == 'Completed') {
                      Navigator.pop(context);
                    } else {
                      _snackBarWidget.content =
                          'failed to deactivate account, please contact developer';
                      _snackBarWidget.showSnack();
                    }
                  },
                  child: widget.currentUser.isActive
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
                      primary: widget.currentUser.isActive
                          ? Colors.grey[300]
                          : Colors.red[400],
                      fixedSize: Size(_size.width / 2, 45),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25))),
                  onPressed: widget.currentUser.isActive ? null : () async {},
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
        padding: const EdgeInsets.only(top: 35, left: 25, right: 10),
        child: SizedBox(
          width: _size.width - 10,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                    child: widget.currentUser.homeAddress != null
                        ? Text(
                            widget.currentUser.homeAddress != null
                                ? widget.currentUser.homeAddress['name']
                                : 'address not assigned',
                            style: textStyle3,
                          )
                        : GestureDetector(
                            onTap: () async {
                              if (Platform.isIOS) {
                              } else {
                                await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => GoogleMapNavigation()));
                              }
                            },
                            child: const Text(
                              'Add Address',
                              style: textStyle5,
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
                        primary: widget.currentUser.isActive
                            ? Colors.red[400]
                            : Colors.green[400],
                        fixedSize: Size(_size.width / 2, 45),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25))),
                    onPressed: () async {
                      var result = await db.updateCurrentUser(
                          uid: widget.currentUser.uid, newUsers: newUserData);
                      if (result == 'Completed') {
                        Navigator.pop(context);
                      } else {
                        _snackBarWidget.content =
                            'failed to update account, please contact developer';
                        _snackBarWidget.showSnack();
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

  selectCountry(Map<String, dynamic> country) {
    print('the country: $country');
    newUserData.nationality = country;
  }
}
