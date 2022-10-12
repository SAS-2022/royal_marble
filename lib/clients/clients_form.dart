import 'dart:io';

import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:royal_marble/models/user_model.dart';
import 'package:royal_marble/services/database.dart';
import 'package:royal_marble/shared/constants.dart';
import 'package:royal_marble/shared/snack_bar.dart';

import '../location/google_map_navigation.dart';
import '../models/business_model.dart';

class ClientForm extends StatefulWidget {
  const ClientForm({Key key, this.client, this.currentUser, this.isNewClient})
      : super(key: key);
  final ClientData client;
  final UserData currentUser;
  final bool isNewClient;

  @override
  State<ClientForm> createState() => _ClientFormState();
}

class _ClientFormState extends State<ClientForm> {
  final _formKey = GlobalKey<FormState>();
  final db = DatabaseService();
  final _snackBarWidget = SnackBarWidget();
  ClientData newClient = ClientData();
  bool _editContent = false;
  Map<String, dynamic> _myLocation = {};
  Size _size;

  @override
  void initState() {
    super.initState();
    _snackBarWidget.context = context;
    newClient.userId = widget.currentUser.uid;
    if (widget.client != null) {
      newClient = widget.client;

      if (widget.client.clientAddress != null) {
        _myLocation = {
          'addressName': newClient.clientAddress['addressName'],
          'Lat': newClient.clientAddress['Lat'],
          'Lng': newClient.clientAddress['Lng'],
        };
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Client Form'),
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
      body: widget.isNewClient
          ? _buildNewClientForm()
          : _buildSelectedClientDetails(),
    );
  }

  //This form will allow to add a new client
  Widget _buildNewClientForm() {
    return Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 35),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const Text(
                  'The following form will allow you to add a new client, all required field should be filled before you can proceed',
                  style: textStyle6,
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
                    label: const Text('Client Name'),
                    hintText: 'Ex: The Granite Co.',
                    fillColor: Colors.grey[100],
                    enabledBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(15.0)),
                        borderSide: BorderSide(color: Colors.grey)),
                    focusedBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(15.0)),
                        borderSide: BorderSide(color: Colors.green)),
                  ),
                  validator: (val) =>
                      val.isEmpty ? 'Client name cannot be empty' : null,
                  onChanged: (val) {
                    setState(() {
                      newClient.clientName = val.trim();
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
                      newClient.contactPerson = val.trim();
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
                    label: const Text('Client Phone'),
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
                      newClient.phoneNumber = val.trim();
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
                      newClient.emailAddress = val.trim();
                    });
                  },
                ),
                const SizedBox(
                  height: 15,
                ),
                Container(
                  decoration: BoxDecoration(
                      border: Border.all(),
                      borderRadius: BorderRadius.circular(15)),
                  height: 50,
                  child: Center(
                    child: GestureDetector(
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
                      child: Text(
                        _myLocation.isNotEmpty
                            ? 'Change Address'
                            : 'Add Address',
                        style: textStyle5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 15,
                ),
                SizedBox(
                  height: 40,
                  child: Center(child: Text('${_myLocation['addressName']}')),
                ),
                const SizedBox(
                  height: 15,
                ),
                //Submit button will allow you add the entered data into the database
                Center(
                  child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          primary: const Color.fromARGB(255, 191, 180, 66),
                          fixedSize: Size(_size.width / 2, 45),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25))),
                      onPressed: () async {
                        if (_formKey.currentState.validate()) {
                          var result =
                              await db.addNewClients(client: newClient);
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
                ),
              ],
            ),
          ),
        ));
  }

  //This form will allow to view and update a current client
  Widget _buildSelectedClientDetails() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 35),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const Text(
                'The following form will allow you to update a current client, all required field should be filled before you can proceed',
                style: textStyle6,
              ),
              const SizedBox(
                height: 15,
              ),
              _editContent
                  ? TextFormField(
                      autofocus: false,
                      initialValue: newClient.clientName,
                      style: textStyle5,
                      decoration: InputDecoration(
                        filled: true,
                        label: const Text('Client Name'),
                        hintText: 'Ex: The Granite Co.',
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
                      validator: (val) =>
                          val.isEmpty ? 'Client name cannot be empty' : null,
                      onChanged: (val) {
                        setState(() {
                          newClient.clientName = val.trim();
                        });
                      },
                    )
                  : Row(children: [
                      const Expanded(
                        flex: 1,
                        child: Text(
                          'Client Name',
                          style: textStyle5,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          widget.client.clientName,
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
                      initialValue: newClient.contactPerson,
                      style: textStyle5,
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
                      validator: (val) =>
                          val.isEmpty ? 'Contact person cannot be empty' : null,
                      onChanged: (val) {
                        setState(() {
                          newClient.contactPerson = val.trim();
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
                          widget.client.contactPerson,
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
                      initialValue: newClient.phoneNumber,
                      style: textStyle5,
                      keyboardType: TextInputType.number,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: InputDecoration(
                        filled: true,
                        label: const Text('Client Phone'),
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
                          newClient.phoneNumber = val.trim();
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
                          widget.client.phoneNumber,
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
                      initialValue: newClient.emailAddress,
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
                          newClient.emailAddress = val.trim();
                        });
                      },
                    )
                  : Row(children: [
                      const Expanded(
                        flex: 1,
                        child: Text(
                          'Client Email',
                          style: textStyle5,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          widget.client.emailAddress,
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
              // SizedBox(
              //   height: 40,
              //   child: Center(child: Text('${_myLocation['addressName']}')),
              // ),
              //Submit button will allow you add the entered data into the database
              _editContent
                  ? Center(
                      child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              primary: const Color.fromARGB(255, 191, 180, 66),
                              fixedSize: Size(_size.width / 2, 45),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25))),
                          onPressed: () async {
                            if (_formKey.currentState.validate()) {
                              var result =
                                  await db.addNewClients(client: newClient);
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
    );
  }

  Future selecteMapLocation(
      {String locationName, LatLng locationAddress}) async {
    if (locationAddress != null && locationName != null) {
      _myLocation = {
        'addressName': locationName,
        'Lat': locationAddress.latitude,
        'Lng': locationAddress.longitude,
      };
      newClient.clientAddress = _myLocation;

      setState(() {});
    }
  }
}
